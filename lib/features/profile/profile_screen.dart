import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import 'saved_recipes_screen.dart';
import 'personal_info_screen.dart';
import 'health_profile_screen.dart';

/// DietCompass — My Profile Screen
/// -----------------------------------------------------------------------
/// Matches the visual language of ScanScreen / ManualEntryScreen:
/// lavender background (0xFFF3F0FB), purple → green brand gradient
/// (0xFF6C4EF5 → 0xFF1E8A4C), frosted glassmorphism cards, staggered
/// entrance choreography and small delightful micro-animations
/// (progress fill, count-up health score, pulsing bell badge, breathing
/// avatar glow, press-scale on every tappable row).
///
/// No custom image assets are required — all icons use Material icons so
/// this file drops in as-is. Swap `_Avatar`'s initials/gradient for a
/// real photo whenever you wire up real user data.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.name = 'Nazia Salmani',
    this.email = 'nazia.salmani@example.com',
    this.phone = '+91 98765 43210',
    this.avatarInitial = 'N',
    this.badgeLabel = 'Healthy Explorer',
    this.memberSince = 'May 2024',
    this.healthScore = 87,
    this.streakDays = 12,
    this.profileCompletion = 0.70,
    this.goal = 'Weight Loss',
    this.dietType = 'Vegetarian',
    this.height = '165 cm',
    this.weight = '58 kg',
    this.appVersion = '1.0.0',
    this.onNotificationsTap,
    this.onSettingsTap,
    this.onEditAvatarTap,
    this.onCompleteNowTap,
    this.onViewHealthDetailsTap,
    this.onGoalTap,
    this.onDietTypeTap,
    this.onHeightTap,
    this.onWeightTap,
    this.onPersonalInfoTap,
    this.onHealthProfileTap,
    this.onDietaryPreferencesTap,
    this.onActivityLevelTap,
    this.onNotificationSettingsTap,
    this.onPrivacyTap,
    this.onHelpSupportTap,
    this.onAboutTap,
  });

  final String name;
  final String email;
  final String phone;
  final String avatarInitial;
  final String badgeLabel;
  final String memberSince;
  final int healthScore;
  final int streakDays;
  final double profileCompletion;
  final String goal;
  final String dietType;
  final String height;
  final String weight;
  final String appVersion;

  final VoidCallback? onNotificationsTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onEditAvatarTap;
  final VoidCallback? onCompleteNowTap;
  final VoidCallback? onViewHealthDetailsTap;
  final VoidCallback? onGoalTap;
  final VoidCallback? onDietTypeTap;
  final VoidCallback? onHeightTap;
  final VoidCallback? onWeightTap;
  final VoidCallback? onPersonalInfoTap;
  final VoidCallback? onHealthProfileTap;
  final VoidCallback? onDietaryPreferencesTap;
  final VoidCallback? onActivityLevelTap;
  final VoidCallback? onNotificationSettingsTap;
  final VoidCallback? onPrivacyTap;
  final VoidCallback? onHelpSupportTap;
  final VoidCallback? onAboutTap;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _ambientCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
              padding: EdgeInsets.fromLTRB(
                18 * scale,
                8 * scale,
                18 * scale,
                28 * scale,
              ),
              physics: const BouncingScrollPhysics(),
              children: [
                FadeTransition(
                  opacity: _fade(0.0, 0.28),
                  child: SlideTransition(
                    position: _slide(0.0, 0.32),
                    child: _TopHeader(
                      uiScale: scale,
                      ambientCtrl: _ambientCtrl,
                      onNotificationsTap: widget.onNotificationsTap,
                      onSettingsTap: widget.onSettingsTap,
                    ),
                  ),
                ),
                SizedBox(height: 16 * scale),

                FadeTransition(
                  opacity: _fade(0.06, 0.4),
                  child: SlideTransition(
                    position: _slide(0.06, 0.44),
                    child: _GlassCard(
                      uiScale: scale,
                      child: _ProfileHeaderSection(
                        uiScale: scale,
                        ambientCtrl: _ambientCtrl,
                        entranceCtrl: _entranceCtrl,
                        name: widget.name,
                        email: widget.email,
                        phone: widget.phone,
                        avatarInitial: widget.avatarInitial,
                        badgeLabel: widget.badgeLabel,
                        memberSince: widget.memberSince,
                        healthScore: widget.healthScore,
                        streakDays: widget.streakDays,
                        onEditAvatarTap: widget.onEditAvatarTap,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16 * scale),

                FadeTransition(
                  opacity: _fade(0.16, 0.48),
                  child: SlideTransition(
                    position: _slide(0.16, 0.52),
                    child: _CompleteProfileBanner(
                      uiScale: scale,
                      entranceCtrl: _entranceCtrl,
                      completion: widget.profileCompletion,
                      onCompleteNowTap: widget.onCompleteNowTap,
                    ),
                  ),
                ),
                SizedBox(height: 22 * scale),

                FadeTransition(
                  opacity: _fade(0.22, 0.5),
                  child: SlideTransition(
                    position: _slide(0.22, 0.54),
                    child: _SectionHeaderRow(
                      uiScale: scale,
                      title: 'My Health Summary',
                      actionLabel: 'View Details',
                      onActionTap: widget.onViewHealthDetailsTap,
                    ),
                  ),
                ),
                SizedBox(height: 12 * scale),

                FadeTransition(
                  opacity: _fade(0.26, 0.56),
                  child: SlideTransition(
                    position: _slide(0.26, 0.6),
                    child: _GlassCard(
                      uiScale: scale,
                      padding: EdgeInsets.symmetric(
                        horizontal: 8 * scale,
                        vertical: 16 * scale,
                      ),
                      child: _HealthSummaryRow(
                        uiScale: scale,
                        goal: widget.goal,
                        dietType: widget.dietType,
                        height: widget.height,
                        weight: widget.weight,
                        onGoalTap: widget.onGoalTap,
                        onDietTypeTap: widget.onDietTypeTap,
                        onHeightTap: widget.onHeightTap,
                        onWeightTap: widget.onWeightTap,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 18 * scale),

                FadeTransition(
                  opacity: _fade(0.32, 0.62),
                  child: SlideTransition(
                    position: _slide(0.32, 0.66),
                    child: _GlassCard(
                      uiScale: scale,
                      padding: EdgeInsets.symmetric(vertical: 4 * scale),
                      child: Column(
                        children: [
                          _ProfileMenuTile(
                            uiScale: scale,
                            icon: Icons.person_outline_rounded,
                            iconBg: const Color(0xFFEDE7FA),
                            iconColor: const Color(0xFF6C4EF5),
                            title: 'Personal Information',
                            subtitle: 'Update your personal details',
                           onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const PersonalInfoScreen(),
    ),
  );
},
                          ),
                          const _TileDivider(),
                          _ProfileMenuTile(
                            uiScale: scale,
                            icon: Icons.favorite_rounded,
                            iconBg: const Color(0xFFE3F5EA),
                            iconColor: const Color(0xFF1E8A4C),
                            title: 'Health Profile',
                            subtitle: 'Manage your health preferences',
                            onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const HealthProfileScreen(),
    ),
  );
},
                          ),
                          const _TileDivider(),
                          _ProfileMenuTile(
                            uiScale: scale,
                            icon: Icons.restaurant_rounded,
                            iconBg: const Color(0xFFFCEEDD),
                            iconColor: const Color(0xFFE0862E),
                            title: 'Dietary Preferences',
                            subtitle: 'Manage allergies and food preferences',
                            onTap: widget.onDietaryPreferencesTap,
                          ),
                          const _TileDivider(),
                          _ProfileMenuTile(
                            uiScale: scale,
                            icon: Icons.directions_run_rounded,
                            iconBg: const Color(0xFFE3EEFC),
                            iconColor: const Color(0xFF3B82F6),
                            title: 'Activity Level',
                            subtitle: 'Set your daily activity level',
                            onTap: widget.onActivityLevelTap,
                          ),
                          const _TileDivider(),

_ProfileMenuTile(
  uiScale: scale,
  icon: Icons.bookmark_rounded,
  iconBg: const Color(0xFFEDE7FA),
  iconColor: const Color(0xFF6C4EF5),
  title: 'Saved Recipes',
  subtitle: 'View your bookmarked recipes',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SavedRecipesScreen(),
      ),
    );
  },
),
                          const _TileDivider(),
                          _ProfileMenuTile(
                            uiScale: scale,
                            icon: Icons.notifications_none_rounded,
                            iconBg: const Color(0xFFFCEAEA),
                            iconColor: const Color(0xFFE0475B),
                            title: 'Notifications',
                            subtitle: 'Manage your notification settings',
                            onTap: widget.onNotificationSettingsTap,
                          ),
                          const _TileDivider(),
                          _ProfileMenuTile(
                            uiScale: scale,
                            icon: Icons.shield_outlined,
                            iconBg: const Color(0xFFEDE7FA),
                            iconColor: const Color(0xFF6C4EF5),
                            title: 'Privacy & Security',
                            subtitle: 'Control your data and privacy',
                            onTap: widget.onPrivacyTap,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16 * scale),

                FadeTransition(
                  opacity: _fade(0.4, 0.7),
                  child: SlideTransition(
                    position: _slide(0.4, 0.74),
                    child: _GlassCard(
                      uiScale: scale,
                      padding: EdgeInsets.symmetric(vertical: 4 * scale),
                      child: Column(
                        children: [
                          _ProfileMenuTile(
                            uiScale: scale,
                            icon: Icons.headset_mic_rounded,
                            iconBg: const Color(0xFFE3F5EA),
                            iconColor: const Color(0xFF1E8A4C),
                            title: 'Help & Support',
                            subtitle: 'Get help and contact support',
                            onTap: widget.onHelpSupportTap,
                          ),
                          const _TileDivider(),
                          _ProfileMenuTile(
                            uiScale: scale,
                            icon: Icons.info_outline_rounded,
                            iconBg: const Color(0xFFEDE7FA),
                            iconColor: const Color(0xFF6C4EF5),
                            title: 'About DietCompass',
                            subtitle: 'App version ${widget.appVersion}',
                            onTap: widget.onAboutTap,
                          ),
                        ],
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
// Ambient glass backdrop — soft blurred colour blobs
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
              color: color.withValues(alpha: 0.22),
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
            color: Colors.white.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.75), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C4EF5).withValues(alpha: 0.08),
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
// Generic press-scale wrapper for tappable elements
// ---------------------------------------------------------------------------
class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, this.onTap, this.minScale = 0.96});
  final Widget child;
  final VoidCallback? onTap;
  final double minScale;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _scale = widget.minScale),
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
// Top header — title/subtitle + notification bell (pulsing badge) + settings
// ---------------------------------------------------------------------------
class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.uiScale,
    required this.ambientCtrl,
    this.onNotificationsTap,
    this.onSettingsTap,
  });
  final double uiScale;
  final AnimationController ambientCtrl;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Profile',
                style: TextStyle(
                  fontSize: 24 * uiScale,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B1B2E),
                ),
              ),
              SizedBox(height: 2 * uiScale),
              Text(
                'Manage your account and preferences',
                style: TextStyle(fontSize: 12 * uiScale, color: const Color(0xFF6B6B7B)),
              ),
            ],
          ),
        ),
        _Pressable(
          onTap: onNotificationsTap,
          child: _HeaderIconButton(
            uiScale: uiScale,
            icon: Icons.notifications_none_rounded,
            child: AnimatedBuilder(
              animation: ambientCtrl,
              builder: (context, child) {
                final pulse = 0.85 + (ambientCtrl.value * 0.3);
                return Positioned(
                  top: 8 * uiScale,
                  right: 8 * uiScale,
                  child: Transform.scale(
                    scale: pulse,
                    child: Container(
                      width: 8 * uiScale,
                      height: 8 * uiScale,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6C4EF5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        SizedBox(width: 10 * uiScale),
        _Pressable(
          onTap: onSettingsTap,
          child: _HeaderIconButton(uiScale: uiScale, icon: Icons.settings_outlined),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.uiScale, required this.icon, this.child});
  final double uiScale;
  final IconData icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44 * uiScale,
      height: 44 * uiScale,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(child: Icon(icon, size: 20 * uiScale, color: const Color(0xFF1B1B2E))),
          if (child != null) child!,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile header — avatar, name, badge, contact info, stat mini-cards
// ---------------------------------------------------------------------------
class _ProfileHeaderSection extends StatelessWidget {
  const _ProfileHeaderSection({
    required this.uiScale,
    required this.ambientCtrl,
    required this.entranceCtrl,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarInitial,
    required this.badgeLabel,
    required this.memberSince,
    required this.healthScore,
    required this.streakDays,
    this.onEditAvatarTap,
  });

  final double uiScale;
  final AnimationController ambientCtrl;
  final AnimationController entranceCtrl;
  final String name;
  final String email;
  final String phone;
  final String avatarInitial;
  final String badgeLabel;
  final String memberSince;
  final int healthScore;
  final int streakDays;
  final VoidCallback? onEditAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Faint decorative leaf sprigs, top-right
        Positioned(
          top: -6 * uiScale,
          right: -10 * uiScale,
          child: Opacity(
            opacity: 0.35,
            child: Transform.rotate(
              angle: 0.35,
              child: Icon(Icons.spa_rounded, size: 78 * uiScale, color: const Color(0xFF6C4EF5)),
            ),
          ),
        ),
        Positioned(
          top: 40 * uiScale,
          right: 26 * uiScale,
          child: Opacity(
            opacity: 0.22,
            child: Transform.rotate(
              angle: -0.2,
              child: Icon(Icons.eco_rounded, size: 34 * uiScale, color: const Color(0xFF6C4EF5)),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(
                  uiScale: uiScale,
                  initial: avatarInitial,
                  ambientCtrl: ambientCtrl,
                  onEditTap: onEditAvatarTap,
                ),
                SizedBox(width: 14 * uiScale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8 * uiScale,
                        runSpacing: 4 * uiScale,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 17 * uiScale,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1B1B2E),
                            ),
                          ),
                          _Badge(uiScale: uiScale, label: badgeLabel),
                        ],
                      ),
                      SizedBox(height: 8 * uiScale),
                      _ContactRow(
                        uiScale: uiScale,
                        icon: Icons.mail_outline_rounded,
                        text: email,
                      ),
                      SizedBox(height: 4 * uiScale),
                      _ContactRow(
                        uiScale: uiScale,
                        icon: Icons.call_outlined,
                        text: phone,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16 * uiScale),
            Row(
              children: [
                Expanded(
                  child: _StatMiniCard(
                    uiScale: uiScale,
                    icon: Icons.calendar_today_rounded,
                    iconBg: const Color(0xFFEDE7FA),
                    iconColor: const Color(0xFF6C4EF5),
                    label: 'Member Since',
                    value: memberSince,
                    valueColor: const Color(0xFF1B1B2E),
                  ),
                ),
                SizedBox(width: 10 * uiScale),
                Expanded(
                  child: _StatMiniCard(
                    uiScale: uiScale,
                    icon: Icons.favorite_rounded,
                    iconBg: const Color(0xFFEDE7FA),
                    iconColor: const Color(0xFF6C4EF5),
                    label: 'Health Score',
                    value: '',
                    valueColor: const Color(0xFF1E8A4C),
                    valueBuilder: (context) => TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: healthScore),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (context, val, child) => RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14 * uiScale,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E8A4C),
                          ),
                          children: [
                            TextSpan(text: '$val'),
                            TextSpan(
                              text: ' /100',
                              style: TextStyle(
                                fontSize: 11 * uiScale,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6B6B7B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10 * uiScale),
                Expanded(
                  child: _StatMiniCard(
                    uiScale: uiScale,
                    icon: Icons.local_fire_department_rounded,
                    iconBg: const Color(0xFFFCEEDD),
                    iconColor: const Color(0xFFE0862E),
                    label: 'Streak',
                    value: '$streakDays days',
                    valueColor: const Color(0xFF6C4EF5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.uiScale,
    required this.initial,
    required this.ambientCtrl,
    this.onEditTap,
  });
  final double uiScale;
  final String initial;
  final AnimationController ambientCtrl;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    final d = 76 * uiScale;
    return SizedBox(
      width: d + 10 * uiScale,
      height: d + 10 * uiScale,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: ambientCtrl,
            builder: (context, child) {
              final glow = 0.18 + ambientCtrl.value * 0.14;
              return Container(
                width: d,
                height: d,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C4EF5), Color(0xFF1E8A4C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C4EF5).withValues(alpha: glow),
                      blurRadius: 22,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 30 * uiScale,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _Pressable(
              onTap: onEditTap,
              child: Container(
                width: 26 * uiScale,
                height: 26 * uiScale,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF3F0FB), width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.edit_rounded, size: 13 * uiScale, color: const Color(0xFF6C4EF5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.uiScale, required this.label});
  final double uiScale;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9 * uiScale, vertical: 5 * uiScale),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F5EA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco_rounded, size: 12 * uiScale, color: const Color(0xFF1E8A4C)),
          SizedBox(width: 4 * uiScale),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5 * uiScale,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E8A4C),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.uiScale, required this.icon, required this.text});
  final double uiScale;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13 * uiScale, color: const Color(0xFFB0ACC2)),
        SizedBox(width: 6 * uiScale),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12 * uiScale, color: const Color(0xFF6B6B7B)),
          ),
        ),
      ],
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  const _StatMiniCard({
    required this.uiScale,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
    this.valueBuilder,
  });
  final double uiScale;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;
  final WidgetBuilder? valueBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * uiScale, vertical: 12 * uiScale),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEAF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26 * uiScale,
            height: 26 * uiScale,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 14 * uiScale, color: iconColor),
          ),
          SizedBox(height: 8 * uiScale),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9.5 * uiScale, color: const Color(0xFF6B6B7B)),
          ),
          SizedBox(height: 2 * uiScale),
          valueBuilder != null
              ? valueBuilder!(context)
              : Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13 * uiScale,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                  ),
                ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Complete Your Health Profile banner — animated progress fill
// ---------------------------------------------------------------------------
class _CompleteProfileBanner extends StatelessWidget {
  const _CompleteProfileBanner({
    required this.uiScale,
    required this.entranceCtrl,
    required this.completion,
    this.onCompleteNowTap,
  });
  final double uiScale;
  final AnimationController entranceCtrl;
  final double completion;
  final VoidCallback? onCompleteNowTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.all(16 * uiScale),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F5EA).withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFBFE6CE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42 * uiScale,
                    height: 42 * uiScale,
                    decoration: const BoxDecoration(
                      color: Color(0xFFCDEEDA),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.track_changes_rounded,
                        size: 21 * uiScale, color: const Color(0xFF1E8A4C)),
                  ),
                  SizedBox(width: 12 * uiScale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Complete Your Health Profile',
                          style: TextStyle(
                            fontSize: 13.5 * uiScale,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1B1B2E),
                          ),
                        ),
                        SizedBox(height: 2 * uiScale),
                        Text(
                          'Help us give you better recommendations',
                          style: TextStyle(fontSize: 11 * uiScale, color: const Color(0xFF4E7A5F)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8 * uiScale),
                  _Pressable(
                    onTap: onCompleteNowTap,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14 * uiScale,
                        vertical: 9 * uiScale,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF1E8A4C)),
                      ),
                      child: Text(
                        'Complete Now',
                        style: TextStyle(
                          fontSize: 11 * uiScale,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E8A4C),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14 * uiScale),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 8 * uiScale,
                        color: const Color(0xFFD7E9DD),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: completion),
                          duration: const Duration(milliseconds: 1300),
                          curve: Curves.easeOutCubic,
                          builder: (context, val, child) => FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: val,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1E8A4C), Color(0xFF3FBE7E)],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10 * uiScale),
                  Text(
                    '${(completion * 100).round()}%',
                    style: TextStyle(
                      fontSize: 12 * uiScale,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E8A4C),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header row with a "View Details" action
// ---------------------------------------------------------------------------
class _SectionHeaderRow extends StatelessWidget {
  const _SectionHeaderRow({
    required this.uiScale,
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });
  final double uiScale;
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15.5 * uiScale,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1B1B2E),
            ),
          ),
        ),
        if (actionLabel != null)
          _Pressable(
            onTap: onActionTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel!,
                  style: TextStyle(
                    fontSize: 12 * uiScale,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6C4EF5),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 16 * uiScale, color: const Color(0xFF6C4EF5)),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Health summary row — Goal / Diet Type / Height / Weight
// ---------------------------------------------------------------------------
class _HealthSummaryRow extends StatelessWidget {
  const _HealthSummaryRow({
    required this.uiScale,
    required this.goal,
    required this.dietType,
    required this.height,
    required this.weight,
    this.onGoalTap,
    this.onDietTypeTap,
    this.onHeightTap,
    this.onWeightTap,
  });

  final double uiScale;
  final String goal;
  final String dietType;
  final String height;
  final String weight;
  final VoidCallback? onGoalTap;
  final VoidCallback? onDietTypeTap;
  final VoidCallback? onHeightTap;
  final VoidCallback? onWeightTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _HealthSummaryItem(
            uiScale: uiScale,
            icon: Icons.flag_rounded,
            iconBg: const Color(0xFFE3F5EA),
            iconColor: const Color(0xFF1E8A4C),
            label: 'Goal',
            value: goal,
            valueColor: const Color(0xFF1E8A4C),
            onTap: onGoalTap,
          ),
        ),
        _VDivider(uiScale: uiScale),
        Expanded(
          child: _HealthSummaryItem(
            uiScale: uiScale,
            iconBg: const Color(0xFFEDE7FA),
            label: 'Diet Type',
            value: dietType,
            valueColor: const Color(0xFF6C4EF5),
            onTap: onDietTypeTap,
            customIcon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.person_rounded, size: 16 * uiScale, color: const Color(0xFF6C4EF5)),
                Positioned(
                  right: -2 * uiScale,
                  bottom: -2 * uiScale,
                  child: Icon(Icons.check_circle_rounded,
                      size: 10 * uiScale, color: const Color(0xFF1E8A4C)),
                ),
              ],
            ),
          ),
        ),
        _VDivider(uiScale: uiScale),
        Expanded(
          child: _HealthSummaryItem(
            uiScale: uiScale,
            icon: Icons.straighten_rounded,
            iconBg: const Color(0xFFFCEEDD),
            iconColor: const Color(0xFFE0862E),
            label: 'Height',
            value: height,
            valueColor: const Color(0xFFE0862E),
            onTap: onHeightTap,
          ),
        ),
        _VDivider(uiScale: uiScale),
        Expanded(
          child: _HealthSummaryItem(
            uiScale: uiScale,
            icon: Icons.monitor_weight_rounded,
            iconBg: const Color(0xFFE3EEFC),
            iconColor: const Color(0xFF3B82F6),
            label: 'Weight',
            value: weight,
            valueColor: const Color(0xFF3B82F6),
            onTap: onWeightTap,
          ),
        ),
      ],
    );
  }
}

class _VDivider extends StatelessWidget {
  const _VDivider({required this.uiScale});
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 64 * uiScale,
      color: const Color(0xFFEDEAF7),
    );
  }
}

class _HealthSummaryItem extends StatelessWidget {
  const _HealthSummaryItem({
    required this.uiScale,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.valueColor,
    this.icon,
    this.iconColor,
    this.customIcon,
    this.onTap,
  });

  final double uiScale;
  final Color iconBg;
  final String label;
  final String value;
  final Color valueColor;
  final IconData? icon;
  final Color? iconColor;
  final Widget? customIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38 * uiScale,
            height: 38 * uiScale,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: customIcon ?? Icon(icon, size: 18 * uiScale, color: iconColor),
          ),
          SizedBox(height: 8 * uiScale),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5 * uiScale,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1B1B2E),
            ),
          ),
          SizedBox(height: 3 * uiScale),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5 * uiScale,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 13 * uiScale, color: valueColor),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Generic menu tile with press highlight
// ---------------------------------------------------------------------------
class _ProfileMenuTile extends StatefulWidget {
  const _ProfileMenuTile({
    required this.uiScale,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final double uiScale;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  State<_ProfileMenuTile> createState() => _ProfileMenuTileState();
}

class _ProfileMenuTileState extends State<_ProfileMenuTile> {
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
        padding: EdgeInsets.symmetric(horizontal: 10 * uiScale, vertical: 12 * uiScale),
        child: Row(
          children: [
            Container(
              width: 40 * uiScale,
              height: 40 * uiScale,
              decoration: BoxDecoration(
                color: widget.iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, size: 19 * uiScale, color: widget.iconColor),
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
                      color: const Color(0xFF1B1B2E),
                    ),
                  ),
                  SizedBox(height: 2 * uiScale),
                  Text(
                    widget.subtitle,
                    style: TextStyle(fontSize: 11 * uiScale, color: const Color(0xFF6B6B7B)),
                  ),
                ],
              ),
            ),
            AnimatedSlide(
              offset: _pressed ? const Offset(0.06, 0) : Offset.zero,
              duration: const Duration(milliseconds: 140),
              child: Icon(Icons.chevron_right_rounded,
                  size: 18 * uiScale, color: const Color(0xFFB0ACC2)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFEDEAF7));
  }
}