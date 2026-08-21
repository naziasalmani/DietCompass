import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/core/model/food_product.dart';
import 'package:diet_compass/core/model/personalization_profile.dart';
import 'package:diet_compass/core/services/recommendation_service.dart';

void main() {
  group('RecommendationService Tests (Single Source of Truth)', () {
    final recommendationService = RecommendationService.instance;

    final baseProduct = FoodProduct(
      barcode: '123456',
      name: 'Organic Rolled Oats',
      brand: 'Pure Farm',
      imageUrl: 'https://example.com/oats.jpg',
      ingredients: '100% Whole Grain Rolled Oats',
      allergens: [],
      calories: 389,
      protein: 16.9,
      carbohydrates: 66.3,
      fat: 6.9,
      fiber: 10.6,
      sugar: 1.0,
      sodium: 0.002,
      nutriScore: 'A',
      novaGroup: 1,
    );

    final highSugarSnack = FoodProduct(
      barcode: '999999',
      name: 'Frosted Chocolate Biscuits',
      brand: 'SweetCorp',
      imageUrl: 'https://example.com/biscuits.jpg',
      ingredients: 'Wheat flour, sugar, palm oil, cocoa, milk solids, artificial flavor',
      allergens: ['Wheat', 'Milk'],
      calories: 490,
      protein: 4.5,
      carbohydrates: 72.0,
      fat: 21.0,
      fiber: 1.2,
      sugar: 38.0,
      sodium: 0.45,
      nutriScore: 'E',
      novaGroup: 4,
    );

    final chickenSalad = FoodProduct(
      barcode: '777777',
      name: 'Grilled Chicken Salad',
      brand: 'FreshDeli',
      imageUrl: 'https://example.com/salad.jpg',
      ingredients: 'Grilled chicken breast, lettuce, cucumber, olive oil dressing',
      allergens: [],
      calories: 220,
      protein: 28.0,
      carbohydrates: 5.0,
      fat: 8.0,
      fiber: 2.5,
      sugar: 1.5,
      sodium: 0.35,
      nutriScore: 'A',
      novaGroup: 2,
    );

    final peanutButter = FoodProduct(
      barcode: '555555',
      name: 'Creamy Peanut Butter',
      brand: 'NuttyCo',
      imageUrl: 'https://example.com/pb.jpg',
      ingredients: 'Roasted peanuts, salt',
      allergens: ['Peanuts'],
      calories: 588,
      protein: 25.0,
      carbohydrates: 20.0,
      fat: 50.0,
      fiber: 6.0,
      sugar: 3.0,
      sodium: 0.15,
      nutriScore: 'B',
      novaGroup: 2,
    );

    test('Single source of truth: Compatibility Score is identical across method calls', () {
      final personalization = PersonalizationProfile(
        id: 'user1',
        userId: 'u1',
        goals: {'High Fibre Diet', 'Low Sugar Diet'},
        dietType: 'Vegetarian',
      );

      final eval = recommendationService.evaluateCompatibility(
        baseProduct,
        personalization: personalization,
      );

      final score = recommendationService.calculateCompatibilityScore(
        baseProduct,
        personalization: personalization,
      );

      expect(eval.score, equals(score));
      expect(eval.isSuitable, isTrue);
      expect(eval.score, greaterThanOrEqualTo(80));
    });

    test('Nutrition Score is distinct from Personal Compatibility Score', () {
      final nutritionScore = recommendationService.calculateNutritionScore(baseProduct);
      final compatibilityScore = recommendationService.calculateCompatibilityScore(baseProduct);

      expect(nutritionScore, isA<int>());
      expect(compatibilityScore, isA<int>());
      expect(nutritionScore, greaterThan(0));
    });

    test('Strict allergy filter excludes peanut products for peanut allergy', () {
      final allergyProfile = PersonalizationProfile(
        id: 'user3',
        userId: 'u3',
        allergies: {'Peanuts'},
        dietType: 'Vegetarian',
      );

      final compatible = recommendationService.filterCompatibleProducts(
        [baseProduct, peanutButter, highSugarSnack],
        personalization: allergyProfile,
      );

      expect(compatible.any((p) => p.name.contains('Peanut')), isFalse);
      expect(compatible.contains(baseProduct), isTrue);

      final evalPb = recommendationService.evaluateCompatibility(
        peanutButter,
        personalization: allergyProfile,
      );
      expect(evalPb.isSuitable, isFalse);
      expect(evalPb.allergyAlerts, isNotEmpty);
      expect(evalPb.score, lessThanOrEqualTo(25));
    });

    test('Strict dietary filter excludes meat/chicken products for Vegetarian/Vegan', () {
      final vegProfile = PersonalizationProfile(
        id: 'user4',
        userId: 'u4',
        dietType: 'Vegetarian',
      );

      final compatible = recommendationService.filterCompatibleProducts(
        [baseProduct, chickenSalad],
        personalization: vegProfile,
      );

      expect(compatible.contains(chickenSalad), isFalse);
      expect(compatible.contains(baseProduct), isTrue);

      final evalChicken = recommendationService.evaluateCompatibility(
        chickenSalad,
        personalization: vegProfile,
      );
      expect(evalChicken.isSuitable, isFalse);
      expect(evalChicken.dietaryAlerts, isNotEmpty);
      expect(evalChicken.score, lessThanOrEqualTo(35));
    });

    test('Smart Cart Advice calculates high sugar count accurately', () {
      final cartItems = [
        baseProduct, // sugar: 1.0g (safe)
        highSugarSnack, // sugar: 38.0g (high sugar!)
      ];

      final advice = recommendationService.calculateSmartCartAdvice(cartItems);

      expect(advice.highSugarCount, equals(1));
      expect(advice.adviceMessage, contains('1 high-sugar item'));
    });

    test('Product ranking orders highest matching products first', () {
      final profile = PersonalizationProfile(
        id: 'user5',
        userId: 'u5',
        goals: {'High Fibre Diet', 'Low Sugar Diet'},
        dietType: 'Vegetarian',
      );

      final ranked = recommendationService.rankProducts(
        [highSugarSnack, baseProduct],
        personalization: profile,
        strictFilter: false,
      );

      expect(ranked.first.barcode, equals(baseProduct.barcode));
    });
  });
}
