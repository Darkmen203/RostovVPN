import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rostov_vpn/features/connection/notifier/connection_notifier.dart';
import 'package:rostov_vpn/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';

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

    final display = await screenRetriever.getPrimaryDisplay();
    final workAreaSize = display.size;
    //   или 'size' (размер всего экрана),
    //   но чаще лучше брать 'workAreaSize' (без панели задач).

    var windowWidth = 368.0;
    var windowHeight = 800.0;
    log('$windowHeight windowHeight $workAreaSize' );

    // Если не помещается по ширине или высоте - уменьшаем
    if (windowWidth > workAreaSize.width ||
        windowHeight > workAreaSize.height) {
      // Простой вариант — «зажать» до рабочей области
      windowWidth = windowWidth.clamp(0, workAreaSize.width);
      windowHeight = windowHeight.clamp(0, workAreaSize.height - 20);
      await windowManager.setMinimumSize(Size(windowWidth, windowHeight));
    }else{
      await windowManager.setMinimumSize(minimumWindowSize);
    }

    // Устанавливаем итоговый размер (может быть уменьшен)
    await windowManager.setSize(Size(windowWidth, windowHeight));

    // При желании можно ещё зацентрировать
    await windowManager.center();
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
    await ref
        .read(connectionNotifierProvider.notifier)
        .abortConnection()
        .timeout(const Duration(seconds: 2))
        .catchError(
      (e) {
        loggy.warning("error aborting connection on quit", e);
      },
    );
    await trayManager.destroy();
    await windowManager.destroy();
  }
}
