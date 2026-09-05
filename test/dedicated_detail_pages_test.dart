import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/core/model/food_product.dart';
import 'package:diet_compass/features/scan/result_screen.dart';
import 'package:diet_compass/features/scan/ingredients_detail_screen.dart';
import 'package:diet_compass/features/scan/full_nutrition_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fullProduct = FoodProduct(
    barcode: '9876543210',
    name: 'Organic Rolled Oat Milk',
    brand: 'DietCompass Organics',
    imageUrl: 'assets/images/product_quaker.png',
    ingredients: 'Filtered Water, Whole Grain Oats, Sea Salt, E476',
    allergens: const ['Oats'],
    calories: 140,
    protein: 4,
    carbohydrates: 20,
    fat: 5,
    saturatedFat: 1,
    fiber: 3,
    sugar: 6,
    sodium: 120,
    servingSize: '240 ml',
    packageSize: '1 Liter',
    claims: const ['Low Sodium', 'High Fiber'],
  );

  final partialProduct = FoodProduct(
    barcode: '1111222233',
    name: 'Minimal Snack Bar',
    brand: 'Simple Foods',
    imageUrl: '',
    ingredients: 'Almonds, Honey',
    allergens: const ['Almonds'],
    calories: 180,
    protein: 6,
    carbohydrates: null, // Null nutrient field
    fat: 10,
    saturatedFat: null, // Null nutrient field
    fiber: null,
    sugar: 8,
    sodium: null,
  );

  setUp(() {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      FlutterError.presentError(details);
    };
  });

  testWidgets('View Ingredients opens dedicated IngredientsDetailScreen with real product data', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: ResultScreen(product: fullProduct),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1000));

    // Tap top-right three dots
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, -500), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));

    // Tap View Ingredients
    final viewIngredientsFinder = find.text('View Ingredients');
    expect(viewIngredientsFinder, findsOneWidget);
    await tester.tap(viewIngredientsFinder);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify IngredientsDetailScreen is pushed
    expect(find.byType(IngredientsDetailScreen), findsOneWidget);
    expect(find.text('Ingredients'), findsOneWidget);
    expect(find.text('Organic Rolled Oat Milk'), findsWidgets);
    expect(find.text('DietCompass Organics'), findsWidgets);

    // Verify ingredients statement
    expect(find.text('Filtered Water, Whole Grain Oats, Sea Salt, E476'), findsOneWidget);

    // Test back button returns to ResultScreen
    await tester.tap(find.byTooltip('Back to Result').last);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(IngredientsDetailScreen), findsNothing);
    expect(find.byType(ResultScreen), findsOneWidget);
  });

  testWidgets('View Full Nutrition opens dedicated FullNutritionDetailScreen with real nutrition facts', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: ResultScreen(product: fullProduct),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1000));

    // Tap top-right three dots
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, -500), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));

    // Tap View Full Nutrition
    final viewNutritionFinder = find.text('View Full Nutrition');
    expect(viewNutritionFinder, findsOneWidget);
    await tester.tap(viewNutritionFinder);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify FullNutritionDetailScreen is pushed
    expect(find.byType(FullNutritionDetailScreen), findsOneWidget);
    expect(find.text('Full Nutrition'), findsOneWidget);
    expect(find.text('140 kcal'), findsOneWidget);
    expect(find.text('4.0 g'), findsOneWidget);
    expect(find.text('20.0 g'), findsOneWidget);
    expect(find.text('6.0 g'), findsOneWidget);

    // Test back button returns to ResultScreen
    await tester.tap(find.byTooltip('Back to Result').last);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(FullNutritionDetailScreen), findsNothing);
    expect(find.byType(ResultScreen), findsOneWidget);
  });

  testWidgets('FullNutritionDetailScreen handles missing/null nutrients cleanly without fake zeros', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: FullNutritionDetailScreen(product: partialProduct),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('180 kcal'), findsOneWidget);
    expect(find.text('Not available'), findsWidgets);
    expect(find.text('0 g'), findsNothing);
    expect(find.text('0.0 g'), findsNothing);
  });
}
