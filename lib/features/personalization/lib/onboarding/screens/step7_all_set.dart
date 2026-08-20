import 'package:flutter/material.dart';
import '../onboarding_data.dart';
import '../onboarding_theme.dart';
import '../widgets/onboarding_widgets.dart';
import '../../../../home/home_screen.dart';

class Step7AllSet extends StatelessWidget {
  final OnboardingData data;
  final VoidCallback onGetStarted;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final VoidCallback onEdit;

  const Step7AllSet({
    super.key,
    required this.data,
    required this.onGetStarted,
    required this.onBack,
    required this.onSkip,
    required this.onEdit,
  });

  static const features = [
    ('Scan & Analyze', 'food and products instantly', Icons.qr_code_scanner, Color(0xFF34C77B)),
    ('Get AI-powered', 'health scores & insights', Icons.shield_outlined, AppColors.primaryPurple),
    ('Discover healthy', 'recipes tailored for you', Icons.eco, Color(0xFF34C77B)),
    ('Shop smarter', 'with better choices', Icons.shopping_cart_outlined, AppColors.primaryPurple),
    ('Stay on track', 'with reminders & alerts', Icons.notifications_outlined, Colors.redAccent),
  ];

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 7,
      totalSteps: 7,
      stepIcon: Icons.check,
      onBack: onBack,
      onSkip: onSkip,
      bottomButton: GradientButton(
        label: 'Get Started',
        onTap: onGetStarted,
        gradient: AppColors.finalButtonGradient,
      ),
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
                    TextSpan(text: "You're all set! \u{1F389}\n"),
                    TextSpan(text: "Let's start your healthier journey", style: AppText.titleAccent),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your AI assistant is ready to guide you towards smarter food '
                'choices and better nutrition.',
                style: AppText.body,
              ),
              const SizedBox(height: 20),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: AppText.sectionTitle,
                        children: [
                          TextSpan(text: 'With '),
                          TextSpan(text: 'DietCompass', style: TextStyle(color: AppColors.primaryPurple)),
                          TextSpan(text: ', you can:'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: features.map((f) {
                        final (title, subtitle, icon, color) = f;
                        return SizedBox(
                          width: 130,
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: color.withOpacity(0.12),
                                child: Icon(icon, color: color),
                              ),
                              const SizedBox(height: 8),
                              Text(title,
                                  textAlign: TextAlign.center,
                                  style: AppText.cardLabel),
                              Text(subtitle,
                                  textAlign: TextAlign.center,
                                  style: AppText.sectionSubtitle),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Your Summary', style: AppText.sectionTitle),
                        TextButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primaryPurple),
                          label: const Text('Edit', style: TextStyle(color: AppColors.primaryPurple)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      icon: Icons.person_outline,
                      label: 'Personal Info',
                      value: '${data.age.isEmpty ? "—" : data.age} yrs, '
                          '${data.gender ?? "—"}, ${data.height.isEmpty ? "—" : data.height} cm, '
                          '${data.weight.isEmpty ? "—" : data.weight} kg',
                    ),
                    _SummaryRow(
                      icon: Icons.favorite_border,
                      label: 'Medical Conditions',
                      value: data.healthConditions.isEmpty
                          ? 'None'
                          : data.healthConditions.join(', '),
                    ),
                    _SummaryRow(
                      icon: Icons.eco_outlined,
                      label: 'Dietary Preference',
                      value: data.dietType ?? 'Not set',
                    ),
                    _SummaryRow(
                      icon: Icons.track_changes_outlined,
                      label: 'Nutrition Goals',
                      value: data.nutritionFocus.isEmpty
                          ? (data.goals.isEmpty ? 'Not set' : data.goals.join(', '))
                          : data.nutritionFocus.join(', '),
                    ),
                    _SummaryRow(
                      icon: Icons.shield_outlined,
                      label: 'Allergies',
                      value: data.allergies.isEmpty ? 'None' : data.allergies.join(', '),
                    ),
                    _SummaryRow(
                      icon: Icons.restaurant_outlined,
                      label: 'Foods You Dislike',
                      value: data.dislikedFoods.isEmpty ? 'None' : data.dislikedFoods.join(', '),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F9F1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.verified_user_outlined, color: AppColors.success),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your data is safe and secure with us.\nWe never share your personal information.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.success, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Icon(Icons.favorite, color: AppColors.primaryPurple, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Thank you for choosing DietCompass. We're excited to be part of your healthy journey!",
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

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SummaryRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.chipSelectedBg,
            child: Icon(icon, size: 16, color: AppColors.primaryPurple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.cardLabel),
                Text(value, style: AppText.sectionSubtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
