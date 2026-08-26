import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:diet_compass/features/profile/notifications_screen.dart';
import 'package:diet_compass/features/profile/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('DietCompass Notifications Flow Tests', () {
    testWidgets('1. NotificationsScreen renders notifications feed with alerts',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: NotificationsScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Notifications'), findsWidgets);
      expect(find.textContaining('new'), findsWidgets);
      expect(find.text('Alerts'), findsWidgets);
      expect(find.text('Preferences'), findsWidgets);

      // Verify sample notifications
      expect(find.textContaining('Daily Streak Milestone'), findsWidgets);
      expect(find.textContaining('Personalized AI Insight'), findsWidgets);
      expect(find.textContaining('New High-Protein Recipe Found'), findsWidgets);
    });

    testWidgets('2. NotificationsScreen Preferences tab renders notification controls',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: NotificationsScreen(initialTab: 1),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('General Notification Controls'), findsWidgets);
      expect(find.text('Push Notifications'), findsWidgets);
      expect(find.text('Reminders & Schedules'), findsWidgets);
      expect(find.text('Meal & Hydration Reminders'), findsWidgets);
    });

    testWidgets('3. ProfileScreen notification bell navigates to NotificationsScreen',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Find notification bell icon button
      final bellFinder = find.byIcon(Icons.notifications_none_rounded).first;
      expect(bellFinder, findsOneWidget);

      await tester.tap(bellFinder);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(NotificationsScreen), findsOneWidget);
      expect(find.text('Notifications'), findsWidgets);
    });

    testWidgets('4. ProfileScreen Notifications menu tile navigates to NotificationsScreen preferences',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Scroll down to reveal menu tile
      await tester.drag(find.byType(ListView).first, const Offset(0, -600));
      await tester.pump(const Duration(milliseconds: 300));

      // Find the Notifications menu tile
      final tileFinder = find.text('Manage your notification settings');
      expect(tileFinder, findsOneWidget);

      await tester.tap(tileFinder);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(NotificationsScreen), findsOneWidget);
      expect(find.text('Push Notifications'), findsWidgets);
    });
  });
}
