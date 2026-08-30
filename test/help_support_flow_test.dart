import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/features/profile/profile_screen.dart';
import 'package:diet_compass/features/profile/help_support_screen.dart';
import 'package:diet_compass/features/profile/help_guide_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Help & Support Screen Flow Tests', () {
    testWidgets('HelpSupportScreen renders all sections, quick help cards, FAQs, contact and app info', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: HelpSupportScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      // Header
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text("We're here to help you"), findsOneWidget);

      // Section 1: Quick Help
      expect(find.text('How can we help?'), findsOneWidget);
      expect(find.text('Getting Started'), findsOneWidget);
      expect(find.text('Learn how to use DietCompass'), findsOneWidget);
      expect(find.text('Scanning Products'), findsOneWidget);
      expect(find.text('Learn how to scan and analyze food products'), findsOneWidget);
      expect(find.text('Understanding Results'), findsOneWidget);
      expect(find.text('Learn how DietCompass analyzes ingredients and nutrition'), findsOneWidget);
      expect(find.text('Recipes & Recommendations'), findsOneWidget);
      expect(find.text('Get help with recipes and personalized recommendations'), findsOneWidget);

      // Section 2: FAQ
      expect(find.text('Frequently Asked Questions'), findsOneWidget);
      expect(find.text('How does DietCompass analyze a food product?'), findsOneWidget);
      expect(find.text('How do I scan a product?'), findsOneWidget);
      expect(find.text('Where can I see my scan history?'), findsOneWidget);
      expect(find.text('How are my dietary preferences used?'), findsOneWidget);
      expect(find.text('How do I save a recipe?'), findsOneWidget);
      expect(find.text('How do I change my profile information?'), findsOneWidget);
      expect(find.text('How do I protect my account?'), findsOneWidget);

      // Section 3: Contact Us
      expect(find.text('Contact Us'), findsOneWidget);
      expect(find.text('Email Support'), findsOneWidget);
      expect(find.text('Get help from the DietCompass support team'), findsOneWidget);
      expect(find.text('Report a Problem'), findsOneWidget);
      expect(find.text("Tell us about an issue you're experiencing"), findsOneWidget);

      // Section 4: App Information
      expect(find.text('App Information'), findsOneWidget);
      expect(find.text('DietCompass'), findsOneWidget);
      expect(find.text('1.0.0 (Beta)'), findsOneWidget);
    });

    testWidgets('ProfileScreen navigates to HelpSupportScreen and returns via back button', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      final helpTile = find.text('Help & Support').first;
      await tester.ensureVisible(helpTile);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(helpTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 1500));

      // Verify HelpSupportScreen is visible
      expect(find.byType(HelpSupportScreen), findsOneWidget);
      expect(find.text('How can we help?'), findsOneWidget);

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

    testWidgets('Quick help tile navigates to HelpGuideScreen detail and returns', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: HelpSupportScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      final gettingStartedTile = find.text('Getting Started');
      await tester.tap(gettingStartedTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(HelpGuideScreen), findsOneWidget);
      expect(find.text('1. Welcome to DietCompass'), findsOneWidget);

      final backButton = find.byIcon(Icons.arrow_back_rounded);
      await tester.tap(backButton.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(HelpSupportScreen), findsOneWidget);
    });

    testWidgets('FAQ expandable tile expands and collapses on tap', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: HelpSupportScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      final faqQuestion = find.text('How does DietCompass analyze a food product?');
      await tester.tap(faqQuestion);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Answer text is visible
      expect(
        find.textContaining('When you scan a product, DietCompass identifies its barcode'),
        findsOneWidget,
      );

      // Tap again to collapse
      await tester.tap(faqQuestion);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}
