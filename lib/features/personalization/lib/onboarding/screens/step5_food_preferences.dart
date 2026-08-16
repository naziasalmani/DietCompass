import 'package:flutter/material.dart';
import '../onboarding_data.dart';
import '../onboarding_theme.dart';
import '../widgets/onboarding_widgets.dart';

class Step5FoodPreferences extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  const Step5FoodPreferences({
    super.key,
    required this.data,
    required this.onContinue,
    required this.onBack,
    required this.onSkip,
  });

  @override
  State<Step5FoodPreferences> createState() => _Step5FoodPreferencesState();
}

class _Step5FoodPreferencesState extends State<Step5FoodPreferences> {
  bool _showOtherDislikeField = false;
  static const dietTypes = [
    ('Vegetarian', Icons.eco),
    ('Vegan', Icons.spa),
    ('Eggetarian', Icons.egg_outlined),
    ('Non-Vegetarian', Icons.set_meal_outlined),
  ];
  static const allergyOptions = [
    'Milk', 'Eggs', 'Peanuts', 'Tree Nuts', 'Soy',
    'Wheat', 'Gluten', 'Fish', 'Shellfish', 'Sesame',
    'Mustard', 'Celery', 'Lupin', 'Sulphites', 'Other (Specify)',
  ];
  static const dislikeOptions = ['Spicy Food', 'Mushrooms', 'Seafood', 'Bitter Vegetables', 'Other (Specify)'];

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final noneAllergies = d.allergies.contains('None of the above');
    return OnboardingScaffold(
      currentStep: 5,
      totalSteps: 7,
      stepIcon: Icons.eco,
      onBack: widget.onBack,
      onSkip: widget.onSkip,
      bottomButton: GradientButton(label: 'Continue', onTap: widget.onContinue),
      child: EntranceAnimator(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              RichText(
                text: const TextSpan(
                  style: AppText.title,
                  children: [
                    TextSpan(text: 'Food\n'),
                    TextSpan(text: 'Preferences ', style: AppText.titleAccent),
                    TextSpan(text: '\u{1F343}', style: AppText.titleAccent),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Let us know about your diet type and allergies so we can suggest the best options for you.',
                style: AppText.body,
              ),
              const SizedBox(height: 20),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Diet Type', style: AppText.sectionTitle),
                    const Text('Choose the option that best describes you.', style: AppText.sectionSubtitle),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dietTypes.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.7,
                      ),
                      itemBuilder: (_, i) {
                        final (title, icon) = dietTypes[i];
                        return OptionCard(
                          icon: icon,
                          title: title,
                          selected: d.dietType == title,
                          multiSelect: false,
                          onTap: () => setState(() => d.dietType = title),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Allergies', style: AppText.sectionTitle),
                    const Text('Select all that apply to you.', style: AppText.sectionSubtitle),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: allergyOptions.map((a) {
                        final sel = d.allergies.contains(a);
                        return ChoiceChip(
                          label: Text(a),
                          selected: sel,
                          selectedColor: AppColors.chipSelectedBg,
                          side: BorderSide(color: sel ? AppColors.primaryPurple : AppColors.borderLight),
                          labelStyle: TextStyle(
                              color: sel ? AppColors.primaryPurple : AppColors.textDark,
                              fontWeight: FontWeight.w600),
                          onSelected: (_) => setState(() {
                            d.allergies.remove('None of the above');
                            if (!d.allergies.remove(a)) d.allergies.add(a);
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    OptionCard(
                      icon: Icons.verified_user_outlined,
                      iconColor: AppColors.success,
                      title: 'None of the above',
                      selected: noneAllergies,
                      onTap: () => setState(() {
                        if (noneAllergies) {
                          d.allergies.remove('None of the above');
                        } else {
                          d.allergies
                            ..clear()
                            ..add('None of the above');
                        }
                      }),
                    ),
                  ],
                ),
              ),
              SectionCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: const [
          Text(
            'Foods you dislike ',
            style: AppText.sectionTitle,
          ),
          Text(
            '(Optional)',
            style: AppText.sectionSubtitle,
          ),
        ],
      ),

      const Text(
        "This helps us avoid suggesting foods you don't enjoy.",
        style: AppText.sectionSubtitle,
      ),

      const SizedBox(height: 12),

      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: dislikeOptions.map((a) {
          final sel = d.dislikedFoods.contains(a);

          return ChoiceChip(
            label: Text(a),

            selected: sel,

            selectedColor: AppColors.chipSelectedBg,

            side: BorderSide(
              color: sel
                  ? AppColors.primaryPurple
                  : AppColors.borderLight,
            ),

            labelStyle: TextStyle(
              color: sel
                  ? AppColors.primaryPurple
                  : AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),

            onSelected: (_) {
              setState(() {
                if (a == 'Other (Specify)') {
                  _showOtherDislikeField = !_showOtherDislikeField;

                  if (!_showOtherDislikeField) {
                    d.dislikedFoods.remove(a);
                  } else if (!d.dislikedFoods.contains(a)) {
                    d.dislikedFoods.add(a);
                  }
                } else {
                  if (sel) {
                    d.dislikedFoods.remove(a);
                  } else {
                    d.dislikedFoods.add(a);
                  }
                }
              });
            },
          );
        }).toList(),
      ),

      // ======================================================
      // OTHER FOOD TEXT BOX
      // ======================================================

      if (_showOtherDislikeField) ...[
        const SizedBox(height: 14),

        TextField(
          onChanged: (value) {
            // Remove the previous custom value.
            d.dislikedFoods.removeWhere(
              (item) =>
                  !dislikeOptions.contains(item) &&
                  item != 'Other (Specify)',
            );

            if (value.trim().isNotEmpty) {
              d.dislikedFoods.add(value.trim());
            }
          },

          decoration: InputDecoration(
            hintText: 'Specify a food you dislike',

            prefixIcon: const Icon(
              Icons.edit_outlined,
              color: AppColors.primaryPurple,
            ),

            filled: true,
            fillColor: Colors.white,

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.borderLight,
              ),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.borderLight,
              ),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primaryPurple,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    ],
  ),
),
              Row(
                children: const [
                  Icon(Icons.shield_outlined, size: 16, color: AppColors.primaryPurple),
                  SizedBox(width: 8),
                  Text('Your preferences are 100% private and secure.', style: AppText.sectionSubtitle),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
