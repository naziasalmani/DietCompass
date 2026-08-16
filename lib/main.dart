import 'package:flutter/material.dart';

import 'features/onboarding/onboarding_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/login/login_screen.dart';
import 'features/signup/sign_up_screen.dart';
import 'features/forgot_password/forgot_password_screen.dart';
import 'features/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DietCompassApp());
}

class DietCompassApp extends StatelessWidget {
  const DietCompassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DietCompass',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6C4EF5),
        fontFamily: 'Roboto',
      ),
      home: const AppFlow(),
    );
  }
}

class AppFlow extends StatelessWidget {
  const AppFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (appContext) {
        return SplashScreen(
          onFinished: () {
            Navigator.pushReplacement(
              appContext,
              MaterialPageRoute(
                builder: (_) => OnboardingScreen(
  onComplete: () {},
),
              ),
            );
          },
        );
      },
    );
  }
}