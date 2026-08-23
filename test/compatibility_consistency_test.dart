import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/core/model/food_product.dart';
import 'package:diet_compass/core/services/recommendation_service.dart';
import 'package:diet_compass/features/scan/result_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('DietCompass Compatibility Score Consistency & Single Source of Truth', () {
    final testProduct = FoodProduct(
      barcode: '8901234567890',
      name: 'Cadbury Bournville Dark Chocolate',
      brand: 'Cadbury',
      imageUrl: 'https://example.com/bournville.jpg',
      calories: 540.0,
      protein: 5.5,
      carbohydrates: 60.0,
      fat: 30.0,
      fiber: 7.0,
      sugar: 45.0,
      sodium: 50.0,
      ingredients: 'Cocoa solids, sugar, cocoa butter, emulsifiers',
      allergens: ['Milk', 'Soy'],
      nutriScore: 'd',
      novaGroup: 4,
    );

    test('Single Source of Truth: Compatibility calculation is 100% deterministic & cached', () {
      RecommendationService.instance.clearCompatibilityCache();

      final firstEval = RecommendationService.instance.evaluateCompatibility(testProduct);
      final secondEval = RecommendationService.instance.evaluateCompatibility(testProduct);
      final scoreViaCalc = RecommendationService.instance.calculateCompatibilityScore(testProduct);

      expect(firstEval.score, equals(secondEval.score));
      expect(firstEval.score, equals(scoreViaCalc));
      expect(identical(firstEval, secondEval), isTrue, reason: 'Cache must return identical instance for session');
    });

    testWidgets('ResultScreen immediately displays consistent initial compatibility score', (tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final initialEval = RecommendationService.instance.evaluateCompatibility(testProduct);

      await tester.pumpWidget(
        MaterialApp(
          home: ResultScreen(
            product: testProduct,
            initialCompatibility: initialEval,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1800));

      // Verify the score is rendered immediately
      expect(find.text('${initialEval.score}%'), findsWidgets);
      expect(find.text('Personalized Compatibility'), findsOneWidget);
    });
  });
}
