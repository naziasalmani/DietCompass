import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:diet_compass/features/scan/camera_scan_screen.dart';
import 'package:diet_compass/features/scan/scan_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('ScanMode & CameraScanScreen Mode Tests', () {
    testWidgets('1. Scan Product (default mode) displays default Scan Product title and tip',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CameraScanScreen(
            source: CameraSource.scan,
            initialMode: ScanMode.product,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Scan Product'), findsWidgets);
      expect(find.text('Get AI-powered nutrition insights'), findsWidgets);
      expect(
        find.byWidgetPredicate((w) =>
            w is RichText &&
            w.text.toPlainText().contains('Center the product label in the frame')),
        findsWidgets,
      );
      expect(find.text('Make sure the text is clear and well-lit.'), findsWidgets);
    });

    testWidgets('2. Scan Barcode mode displays Scan Barcode title and barcode guidance',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CameraScanScreen(
            source: CameraSource.scan,
            initialMode: ScanMode.barcode,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Scan Barcode'), findsWidgets);
      expect(find.text('Align barcode within the frame'), findsWidgets);
      expect(
        find.byWidgetPredicate((w) =>
            w is RichText &&
            w.text.toPlainText().contains('Place the barcode inside the frame')),
        findsWidgets,
      );
      expect(find.text('Make sure the barcode is clear, flat, and well-lit.'),
          findsWidgets);
    });

    testWidgets('3. Scan Nutrition Label mode displays Scan Nutrition Label title and OCR guidance',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CameraScanScreen(
            source: CameraSource.scan,
            initialMode: ScanMode.ocr,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Scan Nutrition Label'), findsWidgets);
      expect(find.text('Capture nutrition facts or ingredients'), findsWidgets);
      expect(
        find.byWidgetPredicate((w) =>
            w is RichText &&
            w.text.toPlainText().contains('Center the nutrition label inside the frame')),
        findsWidgets,
      );
      expect(
          find.text('Ensure numbers and ingredients are sharp and well-lit.'),
          findsWidgets);
    });

    testWidgets('4. ScanScreen renders Scan Product, Scan Barcode, and Scan Nutrition Label buttons',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ScanScreen(userName: 'Test User'),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 1000));

      // Scan Product CTA
      expect(find.text('Scan Product'), findsWidgets);

      // Quick action cards
      expect(find.text('Scan Barcode'), findsWidgets);
      expect(find.textContaining('Scan Nutrition'), findsWidgets);
    });
  });
}
