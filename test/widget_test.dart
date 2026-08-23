import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/features/login/login_screen.dart';
import 'package:diet_compass/features/splash/splash_screen.dart';
import 'package:diet_compass/main.dart';

void main() {
  testWidgets('DietCompass app launches splash screen', (tester) async {
    await tester.pumpWidget(const DietCompassApp());
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Preparing your personalized experience...'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
  });

  testWidgets('Login form validates email and password format', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.enterText(find.byType(TextFormField).at(0), 'invalid-email');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.ensureVisible(find.text('Login'));
    await tester.pump();
    await tester.tap(find.text('Login'));
    await tester.pump();

    expect(find.text('Enter a valid email, username, or phone number'), findsOneWidget);
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
  });
}
