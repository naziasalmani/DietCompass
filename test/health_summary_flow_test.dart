import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/features/profile/profile_screen.dart';
import 'package:diet_compass/features/profile/health_profile_screen.dart';
import 'package:diet_compass/features/profile/dietary_preferences_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Health Summary Navigation Tests', () {
    testWidgets('Tapping "View Details" next to My Health Summary opens HealthProfileScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      final viewDetailsButton = find.text('View Details');
      expect(viewDetailsButton, findsOneWidget);

      await tester.tap(viewDetailsButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Verify HealthProfileScreen is displayed
      expect(find.byType(HealthProfileScreen), findsOneWidget);
    });

    testWidgets('Tapping Diet Type chip in Health Summary opens DietaryPreferencesScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      final dietTypeChip = find.text('Vegetarian');
      expect(dietTypeChip, findsWidgets);

      await tester.tap(dietTypeChip.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Verify DietaryPreferencesScreen is displayed
      expect(find.byType(DietaryPreferencesScreen), findsOneWidget);
    });
  });
}
