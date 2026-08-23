import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:diet_compass/core/model/food_product.dart';
import 'package:diet_compass/core/model/scan_history_item.dart';
import 'package:diet_compass/core/services/scan_history_service.dart';
import 'package:diet_compass/features/home/home_screen.dart';
import 'package:diet_compass/features/scan/scan_history_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('ScanHistoryItem Model', () {
    test('converts from and to JSON properly', () {
      final json = {
        '_id': 'scan_123',
        'userId': 'user_abc',
        'barcode': '8901234567890',
        'productName': 'Cadbury Dairy Milk Silk',
        'brand': 'Cadbury',
        'imageUrl': 'https://example.com/dairy_milk.jpg',
        'score': 85,
        'ingredients': 'Sugar, Cocoa Butter, Milk Solids',
        'allergens': ['Milk', 'Soy'],
        'nutrients': {'calories': 534, 'protein': 7.3, 'sugar': 57.0},
        'scannedAt': '2026-08-23T10:30:00.000Z',
      };

      final item = ScanHistoryItem.fromJson(json);
      expect(item.id, 'scan_123');
      expect(item.userId, 'user_abc');
      expect(item.barcode, '8901234567890');
      expect(item.productName, 'Cadbury Dairy Milk Silk');
      expect(item.brand, 'Cadbury');
      expect(item.imageUrl, 'https://example.com/dairy_milk.jpg');
      expect(item.score, 85);
      expect(item.ingredients, 'Sugar, Cocoa Butter, Milk Solids');
      expect(item.allergens, ['Milk', 'Soy']);
      expect(item.nutrients['calories'], 534);

      final foodProduct = item.toFoodProduct();
      expect(foodProduct.barcode, '8901234567890');
      expect(foodProduct.name, 'Cadbury Dairy Milk Silk');
      expect(foodProduct.brand, 'Cadbury');
      expect(foodProduct.imageUrl, 'https://example.com/dairy_milk.jpg');
      expect(foodProduct.ingredients, 'Sugar, Cocoa Butter, Milk Solids');
      expect(foodProduct.allergens, ['Milk', 'Soy']);
      expect(foodProduct.calories, 534.0);
    });

    test('RecentScan.fromHistoryItem maps properly', () {
      final item = ScanHistoryItem(
        id: 'scan_1',
        userId: 'u1',
        barcode: '123456',
        productName: 'Maggi Noodles',
        brand: 'Nestle',
        imageUrl: 'https://example.com/maggi.png',
        score: 78,
        ingredients: 'Wheat flour, Palm oil',
        allergens: const ['Gluten'],
        nutrients: const {},
        scannedAt: DateTime.now(),
      );

      final recent = RecentScan.fromHistoryItem(item);
      expect(recent.name, 'Maggi Noodles');
      expect(recent.score, 78);
      expect(recent.asset, 'https://example.com/maggi.png');
      expect(recent.barcode, '123456');
      expect(recent.brand, 'Nestle');

      final prod = recent.toFoodProduct();
      expect(prod.name, 'Maggi Noodles');
      expect(prod.brand, 'Nestle');
    });
  });

  group('ScanHistoryService cache operations', () {
    test('clearCache resets in-memory history', () {
      ScanHistoryService.instance.clearCache();
      expect(ScanHistoryService.instance.currentHistory, isEmpty);
    });
  });

  group('HomeScreen Recent Scans Rendering', () {
    testWidgets('renders empty state when scan history is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(
            recentScans: [],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.scrollUntilVisible(
        find.text('Recent Scans'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Recent Scans'), findsOneWidget);
      expect(find.text('No scans yet'), findsOneWidget);
      expect(find.text('Scan a product to see your scan history here.'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
    });

    testWidgets('renders real items when populated', (tester) async {
      final scans = [
        const RecentScan(
          name: 'Cadbury Dairy Milk',
          time: 'Just now',
          score: 85,
          asset: '',
          brand: 'Cadbury',
        ),
        const RecentScan(
          name: 'Pepsi Black',
          time: 'Today, 10:00 AM',
          score: 65,
          asset: '',
          brand: 'PepsiCo',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            recentScans: scans,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.scrollUntilVisible(
        find.text('Recent Scans'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Recent Scans'), findsOneWidget);
      expect(find.text('Cadbury Dairy Milk'), findsOneWidget);
      expect(find.text('Pepsi Black'), findsOneWidget);
      expect(find.text('85/100'), findsOneWidget);
      expect(find.text('65/100'), findsOneWidget);
    });
  });

  group('ScanHistoryScreen Widget', () {
    testWidgets('renders scan history screen and empty state', (tester) async {
      ScanHistoryService.instance.clearCache();
      await tester.pumpWidget(
        const MaterialApp(
          home: ScanHistoryScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('All Scans'), findsOneWidget);
      expect(find.text('No scans yet'), findsOneWidget);
    });
  });
}
