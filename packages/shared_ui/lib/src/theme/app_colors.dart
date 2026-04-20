import 'dart:ui' show Color;

import 'package:flutter/material.dart';

/// Semantic color tokens. Widgets never reference raw `Color(0xFF…)` —
/// they read from `Theme.of(context).extension<AppColors>()` so rebrands
/// and dark mode come "for free".
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brandPrimary,
    required this.brandOnPrimary,
    required this.surface,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSubtle,
    required this.danger,
    required this.success,
  });

  factory AppColors.light() => const AppColors(
        brandPrimary: Color(0xFF1F7A4D),
        brandOnPrimary: Color(0xFFFFFFFF),
        surface: Color(0xFFFAFAFA),
        surfaceElevated: Color(0xFFFFFFFF),
        textPrimary: Color(0xFF101418),
        textSubtle: Color(0xFF5A6470),
        danger: Color(0xFFC2261B),
        success: Color(0xFF1F8A45),
      );

  factory AppColors.dark() => const AppColors(
        brandPrimary: Color(0xFF3DA06F),
        brandOnPrimary: Color(0xFF0B1A12),
        surface: Color(0xFF101418),
        surfaceElevated: Color(0xFF1A1F25),
        textPrimary: Color(0xFFF2F4F6),
        textSubtle: Color(0xFFA0AAB5),
        danger: Color(0xFFF05951),
        success: Color(0xFF4EC87A),
      );

  final Color brandPrimary;
  final Color brandOnPrimary;
  final Color surface;
  final Color surfaceElevated;
  final Color textPrimary;
  final Color textSubtle;
  final Color danger;
  final Color success;

  @override
  AppColors copyWith({
    Color? brandPrimary,
    Color? brandOnPrimary,
    Color? surface,
    Color? surfaceElevated,
    Color? textPrimary,
    Color? textSubtle,
    Color? danger,
    Color? success,
  }) =>
      AppColors(
        brandPrimary: brandPrimary ?? this.brandPrimary,
        brandOnPrimary: brandOnPrimary ?? this.brandOnPrimary,
        surface: surface ?? this.surface,
        surfaceElevated: surfaceElevated ?? this.surfaceElevated,
        textPrimary: textPrimary ?? this.textPrimary,
        textSubtle: textSubtle ?? this.textSubtle,
        danger: danger ?? this.danger,
        success: success ?? this.success,
      );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t)!,
      brandOnPrimary: Color.lerp(brandOnPrimary, other.brandOnPrimary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSubtle: Color.lerp(textSubtle, other.textSubtle, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}
