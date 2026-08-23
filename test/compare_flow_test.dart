import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/core/model/food_product.dart';
import 'package:diet_compass/core/model/ai_analysis_model.dart';
import 'package:diet_compass/features/scan/compare_screen.dart';

void main() {
  group('DietCompass Product Comparison Tests', () {
    testWidgets('CompareScreen renders current product and best alternative with full nutrition table', (tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final currentProduct = FoodProduct(
        barcode: '8901234567890',
        name: 'Cadbury Dairy Milk',
        brand: 'Cadbury',
        imageUrl: '',
        ingredients: 'Sugar, Milk Solids, Cocoa Butter, Cocoa Solids, Emulsifiers (442, 476)',
        allergens: ['Milk'],
        calories: 532,
        protein: 7.8,
        carbohydrates: 58.5,
        fat: 30.5,
        fiber: 2.1,
        sugar: 57.0,
        sodium: 140.0,
      );

      final bestAlternative = FoodProduct(
        barcode: '8909876543210',
        name: 'Amul Dark Chocolate 75%',
        brand: 'Amul',
        imageUrl: '',
        ingredients: 'Cocoa Solids, Sugar, Cocoa Butter, Emulsifier (322)',
        allergens: ['Soy'],
        calories: 490,
        protein: 8.5,
        carbohydrates: 38.0,
        fat: 33.0,
        fiber: 7.5,
        sugar: 24.0,
        sodium: 20.0,
      );

      final nutritionComp = ProductNutritionComparison(
        sugarDiff: 33.0,
        proteinDiff: 0.7,
        fiberDiff: 5.4,
        calorieDiff: 42,
        sodiumDiff: 120,
        highlights: ['↓ 33g Less Sugar', '↑ High in Fibre'],
        differentiator: '↓ 33g Less Sugar',
        matchReason: 'Provides 24.0g sugar per 100g vs 57.0g in Cadbury Dairy Milk.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CompareScreen(
            currentProduct: currentProduct,
            alternativeProduct: bestAlternative,
            nutritionComparison: nutritionComp,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));

      // Check header
      expect(find.text('Product Comparison'), findsOneWidget);
      expect(find.text('See how your choice compares with a healthier alternative'), findsOneWidget);

      // Check product cards
      expect(find.text('Cadbury Dairy Milk'), findsOneWidget);
      expect(find.text('Cadbury'), findsOneWidget);
      expect(find.text('Your Choice'), findsWidgets);

      expect(find.text('Amul Dark Chocolate 75%'), findsOneWidget);
      expect(find.text('Amul'), findsOneWidget);
      expect(find.text('⭐ Best Alternative'), findsOneWidget);

      // Check "Why this alternative?" section
      expect(find.text('Why this alternative?'), findsOneWidget);
      expect(find.textContaining('33g less sugar'), findsOneWidget);

      // Check nutrition comparison table
      expect(find.text('Nutrition Comparison'), findsOneWidget);
      expect(find.text('57.0 g'), findsOneWidget); // Current sugar
      expect(find.text('24.0 g'), findsOneWidget); // Alt sugar
      expect(find.text('7.8 g'), findsOneWidget);  // Current protein
      expect(find.text('8.5 g'), findsOneWidget);  // Alt protein

      // Check Personal Health Compatibility
      expect(find.text('Personal Health Compatibility'), findsOneWidget);
      expect(find.text('Weight Management'), findsOneWidget);
      expect(find.text('Heart Health'), findsOneWidget);

      // Check Ingredient Insights
      expect(find.text('Ingredient Insights'), findsOneWidget);

      // Check Action Button
      expect(find.text('View Full Analysis for Amul Dark Chocolate 75%'), findsOneWidget);
    });

    testWidgets('CompareScreen gracefully displays "Not available" for null/missing nutrient data (never 0)', (tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final currentProduct = FoodProduct(
        barcode: '11111111',
        name: 'Artisan Biscuit',
        brand: 'Bakery Co',
        imageUrl: '',
        ingredients: 'Flour, Butter',
        allergens: [],
        calories: null,
        protein: null,
        carbohydrates: null,
        fat: null,
        fiber: null,
        sugar: null,
        sodium: null,
      );

      final bestAlternative = FoodProduct(
        barcode: '22222222',
        name: 'Oat Digestive Biscuit',
        brand: 'NutriBake',
        imageUrl: '',
        ingredients: 'Whole Oats, Wheat Flour',
        allergens: [],
        calories: 420,
        protein: 9.0,
        carbohydrates: 62.0,
        fat: 15.0,
        fiber: 6.5,
        sugar: 12.0,
        sodium: 180.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CompareScreen(
            currentProduct: currentProduct,
            alternativeProduct: bestAlternative,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));

      // Check that missing nutrients show "Not available" and NOT "0 g" or "0 kcal"
      expect(find.text('Not available'), findsWidgets);
      expect(find.text('0.0 g'), findsNothing);
      expect(find.text('0 kcal'), findsNothing);
      expect(find.text('0 mg'), findsNothing);
    });

    testWidgets('CompareScreen shows friendly unavailable state when alternative product is not found', (tester) async {
      final rareProduct = FoodProduct(
        barcode: '9999999999',
        name: 'Rare Unclassified Botanical Tonic',
        brand: 'HerbalLab',
        imageUrl: '',
        ingredients: 'Secret Botanical Distillate',
        allergens: [],
        calories: null,
        protein: null,
        carbohydrates: null,
        fat: null,
        fiber: null,
        sugar: null,
        sodium: null,
      );

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: CompareScreen(
              currentProduct: rareProduct,
              alternativeProduct: null, // trigger fetch which will complete with empty
            ),
          ),
        );

        for (int i = 0; i < 40; i++) {
          await Future.delayed(const Duration(milliseconds: 100));
          await tester.pump();
          if (find.text('Comparison unavailable').evaluate().isNotEmpty) {
            break;
          }
        }
      });

      // If no alternatives returned, friendly unavailable state is shown
      expect(find.text('Comparison unavailable'), findsOneWidget);
      expect(find.textContaining("We couldn't find a suitable alternative"), findsOneWidget);
      expect(find.text('Back to Product Analysis'), findsOneWidget);
    });
  });
}
