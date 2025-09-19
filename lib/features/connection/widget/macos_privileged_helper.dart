import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rostov_vpn/features/config_option/data/config_option_repository.dart';
import 'package:rostov_vpn/singbox/model/singbox_config_enum.dart';

/// Показывает диалог при отсутствии привилегий для TUN на macOS
/// Предлагает: установить системный helper (требуется пароль) или переключиться на System Proxy
Future<void> showMacOsTunHelperDialog(BuildContext context, WidgetRef ref) async {
  if (!Platform.isMacOS) return;

  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Требуются права для TUN'),
        content: const Text(
          'Для режима TUN на macOS нужен системный компонент.\n'
          'Можно установить helper (потребуется пароль администратора)\n'
          'или переключиться на режим System Proxy без прав.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _attemptInstallHelper(context);
            },
            child: const Text('Установить helper'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(ConfigOptions.serviceMode.notifier).update(ServiceMode.systemProxy);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Включён режим System Proxy')),
                );
              }
            },
            child: const Text('System Proxy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
        ],
      );
    },
  );
}

/// Черновая попытка установки helper без SMJobBless.
/// Проверяет наличие helper-бинаря и (опционально) plist; при наличии plist
/// пробует автоматическую установку через osascript (админ-пароль).
Future<void> _attemptInstallHelper(BuildContext context) async {
  // Пытаемся угадать расположение бандла и ресурсов
  final exe = Platform.resolvedExecutable;
  // Обычно: .../YourApp.app/Contents/MacOS/YourApp
  final contentsDir = () {
    final macosIdx = exe.indexOf('/Contents/MacOS/');
    if (macosIdx > 0) return exe.substring(0, macosIdx + '/Contents'.length);
    return '';
  }();

  final candidates = <String>[
    if (contentsDir.isNotEmpty) '$contentsDir/Resources/RostovVPNCli',
    if (contentsDir.isNotEmpty) '$contentsDir/Resources/rostovvpn-helper',
    '${Directory.current.path}/libcore/bin/RostovVPNCli',
    // Доп. пути, которые встречаются у вас в репо
    '${Directory.current.path}/libcore/bin/GNUSparseFile.0/RostovVPNCli',
    '${Directory.current.path}/libcore/bin/GNUSparseFile.0/HiddifyCli',
  ];

  final existing = candidates.where((p) => File(p).existsSync()).toList();
  if (existing.isEmpty) {
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Helper не найден'),
          content: Text(
            'Не удалось найти macOS helper в ресурсах приложения.\n\n'
            'Ожидаемые пути:\n- ${candidates.join('\n- ')}\n\n'
            'Добавьте бинарь helper для macOS (x86_64/arm64) в ресурсы приложения\n'
            'и повторите попытку. Временно вы можете использовать режим System Proxy.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Ок'),
            ),
          ],
        ),
      );
    }
    return;
  }

  final helperPath = existing.first;
  final plistLabel = 'com.rostovvpn.helper';
  final plistPath = '/Library/LaunchDaemons/$plistLabel.plist';
  final helperDst = '/Library/PrivilegedHelperTools/$plistLabel';

  // Пытаемся найти готовый plist в ресурсах
  final bundledPlistCandidates = <String>[
    if (contentsDir.isNotEmpty) '$contentsDir/Resources/$plistLabel.plist',
    '${Directory.current.path}/macos/$plistLabel.plist',
    '${Directory.current.path}/macos/packaging/$plistLabel.plist',
  ];
  final bundledPlist = bundledPlistCandidates.firstWhere(
    (p) => File(p).existsSync(),
    orElse: () => '',
  );

  if (bundledPlist.isNotEmpty) {
    // Автоматическая установка через osascript
    final cmds = [
      '/usr/bin/xattr -dr com.apple.quarantine ' + _shQ(helperPath) + ' || true',
      '/usr/bin/xattr -dr com.apple.quarantine ' + _shQ(bundledPlist) + ' || true',
      '/bin/mkdir -p /Library/PrivilegedHelperTools',
      '/bin/cp -f ' + _shQ(helperPath) + ' ' + _shQ(helperDst),
      '/usr/sbin/chown root:wheel ' + _shQ(helperDst),
      '/bin/chmod 755 ' + _shQ(helperDst),
      '/bin/cp -f ' + _shQ(bundledPlist) + ' ' + _shQ(plistPath),
      '/usr/sbin/chown root:wheel ' + _shQ(plistPath),
      '/bin/chmod 644 ' + _shQ(plistPath),
      '/bin/launchctl bootstrap system ' + _shQ(plistPath) + ' || /bin/launchctl bootout system ' + _shQ(plistPath) + ' && /bin/launchctl bootstrap system ' + _shQ(plistPath),
      '/bin/launchctl enable system/' + plistLabel,
      '/bin/launchctl kickstart -k system/' + plistLabel,
    ];

    final appleScript = 'do shell script "' +
        cmds.map((c) => c.replaceAll('"', '\\"')).join(' && ').replaceAll('\n', ' ; ') +
        '" with administrator privileges';
    try {
      final result = await Process.run('/usr/bin/osascript', ['-e', appleScript]);
      if (result.exitCode == 0) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Helper установлен и запущен')),
          );
        }
        return;
      } else {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Ошибка установки helper\'а'),
              content: SingleChildScrollView(
                child: SelectableText('Код: ${result.exitCode}\n${result.stderr}\n${result.stdout}'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Закрыть'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Не удалось запустить osascript'),
            content: Text('$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Ок'),
              ),
            ],
          ),
        );
      }
    }
  }

  // Нет plist — показать инструкции
  final commands = [
    'set -e',
    'sudo mkdir -p /Library/PrivilegedHelperTools',
    "sudo cp -f '${helperPath.replaceAll("'", "'\\''")}' '$helperDst'",
    'sudo chown root:wheel "'+helperDst+'"',
    'sudo chmod 755 "'+helperDst+'"',
    '# Сохраните launchd plist в '+plistPath+', затем:',
    'sudo launchctl bootstrap system "'+plistPath+'"',
    'sudo launchctl enable system/'+plistLabel,
    'sudo launchctl kickstart -k system/'+plistLabel,
  ].join('\n');

  if (context.mounted) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Требуется подготовка plist'),
        content: SingleChildScrollView(
          child: SelectableText(
            'Найден helper: '+helperPath+'\n\n'
            'Для завершения установки нужен launchd plist (Label: '+plistLabel+').\n\n'
            'Шаги (в терминале):\n\n'+commands,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}

String _shQ(String path) => '\'' + path.replaceAll('\'', '\'\\\'\'') + '\'';
