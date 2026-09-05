import 'dart:ui';

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/model/health_compass_data.dart';
import '../../core/model/user_profile.dart';
import '../../core/model/scan_history_item.dart';
import '../../core/services/scan_history_service.dart';
import '../../core/services/profile_service.dart';
import '../home/home_screen.dart';
import '../scan/scan_screen.dart';
import '../ai/ai_recommendation_screen.dart';
import '../pantry/pantry_screen.dart';
import 'compatibility_trend_chart.dart';

/// DietCompass — Dashboard Screen (Real Data Only Version)
/// -----------------------------------------------------------------------
/// Displays ONLY real, user-specific data from:
/// - HealthCompassData: Average Compatibility, Products Analyzed, Ingredients Flagged, Better Alternatives, Scans This Week
/// - UserProfile: Streak Days
/// - ScanHistoryService: Recent scans
///
/// ALL DATA IS REAL.
/// NO HARDCODED VALUES.
/// NO FAKE ANALYTICS.
/// NO ASSUMED CONSUMPTION FROM SCANS.
/// ONE SOURCE OF TRUTH FOR EACH METRIC.

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.userName,
    this.avatarImage,
    this.onNotificationTap,
    this.onCalendarTap,
    this.onNutrientSeeDetails,
    this.onViewInsightsTap,
    this.onTopFoodsSeeAll,
    this.onTopFoodTap,
    this.onEditGoalsTap,
    this.onCaloriesRangeTap,
    this.onMacroRangeTap,
    this.onNavTap,
    this.initialNavIndex = 4,
  });

  final String? userName;
  final ImageProvider? avatarImage;

  final VoidCallback? onNotificationTap;
  final VoidCallback? onCalendarTap;
  final VoidCallback? onNutrientSeeDetails;
  final VoidCallback? onViewInsightsTap;
  final VoidCallback? onTopFoodsSeeAll;
  final ValueChanged<int>? onTopFoodTap;
  final VoidCallback? onEditGoalsTap;
  final VoidCallback? onCaloriesRangeTap;
  final VoidCallback? onMacroRangeTap;
  final ValueChanged<int>? onNavTap;
  final int initialNavIndex;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _ambientCtrl;
  late int _navIndex;

  String _displayName = '';
  HealthCompassData? _healthCompass;
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _navIndex = widget.initialNavIndex;
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..value = 1.0;
    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    ProfileService.instance.addListener(_onDataChanged);
    ScanHistoryService.instance.addListener(_onDataChanged);
    _loadDashboardData();
  }

  void _onDataChanged() {
    if (mounted) {
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      // Get authenticated user's profile
      final profile = ProfileService.instance.currentProfile;

      // Get authenticated user's health compass data (from real scan history)
      // This uses the same source as the Home Screen's "YOUR HEALTH COMPASS"
      final healthCompass = ScanHistoryService.instance.computeHealthCompass();

      // Get user's display name
      final displayName = widget.userName ?? profile?.fullName ?? 'User';

      if (mounted) {
        setState(() {
          _userProfile = profile;
          _healthCompass = healthCompass;
          _displayName = displayName;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[DashboardScreen] Error loading data: $e');
      if (mounted) {
        setState(() {
          _displayName = widget.userName ?? 'User';
          _isLoading = false;
        });
      }
    }
  }

  /// Get recent scans for the dashboard (up to 5 most recent)
  Future<List<ScanHistoryItem>> _getRecentScans() async {
    try {
      final scans = await ScanHistoryService.instance.getScanHistory(limit: 5);
      return scans;
    } catch (e) {
      debugPrint('[DashboardScreen] Error loading recent scans: $e');
      return [];
    }
  }

  @override
  void dispose() {
    ProfileService.instance.removeListener(_onDataChanged);
    ScanHistoryService.instance.removeListener(_onDataChanged);
    _entranceCtrl.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

  Animation<double> _fade(double s, double e) => CurvedAnimation(
    parent: _entranceCtrl,
    curve: Interval(s, e, curve: Curves.easeOut),
  );

  Animation<Offset> _slide(double s, double e) =>
      Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entranceCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 390).clamp(0.85, 1.25);
    final colors = context.dcColors;

    return Scaffold(
      backgroundColor: colors.bg,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (!colors.isDark)
            Positioned.fill(
              child: Image.asset(
                'assets/images/home_bg.jpeg',
                fit: BoxFit.cover,
              ),
            )
          else
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF13111C), Color(0xFF0D0C14)],
                  ),
                ),
              ),
            ),

          SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16 * scale,
                8 * scale,
                16 * scale,
                110 * scale,
              ),
              physics: const BouncingScrollPhysics(),
              children: [
                // HEADER
                FadeTransition(
                  opacity: _fade(0.0, 0.25),
                  child: _Header(
                    uiScale: scale,
                    userName: _displayName,
                    avatarImage: widget.avatarImage,
                    onNotificationTap: widget.onNotificationTap,
                    onCalendarTap: widget.onCalendarTap,
                  ),
                ),
                SizedBox(height: 18 * scale),

                // YOUR OVERVIEW SECTION
                FadeTransition(
                  opacity: _fade(0.03, 0.3),
                  child: Text(
                    'Your Overview',
                    style: TextStyle(
                      fontSize: 16.5 * scale,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                SizedBox(height: 10 * scale),

                FadeTransition(
                  opacity: _fade(0.06, 0.4),
                  child: SlideTransition(
                    position: _slide(0.06, 0.42),
                    child: _OverviewRow(
                      uiScale: scale,
                      entranceCtrl: _entranceCtrl,
                      averageCompatibility:
                          _healthCompass?.averageCompatibility,
                      compatibilityLabel:
                          _healthCompass?.compatibilityLabel ?? 'No scans yet',
                      streakDays: _userProfile?.streakDays ?? 0,
                      ambientCtrl: _ambientCtrl,
                    ),
                  ),
                ),
                SizedBox(height: 20 * scale),

                // SCAN INSIGHTS SECTION (Real data from HealthCompassData)
                if (_healthCompass != null && _healthCompass!.hasScans)
                  FadeTransition(
                    opacity: _fade(0.1, 0.45),
                    child: SlideTransition(
                      position: _slide(0.1, 0.48),
                      child: _ScanInsightsSection(
                        uiScale: scale,
                        healthCompass: _healthCompass!,
                      ),
                    ),
                  )
                else
                  FadeTransition(
                    opacity: _fade(0.1, 0.45),
                    child: SlideTransition(
                      position: _slide(0.1, 0.48),
                      child: _EmptyStateCard(
                        uiScale: scale,
                        icon: Icons.analytics_outlined,
                        title: 'No scans yet',
                        message:
                            'Scan your first product to start building your food insights and see detailed analytics here.',
                      ),
                    ),
                  ),
                SizedBox(height: 18 * scale),

                // RECENT SCANS SECTION (Real scanned products)
                if (_healthCompass != null && _healthCompass!.hasScans)
                  FadeTransition(
                    opacity: _fade(0.16, 0.5),
                    child: SlideTransition(
                      position: _slide(0.16, 0.52),
                      child: FutureBuilder<List<ScanHistoryItem>>(
                        future: _getRecentScans(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _RecentScansSkeletonLoader(uiScale: scale);
                          }

                          if (snapshot.hasError ||
                              !snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return _RecentScansSection(
                            uiScale: scale,
                            recentScans: snapshot.data!,
                          );
                        },
                      ),
                    ),
                  ),
                SizedBox(height: 18 * scale),

                // COMPATIBILITY TREND CHART (Real compatibility scores over time)
                if (_healthCompass != null && _healthCompass!.hasScans)
                  FadeTransition(
                    opacity: _fade(0.19, 0.54),
                    child: SlideTransition(
                      position: _slide(0.19, 0.56),
                      child: CompatibilityTrendChart(
                        uiScale: scale,
                      ),
                    ),
                  ),
                if (_healthCompass != null && _healthCompass!.hasScans)
                  SizedBox(height: 18 * scale),

                // COMPATIBILITY OVERVIEW (Real distribution from scans)
                if (_healthCompass != null && _healthCompass!.hasScans)
                  FadeTransition(
                    opacity: _fade(0.22, 0.56),
                    child: SlideTransition(
                      position: _slide(0.22, 0.58),
                      child: _CompatibilityOverviewSection(
                        uiScale: scale,
                        healthCompass: _healthCompass!,
                      ),
                    ),
                  ),
                SizedBox(height: 18 * scale),

                // YOUR GOALS SECTION (Real goals or empty state)
                FadeTransition(
                  opacity: _fade(0.28, 0.62),
                  child: SlideTransition(
                    position: _slide(0.28, 0.64),
                    child: _GoalsSection(
                      uiScale: scale,
                      userProfile: _userProfile,
                      onEditGoalsTap: widget.onEditGoalsTap,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNavBar(
        uiScale: scale,
        selectedIndex: _navIndex,
        onTap: (i) {
          setState(() => _navIndex = i);

          switch (i) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
              break;

            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => ScanScreen()),
              );
              break;

            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => AiShoppingScreen()),
              );
              break;

            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => PantryScreen()),
              );
              break;

            case 4:
              // Already on Dashboard.
              break;
          }

          widget.onNavTap?.call(i);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State Card
// ---------------------------------------------------------------------------
class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.uiScale,
    required this.icon,
    required this.title,
    required this.message,
  });

  final double uiScale;
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 36 * uiScale, color: colors.textMuted),
          SizedBox(height: 12 * uiScale),
          Text(
            title,
            style: TextStyle(
              fontSize: 13.5 * uiScale,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6 * uiScale),
          Text(
            message,
            style: TextStyle(
              fontSize: 11 * uiScale,
              color: colors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  const _Header({
    required this.uiScale,
    required this.userName,
    this.avatarImage,
    this.onNotificationTap,
    this.onCalendarTap,
  });

  final double uiScale;
  final String userName;
  final ImageProvider? avatarImage;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onCalendarTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Row(
      children: [
        Container(
          width: 52 * uiScale,
          height: 52 * uiScale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [colors.iconPurple, colors.iconGreen],
            ),
            image: avatarImage != null
                ? DecorationImage(image: avatarImage!, fit: BoxFit.cover)
                : null,
          ),
          child: avatarImage == null
              ? Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 19 * uiScale,
                    ),
                  ),
                )
              : null,
        ),
        SizedBox(width: 12 * uiScale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Hello, $userName! ',
                    style: TextStyle(
                      fontSize: 17 * uiScale,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text('👋', style: TextStyle(fontSize: 15 * uiScale)),
                ],
              ),
              Text(
                'Track your progress & build healthier habits.',
                style: TextStyle(
                  fontSize: 11 * uiScale,
                  height: 1.3,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8 * uiScale),
        _HeaderIconButton(
          uiScale: uiScale,
          icon: Icons.notifications_none_rounded,
          showDot: true,
          onTap: onNotificationTap,
        ),
        SizedBox(width: 8 * uiScale),
        _HeaderIconButton(
          uiScale: uiScale,
          icon: Icons.calendar_today_outlined,
          onTap: onCalendarTap,
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatefulWidget {
  const _HeaderIconButton({
    required this.uiScale,
    required this.icon,
    this.showDot = false,
    this.onTap,
  });
  final double uiScale;
  final IconData icon;
  final bool showDot;
  final VoidCallback? onTap;

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.9),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40 * widget.uiScale,
              height: 40 * widget.uiScale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.surface,
                border: Border.all(color: colors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: colors.isDark ? 0.20 : 0.06,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                size: 17 * widget.uiScale,
                color: colors.iconPurple,
              ),
            ),
            if (widget.showDot)
              Positioned(
                top: 1,
                right: 3,
                child: Container(
                  width: 8 * widget.uiScale,
                  height: 8 * widget.uiScale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE0525C),
                    border: Border.all(color: colors.surface, width: 1.4),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overview row: Average Compatibility + Streak
// ---------------------------------------------------------------------------
class _OverviewRow extends StatelessWidget {
  const _OverviewRow({
    required this.uiScale,
    required this.entranceCtrl,
    this.averageCompatibility,
    required this.compatibilityLabel,
    required this.streakDays,
    required this.ambientCtrl,
  });

  final double uiScale;
  final AnimationController entranceCtrl;
  final int? averageCompatibility;
  final String compatibilityLabel;
  final int streakDays;
  final AnimationController ambientCtrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;

    // Determine color based on compatibility score
    Color compatibilityColor = colors.textMuted;
    if (averageCompatibility != null) {
      if (averageCompatibility! >= 90) {
        compatibilityColor = const Color(0xFF1E8A4C);
      } else if (averageCompatibility! >= 75) {
        compatibilityColor = const Color(0xFF1E8A4C);
      } else if (averageCompatibility! >= 60) {
        compatibilityColor = const Color(0xFFE0862E);
      } else {
        compatibilityColor = const Color(0xFFE0525C);
      }
    }

    return Row(
      children: [
        Expanded(
          child: _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Average Compatibility',
                  style: TextStyle(
                    fontSize: 12.5 * uiScale,
                    fontWeight: FontWeight.w800,
                    color: colors.iconPurple,
                  ),
                ),
                SizedBox(height: 8 * uiScale),
                if (averageCompatibility != null)
                  Text(
                    '$averageCompatibility / 100',
                    style: TextStyle(
                      fontSize: 30 * uiScale,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  )
                else
                  Text(
                    'No data',
                    style: TextStyle(
                      fontSize: 20 * uiScale,
                      fontWeight: FontWeight.w800,
                      color: colors.textSecondary,
                    ),
                  ),
                SizedBox(height: 6 * uiScale),
                Text(
                  compatibilityLabel,
                  style: TextStyle(
                    fontSize: 10 * uiScale,
                    fontWeight: FontWeight.w700,
                    color: compatibilityColor,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(width: 12 * uiScale),

        Expanded(
          child: _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Streak',
                  style: TextStyle(
                    fontSize: 12.5 * uiScale,
                    fontWeight: FontWeight.w800,
                    color: colors.iconPurple,
                  ),
                ),
                SizedBox(height: 8 * uiScale),
                Icon(
                  Icons.local_fire_department,
                  color: streakDays > 0 ? colors.iconOrange : colors.textMuted,
                  size: 28 * uiScale,
                ),
                SizedBox(height: 8 * uiScale),
                Text(
                  streakDays > 0 ? '$streakDays days' : 'No streak',
                  style: TextStyle(
                    fontSize: 20 * uiScale,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Glass card helper
// ---------------------------------------------------------------------------
class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.padding, this.radius = 20});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: padding ?? const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface.withValues(
              alpha: colors.isDark ? 0.90 : 0.70,
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: colors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: colors.isDark ? 0.20 : 0.05,
                ),
                blurRadius: 18,
                offset: const Offset(0, 8),
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
// Scan Insights Section (Real data: Products Analyzed, Ingredients Flagged, etc.)
// ---------------------------------------------------------------------------
class _ScanInsightsSection extends StatelessWidget {
  const _ScanInsightsSection({
    required this.uiScale,
    required this.healthCompass,
  });

  final double uiScale;
  final HealthCompassData healthCompass;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scan Insights',
          style: TextStyle(
            fontSize: 15.5 * uiScale,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: 10 * uiScale),

        // 2x2 grid of metrics
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.1,
          mainAxisSpacing: 10 * uiScale,
          crossAxisSpacing: 10 * uiScale,
          children: [
            _MetricCard(
              uiScale: uiScale,
              icon: Icons.check_circle_outline,
              label: 'Products Analyzed',
              value: '${healthCompass.productsAnalyzed}',
              colors: colors,
            ),
            _MetricCard(
              uiScale: uiScale,
              icon: Icons.warning_outlined,
              label: 'Ingredients Flagged',
              value: '${healthCompass.ingredientsFlagged}',
              colors: colors,
            ),
            _MetricCard(
              uiScale: uiScale,
              icon: Icons.auto_awesome,
              label: 'Better Alternatives',
              value: '${healthCompass.betterAlternatives}',
              colors: colors,
            ),
            _MetricCard(
              uiScale: uiScale,
              icon: Icons.calendar_today_outlined,
              label: 'Scans This Week',
              value: '${healthCompass.scansThisWeek}',
              colors: colors,
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Metric Card (for Scan Insights)
// ---------------------------------------------------------------------------
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.uiScale,
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
  });

  final double uiScale;
  final IconData icon;
  final String label;
  final String value;
  final DietCompassThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24 * uiScale, color: colors.iconPurple),
          SizedBox(height: 8 * uiScale),
          Text(
            value,
            style: TextStyle(
              fontSize: 22 * uiScale,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 4 * uiScale),
          Text(
            label,
            style: TextStyle(
              fontSize: 10 * uiScale,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent Scans Section
// ---------------------------------------------------------------------------
class _RecentScansSection extends StatelessWidget {
  const _RecentScansSection({required this.uiScale, required this.recentScans});

  final double uiScale;
  final List<ScanHistoryItem> recentScans;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Scans',
              style: TextStyle(
                fontSize: 15.5 * uiScale,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                // Navigate to Scan History
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const HomeScreen(), // Placeholder - would be ScanHistoryScreen
                  ),
                );
              },
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 11 * uiScale,
                      fontWeight: FontWeight.w700,
                      color: colors.iconPurple,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 14 * uiScale,
                    color: colors.iconPurple,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 10 * uiScale),

        // List of recent scans
        ...recentScans
            .take(3)
            .map(
              (scan) => Padding(
                padding: EdgeInsets.only(bottom: 8 * uiScale),
                child: _RecentScanTile(
                  uiScale: uiScale,
                  scan: scan,
                  colors: colors,
                ),
              ),
            )
            .toList(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Recent Scan Tile
// ---------------------------------------------------------------------------
class _RecentScanTile extends StatelessWidget {
  const _RecentScanTile({
    required this.uiScale,
    required this.scan,
    required this.colors,
  });

  final double uiScale;
  final ScanHistoryItem scan;
  final DietCompassThemeColors colors;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(
        children: [
          // Product image or placeholder
          if (scan.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                scan.imageUrl,
                width: 50 * uiScale,
                height: 50 * uiScale,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 50 * uiScale,
                    height: 50 * uiScale,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 20 * uiScale,
                      color: colors.textMuted,
                    ),
                  );
                },
              ),
            )
          else
            Container(
              width: 50 * uiScale,
              height: 50 * uiScale,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 24 * uiScale,
                color: colors.textMuted,
              ),
            ),

          SizedBox(width: 12 * uiScale),

          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scan.productName,
                  style: TextStyle(
                    fontSize: 12.5 * uiScale,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (scan.brand.isNotEmpty)
                  Text(
                    scan.brand,
                    style: TextStyle(
                      fontSize: 10 * uiScale,
                      color: colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                SizedBox(height: 2 * uiScale),
                Text(
                  _formatDate(scan.scannedAt),
                  style: TextStyle(
                    fontSize: 9 * uiScale,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 12 * uiScale),

          // Compatibility score
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8 * uiScale,
              vertical: 6 * uiScale,
            ),
            decoration: BoxDecoration(
              color: scan.score >= 75
                  ? const Color(0xFFE4F5E9)
                  : scan.score >= 60
                  ? const Color(0xFFFFF3E0)
                  : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${scan.score}/100',
              style: TextStyle(
                fontSize: 11 * uiScale,
                fontWeight: FontWeight.w700,
                color: scan.score >= 75
                    ? const Color(0xFF1E8A4C)
                    : scan.score >= 60
                    ? const Color(0xFFE0862E)
                    : const Color(0xFFE0525C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent Scans Skeleton Loader
// ---------------------------------------------------------------------------
class _RecentScansSkeletonLoader extends StatelessWidget {
  const _RecentScansSkeletonLoader({required this.uiScale});
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Scans',
          style: TextStyle(
            fontSize: 15.5 * uiScale,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: 10 * uiScale),
        ...List.generate(
          2,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: 8 * uiScale),
            child: _GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 50 * uiScale,
                    height: 50 * uiScale,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  SizedBox(width: 12 * uiScale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100 * uiScale,
                          height: 8 * uiScale,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(height: 6 * uiScale),
                        Container(
                          width: 60 * uiScale,
                          height: 7 * uiScale,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(4),
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
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Compatibility Overview Section (Real distribution)
// ---------------------------------------------------------------------------
class _CompatibilityOverviewSection extends StatelessWidget {
  const _CompatibilityOverviewSection({
    required this.uiScale,
    required this.healthCompass,
  });

  final double uiScale;
  final HealthCompassData healthCompass;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;

    // Calculate distribution from the scans
    // This is REAL data - percentage of products in each compatibility tier
    final total = healthCompass.productsAnalyzed;
    if (total == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compatibility Distribution',
          style: TextStyle(
            fontSize: 15.5 * uiScale,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: 10 * uiScale),

        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your analyzed products',
                style: TextStyle(
                  fontSize: 12 * uiScale,
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(height: 12 * uiScale),

              // Legend
              _DistributionLegend(
                uiScale: uiScale,
                label: 'Excellent (90-100)',
                color: const Color(0xFF1E8A4C),
                colors: colors,
              ),
              SizedBox(height: 8 * uiScale),
              _DistributionLegend(
                uiScale: uiScale,
                label: 'Good (75-89)',
                color: const Color(0xFF1E8A4C),
                colors: colors,
              ),
              SizedBox(height: 8 * uiScale),
              _DistributionLegend(
                uiScale: uiScale,
                label: 'Fair (60-74)',
                color: const Color(0xFFE0862E),
                colors: colors,
              ),
              SizedBox(height: 8 * uiScale),
              _DistributionLegend(
                uiScale: uiScale,
                label: 'Needs Attention (<60)',
                color: const Color(0xFFE0525C),
                colors: colors,
              ),

              SizedBox(height: 12 * uiScale),
              Text(
                'Based on real scanned products',
                style: TextStyle(
                  fontSize: 10 * uiScale,
                  color: colors.textMuted,
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
// Distribution Legend Item
// ---------------------------------------------------------------------------
class _DistributionLegend extends StatelessWidget {
  const _DistributionLegend({
    required this.uiScale,
    required this.label,
    required this.color,
    required this.colors,
  });

  final double uiScale;
  final String label;
  final Color color;
  final DietCompassThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12 * uiScale,
          height: 12 * uiScale,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: 8 * uiScale),
        Text(
          label,
          style: TextStyle(
            fontSize: 11 * uiScale,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Goals Section
// ---------------------------------------------------------------------------
class _GoalsSection extends StatelessWidget {
  const _GoalsSection({
    required this.uiScale,
    this.userProfile,
    this.onEditGoalsTap,
  });

  final double uiScale;
  final UserProfile? userProfile;
  final VoidCallback? onEditGoalsTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Your Goals',
                style: TextStyle(
                  fontSize: 13.5 * uiScale,
                  fontWeight: FontWeight.w800,
                  color: colors.iconPurple,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onEditGoalsTap,
                child: Row(
                  children: [
                    Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 11 * uiScale,
                        fontWeight: FontWeight.w700,
                        color: colors.iconPurple,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 14 * uiScale,
                      color: colors.iconPurple,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * uiScale),

          if (userProfile != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show actual user goals from profile
                _GoalBadge(
                  uiScale: uiScale,
                  icon: Icons.restaurant_outlined,
                  label: 'Diet Type',
                  value: userProfile!.dietType,
                  colors: colors,
                ),
                SizedBox(height: 8 * uiScale),

                if (userProfile!.height.isNotEmpty ||
                    userProfile!.weight.isNotEmpty)
                  Column(
                    children: [
                      _GoalBadge(
                        uiScale: uiScale,
                        icon: Icons.height,
                        label: 'Height',
                        value: userProfile!.height.isNotEmpty
                            ? userProfile!.height
                            : 'Not set',
                        colors: colors,
                      ),
                      SizedBox(height: 8 * uiScale),
                    ],
                  ),

                if (userProfile!.weight.isNotEmpty)
                  Column(
                    children: [
                      _GoalBadge(
                        uiScale: uiScale,
                        icon: Icons.scale,
                        label: 'Weight',
                        value: userProfile!.weight,
                        colors: colors,
                      ),
                      SizedBox(height: 8 * uiScale),
                    ],
                  ),

                Text(
                  'Set measurable health targets to track progress.',
                  style: TextStyle(
                    fontSize: 10 * uiScale,
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.flag_outlined,
                  size: 32 * uiScale,
                  color: colors.textMuted,
                ),
                SizedBox(height: 12 * uiScale),
                Text(
                  'No profile data yet',
                  style: TextStyle(
                    fontSize: 12.5 * uiScale,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: 6 * uiScale),
                Text(
                  'Complete your profile to set health-related goals.',
                  style: TextStyle(
                    fontSize: 10 * uiScale,
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Goal Badge
// ---------------------------------------------------------------------------
class _GoalBadge extends StatelessWidget {
  const _GoalBadge({
    required this.uiScale,
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
  });

  final double uiScale;
  final IconData icon;
  final String label;
  final String value;
  final DietCompassThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16 * uiScale, color: colors.iconPurple),
        SizedBox(width: 8 * uiScale),
        Text(
          label,
          style: TextStyle(
            fontSize: 11 * uiScale,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 11 * uiScale,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom nav bar
// ---------------------------------------------------------------------------
class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.uiScale,
    required this.selectedIndex,
    required this.onTap,
  });
  final double uiScale;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.qr_code_scanner_rounded, label: 'Scan'),
    (icon: Icons.smart_toy_rounded, label: 'AI'),
    (icon: Icons.kitchen_rounded, label: 'Pantry'),
    (icon: Icons.pie_chart_rounded, label: 'Dashboard'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.fromLTRB(
          10 * uiScale,
          0,
          10 * uiScale,
          10 * uiScale,
        ),
        padding: EdgeInsets.symmetric(vertical: 8 * uiScale),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: colors.isDark ? 0.25 : 0.08,
              ),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final selected = i == selectedIndex;
            final item = _items[i];
            return GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(
                  horizontal: selected ? 10 * uiScale : 6 * uiScale,
                  vertical: 6 * uiScale,
                ),
                decoration: BoxDecoration(
                  color: selected ? colors.iconPurpleBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 18 * uiScale,
                      color: selected ? colors.iconPurple : colors.textMuted,
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: selected
                          ? Padding(
                              padding: EdgeInsets.only(top: 2 * uiScale),
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 8.5 * uiScale,
                                  fontWeight: FontWeight.w700,
                                  color: colors.iconPurple,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
