import 'package:flutter/material.dart';
import '../onboarding_theme.dart';
import '../widgets/onboarding_widgets.dart';

class Step1Welcome extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onSkip;

  const Step1Welcome({
    super.key,
    required this.onGetStarted,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 1,
      totalSteps: 7,
      stepIcon: Icons.eco,
      onSkip: onSkip,

      // Keep the existing Get Started button
      bottomButton: GradientButton(
        label: 'Get Started',
        onTap: onGetStarted,
      ),

      // Only the background image remains in the main content
      child: SizedBox.expand(
        child: Image.asset(
          'assets/images/ob1.jpeg',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}