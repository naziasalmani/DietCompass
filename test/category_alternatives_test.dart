import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/core/model/food_product.dart';
import 'package:diet_compass/core/model/personalization_profile.dart';
import 'package:diet_compass/core/services/product_category_service.dart';
import 'package:diet_compass/core/services/recommendation_service.dart';

void main() {
  group('Category-Aware Better Alternatives Tests', () {
    final categoryService = ProductCategoryService.instance;
    final recommendationService = RecommendationService.instance;

    // Sample test products
    final cadburyDairyMilk = FoodProduct(
      barcode: '8901233024011',
      name: 'Cadbury Dairy Milk Chocolate',
      brand: 'Cadbury',
      imageUrl: 'https://example.com/dairymilk.jpg',
      ingredients: 'Sugar, milk solids, cocoa butter, cocoa solids, emulsifiers',
      allergens: ['milk'],
      calories: 534.0,
      protein: 7.8,
      carbohydrates: 60.5,
      fat: 29.5,
      fiber: 2.1,
      sugar: 58.8,
      sodium: 0.15,
    );

    final amulDarkChocolate = FoodProduct(
      barcode: '8901262010101',
      name: 'Amul 55% Dark Chocolate',
      brand: 'Amul',
      imageUrl: 'https://example.com/amuldark.jpg',
      ingredients: 'Cocoa solids, sugar, cocoa butter, emulsifiers',
      allergens: [],
      calories: 520.0,
      protein: 8.5,
      carbohydrates: 48.0,
      fat: 32.0,
      fiber: 7.2,
      sugar: 28.0,
      sodium: 0.05,
    );

    final sugarFreeDarkChocolate = FoodProduct(
      barcode: '8901262099999',
      name: 'Sugar Free 70% Dark Chocolate Bar',
      brand: 'HealthyChoc',
      imageUrl: 'https://example.com/sfchoc.jpg',
      ingredients: 'Cocoa mass, cocoa butter, stevia extract, erythritol',
      allergens: [],
      calories: 480.0,
      protein: 9.0,
      carbohydrates: 30.0,
      fat: 36.0,
      fiber: 11.0,
      sugar: 1.5,
      sodium: 0.02,
    );

    final quakerOats = FoodProduct(
      barcode: '8901491101831',
      name: 'Quaker Whole Rolled Oats',
      brand: 'Quaker',
      imageUrl: 'https://example.com/quaker.jpg',
      ingredients: '100% Whole grain rolled oats',
      allergens: ['oats'],
      calories: 389.0,
      protein: 13.0,
      carbohydrates: 66.0,
      fat: 6.5,
      fiber: 10.0,
      sugar: 1.0,
      sodium: 0.01,
    );

    final saffolaOats = FoodProduct(
      barcode: '8901088001011',
      name: 'Saffola Rolled Oats 100% Natural',
      brand: 'Saffola',
      imageUrl: 'https://example.com/saffola.jpg',
      ingredients: 'Rolled oats',
      allergens: ['oats'],
      calories: 380.0,
      protein: 12.5,
      carbohydrates: 65.0,
      fat: 7.0,
      fiber: 9.5,
      sugar: 1.2,
      sodium: 0.01,
    );

    final thumsUp = FoodProduct(
      barcode: '8901764012211',
      name: 'Thums Up Soft Drink',
      brand: 'Coca Cola',
      imageUrl: 'https://example.com/thumsup.jpg',
      ingredients: 'Carbonated water, sugar, acidity regulator, caffeine, caramel color',
      allergens: [],
      calories: 44.0,
      protein: 0.0,
      carbohydrates: 11.0,
      fat: 0.0,
      fiber: 0.0,
      sugar: 10.8,
      sodium: 0.02,
    );

    final dietCoke = FoodProduct(
      barcode: '8901764099881',
      name: 'Diet Coke Zero Sugar Cola',
      brand: 'Coca Cola',
      imageUrl: 'https://example.com/dietcoke.jpg',
      ingredients: 'Carbonated water, caramel color, aspartame, acesulfame potassium, caffeine',
      allergens: [],
      calories: 0.5,
      protein: 0.0,
      carbohydrates: 0.1,
      fat: 0.0,
      fiber: 0.0,
      sugar: 0.0,
      sodium: 0.01,
    );

    final sparklingWater = FoodProduct(
      barcode: '8901764077661',
      name: 'Himalayan Sparkling Water Natural',
      brand: 'Tata',
      imageUrl: 'https://example.com/sparkling.jpg',
      ingredients: 'Carbonated natural mineral water',
      allergens: [],
      calories: 0.0,
      protein: 0.0,
      carbohydrates: 0.0,
      fat: 0.0,
      fiber: 0.0,
      sugar: 0.0,
      sodium: 0.0,
    );

    final laysChips = FoodProduct(
      barcode: '8901491501011',
      name: 'Lays Classic Salted Potato Chips',
      brand: 'Lays',
      imageUrl: 'https://example.com/lays.jpg',
      ingredients: 'Potato, edible vegetable oil, salt',
      allergens: [],
      calories: 540.0,
      protein: 6.8,
      carbohydrates: 52.0,
      fat: 34.0,
      fiber: 3.5,
      sugar: 1.5,
      sodium: 0.65,
    );

    final bakedLentilChips = FoodProduct(
      barcode: '8901491599881',
      name: 'Baked Lentil & Quinoa Popped Chips',
      brand: 'SnackSmart',
      imageUrl: 'https://example.com/bakedchips.jpg',
      ingredients: 'Lentil flour, quinoa flour, olive oil, sea salt',
      allergens: [],
      calories: 410.0,
      protein: 16.0,
      carbohydrates: 58.0,
      fat: 12.0,
      fiber: 8.0,
      sugar: 2.0,
      sodium: 0.28,
    );

    test('Classifies products into accurate semantic food categories', () {
      expect(categoryService.classifyProduct(cadburyDairyMilk), FoodCategoryType.chocolateConfectionery);
      expect(categoryService.classifyProduct(amulDarkChocolate), FoodCategoryType.chocolateConfectionery);
      expect(categoryService.classifyProduct(thumsUp), FoodCategoryType.carbonatedBeverage);
      expect(categoryService.classifyProduct(dietCoke), FoodCategoryType.carbonatedBeverage);
      expect(categoryService.classifyProduct(quakerOats), FoodCategoryType.breakfastCerealOats);
      expect(categoryService.classifyProduct(saffolaOats), FoodCategoryType.breakfastCerealOats);
      expect(categoryService.classifyProduct(laysChips), FoodCategoryType.chipsSavorySnacks);
      expect(categoryService.classifyProduct(bakedLentilChips), FoodCategoryType.chipsSavorySnacks);
    });

    test('Semantic Category similarity accepts same-category and rejects cross-category products', () {
      // Chocolates vs Chocolates: ACCEPT
      expect(categoryService.isProductSimilarCategory(cadburyDairyMilk, amulDarkChocolate), isTrue);
      expect(categoryService.isProductSimilarCategory(cadburyDairyMilk, sugarFreeDarkChocolate), isTrue);

      // Chocolates vs Soft Drinks / Oats / Chips: REJECT
      expect(categoryService.isProductSimilarCategory(cadburyDairyMilk, thumsUp), isFalse);
      expect(categoryService.isProductSimilarCategory(cadburyDairyMilk, sparklingWater), isFalse);
      expect(categoryService.isProductSimilarCategory(cadburyDairyMilk, quakerOats), isFalse);
      expect(categoryService.isProductSimilarCategory(cadburyDairyMilk, laysChips), isFalse);

      // Oats vs Oats: ACCEPT
      expect(categoryService.isProductSimilarCategory(quakerOats, saffolaOats), isTrue);

      // Oats vs Chocolate / Soda: REJECT
      expect(categoryService.isProductSimilarCategory(quakerOats, cadburyDairyMilk), isFalse);
      expect(categoryService.isProductSimilarCategory(quakerOats, dietCoke), isFalse);

      // Soda vs Soda: ACCEPT
      expect(categoryService.isProductSimilarCategory(thumsUp, dietCoke), isTrue);

      // Soda vs Oats / Butter: REJECT
      expect(categoryService.isProductSimilarCategory(thumsUp, quakerOats), isFalse);
    });

    test('Better Alternatives for Cadbury Dairy Milk ONLY returns chocolates, NEVER Oats or Soda', () {
      final candidates = [
        amulDarkChocolate, // Valid: Chocolate (lower sugar: 28g vs 58.8g)
        sugarFreeDarkChocolate, // Valid: Chocolate (sugar free: 1.5g)
        quakerOats, // INVALID: Oats (even though health score is high!)
        sparklingWater, // INVALID: Water (even though 0 sugar!)
        thumsUp, // INVALID: Soft drink
        bakedLentilChips, // INVALID: Chips
      ];

      final profile = PersonalizationProfile(
        id: 'user_1',
        userId: 'u1',
        goals: {'Low Sugar Diet'},
        dietType: 'Vegetarian',
      );

      final alternatives = recommendationService.filterAndRankAlternatives(
        currentProduct: cadburyDairyMilk,
        candidates: candidates,
        personalization: profile,
      );

      // Must only return chocolates
      expect(alternatives.isNotEmpty, isTrue);
      for (final alt in alternatives) {
        expect(categoryService.classifyProduct(alt.product), FoodCategoryType.chocolateConfectionery);
        expect(alt.product.name.toLowerCase().contains('oats'), isFalse);
        expect(alt.product.name.toLowerCase().contains('water'), isFalse);
        expect(alt.product.name.toLowerCase().contains('drink'), isFalse);
      }

      // Check factual differentiators
      final topRec = alternatives.firstWhere((a) => a.product.barcode == sugarFreeDarkChocolate.barcode);
      expect(topRec.differentiator, contains('Less Sugar'));
      expect(topRec.matchReason, contains('scanned product'));
    });

    test('Better Alternatives for Quaker Oats ONLY returns Oats/Cereals, NEVER chocolates or soft drinks', () {
      final candidates = [
        saffolaOats, // Valid: Oats
        amulDarkChocolate, // INVALID: Chocolate
        dietCoke, // INVALID: Soft Drink
        bakedLentilChips, // INVALID: Chips
      ];

      final alternatives = recommendationService.filterAndRankAlternatives(
        currentProduct: quakerOats,
        candidates: candidates,
      );

      expect(alternatives.length, 1);
      expect(alternatives.first.product.barcode, saffolaOats.barcode);
    });

    test('Better Alternatives for Thums Up ONLY returns Colas/Beverages, NEVER Oats or Chocolates', () {
      final candidates = [
        dietCoke, // Valid: Soft Drink / Cola
        quakerOats, // INVALID: Oats
        amulDarkChocolate, // INVALID: Chocolate
      ];

      final alternatives = recommendationService.filterAndRankAlternatives(
        currentProduct: thumsUp,
        candidates: candidates,
      );

      expect(alternatives.length, 1);
      expect(alternatives.first.product.barcode, dietCoke.barcode);
      expect(categoryService.classifyProduct(alternatives.first.product), FoodCategoryType.carbonatedBeverage);
    });

    test('Never returns the scanned product itself as an alternative', () {
      final candidates = [
        cadburyDairyMilk, // Exact same product
        amulDarkChocolate,
      ];

      final alternatives = recommendationService.filterAndRankAlternatives(
        currentProduct: cadburyDairyMilk,
        candidates: candidates,
      );

      expect(alternatives.any((a) => a.product.barcode == cadburyDairyMilk.barcode), isFalse);
      expect(alternatives.length, 1);
      expect(alternatives.first.product.barcode, amulDarkChocolate.barcode);
    });
  });
}
