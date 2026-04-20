import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Single source of truth for light and dark themes. Apps apply these via
/// `MaterialApp(theme: AppTheme.light(), darkTheme: AppTheme.dark())`.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(AppColors.light(), Brightness.light);

  static ThemeData dark() => _build(AppColors.dark(), Brightness.dark);

  static ThemeData _build(AppColors colors, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.brandPrimary,
      onPrimary: colors.brandOnPrimary,
      secondary: colors.brandPrimary,
      onSecondary: colors.brandOnPrimary,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      error: colors.danger,
      onError: colors.brandOnPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.surface,
      textTheme: buildAppTextTheme(textColor: colors.textPrimary),
      extensions: <ThemeExtension<dynamic>>[colors, const AppSpacing()],
    );
  }
}
