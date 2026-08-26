import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:diet_compass/core/model/food_product.dart';
import 'package:diet_compass/core/model/health_compass_data.dart';
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

  group('HealthCompassData & Dynamic Calculation Engine', () {
    test('Empty history computes zeroed/empty health compass state', () {
      final data = ScanHistoryService.instance.computeHealthCompass(customHistory: []);
      expect(data.hasScans, false);
      expect(data.averageCompatibility, isNull);
      expect(data.compatibilityLabel, 'No scans yet');
      expect(data.productsAnalyzed, 0);
      expect(data.ingredientsFlagged, 0);
      expect(data.betterAlternatives, 0);
      expect(data.scansThisWeek, 0);
    });

    test('Single scan calculates real score, flagged ingredients and scans this week', () {
      final scan = ScanHistoryItem(
        id: 'scan_1',
        userId: 'user_a',
        barcode: '7622201497991',
        productName: 'Cadbury Dairy Milk',
        brand: 'Cadbury',
        score: 92,
        ingredients: 'Sugar, Cocoa Butter, Milk Solids, Emulsifiers (E442, E476)',
        allergens: const ['Milk'],
        nutrients: const {'sugar': 57.0, 'sodium': 120.0},
        scannedAt: DateTime.now(),
      );

      final data = ScanHistoryService.instance.computeHealthCompass(customHistory: [scan]);
      expect(data.hasScans, true);
      expect(data.averageCompatibility, 92);
      expect(data.compatibilityLabel, 'Excellent');
      expect(data.productsAnalyzed, 1);
      expect(data.scansThisWeek, 1);
      // Ingredients flagged should include sugar, milk allergen, etc.
      expect(data.ingredientsFlagged, greaterThan(0));
    });

    test('Multiple scans calculates exact arithmetic average and deduplicates products and flagged ingredients', () {
      final now = DateTime.now();
      final scans = [
        ScanHistoryItem(
          id: 'scan_1',
          userId: 'user_a',
          barcode: '111',
          productName: 'Quaker Oats',
          brand: 'Quaker',
          score: 90,
          ingredients: 'Whole Grain Rolled Oats',
          allergens: const [],
          nutrients: const {'fiber': 10.0, 'sugar': 1.0},
          scannedAt: now.subtract(const Duration(days: 1)),
        ),
        ScanHistoryItem(
          id: 'scan_2',
          userId: 'user_a',
          barcode: '222',
          productName: 'Pepsi Black',
          brand: 'PepsiCo',
          score: 80,
          ingredients: 'Carbonated Water, Caramel Color, Aspartame, Acesulfame Potassium, Phosphoric Acid',
          allergens: const [],
          nutrients: const {'sugar': 0.0, 'sodium': 20.0},
          scannedAt: now.subtract(const Duration(days: 2)),
        ),
        ScanHistoryItem(
          id: 'scan_3',
          userId: 'user_a',
          barcode: '333',
          productName: 'Lay\'s Potato Chips',
          brand: 'Lay\'s',
          score: 85,
          ingredients: 'Potatoes, Edible Vegetable Oil, Salt, TBHQ',
          allergens: const [],
          nutrients: const {'sodium': 550.0},
          scannedAt: now.subtract(const Duration(days: 3)),
        ),
        ScanHistoryItem(
          id: 'scan_4',
          userId: 'user_a',
          barcode: '444',
          productName: 'Maggi 2-Minute Noodles',
          brand: 'Nestle',
          score: 81,
          ingredients: 'Wheat Flour, Palm Oil, Salt, Hydrolysed Groundnut Protein, Sugar',
          allergens: const ['Gluten', 'Peanut'],
          nutrients: const {'sodium': 820.0},
          scannedAt: now.subtract(const Duration(days: 4)),
        ),
        // Scan older than 7 days
        ScanHistoryItem(
          id: 'scan_old',
          userId: 'user_a',
          barcode: '555',
          productName: 'Amul Butter',
          brand: 'Amul',
          score: 75,
          ingredients: 'Butter, Salt',
          allergens: const ['Milk'],
          nutrients: const {'sodium': 800.0},
          scannedAt: now.subtract(const Duration(days: 10)),
        ),
      ];

      final data = ScanHistoryService.instance.computeHealthCompass(customHistory: scans);
      // (90 + 80 + 85 + 81 + 75) / 5 = 411 / 5 = 82.2 -> 82
      expect(data.averageCompatibility, 82);
      expect(data.compatibilityLabel, 'Good');
      expect(data.productsAnalyzed, 5);
      // Only 4 scans occurred within last 7 days
      expect(data.scansThisWeek, 4);
      expect(data.ingredientsFlagged, greaterThan(0));
    });

    test('Rating label thresholds follow specified standards', () {
      final d1 = HealthCompassData(averageCompatibility: 95, productsAnalyzed: 1, ingredientsFlagged: 0, betterAlternatives: 0, scansThisWeek: 1);
      expect(d1.compatibilityLabel, 'Excellent');

      final d2 = HealthCompassData(averageCompatibility: 84, productsAnalyzed: 1, ingredientsFlagged: 0, betterAlternatives: 0, scansThisWeek: 1);
      expect(d2.compatibilityLabel, 'Good');

      final d3 = HealthCompassData(averageCompatibility: 68, productsAnalyzed: 1, ingredientsFlagged: 0, betterAlternatives: 0, scansThisWeek: 1);
      expect(d3.compatibilityLabel, 'Fair');

      final d4 = HealthCompassData(averageCompatibility: 52, productsAnalyzed: 1, ingredientsFlagged: 0, betterAlternatives: 0, scansThisWeek: 1);
      expect(d4.compatibilityLabel, 'Needs Attention');

      final dEmpty = HealthCompassData.empty();
      expect(dEmpty.compatibilityLabel, 'No scans yet');
    });

    test('User session isolation: clearing cache resets stats to empty', () {
      ScanHistoryService.instance.clearCache();
      final data = ScanHistoryService.instance.computeHealthCompass();
      expect(data.hasScans, false);
      expect(data.productsAnalyzed, 0);
    });
  });

  group('HomeScreen Your Health Compass Rendering', () {
    testWidgets('renders empty state for brand new user with no scans', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      ScanHistoryService.instance.clearCache();

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            healthCompassData: HealthCompassData.empty(),
            recentScans: const [],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.text('YOUR HEALTH COMPASS'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains('--') &&
              w.text.toPlainText().contains('100'),
        ),
        findsOneWidget,
      );
      expect(find.text('Average Compatibility'), findsOneWidget);
      expect(find.text('No scans yet'), findsOneWidget);
      expect(find.text('Start scanning products to build your health insights.'), findsOneWidget);
      expect(find.text('0'), findsNWidgets(4)); // 4 metric tiles showing 0
      expect(find.text('Products\nAnalyzed'), findsOneWidget);
      expect(find.text('Ingredients\nFlagged'), findsOneWidget);
      expect(find.text('Better\nAlternatives'), findsOneWidget);
      expect(find.text('Scans\nThis Week'), findsOneWidget);

      // Confirm old "Today's Nutrition Score" and hardcoded macros are NOT present
      expect(find.text("Today's Nutrition Score"), findsNothing);
      expect(find.text('Calories'), findsNothing);
      expect(find.text('Protein'), findsNothing);
      expect(find.text('Fiber'), findsNothing);
      expect(find.text('Sugar'), findsNothing);
      expect(find.text('Water'), findsNothing);
      expect(find.text('Sodium'), findsNothing);
    });

    testWidgets('renders real dynamic metrics when user has scan history', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const customData = HealthCompassData(
        averageCompatibility: 84,
        productsAnalyzed: 12,
        ingredientsFlagged: 7,
        betterAlternatives: 9,
        scansThisWeek: 6,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(
            healthCompassData: customData,
            recentScans: [],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.text('YOUR HEALTH COMPASS'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains('84') &&
              w.text.toPlainText().contains('100'),
        ),
        findsOneWidget,
      );
      expect(find.text('Average Compatibility'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('Products\nAnalyzed'), findsOneWidget);
      expect(find.text('Ingredients\nFlagged'), findsOneWidget);
      expect(find.text('Better\nAlternatives'), findsOneWidget);
      expect(find.text('Scans\nThis Week'), findsOneWidget);
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
