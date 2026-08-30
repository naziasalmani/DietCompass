import 'package:flutter/material.dart';
import 'package:diet_compass/features/personalization/lib/onboarding/onboarding_data.dart';
import '../../core/services/personalization_service.dart';

/// DietCompass — Dietary Preferences Screen
/// -----------------------------------------------------------------------
/// Matches the exact visual language of My Profile, Health Profile, and
/// Privacy & Security: lavender background (0xFFF3F0FB), ambient blur orbs,
/// frosted white glass cards, rounded icon headers, and curated chip badges.
class DietaryPreferencesScreen extends StatefulWidget {
  const DietaryPreferencesScreen({
    super.key,
    this.initialData,
    this.onBack,
  });

  final OnboardingData? initialData;
  final VoidCallback? onBack;

  @override
  State<DietaryPreferencesScreen> createState() =>
      _DietaryPreferencesScreenState();
}

class _DietaryPreferencesScreenState extends State<DietaryPreferencesScreen>
    with SingleTickerProviderStateMixin {
  late final OnboardingData _data;
  bool _showOtherDislikeField = false;
  bool _isSaving = false;
  final TextEditingController _otherDislikeCtrl = TextEditingController();
  late final AnimationController _animCtrl;

  static const _dietTypes = [
    ('Vegetarian', Icons.eco_rounded, Color(0xFF1E8A4C)),
    ('Vegan', Icons.spa_rounded, Color(0xFF2E7D32)),
    ('Eggetarian', Icons.egg_outlined, Color(0xFFE0862E)),
    ('Non-Vegetarian', Icons.set_meal_outlined, Color(0xFFE0525C)),
  ];

  static const _allergies = [
    'Milk',
    'Eggs',
    'Peanuts',
    'Tree Nuts',
    'Soy',
    'Wheat',
    'Gluten',
    'Fish',
    'Shellfish',
    'Sesame',
    'Mustard',
    'Celery',
    'Lupin',
    'Sulphites',
  ];

  static const _dislikedFoods = [
    'Spicy Food',
    'Mushrooms',
    'Seafood',
    'Bitter Vegetables',
  ];

  @override
  void initState() {
    super.initState();
    _data = widget.initialData ?? OnboardingData();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    final otherCustomDislikes = _data.dislikedFoods
        .where((food) => !_dislikedFoods.contains(food))
        .toList();
    if (otherCustomDislikes.isNotEmpty) {
      _showOtherDislikeField = true;
      _otherDislikeCtrl.text = otherCustomDislikes.join(', ');
    }
  }

  @override
  void dispose() {
    _otherDislikeCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (_showOtherDislikeField && _otherDislikeCtrl.text.trim().isNotEmpty) {
        final customDislikes = _otherDislikeCtrl.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty && !_dislikedFoods.contains(e));
        for (final item in customDislikes) {
          if (!_data.dislikedFoods.contains(item)) {
            _data.dislikedFoods.add(item);
          }
        }
      }

      await PersonalizationService.instance.savePersonalization(_data);
      if (!mounted) return;
      setState(() => _isSaving = false);

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
                  'Dietary preferences updated successfully.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
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
                  'Could not update preferences: $error',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final scale = (width / 390.0).clamp(0.85, 1.25);
    final noneAllergies = _data.allergies.contains('None of the above');

    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FB),
      body: Stack(
        children: [
          // Ambient blurred decorative orbs
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
            top: 250,
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
                // Top Navigation Bar
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14 * scale),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 20 * scale,
                            color: const Color(0xFF1B1B2E),
                          ),
                        ),
                      ),
                      SizedBox(width: 14 * scale),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dietary Preferences',
                              style: TextStyle(
                                fontSize: 18 * scale,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1B1B2E),
                              ),
                            ),
                            Text(
                              'Diet type, allergies & dislikes',
                              style: TextStyle(
                                fontSize: 12 * scale,
                                color: const Color(0xFF6B6B7B),
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
                        // Section 1: Diet Type
                        _buildSectionCard(
                          scale: scale,
                          icon: Icons.restaurant_rounded,
                          iconColor: const Color(0xFF6C4EF5),
                          iconBg: const Color(0xFFEDE7FA),
                          title: 'Diet Type',
                          subtitle: 'Choose the option that best describes your diet',
                          child: Wrap(
                            spacing: 10 * scale,
                            runSpacing: 10 * scale,
                            children: _dietTypes.map((diet) {
                              final selected = _data.dietType == diet.$1;
                              return _buildDietCard(
                                label: diet.$1,
                                icon: diet.$2,
                                color: diet.$3,
                                selected: selected,
                                scale: scale,
                                onTap: () => setState(() => _data.dietType = diet.$1),
                              );
                            }).toList(),
                          ),
                        ),

                        SizedBox(height: 16 * scale),

                        // Section 2: Allergies
                        _buildSectionCard(
                          scale: scale,
                          icon: Icons.warning_amber_rounded,
                          iconColor: const Color(0xFFE0525C),
                          iconBg: const Color(0xFFFFECEE),
                          title: 'Allergies & Intolerances',
                          subtitle: 'Select any foods you are allergic to',
                          child: Wrap(
                            spacing: 8 * scale,
                            runSpacing: 8 * scale,
                            children: [
                              ..._allergies.map((allergy) {
                                final isSelected = _data.allergies.contains(allergy);
                                return _buildTagChip(
                                  label: allergy,
                                  selected: isSelected,
                                  scale: scale,
                                  selectedColor: const Color(0xFFE0525C),
                                  selectedBg: const Color(0xFFFFECEE),
                                  onTap: () => setState(() {
                                    _data.allergies.remove('None of the above');
                                    if (!_data.allergies.remove(allergy)) {
                                      _data.allergies.add(allergy);
                                    }
                                  }),
                                );
                              }),
                              _buildTagChip(
                                label: 'None of the above',
                                selected: noneAllergies,
                                scale: scale,
                                selectedColor: const Color(0xFF1E8A4C),
                                selectedBg: const Color(0xFFE3F5EA),
                                onTap: () => setState(() {
                                  if (noneAllergies) {
                                    _data.allergies.remove('None of the above');
                                  } else {
                                    _data.allergies
                                      ..clear()
                                      ..add('None of the above');
                                  }
                                }),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 16 * scale),

                        // Section 3: Foods You Dislike
                        _buildSectionCard(
                          scale: scale,
                          icon: Icons.thumb_down_alt_outlined,
                          iconColor: const Color(0xFFE0862E),
                          iconBg: const Color(0xFFFCEEDD),
                          title: 'Foods You Dislike',
                          subtitle: 'Avoid recipes and products with ingredients you dislike',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8 * scale,
                                runSpacing: 8 * scale,
                                children: [
                                  ..._dislikedFoods.map((food) {
                                    final isSelected = _data.dislikedFoods.contains(food);
                                    return _buildTagChip(
                                      label: food,
                                      selected: isSelected,
                                      scale: scale,
                                      selectedColor: const Color(0xFFE0862E),
                                      selectedBg: const Color(0xFFFCEEDD),
                                      onTap: () => setState(() {
                                        if (!_data.dislikedFoods.remove(food)) {
                                          _data.dislikedFoods.add(food);
                                        }
                                      }),
                                    );
                                  }),
                                  _buildTagChip(
                                    label: 'Other',
                                    selected: _showOtherDislikeField,
                                    scale: scale,
                                    selectedColor: const Color(0xFF6C4EF5),
                                    selectedBg: const Color(0xFFEDE7FA),
                                    onTap: () => setState(() => _showOtherDislikeField = !_showOtherDislikeField),
                                  ),
                                ],
                              ),
                              if (_showOtherDislikeField) ...[
                                SizedBox(height: 14 * scale),
                                TextField(
                                  controller: _otherDislikeCtrl,
                                  style: TextStyle(fontSize: 13.5 * scale, color: const Color(0xFF1B1B2E)),
                                  decoration: InputDecoration(
                                    hintText: 'Enter foods separated by commas (e.g. olives, bell pepper)',
                                    hintStyle: TextStyle(color: const Color(0xFFA0A0B0), fontSize: 12.5 * scale),
                                    filled: true,
                                    fillColor: const Color(0xFFF9F7FD),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 12 * scale),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12 * scale),
                                      borderSide: BorderSide(color: const Color(0xFF6C4EF5).withValues(alpha: 0.15)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12 * scale),
                                      borderSide: BorderSide(color: const Color(0xFF6C4EF5).withValues(alpha: 0.15)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12 * scale),
                                      borderSide: const BorderSide(color: Color(0xFF6C4EF5), width: 1.5),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    _data.dislikedFoods.removeWhere(
                                      (food) => !_dislikedFoods.contains(food),
                                    );
                                    if (value.trim().isNotEmpty) {
                                      final items = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
                                      for (final item in items) {
                                        if (!_data.dislikedFoods.contains(item)) {
                                          _data.dislikedFoods.add(item);
                                        }
                                      }
                                    }
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),

                        SizedBox(height: 24 * scale),

                        // Save Preferences Button
                        SizedBox(
                          width: double.infinity,
                          height: 50 * scale,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C4EF5),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16 * scale),
                              ),
                            ),
                            child: _isSaving
                                ? SizedBox(
                                    width: 20 * scale,
                                    height: 20 * scale,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.check_rounded, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Save Preferences',
                                        style: TextStyle(
                                          fontSize: 14.5 * scale,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
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

  Widget _buildSectionCard({
    required double scale,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(18 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C4EF5).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              SizedBox(width: 12 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15 * scale,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1B1B2E),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5 * scale,
                        color: const Color(0xFF6B6B7B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16 * scale),
          child,
        ],
      ),
    );
  }

  Widget _buildDietCard({
    required String label,
    required IconData icon,
    required Color color,
    required bool selected,
    required double scale,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 10 * scale),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEDE7FA) : const Color(0xFFF9F7FD),
          borderRadius: BorderRadius.circular(14 * scale),
          border: Border.all(
            color: selected ? const Color(0xFF6C4EF5) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6C4EF5).withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18 * scale,
              color: selected ? const Color(0xFF6C4EF5) : color,
            ),
            SizedBox(width: 8 * scale),
            Text(
              label,
              style: TextStyle(
                fontSize: 13 * scale,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? const Color(0xFF6C4EF5) : const Color(0xFF1B1B2E),
              ),
            ),
            if (selected) ...[
              SizedBox(width: 6 * scale),
              Icon(
                Icons.check_circle_rounded,
                size: 14 * scale,
                color: const Color(0xFF6C4EF5),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip({
    required String label,
    required bool selected,
    required double scale,
    required Color selectedColor,
    required Color selectedBg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 8 * scale),
        decoration: BoxDecoration(
          color: selected ? selectedBg : const Color(0xFFF9F7FD),
          borderRadius: BorderRadius.circular(12 * scale),
          border: Border.all(
            color: selected ? selectedColor.withValues(alpha: 0.8) : const Color(0xFFEBE6F5),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5 * scale,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? selectedColor : const Color(0xFF4A4A5A),
              ),
            ),
            if (selected) ...[
              SizedBox(width: 4 * scale),
              Icon(
                Icons.check_rounded,
                size: 13 * scale,
                color: selectedColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
