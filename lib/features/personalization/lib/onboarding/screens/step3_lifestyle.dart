import 'package:flutter/material.dart';
import '../onboarding_data.dart';
import '../onboarding_theme.dart';
import '../widgets/onboarding_widgets.dart';

class Step3Lifestyle extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  const Step3Lifestyle({
    super.key,
    required this.data,
    required this.onContinue,
    required this.onBack,
    required this.onSkip,
  });

  @override
  State<Step3Lifestyle> createState() => _Step3LifestyleState();
}

class _Step3LifestyleState extends State<Step3Lifestyle> {
  static const activityLevels = [
    (
      'Sedentary',
      'Little or no\nexercise',
      Icons.weekend_outlined,
    ),
    (
      'Lightly Active',
      'Light exercise\n1-3 days/week',
      Icons.directions_walk,
    ),
    (
      'Moderately Active',
      'Moderate exercise\n3-5 days/week',
      Icons.accessibility_new,
    ),
    (
      'Very Active',
      'Hard exercise\n6-7 days/week',
      Icons.directions_run,
    ),
  ];

  static const sleepOptions = [
    ('Under 5 hrs', Icons.sentiment_dissatisfied),
    ('6-7 hrs', Icons.nightlight_round),
    ('7-8 hrs', Icons.bedtime),
    ('8+ hrs', Icons.wb_sunny_outlined),
  ];

  static const waterOptions = [
    '< 1L',
    '1 - 2L',
    '2 - 3L',
    '3L+',
  ];

  @override
  Widget build(BuildContext context) {
    final d = widget.data;

    return OnboardingScaffold(
      currentStep: 3,
      totalSteps: 7,
      stepIcon: Icons.eco,
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

              // --------------------------------------------------
              // TITLE
              // --------------------------------------------------

              RichText(
                text: const TextSpan(
                  style: AppText.title,
                  children: [
                    TextSpan(text: 'Your daily\n'),
                    TextSpan(
                      text: 'lifestyle ',
                      style: AppText.titleAccent,
                    ),
                    TextSpan(
                      text: '\u{1F343}',
                      style: AppText.titleAccent,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'This helps us understand your habits and give better, personalized recommendations.',
                style: AppText.body,
              ),

              const SizedBox(height: 20),

              // ==================================================
              // ACTIVITY LEVEL
              // ==================================================

              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Activity Level',
                      style: AppText.sectionTitle,
                    ),

                    const Text(
                      'How active are you on a regular day?',
                      style: AppText.sectionSubtitle,
                    ),

                    const SizedBox(height: 12),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activityLevels.length,

                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,

                        // Taller cards because they contain
                        // both title and subtitle.
                        childAspectRatio: 1.0,
                      ),

                      itemBuilder: (_, i) {
                        final (title, subtitle, icon) =
                            activityLevels[i];

                        return _LifestyleOptionCard(
                          icon: icon,
                          title: title,
                          subtitle: subtitle,
                          selected: d.activityLevel == title,
                          onTap: () {
                            setState(() {
                              d.activityLevel = title;
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // SLEEP
              // ==================================================

              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sleep',
                      style: AppText.sectionTitle,
                    ),

                    const Text(
                      'How many hours of sleep do you get?',
                      style: AppText.sectionSubtitle,
                    ),

                    const SizedBox(height: 12),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sleepOptions.length,

                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,

                        // Taller than the original 2.4.
                        childAspectRatio: 1.55,
                      ),

                      itemBuilder: (_, i) {
                        final (title, icon) = sleepOptions[i];

                        return _LifestyleOptionCard(
                          icon: icon,
                          title: title,
                          selected: d.sleepHours == title,
                          onTap: () {
                            setState(() {
                              d.sleepHours = title;
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // WATER INTAKE
              // ==================================================

              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Water Intake',
                      style: AppText.sectionTitle,
                    ),

                    const Text(
                      'How much water do you drink daily?',
                      style: AppText.sectionSubtitle,
                    ),

                    const SizedBox(height: 12),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: waterOptions.length,

                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,

                        // Taller cards than the original 2.4.
                        childAspectRatio: 1.55,
                      ),

                      itemBuilder: (_, i) {
                        final title = waterOptions[i];

                        return _LifestyleOptionCard(
                          icon: Icons.local_drink_outlined,
                          title: title,
                          selected: d.waterIntake == title,
                          onTap: () {
                            setState(() {
                              d.waterIntake = title;
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}


// ============================================================
// LIFESTYLE OPTION CARD
// ============================================================

class _LifestyleOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _LifestyleOptionCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),

        child: Container(
          padding: const EdgeInsets.all(12),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(18),

            border: Border.all(
              color: selected
                  ? AppColors.primaryPurple
                  : AppColors.borderLight,
              width: selected ? 2 : 1.5,
            ),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // ------------------------------------------------
              // ICON + CHECK
              // ------------------------------------------------

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Icon(
                    icon,
                    color: AppColors.primaryPurple,
                    size: 30,
                  ),

                  Container(
                    width: 24,
                    height: 24,

                    decoration: BoxDecoration(
                      shape: BoxShape.circle,

                      color: selected
                          ? AppColors.primaryPurple
                          : Colors.white,

                      border: Border.all(
                        color: selected
                            ? AppColors.primaryPurple
                            : AppColors.borderLight,
                        width: 2,
                      ),
                    ),

                    child: selected
                        ? const Icon(
                            Icons.check,
                            size: 15,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ------------------------------------------------
              // TITLE
              // ------------------------------------------------

              Text(
                title,
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  fontSize: 16,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),

              // ------------------------------------------------
              // SUBTITLE
              // ------------------------------------------------

              if (subtitle != null) ...[
                const SizedBox(height: 4),

                Expanded(
                  child: Text(
                    subtitle!,
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.2,
                      color: AppColors.textGray,
                    ),
                  ),
                ),
              ] else
                const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}