import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/core/model/food_product.dart';
import 'package:diet_compass/core/model/personalization_profile.dart';
import 'package:diet_compass/core/model/user_profile.dart';
import 'package:diet_compass/core/services/recipe_service.dart';
import 'package:diet_compass/features/recipe_generator/recipe_generator_screen.dart';

void main() {
  group('DietCompass Product Mode Recipe Generator Tests', () {
    final maggiProduct = FoodProduct(
      barcode: '8901058852394',
      name: 'Maggi Masala Noodles',
      brand: 'Nestle',
      imageUrl: 'https://images.openfoodfacts.org/images/products/maggi.jpg',
      ingredients: 'Wheat Flour, Palm Oil, Salt, Minerals, Spices and Condiments',
      allergens: ['gluten', 'wheat'],
      calories: 380,
      protein: 8.0,
      carbohydrates: 55.0,
      fat: 14.0,
      fiber: 3.5,
      sugar: 2.0,
      sodium: 850.0,
    );

    test('1. Normalizes Maggi Masala Noodles to broad "noodles" category without narrowing query', () {
      final category = RecipeService.normalizeProductCategory(maggiProduct);
      expect(category, 'noodles');
      expect(category, isNot('instant noodles'));
      expect(category, isNot('Maggi Masala Noodles'));
    });

    test('2. Normalizes various packaged products to broad discovery categories', () {
      final chocolate = FoodProduct(
        barcode: '123',
        name: 'Cadbury Dairy Milk Silk',
        brand: 'Cadbury',
        imageUrl: '',
        ingredients: 'Sugar, Milk Solids, Cocoa Butter, Cocoa Solids',
        allergens: ['milk'],
        calories: 520,
        protein: 7.0,
        carbohydrates: 58.0,
        fat: 30.0,
        fiber: 2.0,
        sugar: 55.0,
        sodium: 150.0,
      );
      expect(RecipeService.normalizeProductCategory(chocolate), 'chocolate');

      final oats = FoodProduct(
        barcode: '456',
        name: 'Quaker Rolled Oats',
        brand: 'Quaker',
        imageUrl: '',
        ingredients: 'Whole Grain Rolled Oats',
        allergens: [],
        calories: 375,
        protein: 13.0,
        carbohydrates: 68.0,
        fat: 6.5,
        fiber: 10.0,
        sugar: 1.0,
        sodium: 5.0,
      );
      expect(RecipeService.normalizeProductCategory(oats), 'oats');

      final chips = FoodProduct(
        barcode: '789',
        name: "Lay's Classic Salted Potato Chips",
        brand: "Lay's",
        imageUrl: '',
        ingredients: 'Potatoes, Edible Vegetable Oil, Salt',
        allergens: [],
        calories: 540,
        protein: 6.5,
        carbohydrates: 52.0,
        fat: 34.0,
        fiber: 4.0,
        sugar: 0.5,
        sodium: 580.0,
      );
      expect(RecipeService.normalizeProductCategory(chips), 'potato chips');
    });

    testWidgets('3. Product Mode UI ignores pantry and displays product focus and correct text', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeGeneratorScreen(
              sourceProduct: maggiProduct,
              recipes: [
                RecipeCardData(
                  id: 'ai_maggi_1',
                  title: 'Light Vegetable Maggi Masala Noodles',
                  tagline: 'Vegetarian • Quick 15 min • Balanced',
                  description: 'A wholesome vegetable-packed noodle bowl with carrots and peas.',
                  timeMinutes: 15,
                  kcal: 310,
                  proteinGrams: 9,
                  imageAsset: 'assets/images/recipe_protein_pancakes.jpeg',
                  recipeSource: 'ai',
                  whatsInside: const [
                    WhatsInTag(
                      icon: Icons.eco_rounded,
                      title: 'Vegetable Rich',
                      subtitle: 'Added fiber & vitamins',
                      color: Color(0xFF1E8A4C),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Product Focus badge is visible
      expect(find.text('Product Focus: Maggi Masala Noodles'), findsOneWidget);

      // Recipe card with Maggi title is rendered
      expect(find.text('Light Vegetable Maggi Masala Noodles'), findsOneWidget);
    });

    testWidgets('4. Product Mode Loading State displays product-specific loading message', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeGeneratorScreen(
              sourceProduct: maggiProduct,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Product Focus badge is visible
      expect(find.text('Product Focus: Maggi Masala Noodles'), findsOneWidget);

      // Displays product-specific loading message
      expect(
        find.text('Chef AI is finding recipes for Maggi Masala Noodles...'),
        findsOneWidget,
      );

      // Does NOT mention pantry in product loading
      expect(
        find.text('Chef AI is finding recipes with your pantry...'),
        findsNothing,
      );
    });
  });
}
