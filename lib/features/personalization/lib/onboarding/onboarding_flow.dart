import 'package:flutter/material.dart';
import '../../../home/home_screen.dart';
import 'onboarding_data.dart';
import 'screens/step1_welcome.dart';
import 'screens/step2_personal_info.dart';
import 'screens/step3_lifestyle.dart';
import 'screens/step4_health_info.dart';
import 'screens/step5_food_preferences.dart';
import 'screens/step6_personalize_ai.dart';
import 'screens/step7_all_set.dart';

/// Drop this widget in as your onboarding route, e.g.:
///
/// ```dart
/// MaterialPageRoute(builder: (_) => const OnboardingFlow())
/// ```
///
/// It manages a 7-step [PageView], keeps one [OnboardingData] instance for
/// the whole flow, and calls [onComplete] with the collected data once the
/// user taps "Get Started" on the final summary screen.
class OnboardingFlow extends StatefulWidget {
  final ValueChanged<OnboardingData>? onComplete;
  final VoidCallback? onSkipAll;

  const OnboardingFlow({super.key, this.onComplete, this.onSkipAll});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  final OnboardingData _data = OnboardingData();
  int _currentPage = 0;
  static const int totalPages = 7;

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  void _next() {
    if (_currentPage < totalPages - 1) {
      _goToPage(_currentPage + 1);
    } else {
      widget.onComplete?.call(_data);
    }
  }

  void _back() {
    if (_currentPage > 0) _goToPage(_currentPage - 1);
  }

  void _skip() {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const HomeScreen(),
    ),
  );
}

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // navigation via buttons only
        onPageChanged: (i) => setState(() => _currentPage = i),
        children: [
          Step1Welcome(onGetStarted: _next, onSkip: _skip),
          Step2PersonalInfo(data: _data, onContinue: _next, onBack: _back, onSkip: _skip),
          Step3Lifestyle(data: _data, onContinue: _next, onBack: _back, onSkip: _skip),
          Step4HealthInfo(data: _data, onContinue: _next, onBack: _back, onSkip: _skip),
          Step5FoodPreferences(data: _data, onContinue: _next, onBack: _back, onSkip: _skip),
          Step6PersonalizeAI(data: _data, onContinue: _next, onBack: _back, onSkip: _skip),
          Step7AllSet(
            data: _data,
            onGetStarted: _next,
            onBack: _back,
            onSkip: _skip,
            onEdit: () => _goToPage(1),
          ),
        ],
      ),
    );
  }
}
