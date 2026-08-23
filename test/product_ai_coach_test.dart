import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/core/model/food_product.dart';
import 'package:diet_compass/core/model/ai_analysis_model.dart';
import 'package:diet_compass/core/services/ai_service.dart';
import 'package:diet_compass/features/scan/widgets/product_ai_coach_sheet.dart';
import 'package:diet_compass/features/scan/result_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testProduct = FoodProduct(
    barcode: '7622201497984',
    name: 'Cadbury Dairy Milk Silk Chocolate',
    brand: 'Cadbury',
    imageUrl: '',
    allergens: const ['Milk'],
    ingredients: 'Sugar, Cocoa Butter, Milk Solids, Cocoa Solids, Emulsifiers (442, 476)',
    calories: 534,
    protein: 7.3,
    carbohydrates: 57.0,
    sugar: 56.0,
    fat: 31.0,
    sodium: 150.0,
    fiber: 2.0,
  );

  final testCompatibility = ProductCompatibility(
    score: 51,
    status: 'Moderate Match',
    isSuitable: true,
    allergyAlerts: const [],
    dietaryAlerts: const [],
    positiveFactors: const ['Provides quick energy'],
    concerns: const ['High in sugar (56g/100g)', 'Calorie dense (534 kcal)'],
    summary: 'Cadbury Dairy Milk Silk Chocolate receives a score of 51/100.',
    recommendation: 'Enjoy in moderation as an occasional treat.',
    items: const [],
  );

  group('Product AI Coach UI & Bottom Sheet Tests', () {
    testWidgets('ProductAiCoachSheet renders product context, score, header, and suggestions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductAiCoachSheet(
              product: testProduct,
              compatibility: testCompatibility,
              overallScore: 51,
              goodPoints: const ['Provides quick energy'],
              watchPoints: const ['High in sugar (56g/100g)'],
            ),
          ),
        ),
      );

      // Verify Header & Subtitle
      expect(find.text('Ask AI About This Product'), findsOneWidget);
      expect(find.text('Get personalized answers about this product'), findsOneWidget);

      // Verify Product Context Card
      expect(find.text('Cadbury Dairy Milk Silk Chocolate'), findsAtLeastNWidgets(1));
      expect(find.text('Cadbury'), findsOneWidget);
      expect(find.text('51%'), findsOneWidget);

      // Verify Suggested Question Chips
      expect(find.byType(ActionChip), findsWidgets);
      expect(find.text('Is this product good for me?'), findsOneWidget);
      expect(find.text('Why is my compatibility score 51%?'), findsOneWidget);

      // Verify Input Field
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('ResultScreen quick action "Ask AI Coach" opens ProductAiCoachSheet', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResultScreen(
            product: testProduct,
            initialCompatibility: testCompatibility,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      final askAiCoachFinder = find.text('Ask AI Coach');
      await tester.scrollUntilVisible(
        askAiCoachFinder,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(askAiCoachFinder, findsOneWidget);

      await tester.tap(askAiCoachFinder);
      await tester.pump(const Duration(milliseconds: 500));

      // Verify bottom sheet opened
      expect(find.text('Ask AI About This Product'), findsOneWidget);
      expect(find.text('Get personalized answers about this product'), findsOneWidget);
    });
  });
}
