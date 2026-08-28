import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:diet_compass/core/model/food_product.dart';
import 'package:diet_compass/core/model/pantry_category.dart';
import 'package:diet_compass/core/services/pantry_category_service.dart';
import 'package:diet_compass/core/services/pantry_storage_service.dart';
import 'package:diet_compass/features/pantry/pantry_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('DietCompass Pantry Category & Classification Tests', () {
    final classifier = PantryCategoryService.instance;

    test('1. All mandatory acceptance test products classify to exact expected categories', () {
      final testCases = <Map<String, dynamic>>[
        {
          'product': FoodProduct(
            barcode: '111',
            name: 'Lay\'s Salted Chips',
            brand: 'Lay\'s',
            imageUrl: '',
            ingredients: 'Potatoes, Edible Vegetable Oil, Salt',
            allergens: const [],
            calories: 540,
            protein: 7,
            carbohydrates: 52,
            fat: 34,
            fiber: 4,
            sugar: 0.5,
            sodium: 500,
          ),
          'expected': PantryCategory.snacks,
        },
        {
          'product': FoodProduct(
            barcode: '8901491101837',
            name: 'West Indies\' Hot \'n\' Sweet Chilli',
            brand: 'Lay\'s',
            imageUrl: '',
            ingredients: 'Potato, edible vegetable oil, sugar, spices and condiments',
            allergens: const [],
            calories: 544,
            protein: 6.8,
            carbohydrates: 53.4,
            fat: 33.7,
            fiber: 3.8,
            sugar: 6.2,
            sodium: 680,
          ),
          'expected': PantryCategory.snacks,
        },
        {
          'product': FoodProduct(
            barcode: '8901058852445',
            name: 'Maggi Masala Noodles',
            brand: 'Nestle',
            imageUrl: '',
            ingredients: 'Wheat flour, palm oil, salt, spices',
            allergens: const [],
            calories: 427,
            protein: 8,
            carbohydrates: 63.5,
            fat: 15.7,
            fiber: 3.6,
            sugar: 2.2,
            sodium: 1020,
          ),
          'expected': PantryCategory.readyToEatInstant,
        },
        {
          'product': FoodProduct(
            barcode: '222',
            name: 'Basmati Rice',
            brand: 'Daawat',
            imageUrl: '',
            ingredients: 'Rice',
            allergens: const [],
            calories: 350,
            protein: 8,
            carbohydrates: 78,
            fat: 0.5,
            fiber: 1,
            sugar: 0,
            sodium: 5,
          ),
          'expected': PantryCategory.grainsCereals,
        },
        {
          'product': FoodProduct(
            barcode: '333',
            name: 'Rolled Oats',
            brand: 'Quaker',
            imageUrl: '',
            ingredients: '100% Whole Grain Rolled Oats',
            allergens: const [],
            calories: 389,
            protein: 13,
            carbohydrates: 66,
            fat: 6.9,
            fiber: 10,
            sugar: 1,
            sodium: 4,
          ),
          'expected': PantryCategory.grainsCereals,
        },
        {
          'product': FoodProduct(
            barcode: '444',
            name: 'Toned Milk',
            brand: 'Amul',
            imageUrl: '',
            ingredients: 'Pasteurised Toned Milk',
            allergens: const ['Milk'],
            calories: 58,
            protein: 3.1,
            carbohydrates: 4.7,
            fat: 3.0,
            fiber: 0,
            sugar: 4.7,
            sodium: 50,
          ),
          'expected': PantryCategory.dairyEggs,
        },
        {
          'product': FoodProduct(
            barcode: '5449000012203',
            name: 'Sprite',
            brand: 'Coca-Cola',
            imageUrl: '',
            ingredients: 'Carbonated water, sugar, citric acid',
            allergens: const [],
            calories: 44,
            protein: 0,
            carbohydrates: 10.7,
            fat: 0,
            fiber: 0,
            sugar: 10.7,
            sodium: 15,
          ),
          'expected': PantryCategory.beverages,
        },
        {
          'product': FoodProduct(
            barcode: '555',
            name: 'Tomato Ketchup',
            brand: 'Heinz',
            imageUrl: '',
            ingredients: 'Tomato concentrate, distilled vinegar, sugar, salt, spices',
            allergens: const [],
            calories: 110,
            protein: 1,
            carbohydrates: 27,
            fat: 0,
            fiber: 0,
            sugar: 23,
            sodium: 900,
          ),
          'expected': PantryCategory.condimentsSauces,
        },
        {
          'product': FoodProduct(
            barcode: '666',
            name: 'Turmeric Powder',
            brand: 'Everest',
            imageUrl: '',
            ingredients: '100% pure turmeric powder',
            allergens: const [],
            calories: 350,
            protein: 8,
            carbohydrates: 65,
            fat: 10,
            fiber: 21,
            sugar: 3,
            sodium: 38,
          ),
          'expected': PantryCategory.spicesSeasonings,
        },
        {
          'product': FoodProduct(
            barcode: '777',
            name: 'Toor Dal',
            brand: 'Tata Sampann',
            imageUrl: '',
            ingredients: 'Unpolished Toor Dal',
            allergens: const [],
            calories: 343,
            protein: 22,
            carbohydrates: 63,
            fat: 1.5,
            fiber: 15,
            sugar: 0,
            sodium: 10,
          ),
          'expected': PantryCategory.pulsesLegumes,
        },
        {
          'product': FoodProduct(
            barcode: '888',
            name: 'Whole Wheat Bread',
            brand: 'Britannia',
            imageUrl: '',
            ingredients: 'Whole wheat flour, water, yeast, salt',
            allergens: const ['Wheat'],
            calories: 250,
            protein: 9,
            carbohydrates: 48,
            fat: 2.5,
            fiber: 6,
            sugar: 4,
            sodium: 450,
          ),
          'expected': PantryCategory.bakery,
        },
        {
          'product': FoodProduct(
            barcode: '999',
            name: 'Dairy Milk Silk Chocolate',
            brand: 'Cadbury',
            imageUrl: '',
            ingredients: 'Sugar, milk solids, cocoa butter, cocoa solids',
            allergens: const ['Milk'],
            calories: 534,
            protein: 7.8,
            carbohydrates: 58.5,
            fat: 30.5,
            fiber: 2,
            sugar: 55,
            sodium: 140,
          ),
          'expected': PantryCategory.sweetsDesserts,
        },
      ];

      for (final tc in testCases) {
        final product = tc['product'] as FoodProduct;
        final expected = tc['expected'] as PantryCategory;
        final actual = classifier.classifyProduct(product);
        expect(
          actual,
          expected,
          reason: 'Failed for ${product.brand} - ${product.name}. Expected ${expected.label} but got ${actual.label}',
        );
      }
    });

    test('2. Unclassifiable / unknown item falls back to Other (NEVER Grains)', () {
      final obscureProduct = FoodProduct(
        barcode: '0000',
        name: 'XYZ Mystery Item',
        brand: 'GenericCo',
        imageUrl: '',
        ingredients: '',
        allergens: const [],
        calories: null,
        protein: null,
        carbohydrates: null,
        fat: null,
        fiber: null,
        sugar: null,
        sodium: null,
      );

      final result = classifier.classifyProduct(obscureProduct);
      expect(result, PantryCategory.other);
      expect(result, isNot(PantryCategory.grainsCereals));
    });

    test('3. Semantic classification supports comprehensive grocery taxonomy', () {
      expect(classifier.classifyRaw(name: 'Fresh Spinach Leaves'), PantryCategory.fruitsVegetables);
      expect(classifier.classifyRaw(name: 'Chicken Breast Fillets'), PantryCategory.meatSeafood);
      expect(classifier.classifyRaw(name: 'Pure Mustard Cooking Oil'), PantryCategory.cookingEssentials);
      expect(classifier.classifyRaw(name: 'Frozen Green Peas'), PantryCategory.frozenFoods);
      expect(classifier.classifyRaw(name: 'Doritos Cheese Nachos'), PantryCategory.snacks);
      expect(classifier.classifyRaw(name: 'Kurkure Masala Munch'), PantryCategory.snacks);
      expect(classifier.classifyRaw(name: 'Pringles Sour Cream & Onion'), PantryCategory.snacks);
      expect(classifier.classifyRaw(name: 'Ching\'s Secret Hakka Noodles'), PantryCategory.readyToEatInstant);
      expect(classifier.classifyRaw(name: 'Coca Cola Zero Sugar'), PantryCategory.beverages);
      expect(classifier.classifyRaw(name: 'Greek Yogurt Blueberry', brand: 'Epigamia'), PantryCategory.dairyEggs);
      expect(classifier.classifyRaw(name: 'Rajma Red Kidney Beans'), PantryCategory.pulsesLegumes);
      expect(classifier.classifyRaw(name: 'Garam Masala Powder'), PantryCategory.spicesSeasonings);
    });

    testWidgets('4. PantryScreen loads stored Lay\'s chips and automatically categorizes under Snacks', (tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final lays = FoodProduct(
        barcode: '8901491101844',
        name: 'West Indies\' Hot \'n\' Sweet Chilli',
        brand: 'Lay\'s',
        imageUrl: 'https://example.com/lays.png',
        ingredients: 'Potato, Edible Vegetable Oil, Sugar, Spices & Condiments',
        allergens: const [],
        calories: 535,
        protein: 7,
        carbohydrates: 53,
        fat: 33,
        fiber: 3.5,
        sugar: 6.5,
        sodium: 620,
      );

      final rice = FoodProduct(
        barcode: '8901234567890',
        name: 'Basmati Rice',
        brand: 'Daawat',
        imageUrl: '',
        ingredients: 'Raw Basmati Rice',
        allergens: const [],
        calories: 350,
        protein: 8,
        carbohydrates: 78,
        fat: 0.5,
        fiber: 1.5,
        sugar: 0.1,
        sodium: 5,
      );

      // Add to persistent storage
      await PantryStorageService.instance.clearPantry(userId: 'test_lays_user');
      await PantryStorageService.instance.addProduct(lays, userId: 'test_lays_user');
      await PantryStorageService.instance.addProduct(rice, userId: 'test_lays_user');

      // Load products and convert via PantryCategoryService
      final products = await PantryStorageService.instance.getProducts(userId: 'test_lays_user');
      final items = products.map((p) => PantryItem(
        imageAsset: '',
        imageUrl: p.imageUrl,
        name: p.name,
        category: PantryCategoryService.instance.classifyProduct(p),
        addedOn: DateTime.now(),
        quantity: '1',
        status: ItemStatus.fresh,
        statusDetail: 'In your pantry',
      )).toList();

      await tester.pumpWidget(
        MaterialApp(
          home: PantryScreen(
            items: items,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Lay's chips is visible
      expect(find.text('West Indies\' Hot \'n\' Sweet Chilli'), findsOneWidget);
      expect(find.text('Basmati Rice'), findsOneWidget);

      // Verify Lay's item is labeled as Snacks, NOT Grains
      expect(find.text('Snacks'), findsWidgets);
      expect(find.text('Grains & Cereals'), findsWidgets);

      // Tap "Snacks" filter chip
      await tester.ensureVisible(find.byKey(const ValueKey('category_chip_snacks')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('category_chip_snacks')));
      await tester.pumpAndSettle();

      // In Snacks filter, Lay's is visible, Rice is filtered out
      expect(find.text('West Indies\' Hot \'n\' Sweet Chilli'), findsOneWidget);
      expect(find.text('Basmati Rice'), findsNothing);

      // Tap "Grains & Cereals" filter chip
      await tester.ensureVisible(find.byKey(const ValueKey('category_chip_grainsCereals')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('category_chip_grainsCereals')));
      await tester.pumpAndSettle();

      // In Grains filter, Rice is visible, Lay's is filtered out
      expect(find.text('Basmati Rice'), findsOneWidget);
      expect(find.text('West Indies\' Hot \'n\' Sweet Chilli'), findsNothing);

      // Tap "All" filter chip
      await tester.ensureVisible(find.byKey(const ValueKey('category_chip_all')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('category_chip_all')));
      await tester.pumpAndSettle();

      // Both visible in All
      expect(find.text('West Indies\' Hot \'n\' Sweet Chilli'), findsOneWidget);
      expect(find.text('Basmati Rice'), findsOneWidget);
    });

    testWidgets('5. Manual Add Pantry Item dialog supports all 15 categories with auto-detection', (tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PantryScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Open Add Item Dialog
      await tester.tap(find.byTooltip('Add pantry item'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      // Type "Lay's Hot & Sweet" -> auto-detects Snacks
      await tester.enterText(find.byType(TextField).first, 'Lay\'s Hot & Sweet');
      await tester.pump();

      // Verify Dropdown exists and has all 15 categories
      expect(find.byType(DropdownButtonFormField<PantryCategory>), findsOneWidget);

      // Submit Add Item
      final submitBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Add Item'),
      );
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verified added item appears as Snacks
      expect(find.text('Lay\'s Hot & Sweet'), findsOneWidget);
      expect(find.text('Snacks'), findsWidgets);
    });
  });
}
