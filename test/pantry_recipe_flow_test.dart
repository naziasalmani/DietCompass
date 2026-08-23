import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/core/model/food_product.dart';
import 'package:diet_compass/core/services/pantry_storage_service.dart';
import 'package:diet_compass/features/recipe_generator/recipe_generator_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('DietCompass Pantry and Recipe Generation Flow Tests', () {
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
      allergens: ['Gluten'],
    );

    test('PantryStorageService addProduct and isProductInPantry work correctly', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final inPantryBefore = await PantryStorageService.instance.isProductInPantry(testProduct);
      expect(inPantryBefore, isFalse);

      await PantryStorageService.instance.addProduct(testProduct);
      final inPantryAfter = await PantryStorageService.instance.isProductInPantry(testProduct);
      expect(inPantryAfter, isTrue);

      // Verify no duplicates on adding again
      await PantryStorageService.instance.addProduct(testProduct);
      final products = await PantryStorageService.instance.getProducts();
      final matches = products.where((p) => p.barcode == testProduct.barcode).length;
      expect(matches, equals(1));
    });

    testWidgets('RecipeGeneratorScreen accepts initialProduct and pre-fills pantry item & craving', (tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: RecipeGeneratorScreen(
            initialProduct: testProduct,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify product name appears in product focus banner
      expect(find.textContaining(testProduct.name), findsWidgets);
    });
  });
}

