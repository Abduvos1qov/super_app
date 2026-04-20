import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Builds the [TextTheme] used by both light and dark [ThemeData]s. Widgets
/// use `Theme.of(context).textTheme.*` — never inline [TextStyle].
TextTheme buildAppTextTheme({required Color textColor}) {
  final base = GoogleFonts.interTextTheme();
  return base
      .copyWith(
        displayLarge: base.displayLarge?.copyWith(fontWeight: FontWeight.w700),
        headlineMedium: base.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
        titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        bodyLarge: base.bodyLarge?.copyWith(height: 1.4),
        bodyMedium: base.bodyMedium?.copyWith(height: 1.4),
        labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      )
      .apply(bodyColor: textColor, displayColor: textColor);
}
