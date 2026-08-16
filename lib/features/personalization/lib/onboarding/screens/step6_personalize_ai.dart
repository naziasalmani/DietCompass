import 'package:flutter/material.dart';
import '../onboarding_data.dart';
import '../onboarding_theme.dart';
import '../widgets/onboarding_widgets.dart';

class Step6PersonalizeAI extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  const Step6PersonalizeAI({
    super.key,
    required this.data,
    required this.onContinue,
    required this.onBack,
    required this.onSkip,
  });

  @override
  State<Step6PersonalizeAI> createState() => _Step6PersonalizeAIState();
}

class _Step6PersonalizeAIState extends State<Step6PersonalizeAI> {
  static const focusOptions = [
    (
      'Healthy Eating',
      'Build better eating habits',
      Icons.eco,
    ),
    (
      'Weight Management',
      'Lose, gain or maintain weight',
      Icons.monitor_weight_outlined,
    ),
    (
      'High Protein',
      'Increase daily protein intake',
      Icons.fitness_center,
    ),
    (
      'Low Sugar',
      'Reduce added sugar intake',
      Icons.icecream_outlined,
    ),
    (
      'Low Sodium',
      'Lower salt intake',
      Icons.water_drop_outlined,
    ),
    (
      'High Fibre',
      'Improve digestion & gut health',
      Icons.grass,
    ),
    (
      'Budget Friendly',
      'Eat healthy while saving money',
      Icons.account_balance_wallet_outlined,
    ),
    (
      'Family Meals',
      'Meals for the whole family',
      Icons.groups_outlined,
    ),
    (
      'Kids Nutrition',
      'Healthy choices for kids',
      Icons.child_care,
    ),
    (
      'Sports Nutrition',
      'Fuel your workouts & performance',
      Icons.directions_run,
    ),
    (
      'Vegetarian',
      'Plant-based lifestyle',
      Icons.eco_outlined,
    ),
    (
      'Vegan',
      '100% plant-based lifestyle',
      Icons.spa_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final d = widget.data;

    return OnboardingScaffold(
      currentStep: 6,
      totalSteps: 7,
      stepIcon: Icons.star,
      onBack: widget.onBack,
      onSkip: widget.onSkip,

      bottomButton: GradientButton(
        label: 'Continue',
        onTap: widget.onContinue,
      ),

      child: EntranceAnimator(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // TITLE
              RichText(
                text: const TextSpan(
                  style: AppText.title,
                  children: [
                    TextSpan(text: 'Personalize\n'),
                    TextSpan(
                      text: 'Your AI Assistant ',
                      style: AppText.titleAccent,
                    ),
                    TextSpan(
                      text: '\u2728',
                      style: AppText.titleAccent,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Help our AI understand what matters most to you so it can give you '
                'smarter, safer and more personalized suggestions.',
                style: AppText.body,
              ),

              const SizedBox(height: 20),

              // NUTRITION FOCUS
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '1. Nutrition Focus',
                      style: AppText.sectionTitle,
                    ),

                    const Text(
                      'Select what you would like to focus on.',
                      style: AppText.sectionSubtitle,
                    ),

                    const SizedBox(height: 12),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: focusOptions.length,

                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,

                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,

                        // FIXED:
                        // Lower ratio = taller cards
                        childAspectRatio: 0.95,
                      ),

                      itemBuilder: (_, i) {
                        final (title, subtitle, icon) = focusOptions[i];

                        final selected =
                            d.nutritionFocus.contains(title);

                        return OptionCard(
                          icon: icon,
                          title: title,
                          subtitle: subtitle,
                          selected: selected,

                          onTap: () {
                            setState(() {
                              if (selected) {
                                d.nutritionFocus.remove(title);
                              } else {
                                d.nutritionFocus.add(title);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              // PRODUCT ALERTS
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '2. Product Alerts',
                      style: AppText.sectionTitle,
                    ),

                    const Text(
                      'Get notified about what matters.',
                      style: AppText.sectionSubtitle,
                    ),

                    const SizedBox(height: 4),

                    ...d.productAlerts.keys.map(
                      (k) => ToggleRow(
                        label: k,
                        value: d.productAlerts[k]!,
                        onChanged: (v) {
                          setState(() {
                            d.productAlerts[k] = v;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // AI FEATURES
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '3. AI Features',
                      style: AppText.sectionTitle,
                    ),

                    const Text(
                      'Enable the features you want.',
                      style: AppText.sectionSubtitle,
                    ),

                    const SizedBox(height: 4),

                    ...d.aiFeatures.keys.map(
                      (k) => ToggleRow(
                        label: k,
                        value: d.aiFeatures[k]!,
                        onChanged: (v) {
                          setState(() {
                            d.aiFeatures[k] = v;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // BOTTOM INFORMATION
              Row(
                children: const [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: AppColors.primaryPurple,
                  ),

                  SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      'The more you personalize, the better our AI can serve you! '
                      'You can always update these preferences later in Settings.',
                      style: AppText.sectionSubtitle,
                    ),
                  ),
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