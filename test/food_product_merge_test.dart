import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/core/model/food_product.dart';

void main() {
  group('FoodProduct Merging and Enrichment Tests', () {
    test('Non-null and non-zero values take precedence over zero/null fallback', () {
      final primary = FoodProduct(
        barcode: '123456789',
        name: 'Whole Wheat Bread',
        brand: 'Nature Choice',
        imageUrl: 'https://example.com/bread.jpg',
        ingredients: 'Whole wheat flour, water, yeast, salt',
        allergens: ['gluten'],
        calories: 250.0,
        protein: 0.0, // Zero in primary API
        carbohydrates: 45.0,
        fat: null, // Missing in primary API
        fiber: 6.0,
        sugar: null,
        sodium: 0.35,
      );

      final fallback = FoodProduct(
        barcode: '123456789',
        name: 'Whole Wheat Bread',
        brand: 'Nature Choice',
        imageUrl: '',
        ingredients: '',
        allergens: [],
        calories: 0.0,
        protein: 12.0, // Present in fallback API
        carbohydrates: 0.0,
        fat: 2.5, // Present in fallback API
        fiber: 0.0,
        sugar: 3.0, // Present in fallback API
        sodium: 0.0,
      );

      final merged = primary.mergeWith(fallback);

      expect(merged.barcode, '123456789');
      expect(merged.name, 'Whole Wheat Bread');
      expect(merged.brand, 'Nature Choice');
      expect(merged.imageUrl, 'https://example.com/bread.jpg');
      expect(merged.ingredients, 'Whole wheat flour, water, yeast, salt');
      expect(merged.allergens, ['gluten']);
      // Nutrients verification:
      expect(merged.calories, 250.0); // Retained from primary
      expect(merged.protein, 12.0); // Filled from fallback
      expect(merged.carbohydrates, 45.0); // Retained from primary
      expect(merged.fat, 2.5); // Filled from fallback
      expect(merged.fiber, 6.0); // Retained from primary
      expect(merged.sugar, 3.0); // Filled from fallback
      expect(merged.sodium, 0.35); // Retained from primary
    });

    test('Cascading multi-API merge across 3 sources', () {
      // Source 1: Open Food Facts (has name, image, calories)
      final off = FoodProduct(
        barcode: '890123456',
        name: 'Almond Milk',
        brand: 'Unknown Brand',
        imageUrl: 'https://images.off.org/almond.jpg',
        ingredients: '',
        allergens: [],
        calories: 60.0,
        protein: null,
        carbohydrates: null,
        fat: null,
        fiber: null,
        sugar: null,
        sodium: null,
      );

      // Source 2: USDA (has protein, fat, carbs, brand)
      final usda = FoodProduct(
        barcode: '890123456',
        name: 'Almond Milk Unsweetened',
        brand: 'Silk',
        imageUrl: '',
        ingredients: 'Almondmilk (Filtered Water, Almonds), Vitamin Blend',
        allergens: ['tree nuts'],
        calories: 0.0,
        protein: 1.5,
        carbohydrates: 1.0,
        fat: 2.5,
        fiber: null,
        sugar: null,
        sodium: null,
      );

      // Source 3: UPC / Local DB (has fiber, sugar, sodium)
      final upc = FoodProduct(
        barcode: '890123456',
        name: 'Silk Almond Milk',
        brand: 'Silk',
        imageUrl: '',
        ingredients: '',
        allergens: [],
        calories: null,
        protein: null,
        carbohydrates: null,
        fat: null,
        fiber: 1.0,
        sugar: 0.0,
        sodium: 0.17,
      );

      final merged = off.mergeWith(usda).mergeWith(upc);

      expect(merged.name, 'Almond Milk'); // Kept from API 1
      expect(merged.brand, 'Silk'); // Filled from API 2
      expect(merged.imageUrl, 'https://images.off.org/almond.jpg'); // Kept from API 1
      expect(merged.ingredients, 'Almondmilk (Filtered Water, Almonds), Vitamin Blend'); // Filled from API 2
      expect(merged.allergens, ['tree nuts']); // Filled from API 2
      expect(merged.calories, 60.0); // From API 1
      expect(merged.protein, 1.5); // From API 2
      expect(merged.carbohydrates, 1.0); // From API 2
      expect(merged.fat, 2.5); // From API 2
      expect(merged.fiber, 1.0); // From API 3
      expect(merged.sodium, 0.17); // From API 3
    });

    test('hasMissingOrZeroNutrients and isComplete validation', () {
      final incompleteProduct = FoodProduct(
        barcode: '111',
        name: 'Sample',
        brand: 'Brand',
        imageUrl: 'http://img.png',
        ingredients: 'Ingredients list',
        allergens: [],
        calories: 100.0,
        protein: 0.0, // Zero nutrient
        carbohydrates: 20.0,
        fat: 5.0,
        fiber: 2.0,
        sugar: 1.0,
        sodium: 0.1,
      );

      expect(incompleteProduct.hasMissingOrZeroNutrients, isTrue);
      expect(incompleteProduct.isComplete, isFalse);

      final completeProduct = incompleteProduct.copyWith(protein: 8.0);
      expect(completeProduct.hasMissingOrZeroNutrients, isFalse);
      expect(completeProduct.isComplete, isTrue);
    });
  });
}
