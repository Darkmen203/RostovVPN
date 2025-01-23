import 'package:accessibility_tools/accessibility_tools.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rostov_vpn/constants/colors.dart';
import 'package:rostov_vpn/core/localization/locale_extensions.dart';
import 'package:rostov_vpn/core/localization/locale_preferences.dart';
import 'package:rostov_vpn/core/localization/translations.dart';
import 'package:rostov_vpn/core/login/login_manager_provider.dart';
import 'package:rostov_vpn/core/model/constants.dart';
import 'package:rostov_vpn/core/router/router.dart';
import 'package:rostov_vpn/core/theme/app_theme.dart';
import 'package:rostov_vpn/core/theme/theme_preferences.dart';
import 'package:rostov_vpn/features/app_update/notifier/app_update_notifier.dart';
import 'package:rostov_vpn/features/connection/widget/connection_wrapper.dart';
import 'package:rostov_vpn/features/login/widget/login_page.dart';
import 'package:rostov_vpn/features/profile/notifier/profiles_update_notifier.dart';
import 'package:rostov_vpn/features/shortcut/shortcut_wrapper.dart';
import 'package:rostov_vpn/features/system_tray/widget/system_tray_wrapper.dart';
import 'package:rostov_vpn/features/update_subscription/data/data_expire_alert.dart';
import 'package:rostov_vpn/features/window/widget/window_wrapper.dart';
import 'package:rostov_vpn/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:upgrader/upgrader.dart';

bool _debugAccessibility = false;
bool _didCheck = false;

class App extends HookConsumerWidget with PresLogger {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localePreferencesProvider);
    final themeMode = ref.watch(themePreferencesProvider);
    final theme = AppTheme(themeMode, locale.preferredFontFamily);

    final upgrader = ref.watch(upgraderProvider);
    ref.listen(foregroundProfilesUpdateNotifierProvider, (_, __) {});

    return WindowWrapper(
      TrayWrapper(
        ShortcutWrapper(
          ConnectionWrapper(
            DynamicColorBuilder(
              builder: (ColorScheme? lightColorScheme,
                  ColorScheme? darkColorScheme) {
                return MaterialApp.router(
                  routerConfig: router,
                  locale: locale.flutterLocale,
                  supportedLocales: AppLocaleUtils.supportedLocales,
                  localizationsDelegates: GlobalMaterialLocalizations.delegates,
                  debugShowCheckedModeBanner: false,
                  themeMode: themeMode.flutterThemeMode,
                  color: AppColors.pink,
                  theme: theme.lightTheme(darkColorScheme),
                  darkTheme: theme.darkTheme(darkColorScheme),
                  title: Constants.appName,
                  builder: (context, child) {
                    final loginState = ref.watch(loginManagerProvider);
                    final isLoggedIn = loginState?.isLoggedIn ?? false;

                    // Если НЕ залогинен — показываем LoginPage, иначе — то, что было (child).
                    // Но надо иметь в виду, что при таком подходе GoRouter-страницы «спрячутся».
                    // Это будет работать, если логика GoRouter вам не важна ДО логина.
                    if (!isLoggedIn) {
                      return Navigator(
                        onGenerateRoute: (_) => MaterialPageRoute(
                          builder: (_) => const LoginPage(),
                        ),
                      );
                    }
                    if (loginState == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!_didCheck) {
                      _didCheck = true;
                      // Запускаем в microtask, чтобы не ломать текущий build
                      Future.microtask(() {
                        ref
                            .read(loginManagerProvider.notifier)
                            .checkSubscriptionExpiry();
                      });
                    }
                    child = DataExpireAlert(
                      navigatorKey: router.routerDelegate.navigatorKey,
                      child: UpgradeAlert(
                        upgrader: upgrader,
                        navigatorKey: router.routerDelegate.navigatorKey,
                        child: child ?? const SizedBox(),
                      ),
                    );

                    // Остальная логика (AccessibilityTools и т. д.)
                    if (kDebugMode && _debugAccessibility) {
                      return AccessibilityTools(
                        checkFontOverflows: true,
                        child: child,
                      );
                    }
                    return child;
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
