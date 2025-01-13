import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rostov_vpn/core/preferences/actions_at_closing.dart';
import 'package:rostov_vpn/core/preferences/general_preferences.dart';
import 'package:rostov_vpn/features/common/adaptive_root_scaffold.dart';
import 'package:rostov_vpn/features/window/notifier/window_notifier.dart';
import 'package:rostov_vpn/features/window/widget/window_closing_dialog.dart';
import 'package:rostov_vpn/utils/custom_loggers.dart';
import 'package:rostov_vpn/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';

class WindowWrapper extends StatefulHookConsumerWidget {
  const WindowWrapper(this.child, {super.key});

  final Widget child;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _WindowWrapperState();
}

class _WindowWrapperState extends ConsumerState<WindowWrapper> with WindowListener, AppLogger {
  late AlertDialog closeDialog;

  bool isWindowClosingDialogOpened = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(windowNotifierProvider);

    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    if (PlatformUtils.isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await windowManager.setPreventClose(true);
      });
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Future<void> onWindowClose() async {
    if (RootScaffold.stateKey.currentContext == null) {
      await ref.read(windowNotifierProvider.notifier).close();
      return;
    }

    switch (ref.read(Preferences.actionAtClose)) {
      case ActionsAtClosing.ask:
        if (isWindowClosingDialogOpened) return;
        isWindowClosingDialogOpened = true;
        await showDialog(
          context: RootScaffold.stateKey.currentContext!,
          builder: (BuildContext context) => const WindowClosingDialog(),
        );
        isWindowClosingDialogOpened = false;

      case ActionsAtClosing.hide:
        await ref.read(windowNotifierProvider.notifier).close();

      case ActionsAtClosing.exit:
        await ref.read(windowNotifierProvider.notifier).quit();
    }
  }

  @override
  void onWindowFocus() {
    setState(() {});
  }
}
