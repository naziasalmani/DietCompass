import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:diet_compass/core/theme/app_colors.dart';
import '../../core/services/personalization_service.dart';

/// DietCompass — Health Profile Screen
/// -----------------------------------------------------------------------
/// No new image assets needed. Avatar follows the same pattern as the
/// Personal Information screen — pass [avatarImage] once you have a real
/// photo; it falls back to an initials circle until then.
///
/// Health Goals and Dietary Preferences are real, tappable multi-select
/// chip rows with their own internal state (and `onChanged` callbacks so
/// you can persist selections to a backend). Medical/Lifestyle/Health
/// Metrics tiles are data-driven lists, not hardcoded.
class GoalOption {
  const GoalOption({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;
}

class DietOption {
  const DietOption({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;
}

class InfoTile {
  const InfoTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;
}

class MetricTile {
  const MetricTile({
    this.icon,
    required this.label,
    required this.value,
    this.status,
    this.statusColor,
  });
  final IconData? icon;
  final String label;
  final String value;
  final String? status;
  final Color? statusColor;
}

class HealthProfileScreen extends StatefulWidget {
  const HealthProfileScreen({
    super.key,
    this.avatarImage,
    this.fullName = 'Nazia Shaikh',
    this.badgeLabel = 'Healthy Explorer',
    this.dateOfBirth = '15 May 2005 (19 yrs)',
    this.gender = 'Female',
    this.height = '165 cm',
    this.weight = '58 kg',
    this.profileCompleteness = 78,
    this.goalOptions = const [
      GoalOption(
        icon: Icons.card_travel,
        label: 'Weight Loss',
        color: Color(0xFF6C4EF5),
      ),
      GoalOption(
        icon: Icons.fitness_center,
        label: 'Muscle Gain',
        color: Color(0xFF1E8A4C),
      ),
      GoalOption(
        icon: Icons.bolt,
        label: 'Improve Energy',
        color: Color(0xFFE0862E),
      ),
      GoalOption(
        icon: Icons.nightlight_round,
        label: 'Better Sleep',
        color: Color(0xFF6C4EF5),
      ),
      GoalOption(
        icon: Icons.sentiment_satisfied_outlined,
        label: 'Other',
        color: Color(0xFFE0525C),
      ),
    ],
    this.selectedGoals = const {0},
    this.goalSummary = 'Your Goal: Lose 4-5 kg in the next 3 months',
    this.dietOptions = const [
      DietOption(
        icon: Icons.eco,
        label: 'Vegetarian',
        color: Color(0xFF1E8A4C),
      ),
      DietOption(
        icon: Icons.egg_outlined,
        label: 'No Eggs',
        color: Color(0xFF1B1B2E),
      ),
      DietOption(
        icon: Icons.set_meal_outlined,
        label: 'No Seafood',
        color: Color(0xFF1B1B2E),
      ),
      DietOption(
        icon: Icons.lunch_dining_outlined,
        label: 'No Beef',
        color: Color(0xFF1B1B2E),
      ),
    ],
    this.selectedDiets = const {0},
    this.allergiesSummary = 'Allergies: None',
    this.medicalTiles = const [
      InfoTile(
        icon: Icons.masks_outlined,
        iconBg: Color(0xFFEDE7FA),
        iconColor: Color(0xFF6C4EF5),
        label: 'Allergies',
        value: 'None',
      ),
      InfoTile(
        icon: Icons.extension_outlined,
        iconBg: Color(0xFFE4F5E9),
        iconColor: Color(0xFF1E8A4C),
        label: 'Chronic Conditions',
        value: 'None',
      ),
      InfoTile(
        icon: Icons.medication_outlined,
        iconBg: Color(0xFFFCF2E0),
        iconColor: Color(0xFFE0862E),
        label: 'Medications',
        value: 'None',
      ),
    ],
    this.emergencyContactAdded = true,
    this.lifestyleTiles = const [
      InfoTile(
        icon: Icons.directions_walk,
        iconBg: Color(0xFFE3EEFC),
        iconColor: Color(0xFF3B82F6),
        label: 'Activity Level',
        value: 'Moderate',
      ),
      InfoTile(
        icon: Icons.nightlight_round,
        iconBg: Color(0xFFEDE7FA),
        iconColor: Color(0xFF6C4EF5),
        label: 'Sleep',
        value: '7-8 hours',
      ),
      InfoTile(
        icon: Icons.water_drop_outlined,
        iconBg: Color(0xFFE3EEFC),
        iconColor: Color(0xFF3B82F6),
        label: 'Water Intake',
        value: '6-8 glasses',
      ),
      InfoTile(
        icon: Icons.smoke_free,
        iconBg: Color(0xFFFCEBEB),
        iconColor: Color(0xFFE0525C),
        label: 'Smoking',
        value: 'No',
      ),
    ],
    this.healthMetrics = const [
      MetricTile(
        label: 'BMI',
        value: '21.3',
        status: 'Normal',
        statusColor: Color(0xFF1E8A4C),
      ),
      MetricTile(
        icon: Icons.water_drop_outlined,
        label: 'Blood Group',
        value: 'B+',
      ),
      MetricTile(
        icon: Icons.favorite_border,
        label: 'Blood Pressure',
        value: '110/70',
        status: 'Normal',
        statusColor: Color(0xFF1E8A4C),
      ),
      MetricTile(
        icon: Icons.monitor_heart_outlined,
        label: 'Heart Rate',
        value: '72 bpm',
        status: 'Normal',
        statusColor: Color(0xFF1E8A4C),
      ),
    ],
    this.tip = 'Tip: Keep your profile updated to get better recommendations.',
    this.onBack,
    this.onSaveChanges,
    this.onAvatarTap,
    this.onUpdateNowTap,
    this.onGoalsChanged,
    this.onGoalSummaryTap,
    this.onEditGoals,
    this.onDietsChanged,
    this.onAddMoreDiet,
    this.onAllergiesTap,
    this.onEditDiet,
    this.onEditMedical,
    this.onEmergencyContactTap,
    this.onEditLifestyle,
    this.onEditMetrics,
    this.onNavTap,
    this.initialNavIndex = 4,
  });

  final ImageProvider? avatarImage;
  final String fullName;
  final String badgeLabel;
  final String dateOfBirth;
  final String gender;
  final String height;
  final String weight;
  final int profileCompleteness;

  final List<GoalOption> goalOptions;
  final Set<int> selectedGoals;
  final String goalSummary;

  final List<DietOption> dietOptions;
  final Set<int> selectedDiets;
  final String allergiesSummary;

  final List<InfoTile> medicalTiles;
  final bool emergencyContactAdded;
  final List<InfoTile> lifestyleTiles;
  final List<MetricTile> healthMetrics;
  final String tip;

  final VoidCallback? onBack;
  final VoidCallback? onSaveChanges;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onUpdateNowTap;
  final ValueChanged<Set<int>>? onGoalsChanged;
  final VoidCallback? onGoalSummaryTap;
  final VoidCallback? onEditGoals;
  final ValueChanged<Set<int>>? onDietsChanged;
  final VoidCallback? onAddMoreDiet;
  final VoidCallback? onAllergiesTap;
  final VoidCallback? onEditDiet;
  final VoidCallback? onEditMedical;
  final VoidCallback? onEmergencyContactTap;
  final VoidCallback? onEditLifestyle;
  final VoidCallback? onEditMetrics;
  final ValueChanged<int>? onNavTap;
  final int initialNavIndex;

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late Set<int> _selectedGoals;

  @override
  void initState() {
    super.initState();
    _selectedGoals = {...widget.selectedGoals};
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    _loadCloudPersonalization();
  }

  void _loadCloudPersonalization() {
    final pers = PersonalizationService.instance.currentPersonalization;
    if (pers != null) {
      final newGoals = <int>{};
      for (int i = 0; i < widget.goalOptions.length; i++) {
        if (pers.goals.contains(widget.goalOptions[i].label)) {
          newGoals.add(i);
        }
      }
      if (mounted) {
        setState(() {
          if (newGoals.isNotEmpty) _selectedGoals = newGoals;
        });
      }
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
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

  void _toggleGoal(int i) {
    setState(() {
      _selectedGoals.contains(i)
          ? _selectedGoals.remove(i)
          : _selectedGoals.add(i);
    });
    widget.onGoalsChanged?.call(_selectedGoals);
    _syncGoals();
  }

  Future<void> _syncGoals() async {
    final goals = _selectedGoals
        .map((i) => widget.goalOptions[i].label)
        .toList();
    try {
      await PersonalizationService.instance.updatePersonalization({
        'goals': goals,
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 390).clamp(0.85, 1.25);

    final colors = context.dcColors;
    return Scaffold(
      backgroundColor: colors.bg,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            18 * scale,
            8 * scale,
            18 * scale,
            28 * scale,
          ),
          physics: const BouncingScrollPhysics(),
          children: [
            FadeTransition(
              opacity: _fade(0.0, 0.25),
              child: _TopBar(
                uiScale: scale,
                onBack: widget.onBack,
                onSaveChanges: widget.onSaveChanges,
              ),
            ),
            SizedBox(height: 16 * scale),

            FadeTransition(
              opacity: _fade(0.04, 0.36),
              child: SlideTransition(
                position: _slide(0.04, 0.38),
                child: _ProfileCard(
                  uiScale: scale,
                  entranceCtrl: _entranceCtrl,
                  avatarImage: widget.avatarImage,
                  fullName: widget.fullName,
                  badgeLabel: widget.badgeLabel,
                  dateOfBirth: widget.dateOfBirth,
                  gender: widget.gender,
                  height: widget.height,
                  weight: widget.weight,
                  completeness: widget.profileCompleteness,
                  onAvatarTap: widget.onAvatarTap,
                  onUpdateNowTap: widget.onUpdateNowTap,
                ),
              ),
            ),
            SizedBox(height: 18 * scale),

            FadeTransition(
              opacity: _fade(0.1, 0.42),
              child: SlideTransition(
                position: _slide(0.1, 0.44),
                child: _SectionCard(
                  uiScale: scale,
                  icon: Icons.track_changes_rounded,
                  iconBg: const Color(0xFFEDE7FA),
                  iconColor: const Color(0xFF6C4EF5),
                  title: 'Health Goals',
                  subtitle: 'What do you want to achieve?',
                  onEdit: widget.onEditGoals,
                  child: Column(
                    children: [
                      _ChipsWrap(
                        uiScale: scale,
                        children: List.generate(widget.goalOptions.length, (i) {
                          final g = widget.goalOptions[i];
                          return _SelectableChip(
                            uiScale: scale,
                            icon: g.icon,
                            label: g.label,
                            color: g.color,
                            selected: _selectedGoals.contains(i),
                            onTap: () => _toggleGoal(i),
                          );
                        }),
                      ),
                      SizedBox(height: 10 * scale),
                      _HighlightRow(
                        uiScale: scale,
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFF6C4EF5),
                        bg: const Color(0xFFF1ECFB),
                        text: widget.goalSummary,
                        onTap: widget.onGoalSummaryTap,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16 * scale),

            FadeTransition(
              opacity: _fade(0.22, 0.54),
              child: SlideTransition(
                position: _slide(0.22, 0.56),
                child: _SectionCard(
                  uiScale: scale,
                  icon: Icons.favorite_border,
                  iconBg: const Color(0xFFFCEBEB),
                  iconColor: const Color(0xFFE0525C),
                  title: 'Medical Information',
                  subtitle: 'Important health details',
                  onEdit: widget.onEditMedical,
                  child: Column(
                    children: [
                      _InfoTilesRow(uiScale: scale, tiles: widget.medicalTiles),
                      SizedBox(height: 10 * scale),
                      if (widget.emergencyContactAdded)
                        _AlertRow(
                          uiScale: scale,
                          icon: Icons.shield_outlined,
                          title: 'Emergency Contact Added',
                          subtitle: 'Family contact available for emergencies',
                          actionLabel: 'View / Edit',
                          onTap: widget.onEmergencyContactTap,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16 * scale),

            FadeTransition(
              opacity: _fade(0.28, 0.6),
              child: SlideTransition(
                position: _slide(0.28, 0.62),
                child: _SectionCard(
                  uiScale: scale,
                  icon: Icons.directions_run_rounded,
                  iconBg: const Color(0xFFE3EEFC),
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Lifestyle Information',
                  subtitle: 'Your daily habits and activity',
                  onEdit: widget.onEditLifestyle,
                  child: _InfoTilesRow(
                    uiScale: scale,
                    tiles: widget.lifestyleTiles,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16 * scale),

            FadeTransition(
              opacity: _fade(0.34, 0.68),
              child: SlideTransition(
                position: _slide(0.34, 0.7),
                child: _SectionCard(
                  uiScale: scale,
                  icon: Icons.monitor_heart_outlined,
                  iconBg: const Color(0xFFEDE7FA),
                  iconColor: const Color(0xFF6C4EF5),
                  title: 'Health Metrics',
                  subtitle: 'Track your key health numbers',
                  onEdit: widget.onEditMetrics,
                  child: _MetricsRow(
                    uiScale: scale,
                    metrics: widget.healthMetrics,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16 * scale),

            FadeTransition(
              opacity: _fade(0.42, 0.75),
              child: _TipBanner(uiScale: scale, text: widget.tip),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------
class _TopBar extends StatelessWidget {
  const _TopBar({required this.uiScale, this.onBack, this.onSaveChanges});
  final double uiScale;
  final VoidCallback? onBack;
  final VoidCallback? onSaveChanges;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RoundButton(
          uiScale: uiScale,
          icon: Icons.arrow_back,
          onTap: onBack ?? () => Navigator.of(context).pop(),
        ),
        SizedBox(width: 12 * uiScale),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 4 * uiScale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health Profile',
                  style: TextStyle(
                    fontSize: 21 * uiScale,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1B1B2E),
                  ),
                ),
                SizedBox(height: 3 * uiScale),
                Text(
                  'Manage your health information to get personalized recommendations.',
                  style: TextStyle(
                    fontSize: 11 * uiScale,
                    height: 1.35,
                    color: const Color(0xFF6B6B7B),
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

class _RoundButton extends StatefulWidget {
  const _RoundButton({required this.uiScale, required this.icon, this.onTap});
  final double uiScale;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  State<_RoundButton> createState() => _RoundButtonState();
}

class _RoundButtonState extends State<_RoundButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.9),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 42 * widget.uiScale,
          height: 42 * widget.uiScale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.dcColors.surface,
            border: Border.all(color: context.dcColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: context.dcColors.isDark ? 0.2 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            size: 19 * widget.uiScale,
            color: context.dcColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile card with completeness ring
// ---------------------------------------------------------------------------
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.uiScale,
    required this.entranceCtrl,
    required this.avatarImage,
    required this.fullName,
    required this.badgeLabel,
    required this.dateOfBirth,
    required this.gender,
    required this.height,
    required this.weight,
    required this.completeness,
    this.onAvatarTap,
    this.onUpdateNowTap,
  });

  final double uiScale;
  final AnimationController entranceCtrl;
  final ImageProvider? avatarImage;
  final String fullName;
  final String badgeLabel;
  final String dateOfBirth;
  final String gender;
  final String height;
  final String weight;
  final int completeness;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onUpdateNowTap;

  @override
  Widget build(BuildContext context) {
    final gaugeAnim = CurvedAnimation(
      parent: entranceCtrl,
      curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic),
    );

    return Container(
      padding: EdgeInsets.all(16 * uiScale),
      decoration: BoxDecoration(
        color: context.dcColors.isDark ? const Color(0xFF252236) : const Color(0xFFF1ECFB),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.dcColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 72 * uiScale,
                height: 72 * uiScale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C4EF5), Color(0xFF1E8A4C)],
                  ),
                  image: avatarImage != null
                      ? DecorationImage(image: avatarImage!, fit: BoxFit.cover)
                      : null,
                ),
                child: avatarImage == null
                    ? Center(
                        child: Text(
                          fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 24 * uiScale,
                          ),
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: _CameraButton(uiScale: uiScale, onTap: onAvatarTap),
              ),
            ],
          ),
          SizedBox(width: 14 * uiScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: TextStyle(
                    fontSize: 17 * uiScale,
                    fontWeight: FontWeight.w800,
                    color: context.dcColors.textPrimary,
                  ),
                ),
                SizedBox(height: 5 * uiScale),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8 * uiScale,
                    vertical: 3 * uiScale,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.eco,
                        size: 11 * uiScale,
                        color: const Color(0xFF1E8A4C),
                      ),
                      SizedBox(width: 4 * uiScale),
                      Text(
                        badgeLabel,
                        style: TextStyle(
                          fontSize: 10 * uiScale,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E8A4C),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8 * uiScale),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 11 * uiScale,
                      color: const Color(0xFF9A96A8),
                    ),
                    SizedBox(width: 4 * uiScale),
                    Text(
                      dateOfBirth,
                      style: TextStyle(
                        fontSize: 10.5 * uiScale,
                        color: context.dcColors.textSecondary,
                      ),
                    ),
                    Text(
                      '  •  ',
                      style: TextStyle(
                        fontSize: 10.5 * uiScale,
                        color: context.dcColors.textMuted,
                      ),
                    ),
                    Icon(
                      Icons.person_outline,
                      size: 11 * uiScale,
                      color: context.dcColors.textMuted,
                    ),
                    SizedBox(width: 4 * uiScale),
                    Text(
                      gender,
                      style: TextStyle(
                        fontSize: 10.5 * uiScale,
                        color: context.dcColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4 * uiScale),
                Row(
                  children: [
                    Icon(
                      Icons.straighten,
                      size: 11 * uiScale,
                      color: context.dcColors.textMuted,
                    ),
                    SizedBox(width: 4 * uiScale),
                    Text(
                      height,
                      style: TextStyle(
                        fontSize: 10.5 * uiScale,
                        color: context.dcColors.textSecondary,
                      ),
                    ),
                    Text(
                      '  •  ',
                      style: TextStyle(
                        fontSize: 10.5 * uiScale,
                        color: context.dcColors.textMuted,
                      ),
                    ),
                    Icon(
                      Icons.monitor_weight_outlined,
                      size: 11 * uiScale,
                      color: context.dcColors.textMuted,
                    ),
                    SizedBox(width: 4 * uiScale),
                    Text(
                      weight,
                      style: TextStyle(
                        fontSize: 10.5 * uiScale,
                        color: context.dcColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              SizedBox(
                width: 72 * uiScale,
                height: 44 * uiScale,
                child: AnimatedBuilder(
                  animation: gaugeAnim,
                  builder: (context, _) {
                    final v = (completeness * gaugeAnim.value).round();
                    return CustomPaint(
                      painter: _HalfGaugePainter(
                        progress: gaugeAnim.value * (completeness / 100),
                      ),
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 10 * uiScale),
                          child: Text(
                            '$v%',
                            style: TextStyle(
                              fontSize: 16 * uiScale,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E8A4C),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Text(
                'Profile',
                style: TextStyle(
                  fontSize: 9.5 * uiScale,
                  color: context.dcColors.textSecondary,
                ),
              ),
              Text(
                'Completeness',
                style: TextStyle(
                  fontSize: 9.5 * uiScale,
                  color: context.dcColors.textSecondary,
                ),
              ),
              SizedBox(height: 3 * uiScale),
              GestureDetector(
                onTap: onUpdateNowTap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Update Now',
                      style: TextStyle(
                        fontSize: 10 * uiScale,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6C4EF5),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      size: 11 * uiScale,
                      color: const Color(0xFF6C4EF5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HalfGaugePainter extends CustomPainter {
  _HalfGaugePainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 6;
    final bg = Paint()
      ..color = const Color(0xFFDCE9E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bg,
    );

    final fg = Paint()
      ..color = const Color(0xFF1E8A4C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi * progress,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _HalfGaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _CameraButton extends StatefulWidget {
  const _CameraButton({required this.uiScale, this.onTap});
  final double uiScale;
  final VoidCallback? onTap;

  @override
  State<_CameraButton> createState() => _CameraButtonState();
}

class _CameraButtonState extends State<_CameraButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.9),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 26 * widget.uiScale,
          height: 26 * widget.uiScale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.dcColors.surface,
            border: Border.all(color: context.dcColors.cardBorder, width: 2.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.camera_alt,
            size: 12 * widget.uiScale,
            color: context.dcColors.iconPurple,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared section card
// ---------------------------------------------------------------------------
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.uiScale,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onEdit,
  });

  final double uiScale;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14 * uiScale),
      decoration: BoxDecoration(
        color: context.dcColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.dcColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.dcColors.isDark ? 0.2 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34 * uiScale,
                height: 34 * uiScale,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16 * uiScale, color: iconColor),
              ),
              SizedBox(width: 10 * uiScale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5 * uiScale,
                        fontWeight: FontWeight.w800,
                        color: context.dcColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10.5 * uiScale,
                        color: context.dcColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Row(
                  children: [
                    Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 12 * uiScale,
                        fontWeight: FontWeight.w700,
                        color: context.dcColors.iconPurple,
                      ),
                    ),
                    SizedBox(width: 3 * uiScale),
                    Icon(
                      Icons.edit_outlined,
                      size: 13 * uiScale,
                      color: context.dcColors.iconPurple,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * uiScale),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Selectable chips
// ---------------------------------------------------------------------------
class _ChipsWrap extends StatelessWidget {
  const _ChipsWrap({required this.uiScale, required this.children});
  final double uiScale;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8 * uiScale,
      runSpacing: 8 * uiScale,
      children: children,
    );
  }
}

class _SelectableChip extends StatefulWidget {
  const _SelectableChip({
    required this.uiScale,
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final double uiScale;
  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SelectableChip> createState() => _SelectableChipState();
}

class _SelectableChipState extends State<_SelectableChip> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: 12 * widget.uiScale,
            vertical: 9 * widget.uiScale,
          ),
          decoration: BoxDecoration(
            color: widget.selected
                ? widget.color.withValues(alpha: context.dcColors.isDark ? 0.2 : 0.1)
                : context.dcColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.selected ? widget.color : context.dcColors.cardBorder,
              width: widget.selected ? 1.6 : 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 14 * widget.uiScale,
                color: widget.selected ? widget.color : context.dcColors.textMuted,
              ),
              SizedBox(width: 6 * widget.uiScale),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11.5 * widget.uiScale,
                  fontWeight: FontWeight.w700,
                  color: widget.selected
                      ? widget.color
                      : context.dcColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddMoreChip extends StatefulWidget {
  const _AddMoreChip({required this.uiScale, this.onTap});
  final double uiScale;
  final VoidCallback? onTap;

  @override
  State<_AddMoreChip> createState() => _AddMoreChipState();
}

class _AddMoreChipState extends State<_AddMoreChip> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12 * widget.uiScale,
            vertical: 9 * widget.uiScale,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF1ECFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFCBB8F5), width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add,
                size: 14 * widget.uiScale,
                color: const Color(0xFF6C4EF5),
              ),
              SizedBox(width: 4 * widget.uiScale),
              Text(
                'Add More',
                style: TextStyle(
                  fontSize: 11.5 * widget.uiScale,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6C4EF5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Highlight row (goal summary / allergies summary)
// ---------------------------------------------------------------------------
class _HighlightRow extends StatelessWidget {
  const _HighlightRow({
    required this.uiScale,
    required this.icon,
    required this.iconColor,
    required this.bg,
    required this.text,
    this.onTap,
  });
  final double uiScale;
  final IconData icon;
  final Color iconColor;
  final Color bg;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12 * uiScale,
          vertical: 12 * uiScale,
        ),
        decoration: BoxDecoration(
          color: context.dcColors.isDark ? const Color(0xFF2B264A) : bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.dcColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15 * uiScale, color: iconColor),
            SizedBox(width: 8 * uiScale),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 11.5 * uiScale,
                  fontWeight: FontWeight.w600,
                  color: context.dcColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 16 * uiScale,
              color: context.dcColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info tiles row (Medical / Lifestyle)
// ---------------------------------------------------------------------------
class _InfoTilesRow extends StatelessWidget {
  const _InfoTilesRow({required this.uiScale, required this.tiles});
  final double uiScale;
  final List<InfoTile> tiles;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(tiles.length, (i) {
        final t = tiles[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: i == tiles.length - 1 ? 0 : 8 * uiScale,
            ),
            child: Container(
              padding: EdgeInsets.all(10 * uiScale),
              decoration: BoxDecoration(
                color: context.dcColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.dcColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28 * uiScale,
                    height: 28 * uiScale,
                    decoration: BoxDecoration(
                      color: t.iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(t.icon, size: 13 * uiScale, color: t.iconColor),
                  ),
                  SizedBox(height: 6 * uiScale),
                  Text(
                    t.label,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 9.5 * uiScale,
                      color: context.dcColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 2 * uiScale),
                  Text(
                    t.value,
                    style: TextStyle(
                      fontSize: 12 * uiScale,
                      fontWeight: FontWeight.w800,
                      color: t.valueColor ?? context.dcColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Alert row (Emergency Contact)
// ---------------------------------------------------------------------------
class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.uiScale,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    this.onTap,
  });

  final double uiScale;
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12 * uiScale),
        decoration: BoxDecoration(
          color: context.dcColors.isDark ? const Color(0xFF331C1F) : const Color(0xFFFCEBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.dcColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16 * uiScale, color: context.dcColors.iconRed),
            SizedBox(width: 8 * uiScale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11.5 * uiScale,
                      fontWeight: FontWeight.w700,
                      color: context.dcColors.iconRed,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10 * uiScale,
                      color: context.dcColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel,
                  style: TextStyle(
                    fontSize: 10.5 * uiScale,
                    fontWeight: FontWeight.w700,
                    color: context.dcColors.iconRed,
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  size: 12 * uiScale,
                  color: context.dcColors.iconRed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Health metrics row
// ---------------------------------------------------------------------------
class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.uiScale, required this.metrics});
  final double uiScale;
  final List<MetricTile> metrics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(metrics.length, (i) {
        final m = metrics[i];
        return Expanded(
          child: Column(
            children: [
              if (m.icon != null) ...[
                Icon(
                  m.icon,
                  size: 15 * uiScale,
                  color: const Color(0xFF6C4EF5),
                ),
                SizedBox(height: 4 * uiScale),
              ],
              Text(
                m.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10 * uiScale,
                  color: context.dcColors.textSecondary,
                ),
              ),
              SizedBox(height: 3 * uiScale),
              Text(
                m.value,
                style: TextStyle(
                  fontSize: 15 * uiScale,
                  fontWeight: FontWeight.w800,
                  color: context.dcColors.textPrimary,
                ),
              ),
              if (m.status != null) ...[
                SizedBox(height: 2 * uiScale),
                Text(
                  m.status!,
                  style: TextStyle(
                    fontSize: 9.5 * uiScale,
                    fontWeight: FontWeight.w700,
                    color: m.statusColor ?? const Color(0xFF6B6B7B),
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Tip banner
// ---------------------------------------------------------------------------
class _TipBanner extends StatelessWidget {
  const _TipBanner({required this.uiScale, required this.text});
  final double uiScale;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14 * uiScale,
        vertical: 12 * uiScale,
      ),
      decoration: BoxDecoration(
        color: context.dcColors.isDark ? const Color(0xFF192A3E) : const Color(0xFFE3EEFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dcColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 16 * uiScale,
            color: context.dcColors.iconBlue,
          ),
          SizedBox(width: 8 * uiScale),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11 * uiScale,
                fontWeight: FontWeight.w600,
                color: context.dcColors.isDark ? const Color(0xFF93C5FD) : const Color(0xFF1B4D8F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
