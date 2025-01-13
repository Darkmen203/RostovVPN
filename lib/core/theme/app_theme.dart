import 'package:flutter/material.dart';
import 'package:rostov_vpn/core/theme/app_theme_mode.dart';
import 'package:rostov_vpn/core/theme/theme_extensions.dart';

class AppTheme {
  AppTheme(this.mode, this.fontFamily);
  final AppThemeMode mode;
  final String fontFamily;

  ThemeData lightTheme(ColorScheme? lightColorScheme) {
    final ColorScheme scheme = lightColorScheme ??
        ColorScheme.fromSeed(seedColor: const Color(0xFFD732A8));
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      extensions: const <ThemeExtension<dynamic>>{
        ConnectionButtonTheme.light,
      },
    );
  }

  ThemeData darkTheme(ColorScheme? darkColorScheme) {
    final ColorScheme scheme = darkColorScheme ??
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF680B4E),
          brightness: Brightness.dark,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          mode.trueBlack ? Colors.black : scheme.surface,
      fontFamily: fontFamily,
      extensions: const <ThemeExtension<dynamic>>{
        ConnectionButtonTheme.light,
      },
    );
  }
}
