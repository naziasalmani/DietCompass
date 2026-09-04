import 'package:flutter/material.dart';
import 'package:diet_compass/core/theme/app_colors.dart';
import 'privacy_security_screen.dart';
import 'help_support_screen.dart';

/// DietCompass — About Screen
/// -----------------------------------------------------------------------
/// Matches the exact visual language of My Profile, Help & Support, and
/// Privacy & Security: lavender background (0xFFF3F0FB), ambient blur glows,
/// frosted white glass cards, brand typography, and smooth press animations.
class AboutScreen extends StatefulWidget {
  const AboutScreen({
    super.key,
    this.appVersion = '1.0.0 (Beta)',
    this.onBack,
  });

  final String appVersion;
  final VoidCallback? onBack;

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

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

  void _openPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFF6C4EF5)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Privacy Policy',
                style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1B1B2E), fontSize: 17),
              ),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            'DietCompass is committed to protecting your personal information and health preferences.\n\n'
            '1. Data Ownership: Your profile details, dietary restrictions, scan history, and saved recipes belong exclusively to you.\n\n'
            '2. No Third-Party Selling: We do not sell or monetize your individual dietary or health data to advertisers or third-party brokers.\n\n'
            '3. Encryption & Storage: All network communications are encrypted via TLS/HTTPS, and credentials are securely stored using encrypted storage.\n\n'
            '4. Data Export & Deletion: You can download a complete JSON export of your personal data or request account deletion at any time from the Privacy & Security screen.',
            style: TextStyle(color: Color(0xFF6B6B7B), height: 1.4, fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
              );
            },
            child: const Text('Manage Privacy', style: TextStyle(color: Color(0xFF6C4EF5), fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C4EF5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openHelpSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HelpSupportScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final scale = (width / 390.0).clamp(0.85, 1.25);

    final colors = context.dcColors;
    return Scaffold(
      backgroundColor: colors.bg,
      body: Stack(
        children: [
          // Ambient blurred background glows
          Positioned(
            top: -50,
            left: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C4EF5).withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            top: 260,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E8A4C).withValues(alpha: 0.08),
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
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(14 * scale),
                            border: Border.all(color: colors.cardBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 20 * scale,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(width: 14 * scale),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'About DietCompass',
                              style: TextStyle(
                                fontSize: 18 * scale,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              'Scan. Analyze. Eat Better.',
                              style: TextStyle(
                                fontSize: 12 * scale,
                                color: colors.textSecondary,
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
                        // ── Header Card ─────────────────────────────────────
                        _buildCard(
                          scale: scale,
                          child: Padding(
                            padding: EdgeInsets.all(20 * scale),
                            child: Column(
                              children: [
                                // Logo
                                Container(
                                  width: 72 * scale,
                                  height: 72 * scale,
                                  padding: EdgeInsets.all(10 * scale),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEDE7FA),
                                    borderRadius: BorderRadius.circular(22 * scale),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF6C4EF5).withValues(alpha: 0.12),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/images/compass_icon.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (ctx, err, stack) => Icon(
                                      Icons.explore_rounded,
                                      size: 38 * scale,
                                      color: const Color(0xFF6C4EF5),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 14 * scale),

                                // Title & Tagline
                                Text(
                                  'DietCompass',
                                  style: TextStyle(
                                    fontSize: 22 * scale,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.3,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 4 * scale),
                                Text(
                                  'Scan. Analyze. Eat Better. Live Healthier.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5 * scale,
                                    fontWeight: FontWeight.w700,
                                    color: colors.iconPurple,
                                  ),
                                ),
                                SizedBox(height: 10 * scale),

                                // Version badge
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10 * scale,
                                    vertical: 4 * scale,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.surfaceSecondary,
                                    borderRadius: BorderRadius.circular(8 * scale),
                                    border: Border.all(
                                      color: colors.cardBorder,
                                    ),
                                  ),
                                  child: Text(
                                    'Version ${widget.appVersion}',
                                    style: TextStyle(
                                      fontSize: 11 * scale,
                                      fontWeight: FontWeight.w700,
                                      color: colors.iconPurple,
                                    ),
                                  ),
                                ),

                                SizedBox(height: 16 * scale),
                                Divider(height: 1, color: colors.cardBorder),
                                SizedBox(height: 16 * scale),

                                // Description
                                Text(
                                  'DietCompass helps you make smarter food choices by scanning food products, analyzing ingredients and nutrition information, identifying potentially concerning or hidden ingredients, and providing personalized food and recipe recommendations based on your preferences.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5 * scale,
                                    color: colors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 22 * scale),

                        // ── Features Section ────────────────────────────────
                        _buildSectionHeader('What DietCompass Does', scale),
                        SizedBox(height: 10 * scale),
                        _buildCard(
                          scale: scale,
                          child: Column(
                            children: [
                              _buildFeatureRow(
                                icon: Icons.qr_code_scanner_rounded,
                                iconColor: const Color(0xFF6C4EF5),
                                iconBg: const Color(0xFFEDE7FA),
                                title: 'Scan & Analyze',
                                description: 'Scan food products and understand their ingredients and nutrition information.',
                                scale: scale,
                              ),
                              _buildDivider(),
                              _buildFeatureRow(
                                icon: Icons.tune_rounded,
                                iconColor: const Color(0xFF1E8A4C),
                                iconBg: const Color(0xFFE3F5EA),
                                title: 'Personalized Nutrition',
                                description: 'Get recommendations based on your dietary preferences, goals, allergies, and activity level.',
                                scale: scale,
                              ),
                              _buildDivider(),
                              _buildFeatureRow(
                                icon: Icons.restaurant_menu_rounded,
                                iconColor: const Color(0xFFE0862E),
                                iconBg: const Color(0xFFFCEEDD),
                                title: 'Smart Recipes',
                                description: 'Discover recipes suited to your preferences and nutritional goals.',
                                scale: scale,
                              ),
                              _buildDivider(),
                              _buildFeatureRow(
                                icon: Icons.history_rounded,
                                iconColor: const Color(0xFF3B82F6),
                                iconBg: const Color(0xFFE3EEFC),
                                title: 'Food History',
                                description: 'Keep track of your previous product scans and saved recipes.',
                                scale: scale,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 22 * scale),

                        // ── App Information Section ─────────────────────────
                        _buildSectionHeader('App Information', scale),
                        SizedBox(height: 10 * scale),
                        _buildCard(
                          scale: scale,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 14 * scale),
                            child: Column(
                              children: [
                                _buildInfoRow('App Name', 'DietCompass', scale),
                                const SizedBox(height: 10),
                                Divider(height: 1, color: colors.cardBorder),
                                const SizedBox(height: 10),
                                _buildInfoRow('Version', widget.appVersion, scale),
                                const SizedBox(height: 10),
                                Divider(height: 1, color: colors.cardBorder),
                                const SizedBox(height: 10),
                                _buildInfoRow('Release Channel', 'Beta', scale),
                                const SizedBox(height: 10),
                                Divider(height: 1, color: colors.cardBorder),
                                const SizedBox(height: 10),
                                _buildInfoRow('Platform', 'Android & Web (Flutter)', scale),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 22 * scale),

                        // ── Resources & Links Section ───────────────────────
                        _buildSectionHeader('Resources & Legal', scale),
                        SizedBox(height: 10 * scale),
                        _buildCard(
                          scale: scale,
                          child: Column(
                            children: [
                              _buildNavRow(
                                icon: Icons.shield_outlined,
                                iconColor: const Color(0xFF6C4EF5),
                                iconBg: const Color(0xFFEDE7FA),
                                title: 'Privacy Policy',
                                subtitle: 'Read how DietCompass protects your privacy',
                                scale: scale,
                                onTap: _openPrivacyPolicy,
                              ),
                              _buildDivider(),
                              _buildNavRow(
                                icon: Icons.headset_mic_rounded,
                                iconColor: const Color(0xFF1E8A4C),
                                iconBg: const Color(0xFFE3F5EA),
                                title: 'Help & Support',
                                subtitle: 'Guides, FAQs, and support contact',
                                scale: scale,
                                onTap: _openHelpSupport,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 28 * scale),

                        // ── Footer ──────────────────────────────────────────
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'Made with ❤️ for healthier choices',
                                style: TextStyle(
                                  fontSize: 12 * scale,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6B6B7B),
                                ),
                              ),
                              SizedBox(height: 4 * scale),
                              Text(
                                '© 2026 DietCompass. All rights reserved.',
                                style: TextStyle(
                                  fontSize: 10.5 * scale,
                                  color: const Color(0xFFA0A0B0),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 20 * scale),
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
  }

  Widget _buildSectionHeader(String title, double scale) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15 * scale,
        fontWeight: FontWeight.w800,
        color: context.dcColors.textPrimary,
      ),
    );
  }

  Widget _buildCard({required double scale, required Widget child}) {
    final colors = context.dcColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: colors.iconPurple.withValues(alpha: colors.isDark ? 0.12 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: context.dcColors.cardBorder, indent: 16, endIndent: 16);
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String description,
    required double scale,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 14 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38 * scale,
            height: 38 * scale,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12 * scale),
            ),
            child: Icon(icon, color: iconColor, size: 20 * scale),
          ),
          SizedBox(width: 14 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w800,
                    color: context.dcColors.textPrimary,
                  ),
                ),
                SizedBox(height: 3 * scale),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: context.dcColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, double scale) {
    final colors = context.dcColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5 * scale,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13 * scale,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildNavRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required double scale,
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
                      color: context.dcColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2 * scale),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5 * scale,
                      color: context.dcColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20 * scale, color: context.dcColors.textMuted),
          ],
        ),
      ),
    );
  }
}
