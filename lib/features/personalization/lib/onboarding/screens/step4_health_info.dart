import 'package:flutter/material.dart';
import '../onboarding_data.dart';
import '../onboarding_theme.dart';
import '../widgets/onboarding_widgets.dart';

class Step4HealthInfo extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  const Step4HealthInfo({
    super.key,
    required this.data,
    required this.onContinue,
    required this.onBack,
    required this.onSkip,
  });

  @override
  State<Step4HealthInfo> createState() => _Step4HealthInfoState();
}

class _Step4HealthInfoState extends State<Step4HealthInfo> {
  static const conditions = [
    ('Diabetes', Icons.water_drop_outlined),
    ('High Blood Pressure', Icons.favorite_border),
    ('High Cholesterol', Icons.opacity),
    ('Thyroid', Icons.brightness_1_outlined),
    ('PCOS', Icons.female),
    ('Heart Disease', Icons.favorite),
    ('Kidney Disease', Icons.bubble_chart_outlined),
    ('Fatty Liver', Icons.local_hospital_outlined),
    ('Digestive Issues', Icons.sick_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final none = d.healthConditions.contains('None of the above');
    return OnboardingScaffold(
      currentStep: 4,
      totalSteps: 7,
      stepIcon: Icons.health_and_safety,
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
                    TextSpan(text: 'Health\n'),
                    TextSpan(text: 'Information ', style: AppText.titleAccent),
                    TextSpan(text: '\u{1F6E1}', style: AppText.titleAccent),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Help us know your medical history so we can provide safer and more accurate recommendations.',
                style: AppText.body,
              ),
              const SizedBox(height: 20),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Do you have any of the following?', style: AppText.sectionTitle),
                    const Text('Select all that apply', style: AppText.sectionSubtitle),
                    const SizedBox(height: 12),
                    GridView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: conditions.length + 1,
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 1.40,
  ),
  itemBuilder: (_, i) {
    // Last card = None of the above
    if (i == conditions.length) {
      return OptionCard(
        icon: Icons.verified_user_outlined,
        iconColor: AppColors.success,
        title: 'None of the above',
        selected: none,
        onTap: () => setState(() {
          if (none) {
            d.healthConditions.remove('None of the above');
          } else {
            d.healthConditions
              ..clear()
              ..add('None of the above');
          }
        }),
      );
    }

    final (title, icon) = conditions[i];

    return OptionCard(
      icon: icon,
      title: title,
      selected: d.healthConditions.contains(title),
      onTap: () => setState(() {
        d.healthConditions.remove('None of the above');

        if (!d.healthConditions.remove(title)) {
          d.healthConditions.add(title);
        }
      }),
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
                    const Text('Are you pregnant or breastfeeding?', style: AppText.sectionTitle),
                    const Text('This helps us provide the right nutrition guidance.',
                        style: AppText.sectionSubtitle),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OptionCard(
                            icon: Icons.pregnant_woman,
                            title: 'Yes',
                            selected: d.pregnantOrBreastfeeding == true,
                            multiSelect: false,
                            onTap: () => setState(() => d.pregnantOrBreastfeeding = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OptionCard(
                            icon: Icons.child_friendly,
                            title: 'No',
                            selected: d.pregnantOrBreastfeeding == false,
                            multiSelect: false,
                            onTap: () => setState(() => d.pregnantOrBreastfeeding = false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: const [
                  Icon(Icons.shield_outlined, size: 16, color: AppColors.primaryPurple),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your health information is 100% private and secure. We never share it with anyone.',
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
