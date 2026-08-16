import 'package:flutter/material.dart';
import 'onboarding/onboarding_flow.dart';

/// Standalone demo entry point — run this to preview the onboarding flow
/// on its own (e.g. `flutter run -t lib/main_demo.dart`).
/// In your real app, just navigate to `OnboardingFlow()` from wherever
/// your splash/auth check currently sends first-time users.
void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DietCompass Onboarding',
      theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
      home: OnboardingFlow(
        onComplete: (data) {
          // TODO: persist `data` and navigate to your home_screen.dart
          debugPrint('Onboarding complete: '
              'name=${data.fullName}, goals=${data.goals}, diet=${data.dietType}');
        },
      ),
    );
  }
}
