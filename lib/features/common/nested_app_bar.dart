import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rostov_vpn/constants/colors.dart';
import 'package:rostov_vpn/core/router/router.dart';
import 'package:rostov_vpn/features/common/adaptive_root_scaffold.dart';
import 'package:rostov_vpn/utils/utils.dart';

bool showDrawerButton(BuildContext context) {
  if (!useMobileRouter) return true;
  final String location = GoRouterState.of(context).uri.path;
  if (location == const HomeRoute().location ||
      location == const ProfilesOverviewRoute().location) return true;
  if (location.startsWith(const ProxiesRoute().location)) return true;
  return false;
}

class NestedAppBar extends StatelessWidget {
  const NestedAppBar({
    super.key,
    this.title,
    this.actions,
    this.pinned = true,
    this.forceElevated = true,
    this.bottom,
    this.automaticallyImplyLeading = true,
  });

  final Widget? title;
  final List<Widget>? actions;
  final bool pinned;
  final bool forceElevated;
  final PreferredSizeWidget? bottom;
  final bool automaticallyImplyLeading;

  @override
  Widget build(BuildContext context) {
    RootScaffold.canShowDrawer(context);
    if (automaticallyImplyLeading) {
      return SliverAppBar(
        // Классическая «статическая» тень
        elevation: 1.0,
        // Цвет тени (по умолчанию может быть не совсем заметен)
        shadowColor: Colors.white.withAlpha(60),
        surfaceTintColor: Colors.transparent,

        leading: (RootScaffold.stateKey.currentState?.hasDrawer ?? false) &&
                showDrawerButton(context)
            ? DrawerButton(
                onPressed: () {
                  RootScaffold.stateKey.currentState?.openDrawer();
                },
              )
            : (Navigator.of(context).canPop()
                ? IconButton(
                    icon: Icon(
                        context.isRtl ? Icons.arrow_forward : Icons.arrow_back),
                    padding: EdgeInsets.only(right: context.isRtl ? 50 : 0),
                    onPressed: () {
                      Navigator.of(context)
                          .pop(); // Pops the current route off the navigator stack
                    },
                  )
                : null),
        title: title,
        actions: actions,
        pinned: pinned,
        backgroundColor: AppColors.darkPink,
        automaticallyImplyLeading: automaticallyImplyLeading,
        forceElevated: forceElevated,
        bottom: bottom,
      );
    } else {
      return SliverAppBar(
        // Классическая «статическая» тень
        elevation: 1.0,
        // Цвет тени (по умолчанию может быть не совсем заметен)
        shadowColor: Colors.white.withAlpha(60),
        // Если не хотите, чтобы Material 3 «подкрашивал» фон AppBar
        surfaceTintColor: Colors.transparent,
        title: title,
        actions: actions,
        pinned: pinned,
        backgroundColor: AppColors.darkPink,
        automaticallyImplyLeading: automaticallyImplyLeading,
        // forceElevated: forceElevated,
        bottom: bottom,
      );
    }
  }
}
