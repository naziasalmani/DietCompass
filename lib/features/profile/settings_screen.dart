import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/services/auth_service.dart';
import 'notifications_screen.dart';

import 'privacy_security_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';

/// DietCompass — Settings Screen
/// -----------------------------------------------------------------------
/// Matches the exact visual language of My Profile, Privacy & Security,
/// and About: adapts seamlessly between Light and Dark themes via DietCompassThemeColors.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.appVersion = '1.0.0 (Beta)',
    this.onLogout,
    this.onBack,
  });

  final String appVersion;
  final Future<void> Function()? onLogout;
  final VoidCallback? onBack;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  final String _selectedLanguage = 'English (US)';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AnimatedBuilder(
        animation: ThemeController.instance,
        builder: (context, _) {
          final mq = MediaQuery.of(context);
          final scale = (mq.size.width / 390.0).clamp(0.85, 1.25);
          final currentThemeName = ThemeController.instance.themeModeName;
          final sheetColors = context.dcColors;

          return Container(
            padding: EdgeInsets.all(22 * scale),
            decoration: BoxDecoration(
              color: sheetColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24 * scale)),
              border: Border.all(color: sheetColors.cardBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36 * scale,
                      height: 36 * scale,
                      decoration: BoxDecoration(
                        color: sheetColors.iconPurpleBg,
                        borderRadius: BorderRadius.circular(10 * scale),
                      ),
                      child: Icon(Icons.palette_outlined, color: sheetColors.iconPurple, size: 18 * scale),
                    ),
                    SizedBox(width: 10 * scale),
                    Expanded(
                      child: Text(
                        'Select Theme',
                        style: TextStyle(
                          fontSize: 16.5 * scale,
                          fontWeight: FontWeight.w800,
                          color: sheetColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: 20 * scale, color: sheetColors.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                SizedBox(height: 14 * scale),
                _buildThemeOption(
                  themeName: 'System Default',
                  icon: Icons.brightness_auto_rounded,
                  scale: scale,
                  isSelected: currentThemeName == 'System Default',
                  colors: sheetColors,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ThemeController.instance.setThemeMode(ThemeMode.system);
                  },
                ),
                _buildThemeOption(
                  themeName: 'Light',
                  icon: Icons.light_mode_rounded,
                  scale: scale,
                  isSelected: currentThemeName == 'Light',
                  colors: sheetColors,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ThemeController.instance.setThemeMode(ThemeMode.light);
                  },
                ),
                _buildThemeOption(
                  themeName: 'Dark',
                  icon: Icons.dark_mode_rounded,
                  scale: scale,
                  isSelected: currentThemeName == 'Dark',
                  colors: sheetColors,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ThemeController.instance.setThemeMode(ThemeMode.dark);
                  },
                ),
                SizedBox(height: 10 * scale),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildThemeOption({
    required String themeName,
    required IconData icon,
    required double scale,
    required bool isSelected,
    required DietCompassThemeColors colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14 * scale),
      child: Container(
        margin: EdgeInsets.only(bottom: 8 * scale),
        padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 12 * scale),
        decoration: BoxDecoration(
          color: isSelected ? colors.iconPurpleBg : colors.surfaceSecondary,
          borderRadius: BorderRadius.circular(14 * scale),
          border: Border.all(
            color: isSelected ? colors.iconPurple : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18 * scale, color: isSelected ? colors.iconPurple : colors.textSecondary),
            SizedBox(width: 12 * scale),
            Expanded(
              child: Text(
                themeName,
                style: TextStyle(
                  fontSize: 13.5 * scale,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? colors.iconPurple : colors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, size: 18 * scale, color: colors.iconPurple),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector() {
    final colors = context.dcColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.iconBlueBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.language_rounded, color: colors.iconBlue, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'App Language',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 20, color: colors.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildLangTile('English (US)', true, colors),
            _buildLangTile('Hindi (Coming Soon)', false, colors),
            _buildLangTile('Spanish (Coming Soon)', false, colors),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildLangTile(String lang, bool isActive, DietCompassThemeColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? colors.iconBlueBg : colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? colors.iconBlue : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              lang,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? colors.iconBlue : colors.textMuted,
              ),
            ),
          ),
          if (isActive)
            Icon(Icons.check_circle_rounded, size: 18, color: colors.iconBlue),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    final colors = context.dcColors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.cardBorder),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Color(0xFFE0525C)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Log Out',
                style: TextStyle(fontWeight: FontWeight.w800, color: colors.textPrimary, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out of your DietCompass account?',
          style: TextStyle(color: colors.textSecondary, height: 1.4, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE0525C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (widget.onLogout != null) {
                await widget.onLogout!();
              } else {
                await AuthService.instance.logout();
              }
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final scale = (width / 390.0).clamp(0.85, 1.25);

    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final currentColors = context.dcColors;
        final currentThemeName = ThemeController.instance.themeModeName;

        return Scaffold(
          backgroundColor: currentColors.bg,
          body: Stack(
            children: [
              // Ambient blurred decorative glows
              Positioned(
                top: -50,
                left: -40,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentColors.glowPurple,
                  ),
                ),
              ),
              Positioned(
                top: 280,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentColors.glowGreen,
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    // Top App Bar
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 12 * scale),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: widget.onBack ?? () => Navigator.of(context).pop(),
                            child: Container(
                              width: 40 * scale,
                              height: 40 * scale,
                              decoration: BoxDecoration(
                                color: currentColors.surface,
                                borderRadius: BorderRadius.circular(14 * scale),
                                border: Border.all(color: currentColors.cardBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: currentColors.isDark ? 0.20 : 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                size: 20 * scale,
                                color: currentColors.textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(width: 14 * scale),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Settings',
                                  style: TextStyle(
                                    fontSize: 18 * scale,
                                    fontWeight: FontWeight.w800,
                                    color: currentColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'App preferences & configuration',
                                  style: TextStyle(
                                    fontSize: 12 * scale,
                                    color: currentColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Main Scrollable Content
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── SECTION 1: GENERAL ──────────────────────────────
                            _buildSectionHeader('GENERAL', scale, currentColors),
                            SizedBox(height: 10 * scale),
                            _buildCard(
                              scale: scale,
                              colors: currentColors,
                              child: Column(
                                children: [
                                  _buildRow(
                                    icon: Icons.notifications_none_rounded,
                                    iconBg: currentColors.iconRedBg,
                                    iconColor: currentColors.iconRed,
                                    title: 'Notifications',
                                    subtitle: 'Manage your notification preferences',
                                    scale: scale,
                                    colors: currentColors,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                                      );
                                    },
                                  ),
                                  _buildDivider(currentColors),
                                  _buildRow(
                                    icon: Icons.language_rounded,
                                    iconBg: currentColors.iconBlueBg,
                                    iconColor: currentColors.iconBlue,
                                    title: 'Language',
                                    subtitle: 'Choose your preferred language',
                                    trailingBadge: _selectedLanguage,
                                    scale: scale,
                                    colors: currentColors,
                                    onTap: _showLanguageSelector,
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 22 * scale),

                            // ── SECTION 2: APPEARANCE ───────────────────────────
                            _buildSectionHeader('APPEARANCE', scale, currentColors),
                            SizedBox(height: 10 * scale),
                            _buildCard(
                              scale: scale,
                              colors: currentColors,
                              child: _buildRow(
                                icon: Icons.palette_outlined,
                                iconBg: currentColors.iconPurpleBg,
                                iconColor: currentColors.iconPurple,
                                title: 'Theme',
                                subtitle: 'Customize the appearance of DietCompass',
                                trailingBadge: currentThemeName,
                                scale: scale,
                                colors: currentColors,
                                onTap: _showThemeSelector,
                              ),
                            ),

                            SizedBox(height: 22 * scale),

                            // ── SECTION 3: PRIVACY & SECURITY ───────────────────
                            _buildSectionHeader('PRIVACY & SECURITY', scale, currentColors),
                            SizedBox(height: 10 * scale),
                            _buildCard(
                              scale: scale,
                              colors: currentColors,
                              child: _buildRow(
                                icon: Icons.shield_outlined,
                                iconBg: currentColors.iconPurpleBg,
                                iconColor: currentColors.iconPurple,
                                title: 'Privacy & Security',
                                subtitle: 'Control your data and privacy',
                                scale: scale,
                                colors: currentColors,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
                                  );
                                },
                              ),
                            ),

                            SizedBox(height: 22 * scale),

                            // ── SECTION 4: SUPPORT ──────────────────────────────
                            _buildSectionHeader('SUPPORT', scale, currentColors),
                            SizedBox(height: 10 * scale),
                            _buildCard(
                              scale: scale,
                              colors: currentColors,
                              child: _buildRow(
                                icon: Icons.headset_mic_rounded,
                                iconBg: currentColors.iconGreenBg,
                                iconColor: currentColors.iconGreen,
                                title: 'Help & Support',
                                subtitle: 'Get help and contact support',
                                scale: scale,
                                colors: currentColors,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                                  );
                                },
                              ),
                            ),

                            SizedBox(height: 22 * scale),

                            // ── SECTION 5: ABOUT ────────────────────────────────
                            _buildSectionHeader('ABOUT', scale, currentColors),
                            SizedBox(height: 10 * scale),
                            _buildCard(
                              scale: scale,
                              colors: currentColors,
                              child: _buildRow(
                                icon: Icons.info_outline_rounded,
                                iconBg: currentColors.iconPurpleBg,
                                iconColor: currentColors.iconPurple,
                                title: 'About DietCompass',
                                subtitle: 'App version ${widget.appVersion}',
                                scale: scale,
                                colors: currentColors,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => AboutScreen(appVersion: widget.appVersion)),
                                  );
                                },
                              ),
                            ),

                            SizedBox(height: 22 * scale),

                            // ── SECTION 6: ACCOUNT ──────────────────────────────
                            _buildCard(
                              scale: scale,
                              colors: currentColors,
                              child: _buildRow(
                                icon: Icons.logout_rounded,
                                iconBg: currentColors.iconRedBg,
                                iconColor: currentColors.iconRed,
                                title: 'Log Out',
                                subtitle: 'Sign out of your account on this device',
                                titleColor: currentColors.iconRed,
                                scale: scale,
                                colors: currentColors,
                                onTap: _showLogoutDialog,
                              ),
                            ),

                            SizedBox(height: 28 * scale),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, double scale, DietCompassThemeColors colors) {
    return Padding(
      padding: EdgeInsets.only(left: 4 * scale),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11 * scale,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: colors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildCard({required double scale, required DietCompassThemeColors colors, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: colors.isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF6C4EF5).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDivider(DietCompassThemeColors colors) {
    return Divider(height: 1, color: colors.divider, indent: 16, endIndent: 16);
  }

  Widget _buildRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required double scale,
    required DietCompassThemeColors colors,
    Color? titleColor,
    String? trailingBadge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20 * scale),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 14 * scale),
        child: Row(
          children: [
            Container(
              width: 38 * scale,
              height: 38 * scale,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12 * scale),
              ),
              child: Icon(icon, color: iconColor, size: 18 * scale),
            ),
            SizedBox(width: 14 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5 * scale,
                      fontWeight: FontWeight.w700,
                      color: titleColor ?? colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2 * scale),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5 * scale,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailingBadge != null) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
                decoration: BoxDecoration(
                  color: colors.iconPurpleBg,
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
                child: Text(
                  trailingBadge,
                  style: TextStyle(
                    fontSize: 11 * scale,
                    fontWeight: FontWeight.w700,
                    color: colors.iconPurple,
                  ),
                ),
              ),
              SizedBox(width: 6 * scale),
            ],
            Icon(Icons.chevron_right_rounded, size: 20 * scale, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}
