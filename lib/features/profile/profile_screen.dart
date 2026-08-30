import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/storage_service.dart';
import '../../core/model/user_profile.dart';
import '../../core/model/personalization_profile.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/personalization_service.dart';
import 'saved_recipes_screen.dart';
import 'personal_info_screen.dart';
import 'health_profile_screen.dart';
import 'dietary_preferences_screen.dart';
import 'activity_level_screen.dart';
import 'notifications_screen.dart';
import 'privacy_security_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';
import 'settings_screen.dart';

/// DietCompass — My Profile Screen
/// -----------------------------------------------------------------------
/// Matches the visual language of ScanScreen / ManualEntryScreen:
/// lavender background (0xFFF3F0FB), purple → green brand gradient
/// (0xFF6C4EF5 → 0xFF1E8A4C), frosted glassmorphism cards, staggered
/// entrance choreography and small delightful micro-animations
/// (progress fill, count-up health score, pulsing bell badge, breathing
/// avatar glow, press-scale on every tappable row).
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
    this.appVersion = '1.0.0 (Beta)',
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

    /// Callback invoked when the user confirms logout.
    /// Should revoke the session and navigate to the login screen.
    this.onLogout,
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

  /// Real logout callback — revokes the session on the backend and
  /// clears secure credentials before returning to the login screen.
  final Future<void> Function()? onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _ambientCtrl;

  UserProfile? _profile;
  PersonalizationProfile? _personalization;
  String? _localProfileImagePath;

  String _monthName(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];

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

    _loadCloudProfile();
    _loadLocalProfileImage();
  }

  Future<void> _loadLocalProfileImage() async {
    final path = await StorageService.instance.getProfileImagePath();
    if (path != null && File(path).existsSync()) {
      if (mounted) setState(() => _localProfileImagePath = path);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final dir = await getApplicationDocumentsDirectory();
      final targetFile = File('${dir.path}/profile_avatar.jpg');
      await File(pickedFile.path).copy(targetFile.path);

      await StorageService.instance.saveProfileImagePath(targetFile.path);
      if (mounted) {
        setState(() {
          _localProfileImagePath = targetFile.path;
        });
        ScaffoldMessenger.of(context).showSnackBar(
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
                    'Profile photo updated successfully.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
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
                    'Could not update photo: $e',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  Future<void> _removeAvatar() async {
    await StorageService.instance.saveProfileImagePath(null);
    if (mounted) {
      setState(() {
        _localProfileImagePath = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1B1B2E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text(
            'Profile photo removed.',
            style: TextStyle(fontSize: 12),
          ),
        ),
      );
    }
  }

  void _showAvatarPicker() {
    final colors = context.dcColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final mq = MediaQuery.of(context);
        final scale = (mq.size.width / 390.0).clamp(0.85, 1.25);
        final hasCustomPhoto = _localProfileImagePath != null && File(_localProfileImagePath!).existsSync();

        return Container(
          padding: EdgeInsets.all(22 * scale),
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
                    width: 36 * scale,
                    height: 36 * scale,
                    decoration: BoxDecoration(
                      color: colors.iconPurpleBg,
                      borderRadius: BorderRadius.circular(10 * scale),
                    ),
                    child: Icon(Icons.camera_alt_rounded, color: colors.iconPurple, size: 18 * scale),
                  ),
                  SizedBox(width: 10 * scale),
                  Expanded(
                    child: Text(
                      'Update Profile Photo',
                      style: TextStyle(
                        fontSize: 16.5 * scale,
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
              SizedBox(height: 16 * scale),

              // Option 1: Take a Photo
              _buildAvatarOption(
                icon: Icons.camera_alt_rounded,
                iconColor: colors.iconPurple,
                iconBg: colors.iconPurpleBg,
                title: 'Take a Photo',
                subtitle: 'Use camera to snap a new photo',
                scale: scale,
                colors: colors,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              SizedBox(height: 10 * scale),

              // Option 2: Choose from Gallery
              _buildAvatarOption(
                icon: Icons.photo_library_rounded,
                iconColor: colors.iconGreen,
                iconBg: colors.iconGreenBg,
                title: 'Choose from Gallery',
                subtitle: 'Select an image from device gallery',
                scale: scale,
                colors: colors,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),

              // Option 3: Remove Photo
              if (hasCustomPhoto) ...[
                SizedBox(height: 10 * scale),
                _buildAvatarOption(
                  icon: Icons.delete_outline_rounded,
                  iconColor: colors.iconRed,
                  iconBg: colors.iconRedBg,
                  title: 'Remove Photo',
                  subtitle: 'Restore default avatar',
                  scale: scale,
                  colors: colors,
                  onTap: () {
                    Navigator.pop(ctx);
                    _removeAvatar();
                  },
                ),
              ],

              SizedBox(height: 8 * scale),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarOption({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required double scale,
    required DietCompassThemeColors colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16 * scale),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 12 * scale),
        decoration: BoxDecoration(
          color: colors.surfaceSecondary,
          borderRadius: BorderRadius.circular(16 * scale),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 36 * scale,
              height: 36 * scale,
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
                      color: colors.textPrimary,
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
            Icon(Icons.chevron_right_rounded, size: 20 * scale, color: colors.textMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _loadCloudProfile() async {
    try {
      final token = await StorageService.instance.getAccessToken();
      debugPrint(
        '[PROFILE LOAD AUTH DEBUG] tokenExists = ${token?.isNotEmpty == true}',
      );
      debugPrint(
        '[PROFILE LOAD AUTH DEBUG] tokenLength = ${token?.length ?? 0}',
      );
      final p = await ProfileService.instance.getProfile(forceRefresh: true);
      final pers = await PersonalizationService.instance.getPersonalization();
      if (mounted) {
        setState(() {
          _profile = p;
          _personalization = pers;
        });
      }
    } catch (_) {}
  }

  String get _displayName => _profile?.displayName ?? widget.name;
  String get _email =>
      _profile?.email.isNotEmpty == true ? _profile!.email : widget.email;
  String get _phone => _profile?.phone.isNotEmpty == true
      ? '${_profile!.countryCode} ${_profile!.phone}'
      : widget.phone;
  String get _avatarInitial => _profile?.avatarInitial ?? widget.avatarInitial;
  String get _badgeLabel => _profile?.badgeLabel.isNotEmpty == true
      ? _profile!.badgeLabel
      : widget.badgeLabel;
  String get _dietType => _profile?.dietType.isNotEmpty == true
      ? _profile!.dietType
      : (_personalization?.dietType?.isNotEmpty == true
            ? _personalization!.dietType!
            : widget.dietType);
  String get _height => _profile?.height.isNotEmpty == true
      ? '${_profile!.height} cm'
      : (_personalization?.height.isNotEmpty == true
            ? '${_personalization!.height} cm'
            : widget.height);
  String get _weight => _profile?.weight.isNotEmpty == true
      ? '${_profile!.weight} kg'
      : (_personalization?.weight.isNotEmpty == true
            ? '${_personalization!.weight} kg'
            : widget.weight);
  String get _goal => _personalization?.goals.isNotEmpty == true
      ? _personalization!.goals.first
      : widget.goal;

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

  Animation<Offset> _slide(double s, double e) =>
      Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entranceCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic),
        ),
      );

  void _openDietaryPreferences() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DietaryPreferencesScreen(
          initialData: _personalization?.toOnboardingData(),
        ),
      ),
    ).then((_) => _loadCloudProfile());
  }

  void _openActivityLevel() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityLevelScreen(
          initialActivityLevel: _personalization?.activityLevel,
        ),
      ),
    ).then((_) => _loadCloudProfile());
  }

  void _openNotifications({int initialTab = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(initialTab: initialTab),
      ),
    );
  }

  void _openHealthProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HealthProfileScreen(
          fullName: _displayName,
          gender: _profile?.gender.isNotEmpty == true
              ? _profile!.gender
              : 'Female',
          height: _height,
          weight: _weight,
        ),
      ),
    ).then((_) => _loadCloudProfile());
  }

  void _openPrivacySecurity() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PrivacySecurityScreen(),
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

  void _openAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AboutScreen(appVersion: widget.appVersion),
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          appVersion: widget.appVersion,
          onLogout: widget.onLogout,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 390).clamp(0.85, 1.25);
    final colors = context.dcColors;

    return Scaffold(
      backgroundColor: colors.bg,
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
                      onNotificationsTap: widget.onNotificationsTap ??
                          () => _openNotifications(initialTab: 0),
                      onSettingsTap: widget.onSettingsTap ?? _openSettings,
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
                        name: _displayName,
                        email: _email,
                        phone: _phone,
                        avatarInitial: _avatarInitial,
                        badgeLabel: _badgeLabel,
                        memberSince: _profile?.createdAt == null
                            ? '—'
                            : '${_monthName(_profile!.createdAt!.month)} ${_profile!.createdAt!.year}',
                        healthScore: _profile?.healthScore ?? 0,
                        streakDays: _profile?.streakDays ?? 0,
                        imagePath: _localProfileImagePath,
                        onEditAvatarTap: widget.onEditAvatarTap ?? _showAvatarPicker,
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
                      completion: _profile?.isPersonalizationComplete == true
                          ? 1.0
                          : widget.profileCompletion,
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
                      onActionTap: widget.onViewHealthDetailsTap ?? _openHealthProfile,
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
                        goal: _goal,
                        dietType: _dietType,
                        height: _height,
                        weight: _weight,
                        onGoalTap: widget.onGoalTap ?? _openHealthProfile,
                        onDietTypeTap: widget.onDietTypeTap ?? _openDietaryPreferences,
                        onHeightTap: widget.onHeightTap ?? _openHealthProfile,
                        onWeightTap: widget.onWeightTap ?? _openHealthProfile,
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
                                  builder: (_) => PersonalInfoScreen(
                                    fullName: _profile?.fullName ?? widget.name,
                                    email: _email,
                                    phone: _profile?.phone ?? widget.phone,
                                    countryCode: _profile?.countryCode ?? '+91',
                                    dateOfBirth:
                                        _profile?.dateOfBirth.isNotEmpty == true
                                        ? _profile!.dateOfBirth
                                        : '15 May 2005',
                                    gender: _profile?.gender.isNotEmpty == true
                                        ? _profile!.gender
                                        : 'Female',
                                    country:
                                        _profile?.country.isNotEmpty == true
                                        ? _profile!.country
                                        : 'India',
                                    city: _profile?.city ?? 'Mumbai',
                                    address: _profile?.address ?? '',
                                    occupation: _profile?.occupation ?? '',
                                    dietType: _dietType,
                                    height: _height,
                                    weight: _weight,
                                  ),
                                ),
                              ).then((updated) {
                                if (updated == true) _loadCloudProfile();
                              });
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
                            onTap: widget.onHealthProfileTap ?? _openHealthProfile,
                          ),
                          const _TileDivider(),
                          _ProfileMenuTile(
                            uiScale: scale,
                            icon: Icons.restaurant_rounded,
                            iconBg: const Color(0xFFFCEEDD),
                            iconColor: const Color(0xFFE0862E),
                            title: 'Dietary Preferences',
                            subtitle: 'Manage allergies and food preferences',
                            onTap: widget.onDietaryPreferencesTap ??
                                _openDietaryPreferences,
                          ),
                          const _TileDivider(),
                          _ProfileMenuTile(
                            uiScale: scale,
                            icon: Icons.directions_run_rounded,
                            iconBg: const Color(0xFFE3EEFC),
                            iconColor: const Color(0xFF3B82F6),
                            title: 'Activity Level',
                            subtitle: 'Set your daily activity level',
                            onTap: widget.onActivityLevelTap ??
                                _openActivityLevel,
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
                                  builder: (_) => const SavedRecipesScreen(),
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
                            onTap: widget.onNotificationSettingsTap ??
                                () => _openNotifications(initialTab: 1),
                          ),
                          const _TileDivider(),
                          _ProfileMenuTile(
                            uiScale: scale,
                            icon: Icons.shield_outlined,
                            iconBg: const Color(0xFFEDE7FA),
                            iconColor: const Color(0xFF6C4EF5),
                            title: 'Privacy & Security',
                            subtitle: 'Control your data and privacy',
                            onTap: widget.onPrivacyTap ?? _openPrivacySecurity,
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
                            onTap: widget.onHelpSupportTap ?? _openHelpSupport,
                          ),
                          const _TileDivider(),
                          _ProfileMenuTile(
                            uiScale: scale,
                            icon: Icons.info_outline_rounded,
                            iconBg: const Color(0xFFEDE7FA),
                            iconColor: const Color(0xFF6C4EF5),
                            title: 'About DietCompass',
                            subtitle: 'App version ${widget.appVersion}',
                            onTap: widget.onAboutTap ?? _openAbout,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16 * scale),

                // ── Logout button ───────────────────────────────────────────
                FadeTransition(
                  opacity: _fade(0.5, 0.8),
                  child: SlideTransition(
                    position: _slide(0.5, 0.84),
                    child: _GlassCard(
                      uiScale: scale,
                      padding: EdgeInsets.symmetric(vertical: 4 * scale),
                      child: _LogoutTile(
                        uiScale: scale,
                        onLogout: widget.onLogout,
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
    final colors = context.dcColors;
    return AnimatedBuilder(
      animation: ambientCtrl,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(ambientCtrl.value);
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(color: colors.bg),
            Positioned(
              top: -90 + t * 16,
              right: -60,
              child: _blob(220 * uiScale, colors.iconPurple, colors.isDark ? 0.16 : 0.22),
            ),
            Positioned(
              top: 260 - t * 20,
              left: -70,
              child: _blob(190 * uiScale, colors.iconGreen, colors.isDark ? 0.12 : 0.22),
            ),
            Positioned(
              bottom: -60 + t * 12,
              right: -40,
              child: _blob(180 * uiScale, colors.iconBlue, colors.isDark ? 0.14 : 0.22),
            ),
          ],
        );
      },
    );
  }

  Widget _blob(double size, Color color, double alpha) => ClipRRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: alpha),
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
    final colors = context.dcColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding ?? EdgeInsets.all(16 * uiScale),
          decoration: BoxDecoration(
            color: colors.isDark
                ? const Color(0xFF1D1B2A).withValues(alpha: 0.90)
                : Colors.white.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colors.cardBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : const Color(0xFF6C4EF5).withValues(alpha: 0.08),
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
  const _Pressable({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;
  static const double _minScale = 0.96;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _scale = _Pressable._minScale),
      onTapUp: widget.onTap == null
          ? null
          : (_) => setState(() => _scale = 1.0),
      onTapCancel: widget.onTap == null
          ? null
          : () => setState(() => _scale = 1.0),
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
    final colors = context.dcColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Pressable(
          onTap: () => Navigator.of(context).pop(),
          child: _HeaderIconButton(
            uiScale: uiScale,
            icon: Icons.arrow_back_rounded,
          ),
        ),
        SizedBox(width: 10 * uiScale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Profile',
                style: TextStyle(
                  fontSize: 24 * uiScale,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: 2 * uiScale),
              Text(
                'Manage your account and preferences',
                style: TextStyle(
                  fontSize: 12 * uiScale,
                  color: colors.textSecondary,
                ),
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
                      decoration: BoxDecoration(
                        color: colors.iconPurple,
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
          child: _HeaderIconButton(
            uiScale: uiScale,
            icon: Icons.settings_outlined,
          ),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.uiScale,
    required this.icon,
    this.child,
  });
  final double uiScale;
  final IconData icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Container(
      width: 44 * uiScale,
      height: 44 * uiScale,
      decoration: BoxDecoration(
        color: colors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.20 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              icon,
              size: 20 * uiScale,
              color: colors.textPrimary,
            ),
          ),
          ?child,
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
    this.imagePath,
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
  final String? imagePath;
  final VoidCallback? onEditAvatarTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
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
              child: Icon(
                Icons.spa_rounded,
                size: 78 * uiScale,
                color: colors.iconPurple,
              ),
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
              child: Icon(
                Icons.eco_rounded,
                size: 34 * uiScale,
                color: colors.iconPurple,
              ),
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
                  imagePath: imagePath,
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
                              color: colors.textPrimary,
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
            SizedBox(height: 18 * uiScale),

            // Stat mini-cards row
            Row(
              children: [
                Expanded(
                  child: _StatMiniCard(
                    uiScale: uiScale,
                    icon: Icons.favorite_rounded,
                    iconBg: colors.iconGreenBg,
                    iconColor: colors.iconGreen,
                    label: 'Health Score',
                    value: '$healthScore/100',
                    valueColor: colors.iconGreen,
                  ),
                ),
                SizedBox(width: 10 * uiScale),
                Expanded(
                  child: _StatMiniCard(
                    uiScale: uiScale,
                    icon: Icons.calendar_today_rounded,
                    iconBg: colors.iconPurpleBg,
                    iconColor: colors.iconPurple,
                    label: 'Member Since',
                    value: memberSince,
                    valueColor: colors.textPrimary,
                  ),
                ),
                SizedBox(width: 10 * uiScale),
                Expanded(
                  child: _StatMiniCard(
                    uiScale: uiScale,
                    icon: Icons.local_fire_department_rounded,
                    iconBg: colors.iconOrangeBg,
                    iconColor: colors.iconOrange,
                    label: 'Streak',
                    value: '$streakDays days',
                    valueColor: colors.iconPurple,
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
    this.imagePath,
    this.onEditTap,
  });
  final double uiScale;
  final String initial;
  final AnimationController ambientCtrl;
  final String? imagePath;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    final d = 76 * uiScale;
    final hasImage = imagePath != null && File(imagePath!).existsSync();

    return SizedBox(
      width: d + 10 * uiScale,
      height: d + 10 * uiScale,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _Pressable(
            onTap: onEditTap,
            child: AnimatedBuilder(
              animation: ambientCtrl,
              builder: (context, child) {
                final glow = 0.18 + ambientCtrl.value * 0.14;
                return Container(
                  width: d,
                  height: d,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [colors.iconPurple, colors.iconGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.iconPurple.withValues(alpha: glow),
                        blurRadius: 22,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: hasImage
                        ? Image.file(
                            File(imagePath!),
                            width: d,
                            height: d,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Center(
                              child: Text(
                                initial,
                                style: TextStyle(
                                  fontSize: 30 * uiScale,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              initial,
                              style: TextStyle(
                                fontSize: 30 * uiScale,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
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
                  color: colors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.cardBorder,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.edit_rounded,
                  size: 13 * uiScale,
                  color: colors.iconPurple,
                ),
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
    final colors = context.dcColors;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 9 * uiScale,
        vertical: 5 * uiScale,
      ),
      decoration: BoxDecoration(
        color: colors.iconGreenBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.eco_rounded,
            size: 12 * uiScale,
            color: colors.iconGreen,
          ),
          SizedBox(width: 4 * uiScale),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5 * uiScale,
              fontWeight: FontWeight.w700,
              color: colors.iconGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.uiScale,
    required this.icon,
    required this.text,
  });
  final double uiScale;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Row(
      children: [
        Icon(icon, size: 13 * uiScale, color: colors.textMuted),
        SizedBox(width: 6 * uiScale),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12 * uiScale,
              color: colors.textSecondary,
            ),
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
  });
  final double uiScale;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.dcColors;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * uiScale,
        vertical: 12 * uiScale,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26 * uiScale,
            height: 26 * uiScale,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14 * uiScale, color: iconColor),
          ),
          SizedBox(height: 8 * uiScale),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5 * uiScale,
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: 2 * uiScale),
          Text(
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
    final colors = context.dcColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.all(16 * uiScale),
          decoration: BoxDecoration(
            color: colors.isDark
                ? const Color(0xFF183224).withValues(alpha: 0.85)
                : const Color(0xFFE3F5EA).withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: colors.isDark ? const Color(0xFF225037) : const Color(0xFFBFE6CE),
            ),
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
                    decoration: BoxDecoration(
                      color: colors.isDark ? const Color(0xFF244D37) : const Color(0xFFCDEEDA),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.track_changes_rounded,
                      size: 21 * uiScale,
                      color: colors.iconGreen,
                    ),
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
                            color: colors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2 * uiScale),
                        Text(
                          'Help us give you better recommendations',
                          style: TextStyle(
                            fontSize: 11 * uiScale,
                            color: colors.isDark ? const Color(0xFF68A37E) : const Color(0xFF4E7A5F),
                          ),
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
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.iconGreen),
                      ),
                      child: Text(
                        'Complete Now',
                        style: TextStyle(
                          fontSize: 11 * uiScale,
                          fontWeight: FontWeight.w800,
                          color: colors.iconGreen,
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
                        color: colors.isDark ? const Color(0xFF204432) : const Color(0xFFD7E9DD),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: completion),
                          duration: const Duration(milliseconds: 1300),
                          curve: Curves.easeOutCubic,
                          builder: (context, val, child) =>
                              FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: val,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: LinearGradient(
                                      colors: [
                                        colors.iconGreen,
                                        const Color(0xFF3FBE7E),
                                      ],
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
                      color: colors.iconGreen,
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
    final colors = context.dcColors;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15.5 * uiScale,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
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
                    color: colors.iconPurple,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16 * uiScale,
                  color: colors.iconPurple,
                ),
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
    final colors = context.dcColors;
    return Row(
      children: [
        Expanded(
          child: _HealthSummaryItem(
            uiScale: uiScale,
            icon: Icons.flag_rounded,
            iconBg: colors.iconGreenBg,
            iconColor: colors.iconGreen,
            label: 'Goal',
            value: goal,
            valueColor: colors.iconGreen,
            onTap: onGoalTap,
          ),
        ),
        _VDivider(uiScale: uiScale),
        Expanded(
          child: _HealthSummaryItem(
            uiScale: uiScale,
            iconBg: colors.iconPurpleBg,
            label: 'Diet Type',
            value: dietType,
            valueColor: colors.iconPurple,
            onTap: onDietTypeTap,
            customIcon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.person_rounded,
                  size: 16 * uiScale,
                  color: colors.iconPurple,
                ),
                Positioned(
                  right: -2 * uiScale,
                  bottom: -2 * uiScale,
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 10 * uiScale,
                    color: colors.iconGreen,
                  ),
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
            iconBg: colors.iconOrangeBg,
            iconColor: colors.iconOrange,
            label: 'Height',
            value: height,
            valueColor: colors.iconOrange,
            onTap: onHeightTap,
          ),
        ),
        _VDivider(uiScale: uiScale),
        Expanded(
          child: _HealthSummaryItem(
            uiScale: uiScale,
            icon: Icons.monitor_weight_rounded,
            iconBg: colors.iconBlueBg,
            iconColor: colors.iconBlue,
            label: 'Weight',
            value: weight,
            valueColor: colors.iconBlue,
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
      color: context.dcColors.cardBorder,
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
    final colors = context.dcColors;
    return _Pressable(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38 * uiScale,
            height: 38 * uiScale,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child:
                customIcon ?? Icon(icon, size: 18 * uiScale, color: iconColor),
          ),
          SizedBox(height: 8 * uiScale),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5 * uiScale,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
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
              Icon(
                Icons.chevron_right_rounded,
                size: 13 * uiScale,
                color: valueColor,
              ),
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
    final colors = context.dcColors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        color: _pressed ? colors.surfaceSecondary : Colors.transparent,
        padding: EdgeInsets.symmetric(
          horizontal: 10 * uiScale,
          vertical: 12 * uiScale,
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
                      color: colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2 * uiScale),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontSize: 11 * uiScale,
                      color: colors.textSecondary,
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
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Logout tile — shows a confirmation dialog then calls onLogout
// ---------------------------------------------------------------------------
class _LogoutTile extends StatefulWidget {
  const _LogoutTile({required this.uiScale, this.onLogout});

  final double uiScale;
  final Future<void> Function()? onLogout;

  @override
  State<_LogoutTile> createState() => _LogoutTileState();
}

class _LogoutTileState extends State<_LogoutTile> {
  bool _loading = false;

  Future<void> _confirmLogout() async {
    final colors = context.dcColors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.cardBorder),
        ),
        title: Text(
          'Log Out',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to log out from this device?',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE0525C),
            ),
            child: const Text(
              'Log Out',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    if (widget.onLogout == null) return;

    setState(() => _loading = true);
    try {
      await widget.onLogout!();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.uiScale;
    final colors = context.dcColors;
    return InkWell(
      onTap: _loading ? null : _confirmLogout,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 14 * s),
        child: Row(
          children: [
            Container(
              width: 40 * s,
              height: 40 * s,
              decoration: BoxDecoration(
                color: colors.iconRedBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _loading
                  ? Padding(
                      padding: EdgeInsets.all(10 * s),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(colors.iconRed),
                      ),
                    )
                  : Icon(
                      Icons.logout_rounded,
                      size: 19 * s,
                      color: colors.iconRed,
                    ),
            ),
            SizedBox(width: 12 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Log Out',
                    style: TextStyle(
                      fontSize: 13.5 * s,
                      fontWeight: FontWeight.w800,
                      color: colors.iconRed,
                    ),
                  ),
                  SizedBox(height: 2 * s),
                  Text(
                    'Sign out from this device',
                    style: TextStyle(
                      fontSize: 11 * s,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18 * s,
              color: colors.iconRed,
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
    return Divider(height: 1, thickness: 1, color: context.dcColors.divider);
  }
}
