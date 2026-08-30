import 'package:flutter/material.dart';

/// DietCompass — Central App Colors & Theme Extensions
/// Provides robust color palettes for both Light and Dark modes.
abstract final class AppColors {
  // Brand accents
  static const primaryPurple = Color(0xFF6C4EF5);
  static const primaryPurpleDark = Color(0xFF9D84FF);
  static const primaryGreen = Color(0xFF1E8A4C);
  static const primaryGreenDark = Color(0xFF34D399);

  // Light theme neutrals
  static const lightBg = Color(0xFFF3F0FB);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCardBorder = Color(0xFFEDEAF7);
  static const lightTextPrimary = Color(0xFF1B1B2E);
  static const lightTextSecondary = Color(0xFF6B6B7B);
  static const lightTextMuted = Color(0xFF9E9EB2);
  static const lightDivider = Color(0xFFF3F0FB);

  // Dark theme neutrals
  static const darkBg = Color(0xFF111019);
  static const darkSurface = Color(0xFF1D1B2A);
  static const darkSurfaceSecondary = Color(0xFF252236);
  static const darkCardBorder = Color(0xFF2E2B45);
  static const darkTextPrimary = Color(0xFFF5F4FA);
  static const darkTextSecondary = Color(0xFFA2A0B8);
  static const darkTextMuted = Color(0xFF6E6C84);
  static const darkDivider = Color(0xFF262438);

  // Legacy constants preserved for backward compatibility
  static const white = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFFAFAFA);
  static const charcoal = Color(0xFF212121);
  static const darkGrey = Color(0xFF424242);
  static const mediumGrey = Color(0xFF757575);
  static const lightGrey = Color(0xFF9E9E9E);
  static const forestGreen = Color(0xFF2E7D32);
  static const vibrantGreen = Color(0xFF43A047);
  static const mintGreen = Color(0xFF81C784);
  static const softMint = Color(0xFFE8F5E9);
  static const deepPurple = Color(0xFF7C4DFF);
  static const softPurple = Color(0xFFB388FF);
  static const lavender = Color(0xFFEDE7F6);
  static const paleLavender = Color(0xFFF3E5F5);
  static const softBlue = Color(0xFF64B5F6);
  static const teal = Color(0xFF26A69A);
  static const tealGlow = Color(0xFF4DD0E1);
  static const glassWhite = Color(0xCCFFFFFF);
  static const glassBorder = Color(0x33FFFFFF);
  static const loadingGradientStart = Color(0xFF7C4DFF);
  static const loadingGradientEnd = Color(0xFF43A047);
}

/// ThemeExtension that holds DietCompass-specific theme tokens
class DietCompassThemeColors extends ThemeExtension<DietCompassThemeColors> {
  const DietCompassThemeColors({
    required this.bg,
    required this.surface,
    required this.surfaceSecondary,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.divider,
    required this.iconPurpleBg,
    required this.iconPurple,
    required this.iconGreenBg,
    required this.iconGreen,
    required this.iconBlueBg,
    required this.iconBlue,
    required this.iconOrangeBg,
    required this.iconOrange,
    required this.iconRedBg,
    required this.iconRed,
    required this.glowPurple,
    required this.glowGreen,
    required this.chipBg,
    required this.isDark,
  });

  final Color bg;
  final Color surface;
  final Color surfaceSecondary;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color divider;
  final Color iconPurpleBg;
  final Color iconPurple;
  final Color iconGreenBg;
  final Color iconGreen;
  final Color iconBlueBg;
  final Color iconBlue;
  final Color iconOrangeBg;
  final Color iconOrange;
  final Color iconRedBg;
  final Color iconRed;
  final Color glowPurple;
  final Color glowGreen;
  final Color chipBg;
  final bool isDark;

  static const light = DietCompassThemeColors(
    bg: Color(0xFFF3F0FB),
    surface: Colors.white,
    surfaceSecondary: Color(0xFFF9F7FD),
    cardBorder: Color(0xFFEDEAF7),
    textPrimary: Color(0xFF1B1B2E),
    textSecondary: Color(0xFF6B6B7B),
    textMuted: Color(0xFF9E9EB2),
    divider: Color(0xFFF3F0FB),
    iconPurpleBg: Color(0xFFEDE7FA),
    iconPurple: Color(0xFF6C4EF5),
    iconGreenBg: Color(0xFFE3F5EA),
    iconGreen: Color(0xFF1E8A4C),
    iconBlueBg: Color(0xFFE3EEFC),
    iconBlue: Color(0xFF3B82F6),
    iconOrangeBg: Color(0xFFFCEEDD),
    iconOrange: Color(0xFFE0862E),
    iconRedBg: Color(0xFFFFECEE),
    iconRed: Color(0xFFE0525C),
    glowPurple: Color(0x1A6C4EF5),
    glowGreen: Color(0x141E8A4C),
    chipBg: Color(0xFFF9F7FD),
    isDark: false,
  );

  static const dark = DietCompassThemeColors(
    bg: Color(0xFF111019),
    surface: Color(0xFF1D1B2A),
    surfaceSecondary: Color(0xFF252236),
    cardBorder: Color(0xFF2E2B45),
    textPrimary: Color(0xFFF5F4FA),
    textSecondary: Color(0xFFA2A0B8),
    textMuted: Color(0xFF6E6C84),
    divider: Color(0xFF262438),
    iconPurpleBg: Color(0xFF2C244A),
    iconPurple: Color(0xFF9D84FF),
    iconGreenBg: Color(0xFF193828),
    iconGreen: Color(0xFF34D399),
    iconBlueBg: Color(0xFF1A2B45),
    iconBlue: Color(0xFF60A5FA),
    iconOrangeBg: Color(0xFF3D2A1B),
    iconOrange: Color(0xFFFB923C),
    iconRedBg: Color(0xFF3D1B22),
    iconRed: Color(0xFFF87171),
    glowPurple: Color(0x2E6C4EF5),
    glowGreen: Color(0x241E8A4C),
    chipBg: Color(0xFF252236),
    isDark: true,
  );

  @override
  ThemeExtension<DietCompassThemeColors> copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceSecondary,
    Color? cardBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? divider,
    Color? iconPurpleBg,
    Color? iconPurple,
    Color? iconGreenBg,
    Color? iconGreen,
    Color? iconBlueBg,
    Color? iconBlue,
    Color? iconOrangeBg,
    Color? iconOrange,
    Color? iconRedBg,
    Color? iconRed,
    Color? glowPurple,
    Color? glowGreen,
    Color? chipBg,
    bool? isDark,
  }) {
    return DietCompassThemeColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      cardBorder: cardBorder ?? this.cardBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      divider: divider ?? this.divider,
      iconPurpleBg: iconPurpleBg ?? this.iconPurpleBg,
      iconPurple: iconPurple ?? this.iconPurple,
      iconGreenBg: iconGreenBg ?? this.iconGreenBg,
      iconGreen: iconGreen ?? this.iconGreen,
      iconBlueBg: iconBlueBg ?? this.iconBlueBg,
      iconBlue: iconBlue ?? this.iconBlue,
      iconOrangeBg: iconOrangeBg ?? this.iconOrangeBg,
      iconOrange: iconOrange ?? this.iconOrange,
      iconRedBg: iconRedBg ?? this.iconRedBg,
      iconRed: iconRed ?? this.iconRed,
      glowPurple: glowPurple ?? this.glowPurple,
      glowGreen: glowGreen ?? this.glowGreen,
      chipBg: chipBg ?? this.chipBg,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  ThemeExtension<DietCompassThemeColors> lerp(
    covariant ThemeExtension<DietCompassThemeColors>? other,
    double t,
  ) {
    if (other is! DietCompassThemeColors) return this;
    return DietCompassThemeColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSecondary: Color.lerp(surfaceSecondary, other.surfaceSecondary, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      iconPurpleBg: Color.lerp(iconPurpleBg, other.iconPurpleBg, t)!,
      iconPurple: Color.lerp(iconPurple, other.iconPurple, t)!,
      iconGreenBg: Color.lerp(iconGreenBg, other.iconGreenBg, t)!,
      iconGreen: Color.lerp(iconGreen, other.iconGreen, t)!,
      iconBlueBg: Color.lerp(iconBlueBg, other.iconBlueBg, t)!,
      iconBlue: Color.lerp(iconBlue, other.iconBlue, t)!,
      iconOrangeBg: Color.lerp(iconOrangeBg, other.iconOrangeBg, t)!,
      iconOrange: Color.lerp(iconOrange, other.iconOrange, t)!,
      iconRedBg: Color.lerp(iconRedBg, other.iconRedBg, t)!,
      iconRed: Color.lerp(iconRed, other.iconRed, t)!,
      glowPurple: Color.lerp(glowPurple, other.glowPurple, t)!,
      glowGreen: Color.lerp(glowGreen, other.glowGreen, t)!,
      chipBg: Color.lerp(chipBg, other.chipBg, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

/// Convenience extension on BuildContext
extension DietCompassThemeContext on BuildContext {
  DietCompassThemeColors get dcColors =>
      Theme.of(this).extension<DietCompassThemeColors>() ??
      DietCompassThemeColors.light;

  bool get isDarkMode =>
      Theme.of(this).brightness == Brightness.dark;
}
