import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/features/profile/profile_screen.dart';
import 'package:diet_compass/features/profile/privacy_security_screen.dart';
import 'package:diet_compass/features/profile/password_login_screen.dart';
import 'package:diet_compass/features/profile/google_sign_in_screen.dart';
import 'package:diet_compass/features/profile/active_sessions_screen.dart';
import 'package:diet_compass/features/scan/scan_history_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Privacy & Security Screen Flow Tests', () {
    testWidgets('PrivacySecurityScreen renders all sections, cards, and items properly', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PrivacySecurityScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      // Header
      expect(find.text('Privacy & Security'), findsOneWidget);
      expect(find.text('Control your data and privacy'), findsOneWidget);

      // Overview Card
      expect(find.text('Your Privacy Matters'), findsOneWidget);
      expect(
        find.text('Your personal information and health preferences are securely stored and protected.'),
        findsOneWidget,
      );
      expect(find.text('Encrypted'), findsOneWidget);

      // Section 1: Account & Data
      expect(find.text('Account & Data'), findsOneWidget);
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Health & Dietary Data'), findsOneWidget);
      expect(find.text('Scan History'), findsOneWidget);

      // Section 2: Security
      expect(find.text('Security'), findsOneWidget);
      expect(find.text('Password & Login'), findsOneWidget);
      expect(find.text('Google Sign-In'), findsOneWidget);
      expect(find.text('Active Sessions'), findsOneWidget);

      // Section 3: Data Controls
      expect(find.text('Data Controls'), findsOneWidget);
      expect(find.text('Download My Data'), findsOneWidget);
      expect(find.text('Delete Account'), findsOneWidget);

      // Section 4: Privacy Policy
      expect(find.text('Privacy Policy'), findsOneWidget);

      // Bottom Privacy Notice
      expect(find.text('Your data is secure and 100% private'), findsOneWidget);
    });

    testWidgets('ProfileScreen navigates to PrivacySecurityScreen and back via back button', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      final privacyTile = find.text('Privacy & Security').first;
      await tester.ensureVisible(privacyTile);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(privacyTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.text('Your Privacy Matters'), findsOneWidget);
      expect(find.text('Account & Data'), findsOneWidget);
      expect(find.text('Data Controls'), findsOneWidget);

      final backButtonFinder = find.byIcon(Icons.arrow_back_rounded);
      expect(backButtonFinder, findsWidgets);
      await tester.tap(backButtonFinder.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.text('My Profile'), findsOneWidget);
    });

    testWidgets('Scan History redirects to ScanHistoryScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PrivacySecurityScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      final scanHistoryTile = find.text('Scan History');
      await tester.tap(scanHistoryTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ScanHistoryScreen), findsOneWidget);
    });

    testWidgets('Password & Login redirects to PasswordLoginScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PrivacySecurityScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      final passwordTile = find.text('Password & Login');
      await tester.tap(passwordTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(PasswordLoginScreen), findsOneWidget);
      expect(find.text('CHANGE PASSWORD'), findsOneWidget);
      expect(find.text('Update Password'), findsOneWidget);
    });

    testWidgets('Google Sign-In redirects to GoogleSignInManagementScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PrivacySecurityScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      final googleTile = find.text('Google Sign-In');
      await tester.tap(googleTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(GoogleSignInManagementScreen), findsOneWidget);
      expect(find.text('Direct Google Cloud OAuth'), findsOneWidget);
    });

    testWidgets('Active Sessions redirects to ActiveSessionsScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PrivacySecurityScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      final sessionsTile = find.text('Active Sessions');
      await tester.tap(sessionsTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ActiveSessionsScreen), findsOneWidget);
      expect(find.text('Current Device'), findsOneWidget);
      expect(find.text('Log Out From All Other Devices'), findsOneWidget);
    });

    testWidgets('Download My Data dialog opens cleanly with zero overflow and dismisses on Cancel', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PrivacySecurityScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      final downloadTile = find.text('Download My Data');
      await tester.scrollUntilVisible(downloadTile, 150);
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(downloadTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Request Export'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Download My Data dialog on narrow mobile screen (320px) renders with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PrivacySecurityScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      final downloadTile = find.text('Download My Data');
      await tester.scrollUntilVisible(downloadTile, 150);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(downloadTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Request Export'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
