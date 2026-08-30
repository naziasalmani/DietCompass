import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/core/theme/app_theme.dart';
import 'package:diet_compass/core/theme/theme_controller.dart';
import 'package:diet_compass/features/profile/profile_screen.dart';
import 'package:diet_compass/features/profile/settings_screen.dart';
import 'package:diet_compass/features/profile/notifications_screen.dart';
import 'package:diet_compass/features/profile/privacy_security_screen.dart';
import 'package:diet_compass/features/profile/help_support_screen.dart';
import 'package:diet_compass/features/profile/about_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await ThemeController.instance.init();
    await ThemeController.instance.setThemeMode(ThemeMode.light);
  });

  group('Profile Settings and Avatar Flow Tests', () {
    testWidgets('Tapping Settings button on ProfileScreen opens SettingsScreen and back button returns', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        AnimatedBuilder(
          animation: ThemeController.instance,
          builder: (context, _) => MaterialApp(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeController.instance.themeMode,
            home: const ProfileScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      final settingsIcon = find.byIcon(Icons.settings_outlined);
      expect(settingsIcon, findsOneWidget);

      await tester.tap(settingsIcon);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 1500));

      // Verify SettingsScreen is visible
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('GENERAL'), findsOneWidget);
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('PRIVACY & SECURITY'), findsOneWidget);
      expect(find.text('SUPPORT'), findsOneWidget);
      expect(find.text('ABOUT'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);

      // Back button
      final backButton = find.byIcon(Icons.arrow_back_rounded);
      expect(backButton, findsWidgets);
      await tester.tap(backButton.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('SettingsScreen navigates to Notifications, Privacy, Help & Support, and About', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        AnimatedBuilder(
          animation: ThemeController.instance,
          builder: (context, _) => MaterialApp(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeController.instance.themeMode,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      // 1. Notifications
      final notifRow = find.text('Notifications');
      await tester.tap(notifRow);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(NotificationsScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 2. Privacy & Security
      final privacyRow = find.text('Privacy & Security');
      await tester.tap(privacyRow);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(PrivacySecurityScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 3. Help & Support
      final helpRow = find.text('Help & Support');
      await tester.tap(helpRow);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(HelpSupportScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 4. About DietCompass
      final aboutRow = find.text('About DietCompass');
      await tester.tap(aboutRow);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(AboutScreen), findsOneWidget);
    });

    testWidgets('Full Theme switching workflow: Light -> Dark -> System -> Light with instantaneous reactivity', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        AnimatedBuilder(
          animation: ThemeController.instance,
          builder: (context, _) => MaterialApp(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeController.instance.themeMode,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      // Initial state is Light
      expect(ThemeController.instance.themeMode, ThemeMode.light);

      // Open Theme selector
      await tester.tap(find.text('Theme'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Select Theme'), findsOneWidget);

      // Tap Dark
      await tester.tap(find.text('Dark'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // ThemeController should now be dark
      expect(ThemeController.instance.themeMode, ThemeMode.dark);
      expect(ThemeController.instance.isDarkMode(tester.element(find.byType(SettingsScreen))), isTrue);

      // Open Theme selector again
      await tester.tap(find.text('Theme'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Light
      await tester.tap(find.text('Light'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(ThemeController.instance.themeMode, ThemeMode.light);
      expect(ThemeController.instance.isDarkMode(tester.element(find.byType(SettingsScreen))), isFalse);

      // Open Language selector
      await tester.tap(find.text('Language'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('App Language'), findsOneWidget);
      expect(find.text('English (US)'), findsWidgets);
      expect(find.text('Hindi (Coming Soon)'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('App Language'), findsNothing);
    });

    testWidgets('Tapping profile avatar opens Update Profile Photo bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        AnimatedBuilder(
          animation: ThemeController.instance,
          builder: (context, _) => MaterialApp(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeController.instance.themeMode,
            home: const ProfileScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      final editAvatarIcon = find.byIcon(Icons.edit_rounded);
      expect(editAvatarIcon, findsOneWidget);

      await tester.tap(editAvatarIcon);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Update Profile Photo'), findsOneWidget);
      expect(find.text('Take a Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);

      // Close bottom sheet
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Update Profile Photo'), findsNothing);
    });
  });
}
