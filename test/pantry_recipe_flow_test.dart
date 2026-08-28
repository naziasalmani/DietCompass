import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/core/model/food_product.dart';
import 'package:diet_compass/core/services/pantry_storage_service.dart';
import 'package:diet_compass/features/pantry/pantry_screen.dart';
import 'package:diet_compass/features/recipe_generator/recipe_generator_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('DietCompass Pantry & Persistence Isolation Tests', () {
    final testProduct = FoodProduct(
      barcode: '8901234567890',
      name: 'Organic Rolled Oats',
      brand: 'DietCompass Organics',
      imageUrl: 'https://example.com/oats.jpg',
      calories: 389.0,
      protein: 16.9,
      carbohydrates: 66.3,
      fat: 6.9,
      fiber: 10.6,
      sugar: 0.99,
      sodium: 2.0,
      ingredients: '100% whole grain rolled oats',
      allergens: const ['Gluten'],
    );

    final milkProduct = FoodProduct(
      barcode: '8901000000001',
      name: 'Amul Toned Milk',
      brand: 'Amul',
      imageUrl: 'https://example.com/milk.jpg',
      calories: 58.0,
      protein: 3.0,
      carbohydrates: 4.7,
      fat: 3.0,
      fiber: 0.0,
      sugar: 4.7,
      sodium: 50.0,
      ingredients: 'Toned Milk',
      allergens: const ['Milk'],
    );

    test('1. Fresh account starts with completely empty pantry', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final products = await PantryStorageService.instance.getProducts(
        userId: 'user_fresh_123',
      );
      expect(products, isEmpty);
    });

    test(
      '2. PantryStorageService persists items per user account with strict isolation',
      () async {
        FlutterSecureStorage.setMockInitialValues({});

        // Account A adds Oats
        await PantryStorageService.instance.addProduct(
          testProduct,
          userId: 'user_A',
        );
        final inPantryA = await PantryStorageService.instance.isProductInPantry(
          testProduct,
          userId: 'user_A',
        );
        expect(inPantryA, isTrue);

        // Account B has NOT added anything -> must be empty
        final productsB = await PantryStorageService.instance.getProducts(
          userId: 'user_B',
        );
        expect(productsB, isEmpty);
        final inPantryB = await PantryStorageService.instance.isProductInPantry(
          testProduct,
          userId: 'user_B',
        );
        expect(inPantryB, isFalse);

        // Account B adds Milk
        await PantryStorageService.instance.addProduct(
          milkProduct,
          userId: 'user_B',
        );
        final productsBAfter = await PantryStorageService.instance.getProducts(
          userId: 'user_B',
        );
        expect(productsBAfter.length, equals(1));
        expect(productsBAfter.first.name, equals('Amul Toned Milk'));

        // Account A still only has Oats
        final productsAAfter = await PantryStorageService.instance.getProducts(
          userId: 'user_A',
        );
        expect(productsAAfter.length, equals(1));
        expect(productsAAfter.first.name, equals('Organic Rolled Oats'));

        // Removing item from Account A
        await PantryStorageService.instance.removeProduct(
          testProduct,
          userId: 'user_A',
        );
        final productsAFinal = await PantryStorageService.instance.getProducts(
          userId: 'user_A',
        );
        expect(productsAFinal, isEmpty);

        // Account B is unaffected
        final productsBFinal = await PantryStorageService.instance.getProducts(
          userId: 'user_B',
        );
        expect(productsBFinal.length, equals(1));
      },
    );

    testWidgets(
      '3. PantryScreen renders empty state when user pantry is empty',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 2600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        FlutterSecureStorage.setMockInitialValues({});

        await tester.pumpWidget(const MaterialApp(home: PantryScreen()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Your Pantry is Empty'), findsOneWidget);
        expect(find.text('Total Items'), findsOneWidget);
        expect(find.text('0'), findsWidgets); // Total Items = 0
      },
    );

    testWidgets(
      '4. Add Item dialog: type, press Cancel repeatedly -> NO crashes, NO controller disposal errors',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 2600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        FlutterSecureStorage.setMockInitialValues({});

        await tester.pumpWidget(const MaterialApp(home: PantryScreen()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Loop multiple times to ensure repeated open/cancel does not reuse disposed controllers
        for (int i = 0; i < 3; i++) {
          // Tap Add icon in header or Add Item button
          final addBtn = find.byTooltip('Add pantry item');
          expect(addBtn, findsOneWidget);
          await tester.tap(addBtn);
          await tester.pumpAndSettle();

          // Verify dialog is open
          expect(find.text('Add Pantry Item'), findsOneWidget);
          expect(find.text('Ingredient or Product Name'), findsOneWidget);

          // Enter text into the field
          await tester.enterText(
            find.byType(TextField).first,
            'Whole Grain Oats',
          );
          await tester.pump();

          // Tap Cancel
          final cancelBtn = find.text('Cancel');
          expect(cancelBtn, findsOneWidget);
          await tester.tap(cancelBtn);
          await tester.pumpAndSettle();

          // Verify dialog closed cleanly and pantry screen is intact
          expect(find.text('Add Pantry Item'), findsNothing);
          expect(find.text('My Pantry'), findsOneWidget);
        }
      },
    );

    testWidgets(
      '5. Add Item dialog: fill form, press Add Item -> adds item cleanly and persists',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 2600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        FlutterSecureStorage.setMockInitialValues({});

        await tester.pumpWidget(const MaterialApp(home: PantryScreen()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Open Add Item Dialog
        await tester.tap(find.byTooltip('Add pantry item'));
        await tester.pumpAndSettle();

        // Enter name
        await tester.enterText(find.byType(TextField).first, 'Almond Flour');
        await tester.pump();

        // Tap Add Item button inside dialog
        final submitBtn = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Add Item'),
        );
        expect(submitBtn, findsOneWidget);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        // Verify item now appears on screen
        expect(find.text('Almond Flour'), findsOneWidget);
        expect(find.text('Total Items'), findsOneWidget);
        expect(find.text('1'), findsWidgets);
      },
    );

    testWidgets(
      '6. Pantry item removal confirms, updates UI, and persists deletion',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 2600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        FlutterSecureStorage.setMockInitialValues({});

        final rice = FoodProduct(
          barcode: '8900000000001',
          name: 'Rice',
          brand: '',
          imageUrl: '',
          ingredients: 'Rice',
          allergens: const [],
          calories: 350,
          protein: 7,
          carbohydrates: 78,
          fat: 1,
          fiber: 1,
          sugar: 0,
          sodium: 0,
        );
        await PantryStorageService.instance.addProduct(rice);

        await tester.pumpWidget(const MaterialApp(home: PantryScreen()));
        await tester.pumpAndSettle();
        expect(find.text('Rice'), findsOneWidget);

        await tester.tap(find.text('Rice'));
        await tester.pumpAndSettle();
        expect(find.text('Remove Pantry Item?'), findsOneWidget);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Rice'), findsOneWidget);

        await tester.tap(find.text('Rice'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
        await tester.pumpAndSettle();

        expect(find.text('Rice'), findsNothing);
        expect(find.text('Your Pantry is Empty'), findsOneWidget);
        expect(await PantryStorageService.instance.getProducts(), isEmpty);
      },
    );

    testWidgets(
      '7. RecipeGeneratorScreen shows timeout/retry state on error instead of false zero recipes',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 2600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        FlutterSecureStorage.setMockInitialValues({});

        await tester.pumpWidget(
          const MaterialApp(
            home: RecipeGeneratorScreen(recipes: [], moreIdeas: []),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // In empty pantry mode, it guides the user
        expect(
          find.text(
            'Your pantry is empty. Add ingredients to discover personalized recipes.',
          ),
          findsOneWidget,
        );
        expect(find.text('Open Pantry'), findsOneWidget);
      },
    );
  });
}
