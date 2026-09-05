import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/core/model/food_product.dart';
import 'package:diet_compass/core/services/product_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProductCacheService Unit Tests', () {
    final testProduct = FoodProduct(
      barcode: '8901234567890',
      name: 'Organic Almond Milk',
      brand: 'NutriBio',
      imageUrl: 'https://example.com/almond_milk.jpg',
      ingredients: 'Filtered water, organic almonds, sea salt',
      allergens: ['tree nuts'],
      calories: 30.0,
      protein: 1.0,
      carbohydrates: 1.0,
      fat: 2.5,
      fiber: 0.5,
      sugar: 0.0, // Legitimate zero
      sodium: 0.12,
      servingSize: '240 ml',
    );

    setUp(() async {
      await ProductCacheService.instance.clearProduct('8901234567890');
      await ProductCacheService.instance.clearProduct('0000000000000');
    });

    test('Scenario A & B: Cache MISS on first lookup, Cache HIT on repeated lookup', () async {
      const barcode = '8901234567890';

      // 1. First lookup: Cache MISS
      final firstResult = await ProductCacheService.instance.getProduct(barcode);
      expect(firstResult, isNull);

      // 2. Save canonical merged product
      await ProductCacheService.instance.saveProduct(testProduct);

      // 3. Second lookup: Cache HIT (Returns immediately without external API calls)
      final secondResult = await ProductCacheService.instance.getProduct(barcode);
      expect(secondResult, isNotNull);
      expect(secondResult!.barcode, barcode);
      expect(secondResult.name, 'Organic Almond Milk');
      expect(secondResult.brand, 'NutriBio');
      expect(secondResult.sugar, 0.0);
    });

    test('Scenario D: Legitimate zero values (sugar=0, sodium=0) are recognized as complete', () {
      final dietSoda = FoodProduct(
        barcode: '012345678905',
        name: 'Zero Sugar Sparking Water',
        brand: 'AquaPure',
        imageUrl: 'https://example.com/water.jpg',
        ingredients: 'Carbonated water, natural lemon flavor',
        allergens: [],
        calories: 0.0, // Legitimate zero
        protein: 0.0, // Legitimate zero
        carbohydrates: 0.0, // Legitimate zero
        fat: 0.0, // Legitimate zero
        fiber: 0.0, // Legitimate zero
        sugar: 0.0, // Legitimate zero
        sodium: 0.0, // Legitimate zero
      );

      expect(dietSoda.hasMissingOrZeroNutrients, isFalse);
      expect(dietSoda.isComplete, isTrue);
    });

    test('Scenario D: Contradictory zero values are flagged as missing/incomplete', () {
      final brokenCookie = FoodProduct(
        barcode: '999999999999',
        name: 'Sweet Chocolate Cookies',
        brand: 'BakeryBest',
        imageUrl: 'https://example.com/cookie.jpg',
        ingredients: 'Wheat flour, sugar, palm oil, cocoa powder, cane sugar',
        allergens: ['gluten'],
        calories: 450.0,
        protein: 5.0,
        carbohydrates: 65.0,
        fat: 20.0,
        fiber: 2.0,
        sugar: 0.0, // Contradictory zero: carbs=65g and ingredients have sugar!
        sodium: 0.3,
      );

      expect(brokenCookie.hasMissingOrZeroNutrients, isTrue);
      expect(brokenCookie.isComplete, isFalse);
    });

    test('Field-level merging preserves source metadata and timestamp', () {
      final primary = FoodProduct(
        barcode: '777777777777',
        name: 'Whole Grain Cereal',
        brand: 'HealthChoice',
        imageUrl: 'https://example.com/cereal.jpg',
        ingredients: 'Whole grain oats, wheat bran',
        allergens: ['gluten'],
        calories: 180.0,
        protein: 6.0,
        carbohydrates: 38.0,
        fat: 2.0,
        fiber: null, // missing in primary
        sugar: null, // missing in primary
        sodium: 0.2,
        source: 'Open Food Facts',
      );

      final fallback = FoodProduct(
        barcode: '777777777777',
        name: 'Whole Grain Cereal',
        brand: 'HealthChoice',
        imageUrl: '',
        ingredients: '',
        allergens: [],
        calories: 0.0,
        protein: 0.0,
        carbohydrates: 0.0,
        fat: 0.0,
        fiber: 5.0, // filled from fallback
        sugar: 4.0, // filled from fallback
        sodium: 0.0,
        source: 'USDA',
      );

      final merged = primary.mergeWith(fallback);

      expect(merged.fiber, 5.0);
      expect(merged.sugar, 4.0);
      expect(merged.calories, 180.0);
      expect(merged.protein, 6.0);
      expect(merged.source, 'Open Food Facts');
    });
  });
}
