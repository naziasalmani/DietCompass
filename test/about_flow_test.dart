import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/features/profile/profile_screen.dart';
import 'package:diet_compass/features/profile/about_screen.dart';
import 'package:diet_compass/features/profile/help_support_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('About DietCompass Screen Flow Tests', () {
    testWidgets('AboutScreen renders header, logo, description, features, info, and footer properly', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AboutScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      // Header
      expect(find.text('About DietCompass'), findsWidgets);
      expect(find.text('Scan. Analyze. Eat Better.'), findsOneWidget);

      // Logo & Tagline
      expect(find.text('Scan. Analyze. Eat Better. Live Healthier.'), findsOneWidget);
      expect(find.text('Version 1.0.0 (Beta)'), findsOneWidget);

      // Description
      expect(
        find.textContaining('DietCompass helps you make smarter food choices by scanning food products'),
        findsOneWidget,
      );

      // Features
      expect(find.text('What DietCompass Does'), findsOneWidget);
      expect(find.text('Scan & Analyze'), findsOneWidget);
      expect(find.text('Personalized Nutrition'), findsOneWidget);
      expect(find.text('Smart Recipes'), findsOneWidget);
      expect(find.text('Food History'), findsOneWidget);

      // App Information
      expect(find.text('App Information'), findsOneWidget);
      expect(find.text('App Name'), findsOneWidget);
      expect(find.text('Release Channel'), findsOneWidget);
      expect(find.text('Platform'), findsOneWidget);

      // Resources
      expect(find.text('Resources & Legal'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);

      // Footer
      expect(find.text('Made with ❤️ for healthier choices'), findsOneWidget);
    });

    testWidgets('ProfileScreen navigates to AboutScreen and returns via back button', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      final aboutTile = find.text('About DietCompass').first;
      await tester.ensureVisible(aboutTile);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(aboutTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 1500));

      // Verify AboutScreen is displayed
      expect(find.byType(AboutScreen), findsOneWidget);
      expect(find.text('What DietCompass Does'), findsOneWidget);

      // Tap back button
      final backButton = find.byIcon(Icons.arrow_back_rounded);
      expect(backButton, findsWidgets);
      await tester.tap(backButton.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 1500));

      // Verify returned to ProfileScreen
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('AboutScreen navigates to HelpSupportScreen when tapping Help & Support link', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AboutScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      final helpLink = find.text('Help & Support');
      await tester.tap(helpLink);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(HelpSupportScreen), findsOneWidget);
    });

    testWidgets('AboutScreen opens Privacy Policy dialog when tapping Privacy Policy link', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AboutScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      final privacyLink = find.text('Privacy Policy');
      await tester.tap(privacyLink);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Manage Privacy'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
