import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/core/model/food_product.dart';
import 'package:diet_compass/features/scan/result_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testProduct = FoodProduct(
    barcode: '1234567890',
    name: 'Oat Milk Organic',
    brand: 'DietCompass Organics',
    imageUrl: 'assets/images/product_quaker.png',
    ingredients: 'Filtered Water, Organic Oats, Sea Salt',
    allergens: const ['Oats'],
    calories: 120,
    protein: 3,
    carbohydrates: 16,
    fat: 5,
    fiber: 2,
    sugar: 4,
    sodium: 100,
  );

  Widget buildTestWidget() {
    return MaterialApp(
      home: ResultScreen(
        product: testProduct,
      ),
    );
  }

  setUp(() {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      FlutterError.presentError(details);
    };
  });

  testWidgets('ResultScreen three-dot menu displays exactly 5 options', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget());
    await tester.pump(const Duration(milliseconds: 2000));

    final moreButton = find.byIcon(Icons.more_horiz);
    expect(moreButton, findsOneWidget);

    await tester.tap(moreButton);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('View Ingredients'), findsOneWidget);
    expect(find.text('View Full Nutrition'), findsOneWidget);
    expect(find.text('Report Incorrect Information'), findsOneWidget);
    expect(find.text('Scan Another Product'), findsOneWidget);
    expect(find.text('Remove from Scan History'), findsOneWidget);
  });

  testWidgets('Report Incorrect Information opens report sheet with options', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget());
    await tester.pump(const Duration(milliseconds: 2000));

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, -300), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));

    final itemFinder = find.text('Report Incorrect Information');
    await tester.tap(itemFinder);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Report Incorrect Information'), findsWidgets);
    expect(find.text('Product name is incorrect'), findsOneWidget);
    expect(find.text('Nutrition information is incorrect'), findsOneWidget);
    expect(find.text('Ingredients are incorrect'), findsOneWidget);
    expect(find.text('Product image is incorrect'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('Submit Report'), findsOneWidget);
  });

  testWidgets('Remove from Scan History shows confirmation dialog', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget());
    await tester.pump(const Duration(milliseconds: 2000));

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, -300), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));

    final itemFinder = find.text('Remove from Scan History');
    await tester.tap(itemFinder);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Remove from scan history?'), findsOneWidget);
    expect(find.text('This scan will be removed from your history.'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Remove from scan history?'), findsNothing);
  });
}
