import 'package:flutter/material.dart';

/// Centralized colors/text styles for the DietCompass onboarding flow.
/// Tweak these to match your `home_screen.dart` palette exactly.
class AppColors {
  AppColors._();

  static const Color primaryPurple = Color(0xFF6C4CE0);
  static const Color deepPurple = Color(0xFF4B2FBE);
  static const Color pageBg = Color(0xFFF4F0FB);
  static const Color waveBg = Color(0xFFD8CCF5);
  static const Color cardBg = Colors.white;
  static const Color accentGreen = Color(0xFF34C77B);
  static const Color textDark = Color(0xFF1E1B2E);
  static const Color textGray = Color(0xFF6B6779);
  static const Color borderLight = Color(0xFFE4DEF5);
  static const Color chipSelectedBg = Color(0xFFEFE9FC);
  static const Color success = Color(0xFF34C77B);

  static const LinearGradient primaryButtonGradient = LinearGradient(
    colors: [primaryPurple, deepPurple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient finalButtonGradient = LinearGradient(
    colors: [primaryPurple, accentGreen],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

class AppText {
  AppText._();

  static const TextStyle title = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
    height: 1.15,
  );

  static const TextStyle titleAccent = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryPurple,
    height: 1.15,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14.5,
    color: AppColors.textGray,
    height: 1.4,
  );

  static const TextStyle stepLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryPurple,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static const TextStyle sectionSubtitle = TextStyle(
    fontSize: 13,
    color: AppColors.textGray,
  );

  static const TextStyle cardLabel = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );
}
