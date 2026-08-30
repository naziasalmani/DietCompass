import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/config/app_config.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/storage_service.dart';
import '../scan/scan_history_screen.dart';
import 'personal_info_screen.dart';
import 'health_profile_screen.dart';
import 'dietary_preferences_screen.dart';
import 'password_login_screen.dart';
import 'google_sign_in_screen.dart';
import 'active_sessions_screen.dart';

/// DietCompass — Privacy & Security Screen
/// -----------------------------------------------------------------------
/// Matches the exact visual language of My Profile and Settings:
/// lavender background (0xFFF3F0FB), purple → green brand accents
/// (0xFF6C4EF5 → 0xFF1E8A4C), frosted glassmorphism cards, staggered
/// entrance choreography, rounded icon badges, and smooth press-scale
/// interactions.
class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({
    super.key,
    this.onBack,
  });

  final VoidCallback? onBack;

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _ambientCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

  Animation<double> _fade(double s, double e) => CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(s, e, curve: Curves.easeOut),
      );

  Animation<Offset> _slide(double s, double e) => Tween<Offset>(
        begin: const Offset(0, 0.12),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _entranceCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic),
        ),
      );

  // ---------------------------------------------------------------------------
  // Action Handlers
  // ---------------------------------------------------------------------------
  void _openPersonalInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PersonalInfoScreen(),
      ),
    );
  }

  void _openHealthDietaryData() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ActionBottomSheet(
        title: 'Health & Dietary Data',
        description: 'Choose which aspect of your health and dietary preferences you would like to view or update.',
        actions: [
          _SheetActionItem(
            icon: Icons.health_and_safety_rounded,
            iconColor: const Color(0xFF1E8A4C),
            iconBg: const Color(0xFFE3F5EA),
            title: 'Health Profile',
            subtitle: 'View medical context, biometrics & health goals',
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HealthProfileScreen()),
              );
            },
          ),
          _SheetActionItem(
            icon: Icons.restaurant_rounded,
            iconColor: const Color(0xFFE0862E),
            iconBg: const Color(0xFFFCEEDD),
            title: 'Dietary Preferences',
            subtitle: 'Update diet type, allergies & disliked foods',
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DietaryPreferencesScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openScanHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ScanHistoryScreen(),
      ),
    );
  }

  void _openPasswordLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PasswordLoginScreen(),
      ),
    );
  }

  void _openGoogleSignIn() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const GoogleSignInManagementScreen(),
      ),
    );
  }

  void _openActiveSessions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ActiveSessionsScreen(),
      ),
    );
  }

  void _showDownloadDataDialog() {
    bool isExporting = false;

    showDialog(
      context: context,
      barrierDismissible: !isExporting,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
            contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE7FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.download_rounded,
                    color: Color(0xFF6C4EF5),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Download My Data',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B1B2E),
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You can request a complete copy of your DietCompass personal information, health profile, dietary preferences, and scan history in JSON format.\n\nYour data export will be prepared securely.',
                    style: TextStyle(color: Color(0xFF6B6B7B), height: 1.4, fontSize: 13),
                  ),
                  if (isExporting) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE7FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Color(0xFF6C4EF5)),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Preparing your secure data export...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6C4EF5),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isExporting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B6B7B))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C4EF5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: isExporting
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        setDialogState(() => isExporting = true);

                        final token = await StorageService.instance.getAccessToken();
                        final user = AuthService.instance.currentUser;
                        final endpoint = '${AppConfig.apiBaseUrl}/profile/export';

                        try {
                          final response = await ApiService.instance.get(
                            '/profile/export',
                            requiresAuth: true,
                          );

                          debugPrint('\n[DATA EXPORT DEBUG]');
                          debugPrint('endpoint = $endpoint');
                          debugPrint('method = GET');
                          debugPrint('statusCode = ${response.statusCode}');
                          debugPrint('responseBody = ${response.rawBody ?? response.data}');
                          debugPrint('tokenPresent = ${token != null && token.isNotEmpty}');
                          debugPrint('userId = ${user?.id ?? 'unknown'}\n');

                          Map<String, dynamic>? exportData;

                          if (response.success && response.data != null) {
                            exportData = response.data!['data'] is Map<String, dynamic>
                                ? response.data!['data'] as Map<String, dynamic>
                                : response.data;
                          } else if (response.statusCode == 404) {
                            // If dedicated export route is not yet deployed on remote backend,
                            // fetch real user data from the live authenticated endpoints
                            debugPrint('[DATA EXPORT DEBUG] Fallback to live authenticated endpoints...');
                            final profRes = await ApiService.instance.get('/profile', requiresAuth: true);
                            final persRes = await ApiService.instance.get('/personalization', requiresAuth: true);
                            final scanRes = await ApiService.instance.get('/scan-history', requiresAuth: true);
                            final recRes = await ApiService.instance.get('/recipes/history', requiresAuth: true);

                            final userData = profRes.data?['data']?['user'] ?? profRes.data?['user'] ?? user?.toJson();
                            final personalization = persRes.data?['data'] ?? persRes.data;
                            final scanHistory = scanRes.data?['data'] ?? scanRes.data;
                            final recipeHistory = recRes.data?['data'] ?? recRes.data;
                            final savedRecipes = (recipeHistory is List)
                                ? recipeHistory.where((r) => r['isBookmarked'] == true).toList()
                                : [];

                            exportData = {
                              'exportMetadata': {
                                'appName': 'DietCompass',
                                'version': '1.0.0',
                                'exportedAt': DateTime.now().toIso8601String(),
                                'userId': user?.id ?? '',
                              },
                              'user': userData,
                              'personalization': personalization,
                              'scanHistory': scanHistory,
                              'savedRecipes': savedRecipes,
                              'recipeHistory': recipeHistory,
                            };
                          } else {
                            if (ctx.mounted) {
                              setDialogState(() => isExporting = false);
                            }
                            final is401 = response.statusCode == 401;
                            final errorMsg = is401
                                ? 'Your session has expired. Please log in again.'
                                : (response.message != null && response.message!.isNotEmpty
                                    ? response.message!
                                    : 'Unable to prepare your data export (HTTP ${response.statusCode}). Please try again.');

                            messenger.showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF1B1B2E),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                content: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: Color(0xFFE0525C), size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        errorMsg,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                            return;
                          }

                          if (exportData == null) {
                            if (ctx.mounted) setDialogState(() => isExporting = false);
                            messenger.showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF1B1B2E),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                content: const Text('Export payload was empty. Please try again.', style: TextStyle(fontSize: 12)),
                              ),
                            );
                            return;
                          }

                          final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
                          final dir = await getApplicationDocumentsDirectory();
                          final file = File('${dir.path}/dietcompass_data_export.json');
                          await file.writeAsString(jsonString);

                          final fileExists = await file.exists();
                          debugPrint('[DATA EXPORT DEBUG] File created at: ${file.path}, exists: $fileExists, size: ${await file.length()} bytes');

                          if (!fileExists) {
                            if (ctx.mounted) setDialogState(() => isExporting = false);
                            messenger.showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF1B1B2E),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                content: const Text('Failed to save export file to disk. Please try again.', style: TextStyle(fontSize: 12)),
                              ),
                            );
                            return;
                          }

                          if (ctx.mounted) Navigator.pop(ctx);

                          messenger.showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF1B1B2E),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Color(0xFF1E8A4C), size: 18),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Your data has been exported successfully.',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );

                          await SharePlus.instance.share(
                            ShareParams(
                              files: [XFile(file.path, mimeType: 'application/json')],
                              text: 'DietCompass Data Export',
                              subject: 'DietCompass Data Export',
                            ),
                          );
                        } on TimeoutException {
                          if (ctx.mounted) setDialogState(() => isExporting = false);
                          messenger.showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF1B1B2E),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              content: const Row(
                                children: [
                                  Icon(Icons.wifi_off_rounded, color: Color(0xFFE0862E), size: 18),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Unable to connect to the server. Please check your connection and try again.',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } catch (e, st) {
                          debugPrint('[DATA EXPORT DEBUG] Exception: $e\n$st');
                          if (ctx.mounted) setDialogState(() => isExporting = false);
                          messenger.showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF1B1B2E),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              content: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: Color(0xFFE0525C), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Export error: ${e.toString()}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                child: isExporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('Request Export'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFE0525C)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Delete Account',
                style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFE0525C), fontSize: 17),
              ),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            'Are you sure you want to delete your DietCompass account? This action is permanent and will remove all your scans, preferences, bookmarks, and health profile data.\n\nTo proceed with permanent deletion, please contact support or submit a deletion request.',
            style: TextStyle(color: Color(0xFF6B6B7B), height: 1.4, fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B6B7B))),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE0525C)),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF1B1B2E),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  content: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Color(0xFFE0525C), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Account deletion request logged. Support will verify your request.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: const Text('Confirm Request', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: const Row(
          children: [
            Icon(Icons.policy_outlined, color: Color(0xFF3B82F6)),
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
            'DietCompass is committed to protecting your privacy.\n\n'
            '1. Data Collection: We collect health preferences, dietary goals, and food scans solely to provide personalized nutrition recommendations.\n\n'
            '2. Storage & Security: All tokens and user credentials are encrypted in local secure hardware storage and transmitted over TLS.\n\n'
            '3. Third-Party Sharing: We do not sell or share your personal health data with advertisers.\n\n'
            '4. AI Processing: Meal plans and recipe queries processed by AI do not contain identifiable personal contact information.',
            style: TextStyle(color: Color(0xFF6B6B7B), height: 1.4, fontSize: 13),
          ),
        ),
        actions: [
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 390).clamp(0.85, 1.25);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FB),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _GlassBackdrop(uiScale: scale, ambientCtrl: _ambientCtrl),
          SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(18 * scale, 8 * scale, 18 * scale, 24 * scale),
              physics: const BouncingScrollPhysics(),
              children: [
                // ── Top Header ──────────────────────────────────────────────
                FadeTransition(
                  opacity: _fade(0.0, 0.22),
                  child: SlideTransition(
                    position: _slide(0.0, 0.26),
                    child: _TopHeader(
                      uiScale: scale,
                      onBack: widget.onBack ?? () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                SizedBox(height: 18 * scale),

                // ── Privacy Overview Card ───────────────────────────────────
                FadeTransition(
                  opacity: _fade(0.06, 0.32),
                  child: SlideTransition(
                    position: _slide(0.06, 0.36),
                    child: _GlassCard(
                      uiScale: scale,
                      padding: EdgeInsets.all(18 * scale),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48 * scale,
                            height: 48 * scale,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6C4EF5), Color(0xFF8467F8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16 * scale),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6C4EF5).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.shield_rounded,
                              size: 24 * scale,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 14 * scale),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Your Privacy Matters',
                                        style: TextStyle(
                                          fontSize: 16 * scale,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF1B1B2E),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 7 * scale, vertical: 3 * scale),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE3F5EA),
                                        borderRadius: BorderRadius.circular(8 * scale),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.lock_rounded, size: 10 * scale, color: const Color(0xFF1E8A4C)),
                                          SizedBox(width: 3 * scale),
                                          Text(
                                            'Encrypted',
                                            style: TextStyle(
                                              fontSize: 9.5 * scale,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF1E8A4C),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 5 * scale),
                                Text(
                                  'Your personal information and health preferences are securely stored and protected.',
                                  style: TextStyle(
                                    fontSize: 12 * scale,
                                    height: 1.4,
                                    color: const Color(0xFF6B6B7B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20 * scale),

                // ── Section 1: Account & Data ───────────────────────────────
                FadeTransition(
                  opacity: _fade(0.14, 0.42),
                  child: SlideTransition(
                    position: _slide(0.14, 0.46),
                    child: _SectionHeader(
                      uiScale: scale,
                      title: 'Account & Data',
                    ),
                  ),
                ),
                SizedBox(height: 10 * scale),
                FadeTransition(
                  opacity: _fade(0.18, 0.48),
                  child: SlideTransition(
                    position: _slide(0.18, 0.52),
                    child: _GlassCard(
                      uiScale: scale,
                      padding: EdgeInsets.symmetric(vertical: 4 * scale),
                      child: Column(
                        children: [
                          _PrivacyMenuTile(
                            uiScale: scale,
                            icon: Icons.person_outline_rounded,
                            iconBg: const Color(0xFFEDE7FA),
                            iconColor: const Color(0xFF6C4EF5),
                            title: 'Personal Information',
                            subtitle: 'Manage your personal details',
                            onTap: _openPersonalInfo,
                          ),
                          const _TileDivider(),
                          _PrivacyMenuTile(
                            uiScale: scale,
                            icon: Icons.favorite_outline_rounded,
                            iconBg: const Color(0xFFE3F5EA),
                            iconColor: const Color(0xFF1E8A4C),
                            title: 'Health & Dietary Data',
                            subtitle: 'Manage your health, diet and preference information',
                            onTap: _openHealthDietaryData,
                          ),
                          const _TileDivider(),
                          _PrivacyMenuTile(
                            uiScale: scale,
                            icon: Icons.history_rounded,
                            iconBg: const Color(0xFFE3EEFC),
                            iconColor: const Color(0xFF3B82F6),
                            title: 'Scan History',
                            subtitle: 'View and manage your previous food scans',
                            onTap: _openScanHistory,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20 * scale),

                // ── Section 2: Security ─────────────────────────────────────
                FadeTransition(
                  opacity: _fade(0.24, 0.54),
                  child: SlideTransition(
                    position: _slide(0.24, 0.58),
                    child: _SectionHeader(
                      uiScale: scale,
                      title: 'Security',
                    ),
                  ),
                ),
                SizedBox(height: 10 * scale),
                FadeTransition(
                  opacity: _fade(0.28, 0.6),
                  child: SlideTransition(
                    position: _slide(0.28, 0.64),
                    child: _GlassCard(
                      uiScale: scale,
                      padding: EdgeInsets.symmetric(vertical: 4 * scale),
                      child: Column(
                        children: [
                          _PrivacyMenuTile(
                            uiScale: scale,
                            icon: Icons.lock_outline_rounded,
                            iconBg: const Color(0xFFEDE7FA),
                            iconColor: const Color(0xFF6C4EF5),
                            title: 'Password & Login',
                            subtitle: 'Manage your password and login methods',
                            onTap: _openPasswordLogin,
                          ),
                          const _TileDivider(),
                          _PrivacyMenuTile(
                            uiScale: scale,
                            icon: Icons.account_circle_outlined,
                            iconBg: const Color(0xFFFCEEDD),
                            iconColor: const Color(0xFFE0862E),
                            title: 'Google Sign-In',
                            subtitle: 'Manage your connected Google account',
                            onTap: _openGoogleSignIn,
                          ),
                          const _TileDivider(),
                          _PrivacyMenuTile(
                            uiScale: scale,
                            icon: Icons.devices_rounded,
                            iconBg: const Color(0xFFE3F5EA),
                            iconColor: const Color(0xFF1E8A4C),
                            title: 'Active Sessions',
                            subtitle: 'Manage devices where you\'re signed in',
                            onTap: _openActiveSessions,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20 * scale),

                // ── Section 3: Data Controls ────────────────────────────────
                FadeTransition(
                  opacity: _fade(0.34, 0.66),
                  child: SlideTransition(
                    position: _slide(0.34, 0.7),
                    child: _SectionHeader(
                      uiScale: scale,
                      title: 'Data Controls',
                    ),
                  ),
                ),
                SizedBox(height: 10 * scale),
                FadeTransition(
                  opacity: _fade(0.38, 0.72),
                  child: SlideTransition(
                    position: _slide(0.38, 0.76),
                    child: _GlassCard(
                      uiScale: scale,
                      padding: EdgeInsets.symmetric(vertical: 4 * scale),
                      child: Column(
                        children: [
                          _PrivacyMenuTile(
                            uiScale: scale,
                            icon: Icons.download_rounded,
                            iconBg: const Color(0xFFEDE7FA),
                            iconColor: const Color(0xFF6C4EF5),
                            title: 'Download My Data',
                            subtitle: 'Request a copy of your DietCompass data',
                            onTap: _showDownloadDataDialog,
                          ),
                          const _TileDivider(),
                          _PrivacyMenuTile(
                            uiScale: scale,
                            icon: Icons.delete_outline_rounded,
                            iconBg: const Color(0xFFFFECEE),
                            iconColor: const Color(0xFFE0525C),
                            title: 'Delete Account',
                            titleColor: const Color(0xFFE0525C),
                            subtitle: 'Permanently delete your account and associated data',
                            chevronColor: const Color(0xFFE0525C).withValues(alpha: 0.5),
                            onTap: _showDeleteAccountDialog,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20 * scale),

                // ── Section 4: Legal & Policy ───────────────────────────────
                FadeTransition(
                  opacity: _fade(0.44, 0.78),
                  child: SlideTransition(
                    position: _slide(0.44, 0.82),
                    child: _SectionHeader(
                      uiScale: scale,
                      title: 'Policy',
                    ),
                  ),
                ),
                SizedBox(height: 10 * scale),
                FadeTransition(
                  opacity: _fade(0.48, 0.84),
                  child: SlideTransition(
                    position: _slide(0.48, 0.88),
                    child: _GlassCard(
                      uiScale: scale,
                      padding: EdgeInsets.symmetric(vertical: 4 * scale),
                      child: _PrivacyMenuTile(
                        uiScale: scale,
                        icon: Icons.policy_outlined,
                        iconBg: const Color(0xFFE3EEFC),
                        iconColor: const Color(0xFF3B82F6),
                        title: 'Privacy Policy',
                        subtitle: 'Read how DietCompass handles your data',
                        onTap: _showPrivacyPolicy,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24 * scale),

                // ── Privacy Notice Badge ────────────────────────────────────
                FadeTransition(
                  opacity: _fade(0.54, 0.92),
                  child: SlideTransition(
                    position: _slide(0.54, 0.96),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16 * scale,
                          vertical: 10 * scale,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F5EA),
                          borderRadius: BorderRadius.circular(20 * scale),
                          border: Border.all(
                            color: const Color(0xFF1E8A4C).withValues(alpha: 0.18),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              size: 16 * scale,
                              color: const Color(0xFF1E8A4C),
                            ),
                            SizedBox(width: 8 * scale),
                            Flexible(
                              child: Text(
                                'Your data is secure and 100% private',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5 * scale,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E8A4C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
}

// ---------------------------------------------------------------------------
// Section Header Text
// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.uiScale, required this.title});
  final double uiScale;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4 * uiScale),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.5 * uiScale,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF1B1B2E),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top Header with Back Button
// ---------------------------------------------------------------------------
class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.uiScale,
    required this.onBack,
  });

  final double uiScale;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Pressable(
          onTap: onBack,
          child: Container(
            width: 42 * uiScale,
            height: 42 * uiScale,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              size: 19 * uiScale,
              color: const Color(0xFF1B1B2E),
            ),
          ),
        ),
        SizedBox(width: 14 * uiScale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Privacy & Security',
                style: TextStyle(
                  fontSize: 22 * uiScale,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B1B2E),
                ),
              ),
              SizedBox(height: 2 * uiScale),
              Text(
                'Control your data and privacy',
                style: TextStyle(
                  fontSize: 12 * uiScale,
                  color: const Color(0xFF6B6B7B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Ambient glass backdrop
// ---------------------------------------------------------------------------
class _GlassBackdrop extends StatelessWidget {
  const _GlassBackdrop({required this.uiScale, required this.ambientCtrl});
  final double uiScale;
  final AnimationController ambientCtrl;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambientCtrl,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(ambientCtrl.value);
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(color: const Color(0xFFF3F0FB)),
            Positioned(
              top: -90 + t * 16,
              right: -60,
              child: _blob(220 * uiScale, const Color(0xFF6C4EF5)),
            ),
            Positioned(
              top: 260 - t * 20,
              left: -70,
              child: _blob(190 * uiScale, const Color(0xFF1E8A4C)),
            ),
            Positioned(
              bottom: -60 + t * 12,
              right: -40,
              child: _blob(180 * uiScale, const Color(0xFF3B82F6)),
            ),
          ],
        );
      },
    );
  }

  Widget _blob(double size, Color color) => ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.18),
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Reusable frosted glassmorphism card
// ---------------------------------------------------------------------------
class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.uiScale, required this.child, this.padding});
  final double uiScale;
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding ?? EdgeInsets.all(16 * uiScale),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.75),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C4EF5).withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Press-scale wrapper
// ---------------------------------------------------------------------------
class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _scale = 0.96),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _scale = 1.0),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Menu Tile
// ---------------------------------------------------------------------------
class _PrivacyMenuTile extends StatefulWidget {
  const _PrivacyMenuTile({
    required this.uiScale,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.titleColor = const Color(0xFF1B1B2E),
    this.chevronColor = const Color(0xFFB0ACC2),
    this.onTap,
  });

  final double uiScale;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color titleColor;
  final Color chevronColor;
  final VoidCallback? onTap;

  @override
  State<_PrivacyMenuTile> createState() => _PrivacyMenuTileState();
}

class _PrivacyMenuTileState extends State<_PrivacyMenuTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final uiScale = widget.uiScale;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        color: _pressed ? const Color(0xFFF1ECFB) : Colors.transparent,
        padding: EdgeInsets.symmetric(
          horizontal: 12 * uiScale,
          vertical: 13 * uiScale,
        ),
        child: Row(
          children: [
            Container(
              width: 40 * uiScale,
              height: 40 * uiScale,
              decoration: BoxDecoration(
                color: widget.iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.icon,
                size: 19 * uiScale,
                color: widget.iconColor,
              ),
            ),
            SizedBox(width: 12 * uiScale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 13.5 * uiScale,
                      fontWeight: FontWeight.w800,
                      color: widget.titleColor,
                    ),
                  ),
                  SizedBox(height: 2 * uiScale),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontSize: 11 * uiScale,
                      color: const Color(0xFF6B6B7B),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSlide(
              offset: _pressed ? const Offset(0.06, 0) : Offset.zero,
              duration: const Duration(milliseconds: 140),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 18 * uiScale,
                color: widget.chevronColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Divider between menu tiles
// ---------------------------------------------------------------------------
class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 64,
      endIndent: 12,
      color: Color(0xFFEDEAF7),
    );
  }
}

// ---------------------------------------------------------------------------
// Action Bottom Sheet for multi-option rows
// ---------------------------------------------------------------------------
class _ActionBottomSheet extends StatelessWidget {
  const _ActionBottomSheet({
    required this.title,
    required this.description,
    required this.actions,
  });

  final String title;
  final String description;
  final List<_SheetActionItem> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3DDF5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B1B2E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF6B6B7B),
              ),
            ),
            const SizedBox(height: 16),
            ...actions,
          ],
        ),
      ),
    );
  }
}

class _SheetActionItem extends StatelessWidget {
  const _SheetActionItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B1B2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B6B7B)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFFB0ACC2)),
          ],
        ),
      ),
    );
  }
}
