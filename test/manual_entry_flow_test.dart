import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/core/model/food_product.dart';
import 'package:diet_compass/core/model/personalization_profile.dart';
import 'package:diet_compass/core/services/recommendation_service.dart';
import 'package:diet_compass/features/scan/ai_analysis_screen.dart';
import 'package:diet_compass/features/scan/result_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Manual Nutrition Entry Flow Tests', () {
    test('1. Dairy Milk manual entry creates canonical FoodProduct without data loss', () {
      final product = FoodProduct(
        barcode: '',
        name: 'Dairy Milk',
        brand: 'Cadbury',
        imageUrl: '',
        ingredients: 'Milk, sugar, cocoa butter, cocoa mass',
        allergens: const ['Milk'],
        calories: 534,
        protein: 7.8,
        carbohydrates: 57.0,
        fat: 30.0,
        saturatedFat: 18.5,
        fiber: 2.1,
        sugar: 56.0,
        sodium: 150.0,
        servingSize: '40 g',
        source: 'manual',
      );

      expect(product.name, 'Dairy Milk');
      expect(product.brand, 'Cadbury');
      expect(product.servingSize, '40 g');
      expect(product.calories, 534);
      expect(product.protein, 7.8);
      expect(product.carbohydrates, 57.0);
      expect(product.fat, 30.0);
      expect(product.saturatedFat, 18.5);
      expect(product.fiber, 2.1);
      expect(product.sugar, 56.0);
      expect(product.sodium, 150.0);
      expect(product.hasNutritionData, true);
    });

    test('2. Maggi Noodles manual entry preserves high sodium and ingredients', () {
      final product = FoodProduct(
        barcode: '',
        name: 'Maggi 2-Minute Noodles',
        brand: 'Nestle',
        imageUrl: '',
        ingredients: 'Wheat flour, palm oil, salt, hydrolyzed groundnut protein, spices',
        allergens: const ['Gluten', 'Peanut'],
        calories: 310,
        protein: 6.0,
        carbohydrates: 46.0,
        fat: 11.0,
        fiber: 2.0,
        sugar: 1.5,
        sodium: 900.0,
        servingSize: '70 g',
        source: 'manual',
      );

      expect(product.name, 'Maggi 2-Minute Noodles');
      expect(product.brand, 'Nestle');
      expect(product.sodium, 900.0);
      expect(product.allergens, contains('Gluten'));
      expect(product.ingredients, contains('Wheat flour'));
    });

    test('3. Nutrition compatibility evaluates dynamically based on user profile', () {
      final dairyMilk = FoodProduct(
        barcode: '',
        name: 'Dairy Milk',
        brand: 'Cadbury',
        imageUrl: '',
        ingredients: 'Milk, sugar, cocoa butter, cocoa mass',
        allergens: const ['Milk'],
        calories: 534,
        protein: 7.8,
        carbohydrates: 57.0,
        fat: 30.0,
        sugar: 56.0,
        fiber: 2.0,
        sodium: 150.0,
        servingSize: '40 g',
      );

      // User with Weight Loss & Low Sugar preference
      final userAProfile = PersonalizationProfile(
        id: 'user_a',
        userId: 'user_a_id',
        dietType: 'Vegetarian',
        goals: {'Weight Loss', 'Low Sugar Diet'},
      );

      final compAlice = RecommendationService.instance.evaluateCompatibility(
        dairyMilk,
        personalization: userAProfile,
      );
      expect(compAlice.score, lessThanOrEqualTo(75));

      // User with Weight Gain / Bulking
      final userBProfile = PersonalizationProfile(
        id: 'user_b',
        userId: 'user_b_id',
        dietType: 'Non-Vegetarian',
        goals: {'Weight Gain', 'High Protein Diet'},
      );

      final compBob = RecommendationService.instance.evaluateCompatibility(
        dairyMilk,
        personalization: userBProfile,
      );
      expect(compBob.score, isNotNull);
    });

    testWidgets('4. AiAnalysisScreen renders entered product name and placeholder when no image', (tester) async {
      final product = FoodProduct(
        barcode: '',
        name: 'Cadbury Dairy Milk',
        brand: 'Cadbury',
        imageUrl: '',
        ingredients: 'Milk, sugar, cocoa butter',
        allergens: const ['Milk'],
        calories: 534,
        protein: 7.8,
        carbohydrates: 57.0,
        fat: 30.0,
        fiber: 2.0,
        sugar: 56.0,
        sodium: 150.0,
        servingSize: '40 g',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AiAnalysisScreen(
            product: product,
            productName: product.name,
            productSubtitle: product.brand,
            servingInfo: product.servingSize ?? '40 g',
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Check product name and brand are displayed
      expect(find.text('Cadbury Dairy Milk'), findsOneWidget);
      expect(find.text('Cadbury'), findsOneWidget);
      expect(find.text('40 g'), findsOneWidget);
      // Ensure "Quaker" is never displayed on the screen
      expect(find.text('Quaker Oats'), findsNothing);
    });

    testWidgets('5. ResultScreen renders manual nutrition stats faithfully without Quaker defaults', (tester) async {
      final product = FoodProduct(
        barcode: '',
        name: 'Cadbury Dairy Milk',
        brand: 'Cadbury',
        imageUrl: '',
        ingredients: 'Milk, sugar, cocoa butter',
        allergens: const ['Milk'],
        calories: 534,
        protein: 7.8,
        carbohydrates: 57.0,
        fat: 30.0,
        fiber: 2.0,
        sugar: 56.0,
        sodium: 150.0,
        servingSize: '40 g',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ResultScreen(
            product: product,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 400));

      // Verify product info
      expect(find.textContaining('Cadbury Dairy Milk'), findsWidgets);
      expect(find.textContaining('Cadbury'), findsWidgets);

      // Verify nutrients are visible and non-null
      expect(find.textContaining('534'), findsWidgets); // Calories
      expect(find.textContaining('7.8'), findsWidgets); // Protein
      expect(find.textContaining('57.0'), findsWidgets); // Carbs
      expect(find.textContaining('56.0'), findsWidgets); // Sugar

      // Verify Quaker is not displayed
      expect(find.text('Quaker Oats'), findsNothing);
    });
  });
}
