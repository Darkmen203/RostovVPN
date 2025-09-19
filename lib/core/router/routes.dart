import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rostov_vpn/constants/colors.dart';
import 'package:rostov_vpn/core/router/app_router.dart';
import 'package:rostov_vpn/features/appBar/header_bar.dart';
import 'package:rostov_vpn/features/config_option/overview/config_options_page.dart';
import 'package:rostov_vpn/features/config_option/widget/quick_settings_modal.dart';
import 'package:rostov_vpn/features/home/widget/home_page.dart';
import 'package:rostov_vpn/features/intro/widget/intro_page.dart';
import 'package:rostov_vpn/features/log/overview/logs_overview_page.dart';
import 'package:rostov_vpn/features/navBar/nav_bar.dart';
import 'package:rostov_vpn/features/per_app_proxy/overview/per_app_proxy_page.dart';
import 'package:rostov_vpn/features/profile/add/add_profile_modal.dart';
import 'package:rostov_vpn/features/profile/details/profile_details_page.dart';
import 'package:rostov_vpn/features/profile/overview/profiles_overview_page.dart';
import 'package:rostov_vpn/features/proxy/overview/proxies_overview_page.dart';
import 'package:rostov_vpn/features/settings/about/about_page.dart';
import 'package:rostov_vpn/features/settings/overview/settings_overview_page.dart';
import 'package:rostov_vpn/utils/utils.dart';

part 'routes.g.dart';

/// ✅ Хелперы платформы в одном месте
bool get isDesktopPlatform => const {
      TargetPlatform.macOS,
      TargetPlatform.linux,
      TargetPlatform.windows,
    }.contains(defaultTargetPlatform);

bool get isMobilePlatform =>
    const {
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.fuchsia,
    }.contains(defaultTargetPlatform) &&
    !kIsWeb;

GlobalKey<NavigatorState>? _dynamicRootKey =
    // useMobileRouter ? rootNavigatorKey :
    null;

@TypedShellRoute<AppShellRoute>(
  routes: [
    TypedGoRoute<HomeRoute>(
      path: "/",
      name: HomeRoute.name,
      routes: [
        TypedGoRoute<AddProfileRoute>(path: "add", name: AddProfileRoute.name),
        TypedGoRoute<ProfilesOverviewRoute>(
            path: "profiles", name: ProfilesOverviewRoute.name),
        TypedGoRoute<NewProfileRoute>(
            path: "profiles/new", name: NewProfileRoute.name),
        TypedGoRoute<ProfileDetailsRoute>(
            path: "profiles/:id", name: ProfileDetailsRoute.name),
        TypedGoRoute<ConfigOptionsRoute>(
            path: "config-options", name: ConfigOptionsRoute.name),
        TypedGoRoute<QuickSettingsRoute>(
            path: "quick-settings", name: QuickSettingsRoute.name),
    // TypedGoRoute<SettingsRoute>(path: "/settings", name: SettingsRoute.name),

        TypedGoRoute<SettingsRoute>( 
          path: "settings",
          name: SettingsRoute.name,
          routes: [
            TypedGoRoute<PerAppProxyRoute>(
              path: "per-app-proxy",
              name: PerAppProxyRoute.name,
            ),
          ],
        ),
        TypedGoRoute<LogsOverviewRoute>(
            path: "logs", name: LogsOverviewRoute.name),
        TypedGoRoute<AboutRoute>(path: "about", name: AboutRoute.name),
      ],
    ),
    TypedGoRoute<ProxiesRoute>(path: "/proxies", name: ProxiesRoute.name),
  ],
)

class AppShellRoute extends ShellRouteData {
  const AppShellRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget child) {
    return AppShellWidget(child: child);
  }
}

class AppShellWidget extends StatefulWidget {
  final Widget child;
  const AppShellWidget({super.key, required this.child});

  @override
  State<AppShellWidget> createState() => _AppShellWidgetState();
}

class _AppShellWidgetState extends State<AppShellWidget> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    if (location.startsWith('/settings')) {
      _selectedIndex = 1;
    } else if (location.startsWith('/about')) {
      _selectedIndex = 2;
    } else if (location.startsWith('/proxies')) {
      _selectedIndex = 3;
    } else {
      _selectedIndex = 0;
    }

    return Scaffold(
      backgroundColor: AppColors.darkGray,
      appBar: const HeaderBar(),
      // ✅ исправлено определение платформы
      body: isMobilePlatform
          ? Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: widget.child,
            )
          : widget.child,
      bottomNavigationBar: NavBar(
        selectedIndex: _selectedIndex,
        onTabSelected: (index) {
          setState(() => _selectedIndex = index);
          switch (index) {
            case 0: context.go('/');
            case 1: context.go('/settings');
            case 2: context.go('/about');
            case 3: context.go('/proxies');
          }
        },
      ),
    );
  }
}

/* -------------------------------------------------------------------
   ОСТАЛЬНЫЕ РОУТЫ (НЕ ВХОДЯТ В SHELL, ИЛИ ПЕРЕХОДЯТ ЧЕРЕЗ buildPage)
   ------------------------------------------------------------------- */

@TypedGoRoute<IntroRoute>(path: "/intro", name: IntroRoute.name)
class IntroRoute extends GoRouteData {
  const IntroRoute();
  static const name = "Intro";

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return MaterialPage(
      fullscreenDialog: true,
      name: name,
      child: IntroPage(),
    );
  }
}

class HomeRoute extends GoRouteData {
  const HomeRoute();
  static const name = "Home";

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const NoTransitionPage(
      name: name,
      child: HomePage(),
    );
  }
}

class ProxiesRoute extends GoRouteData {
  const ProxiesRoute();
  static const name = "Proxies";

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const NoTransitionPage(
      name: name,
      child: ProxiesOverviewPage(),
    );
  }
}

class AddProfileRoute extends GoRouteData {
  const AddProfileRoute({this.url});
  final String? url;
  static const name = "Add Profile";

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return BottomSheetPage(
      fixed: true,
      name: name,
      builder: (controller) => AddProfileModal(
        url: url,
        scrollController: controller,
      ),
    );
  }
}

class ProfilesOverviewRoute extends GoRouteData {
  const ProfilesOverviewRoute();
  static const name = "Profiles";

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return BottomSheetPage(
      name: name,
      builder: (controller) =>
          ProfilesOverviewModal(scrollController: controller),
    );
  }
}

class NewProfileRoute extends GoRouteData {
  const NewProfileRoute();
  static const name = "New Profile";

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const MaterialPage(
      fullscreenDialog: true,
      name: name,
      child: ProfileDetailsPage("new"),
    );
  }
}

class ProfileDetailsRoute extends GoRouteData {
  const ProfileDetailsRoute(this.id);
  final String id;
  static const name = "Profile Details";

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return MaterialPage(
      fullscreenDialog: true,
      name: name,
      child: ProfileDetailsPage(id),
    );
  }
}

class LogsOverviewRoute extends GoRouteData {
  const LogsOverviewRoute();
  static const name = "Logs";

  static final GlobalKey<NavigatorState>? $parentNavigatorKey = _dynamicRootKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    if (useMobileRouter) {
      return const MaterialPage(
        name: name,
        child: LogsOverviewPage(),
      );
    }
    return const NoTransitionPage(name: name, child: LogsOverviewPage());
  }
}

class QuickSettingsRoute extends GoRouteData {
  const QuickSettingsRoute();
  static const name = "Quick Settings";

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return BottomSheetPage(
      fixed: true,
      name: name,
      builder: (controller) => const QuickSettingsModal(),
    );
  }
}

class SettingsRoute extends GoRouteData {
  const SettingsRoute();
  static const name = "Settings";

  static final GlobalKey<NavigatorState>? $parentNavigatorKey = _dynamicRootKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    // if (useMobileRouter) {
    //   return const MaterialPage(
    //     name: name,
    //     child: SettingsOverviewPage(),
    //   );
    // }
    return const NoTransitionPage(name: name, child: SettingsOverviewPage());
  }
}

class ConfigOptionsRoute extends GoRouteData {
  const ConfigOptionsRoute({this.section});
  final String? section;
  static const name = "Config Options";

  static final GlobalKey<NavigatorState>? $parentNavigatorKey = _dynamicRootKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    if (useMobileRouter) {
      return MaterialPage(
        name: name,
        child: ConfigOptionsPage(section: section),
      );
    }
    return NoTransitionPage(
      name: name,
      child: ConfigOptionsPage(section: section),
    );
  }
}

class PerAppProxyRoute extends GoRouteData {
  const PerAppProxyRoute();
  static const name = "Per-app Proxy";

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const MaterialPage(
      fullscreenDialog: true,
      name: name,
      child: PerAppProxyPage(),
    );
  }
}

class AboutRoute extends GoRouteData {
  const AboutRoute();
  static const name = "About";

  static final GlobalKey<NavigatorState>? $parentNavigatorKey = _dynamicRootKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    if (useMobileRouter) {
      return const MaterialPage(
        name: name,
        child: AboutPage(),
      );
    }
    return const NoTransitionPage(name: name, child: AboutPage());
  }
}
