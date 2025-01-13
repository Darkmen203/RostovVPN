import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rostov_vpn/features/connection/notifier/connection_notifier.dart';
import 'package:rostov_vpn/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

part 'window_notifier.g.dart';

const minimumWindowSize = Size(368, 800);
const defaultWindowSize = Size(428, 800);

@Riverpod(keepAlive: true)
class WindowNotifier extends _$WindowNotifier with AppLogger {
  @override
  Future<void> build() async {
    if (!PlatformUtils.isDesktop) return;

    // if (Platform.isWindows) {
    //   loggy.debug("ensuring single instance");
    //   await WindowsSingleInstance.ensureSingleInstance([], "RostovVPN");
    // }

    await windowManager.ensureInitialized();
    await windowManager.setMinimumSize(minimumWindowSize);
    await windowManager.setSize(defaultWindowSize);
  }

  Future<void> open({bool focus = true}) async {
    await windowManager.show();
    if (focus) await windowManager.focus();
    if (Platform.isMacOS) {
      await windowManager.setSkipTaskbar(false);
    }
  }

  // TODO add option to quit or minimize to tray
  Future<void> close() async {
    await windowManager.hide();
    if (Platform.isMacOS) {
      await windowManager.setSkipTaskbar(true);
    }
  }

  Future<void> quit() async {
    await ref.read(connectionNotifierProvider.notifier).abortConnection().timeout(const Duration(seconds: 2)).catchError(
      (e) {
        loggy.warning("error aborting connection on quit", e);
      },
    );
    await trayManager.destroy();
    await windowManager.destroy();
  }
}
