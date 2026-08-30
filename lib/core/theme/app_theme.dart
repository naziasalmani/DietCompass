import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  /// Builds the production DietCompass Light Theme
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF3F0FB),
      cardColor: Colors.white,
      dividerColor: const Color(0xFFF3F0FB),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6C4EF5),
        secondary: Color(0xFF1E8A4C),
        surface: Colors.white,
        onSurface: Color(0xFF1B1B2E),
        onPrimary: Colors.white,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      extensions: const [DietCompassThemeColors.light],
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: const Color(0xFF1B1B2E),
        displayColor: const Color(0xFF1B1B2E),
      ),
    );
  }

  /// Builds the production DietCompass Dark Theme
  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF111019),
      cardColor: const Color(0xFF1D1B2A),
      dividerColor: const Color(0xFF262438),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF9D84FF),
        secondary: Color(0xFF34D399),
        surface: Color(0xFF1D1B2A),
        onSurface: Color(0xFFF5F4FA),
        onPrimary: Colors.white,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1D1B2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1D1B2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      extensions: const [DietCompassThemeColors.dark],
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: const Color(0xFFF5F4FA),
        displayColor: const Color(0xFFF5F4FA),
      ),
    );
  }
}
