import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/core/model/food_product.dart';
import 'package:diet_compass/core/services/recommendation_service.dart';
import 'package:diet_compass/features/ai/ai_recommendation_screen.dart';
import 'package:diet_compass/features/scan/result_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  final dairyMilk = FoodProduct(
    barcode: '7622201497984',
    name: 'Cadbury Dairy Milk',
    brand: 'Cadbury',
    imageUrl: 'https://example.com/dairymilk.jpg',
    calories: 534.0,
    protein: 7.3,
    carbohydrates: 57.0,
    fat: 30.5,
    fiber: 2.1,
    sugar: 56.0,
    sodium: 0.15,
    ingredients: 'Sugar, Milk Solids, Cocoa Butter, Cocoa Solids, Emulsifiers',
    allergens: const ['Milk'],
  );

  final maggi = FoodProduct(
    barcode: '8901058852394',
    name: 'Maggi Masala Noodles',
    brand: 'Nestlé',
    imageUrl: 'https://example.com/maggi.jpg',
    calories: 427.0,
    protein: 8.0,
    carbohydrates: 63.5,
    fat: 15.7,
    fiber: 3.6,
    sugar: 2.2,
    sodium: 1020.0,
    ingredients: 'Wheat Flour, Palm Oil, Salt, Minerals, Spices and Condiments',
    allergens: const ['Gluten', 'Wheat'],
  );

  group('DietCompass AI Recommendation Screen Flow Tests', () {
    test('TEST 1 (Service): Cadbury Dairy Milk returns 6–8 real chocolate alternatives', () async {
      final recs = await RecommendationService.instance.getCategoryAwareAlternatives(
        dairyMilk,
        limit: 8,
      );

      expect(recs.length, inInclusiveRange(6, 8));

      for (final rec in recs) {
        final name = rec.product.name.toLowerCase();
        final brand = rec.product.brand.toLowerCase();
        final ing = rec.product.ingredients.toLowerCase();

        final isChocolate = name.contains('chocolate') ||
            name.contains('bournville') ||
            name.contains('cocoa') ||
            name.contains('dark') ||
            name.contains('amul') ||
            name.contains('lindt') ||
            name.contains('ketofy') ||
            name.contains('zevic') ||
            name.contains('mojo') ||
            name.contains('hershey') ||
            ing.contains('cocoa') ||
            ing.contains('chocolate');

        expect(isChocolate, isTrue, reason: '${rec.product.name} must be a chocolate product');
        expect(rec.product.name.toLowerCase(), isNot(equals(dairyMilk.name.toLowerCase())));
        expect(rec.compatibility.score, greaterThan(0));
      }
    });

    test('TEST 2 (Service): Maggi Masala Noodles returns 6–8 real noodle/pasta alternatives', () async {
      final recs = await RecommendationService.instance.getCategoryAwareAlternatives(
        maggi,
        limit: 8,
      );

      expect(recs.length, inInclusiveRange(6, 8));

      for (final rec in recs) {
        final name = rec.product.name.toLowerCase();
        final ing = rec.product.ingredients.toLowerCase();

        final isNoodleOrPasta = name.contains('noodle') ||
            name.contains('noodles') ||
            name.contains('pasta') ||
            name.contains('spaghetti') ||
            name.contains('fusilli') ||
            name.contains('macaroni') ||
            name.contains('hakka') ||
            name.contains('oodles') ||
            name.contains('slurrp') ||
            name.contains('atta') ||
            name.contains('oats') ||
            ing.contains('flour') ||
            ing.contains('wheat');

        expect(isNoodleOrPasta, isTrue, reason: '${rec.product.name} must be a noodle/pasta alternative');
        expect(rec.product.name.toLowerCase(), isNot(equals(maggi.name.toLowerCase())));
        expect(rec.compatibility.score, greaterThan(0));
      }
    });

    testWidgets('TEST 1 (UI Flow): ResultScreen -> Tap AI Recommendation -> AiShoppingScreen receives Cadbury Dairy Milk', (tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ResultScreen(
            product: dairyMilk,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Find and tap "Ai Recommendation" button
      final aiRecBtn = find.text('Ai Recommendation');
      expect(aiRecBtn, findsOneWidget);

      await tester.tap(aiRecBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 2. Verify AiShoppingScreen is opened with Cadbury Dairy Milk context
      expect(find.byType(AiShoppingScreen), findsOneWidget);
      expect(find.text('AI RECOMMENDATIONS FOR'), findsOneWidget);
      expect(find.text(dairyMilk.name), findsWidgets);
      expect(find.text('Better Alternatives for ${dairyMilk.name}'), findsOneWidget);
    });

    testWidgets('TEST 2 (UI Flow): ResultScreen -> Tap AI Recommendation -> AiShoppingScreen receives Maggi Masala Noodles', (tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ResultScreen(
            product: maggi,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Find and tap "Ai Recommendation" button
      final aiRecBtn = find.text('Ai Recommendation');
      expect(aiRecBtn, findsOneWidget);

      await tester.tap(aiRecBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 2. Verify AiShoppingScreen is opened with Maggi Masala Noodles context
      expect(find.byType(AiShoppingScreen), findsOneWidget);
      expect(find.text('AI RECOMMENDATIONS FOR'), findsOneWidget);
      expect(find.text(maggi.name), findsWidgets);
      expect(find.text('Better Alternatives for ${maggi.name}'), findsOneWidget);
    });

    testWidgets('TEST 3 (UI Flow): ResultScreen "Better Alternatives for You" displays 1 to 3 items max', (tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ResultScreen(
            product: dairyMilk,
            alternatives: const [
              AlternativeProduct(asset: 'assets/images/dark_chocolate.png', name: 'Amul Dark Chocolate', subtitle: 'Amul', score: 85, differentiator: 'Low Sugar'),
              AlternativeProduct(asset: 'assets/images/dark_chocolate.png', name: 'Bournville Dark Chocolate', subtitle: 'Cadbury', score: 82, differentiator: 'Antioxidants'),
              AlternativeProduct(asset: 'assets/images/dark_chocolate.png', name: 'Lindt Excellence 70%', subtitle: 'Lindt', score: 88, differentiator: 'Higher Cocoa'),
              AlternativeProduct(asset: 'assets/images/dark_chocolate.png', name: 'Zevic Sugar Free Dark', subtitle: 'Zevic', score: 90, differentiator: 'Sugar Free'),
            ],
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify "Better Alternatives for You" section exists
      expect(find.text('Better Alternatives for You'), findsOneWidget);

      // 2. Verify only 3 items max are rendered (4th item Zevic is not rendered in AI Result)
      expect(find.text('Amul Dark Chocolate'), findsOneWidget);
      expect(find.text('Bournville Dark Chocolate'), findsOneWidget);
      expect(find.text('Lindt Excellence 70%'), findsOneWidget);
      expect(find.text('Zevic Sugar Free Dark'), findsNothing);
    });
  });
}
