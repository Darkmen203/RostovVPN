import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rostov_vpn/core/localization/translations.dart';
import 'package:rostov_vpn/core/model/constants.dart';
import 'package:rostov_vpn/features/config_option/data/config_option_repository.dart';
import 'package:rostov_vpn/features/connection/model/connection_status.dart';
import 'package:rostov_vpn/features/connection/notifier/connection_notifier.dart';
import 'package:rostov_vpn/features/proxy/active/active_proxy_notifier.dart';
import 'package:rostov_vpn/features/window/notifier/window_notifier.dart';
import 'package:rostov_vpn/gen/assets.gen.dart';
import 'package:rostov_vpn/singbox/model/singbox_config_enum.dart';
import 'package:rostov_vpn/utils/utils.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

part 'system_tray_notifier.g.dart';

@Riverpod(keepAlive: true)
class SystemTrayNotifier extends _$SystemTrayNotifier with AppLogger {
  @override
  Future<void> build() async {
    if (!PlatformUtils.isDesktop) return;

    // узкое наблюдение только за нужным полем, без await
    final delay = ref.watch(
      activeProxyNotifierProvider
          .select((s) => s.valueOrNull?.urlTestDelay ?? 0),
    );
    final newConnectionStatus = delay > 0 && delay < 65000;
    final connectionAv = ref.watch(connectionNotifierProvider);
    final connection =
        connectionAv.value ?? const ConnectionStatus.disconnected();

    final t = ref.watch(translationsProvider);

    var tooltip = Constants.appName;
    final serviceMode = ref.watch(ConfigOptions.serviceMode);
    if (connection == const Disconnected()) {
      unawaited(SystemTrayNotifier.setIcon(connection));
    } else if (newConnectionStatus) {
      unawaited(SystemTrayNotifier.setIcon(const Connected()));
      tooltip = "$tooltip - ${connection.present(t)}";
      if (newConnectionStatus) {
        tooltip = "$tooltip : ${delay}ms";
      } else {
        tooltip = "$tooltip : -";
      }
      // else if (delay>1000)
      //   SystemTrayNotifier.setIcon(timeout ? Disconnecting() : Connecting());
    } else {
      unawaited(SystemTrayNotifier.setIcon(const Disconnecting()));
      tooltip = "$tooltip - ${connection.present(t)}";
    }
    if (Platform.isMacOS) {
      unawaited(windowManager.setBadgeLabel("${delay}ms").catchError((e) {
        loggy.debug('setBadgeLabel error', e);
      }),);
    }
    if (!Platform.isLinux) {
      unawaited(trayManager
          .setToolTip(tooltip)
          .timeout(const Duration(seconds: 2))
          .catchError((e) => loggy.debug('setToolTip error', e)),);
    }

    // loggy.debug('updating system tray');

    final menu = Menu(
      items: [
        MenuItem(
          label: t.tray.dashboard,
          onClick: (_) async {
            await ref.read(windowNotifierProvider.notifier).open();
          },
        ),
        MenuItem.separator(),
        MenuItem.checkbox(
          label: switch (connection) {
            Disconnected() => t.tray.status.connect,
            Connecting() => t.tray.status.connecting,
            Connected() => t.tray.status.disconnect,
            Disconnecting() => t.tray.status.disconnecting,
          },
          // checked: connection.isConnected,
          checked: false,
          disabled: connection.isSwitching,
          onClick: (_) async {
            await ref
                .read(connectionNotifierProvider.notifier)
                .toggleConnection();
          },
        ),
        MenuItem.separator(),
        MenuItem(
          label: t.config.serviceMode,
          icon: Assets.images.trayIconIco,
          disabled: true,
        ),

        ...ServiceMode.values.map(
          (e) => MenuItem.checkbox(
            checked: e == serviceMode,
            key: e.name,
            label: e.present(t),
            onClick: (menuItem) async {
              final newMode = ServiceMode.values.byName(menuItem.key!);
              loggy.debug("switching service mode: [$newMode]");
              await ref
                  .read(ConfigOptions.serviceMode.notifier)
                  .update(newMode);
            },
          ),
        ),

        // MenuItem.submenu(
        //   label: t.tray.open,
        //   submenu: Menu(
        //     items: [
        //       ...destinations.map(
        //         (e) => MenuItem(
        //           label: e.$1,
        //           onClick: (_) async {
        //             await ref.read(windowNotifierProvider.notifier).open();
        //             ref.read(routerProvider).go(e.$2);
        //           },
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        MenuItem.separator(),
        MenuItem(
          label: t.tray.quit,
          onClick: (_) async {
            return ref.read(windowNotifierProvider.notifier).quit();
          },
        ),
      ],
    );

    // не блокируем build: выполняем контекстное меню «в фоне»
    unawaited(trayManager
        .setContextMenu(menu)
        .timeout(const Duration(seconds: 3))
        .catchError((e) => loggy.debug('setContextMenu error', e)),);
  }

  static Future<void> setIcon(ConnectionStatus status) async {
    if (!PlatformUtils.isDesktop) return;
    try {
      await trayManager.setIcon(
        _trayIconPath(status),
        isTemplate: Platform.isMacOS,
      );
    } catch (e) {
      // иконка — не критично
    }
  }

  static String _trayIconPath(ConnectionStatus status) {
    if (Platform.isWindows) {
      final Brightness brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      final isDarkMode = brightness == Brightness.dark;
      switch (status) {
        case Connected():
          return Assets.images.trayIconConnectedIco;
        case Connecting():
          return Assets.images.trayIconDisconnectedIco;
        case Disconnecting():
          return Assets.images.trayIconDisconnectedIco;
        case Disconnected():
          if (isDarkMode) {
            return Assets.images.trayIconIco;
          } else {
            return Assets.images.trayIconDarkIco;
          }
      }
    }
    const isDarkMode = false;
    switch (status) {
      case Connected():
        return Assets.images.trayIconConnectedPng.path;
      case Connecting():
        return Assets.images.trayIconDisconnectedPng.path;
      case Disconnecting():
        return Assets.images.trayIconDisconnectedPng.path;
      case Disconnected():
        if (isDarkMode) {
          return Assets.images.trayIconDarkPng.path;
        } else {
          return Assets.images.trayIconPng.path;
        }
    }
    // return Assets.images.trayIconPng.path;
  }
}
