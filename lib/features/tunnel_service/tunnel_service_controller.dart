import 'dart:async';
import 'dart:io';

class TunnelServiceController {
  static const int _port = 18020;

  /// Самолечение на старте: пытаемся остановить TunService и освободить порт.
  static Future<void> selfHealOnStartup() async {
    try {
      await _stop();
    } catch (_) {}
    final ok = await _waitPortClosed(const Duration(seconds: 2));
    if (!ok) {
      try {
        await _forceDeactivate();
      } catch (_) {}
      await _waitPortClosed(const Duration(seconds: 2));
    }
  }

  /// Корректное выключение перед выходом из приложения.
  static Future<void> gracefulShutdown() async {
    try {
      await _stop();
    } catch (_) {}
    final ok = await _waitPortClosed(const Duration(seconds: 3));
    if (!ok) {
      try {
        await _forceDeactivate();
      } catch (_) {}
      await _waitPortClosed(const Duration(seconds: 2));
    }

    // На всякий случай снимаем системный прокси,
    // если пользователь был в proxy-режиме (safe для всех режимов).
    try {
      await disableProxyOnQuit();
    } catch (_) {}
  }

  // ---------- helpers ----------

  static Future<void> _stop() => _runCli(['tunnel', 'stop']);
  static Future<void> _forceDeactivate() =>
      _runCli(['tunnel', 'deactivate-force']);

  static Future<void> _runCli(List<String> args) async {
    final exe = Platform.isWindows ? 'RostovVPNCli.exe' : 'RostovVPNCli';

    // Набор кандидатов: PATH/текущая папка/рядом с exe/bin
    final candidates = <String>[
      exe,
      'bin/$exe',
      '../bin/$exe',
      _joinIfExists(_resolvedDir(), exe),
      _joinIfExists(Directory(_resolvedDir()).parent.path, exe),
    ].where((e) => e.isNotEmpty).toList();

    Object? lastErr;
    for (final c in candidates) {
      try {
        final result =
            await Process.run(c, args).timeout(const Duration(seconds: 2));
        if (result.exitCode == 0) return;
        // если не 0 — возможно сервис уже остановлен; просто идём дальше
        lastErr = 'exit=${result.exitCode} ${result.stderr}';
      } catch (e) {
        lastErr = e;
        continue;
      }
    }
    // В релизе молча игнорируем; при дев-отладке можно залогировать lastErr.
  }

  /// Снятие системного прокси при выходе (best-effort).
  /// Сначала пробуем CLI: `RostovVPNCli proxy off`.
  /// Если команда не доступна — применяем OS-fallback.
  static Future<void> disableProxyOnQuit() async {
    // 1) Предпочтительно поручаем CLI (он может сделать WinINet refresh и т.д.)
    try {
      await _runCli(['proxy', 'off']);
    } catch (_) {}

    // 2) Fallback по ОС
    if (Platform.isWindows) {
      // HKCU\...\Internet Settings: ProxyEnable=0, очистка ProxyServer/AutoConfigURL/ProxyOverride
      // Эти операции не требуют админ-прав (HKCU).
      await _runCmd([
        'reg',
        'add',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
        '/v',
        'ProxyEnable',
        '/t',
        'REG_DWORD',
        '/d',
        '0',
        '/f'
      ]);
      await _runCmd([
        'reg',
        'delete',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
        '/v',
        'ProxyServer',
        '/f'
      ]);
      await _runCmd([
        'reg',
        'delete',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
        '/v',
        'AutoConfigURL',
        '/f'
      ]);
      await _runCmd([
        'reg',
        'delete',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
        '/v',
        'ProxyOverride',
        '/f'
      ]);
      // WinHTTP (служебный прокси). М.б. понадобятся права — best-effort.
      await _runCmd(['netsh', 'winhttp', 'reset', 'proxy']);
    } else if (Platform.isLinux) {
      // GNOME: системный прокси через gsettings
      await _runCmd(
          ['gsettings', 'set', 'org.gnome.system.proxy', 'mode', 'none']);
    } else if (Platform.isMacOS) {
      // Пока только CLI; при необходимости добавим networksetup с именами сервисов.
    }
  }

  static Future<void> _runCmd(List<String> cmd) async {
    try {
      final result = await Process.run(
        cmd.first,
        cmd.length > 1 ? cmd.sublist(1) : const <String>[],
      ).timeout(const Duration(seconds: 2));
      // игнорируем exitCode — это best-effort
    } catch (_) {/* ignore */}
  }

  static Future<bool> _waitPortClosed(Duration timeout) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final open = await _isPortOpen();
      if (!open) return true;
      await Future.delayed(const Duration(milliseconds: 150));
    }
    return !(await _isPortOpen());
  }

  static Future<bool> _isPortOpen() async {
    try {
      final socket = await Socket.connect('127.0.0.1', _port,
          timeout: const Duration(milliseconds: 250));
      await socket.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  static String _resolvedDir() {
    try {
      return File(Platform.resolvedExecutable).parent.path;
    } catch (_) {
      return Directory.current.path;
    }
  }

  static String _joinIfExists(String dir, String file) {
    final p = '$dir${Platform.pathSeparator}$file';
    return File(p).existsSync() ? p : '';
  }
}
