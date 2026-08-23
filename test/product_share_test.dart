import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/core/model/food_product.dart';
import 'package:diet_compass/features/scan/result_screen.dart';
import 'package:diet_compass/features/scan/services/product_share_service.dart';
import 'package:diet_compass/features/scan/widgets/product_share_card.dart';

void main() {
  group('DietCompass Product Share Tests', () {
    test('generateShareText produces dynamic, branded analysis with full data', () {
      final product = FoodProduct(
        barcode: '8901234567890',
        name: 'Organic Rolled Oats',
        brand: 'Quaker',
        imageUrl: 'https://example.com/oats.png',
        ingredients: '100% Whole Grain Rolled Oats',
        allergens: ['Gluten'],
        calories: 389,
        protein: 16.9,
        carbohydrates: 66.3,
        fat: 6.9,
        fiber: 10.6,
        sugar: 1.0,
        sodium: 2.0,
      );

      final nutrients = [
        const NutrientStat(label: 'Calories', value: '389', unit: 'kcal', icon: Icons.local_fire_department, color: Colors.purple, badge: 'Moderate'),
        const NutrientStat(label: 'Protein', value: '16.9', unit: 'g', icon: Icons.fitness_center, color: Colors.green, badge: 'High'),
        const NutrientStat(label: 'Sugar', value: '1.0', unit: 'g', icon: Icons.icecream, color: Colors.green, badge: 'Low Sugar'),
        const NutrientStat(label: 'Fiber', value: '10.6', unit: 'g', icon: Icons.eco_outlined, color: Colors.green, badge: 'High'),
      ];

      final compatibility = [
        const CompatibilityItem(icon: Icons.monitor_weight_outlined, label: 'Weight Management', rating: 'Good'),
        const CompatibilityItem(icon: Icons.favorite_outline, label: 'Heart Health', rating: 'Excellent'),
      ];

      final goodPoints = [
        const ProsConsItem(title: 'High in dietary fiber', subtitle: 'Supports healthy digestion'),
        const ProsConsItem(title: 'Zero added sugar', subtitle: 'Great for blood sugar control'),
      ];

      final watchPoints = [
        const ProsConsItem(title: 'Contains Gluten', subtitle: 'Check if you have celiac sensitivity'),
      ];

      final shareText = ProductShareService.instance.generateShareText(
        product: product,
        overallScore: 88,
        compatibilityScore: 92,
        nutrients: nutrients,
        compatibility: compatibility,
        goodPoints: goodPoints,
        watchPoints: watchPoints,
        aiRecommendation: 'Excellent whole-grain breakfast option high in beta-glucan fiber.',
      );

      // Verify branding
      expect(shareText, contains('DietCompass • AI Food Analysis'));
      expect(shareText, contains('Scanned with DietCompass'));

      // Verify product info
      expect(shareText, contains('Organic Rolled Oats (Quaker)'));
      expect(shareText, contains('8901234567890'));

      // Verify scores
      expect(shareText, contains('88/100 (Excellent Choice)'));
      expect(shareText, contains('92% Match'));

      // Verify nutrients
      expect(shareText, contains('Calories: 389 kcal'));
      expect(shareText, contains('Protein: 16.9 g'));
      expect(shareText, contains('Sugar: 1.0 g'));
      expect(shareText, contains('Fiber: 10.6 g'));

      // Verify pros & cons
      expect(shareText, contains('High in dietary fiber'));
      expect(shareText, contains('Contains Gluten'));

      // Verify recommendation
      expect(shareText, contains('Excellent whole-grain breakfast option'));
    });

    test('generateShareText handles products with missing/null API fields gracefully', () {
      final product = FoodProduct(
        barcode: '',
        name: 'Mystery Beverage',
        brand: '',
        imageUrl: '',
        ingredients: 'Water, Flavoring',
        allergens: [],
        calories: null,
        protein: null,
        carbohydrates: null,
        fat: null,
        fiber: null,
        sugar: null,
        sodium: null,
      );

      // Null nutrients marked as unavailable
      final nutrients = [
        const NutrientStat(label: 'Calories', value: 'Unavailable', unit: '', icon: Icons.local_fire_department, color: Colors.grey, badge: 'Unknown', isAvailable: false),
        const NutrientStat(label: 'Sugar', value: 'Unavailable', unit: '', icon: Icons.icecream, color: Colors.grey, badge: 'Unknown', isAvailable: false),
      ];

      final shareText = ProductShareService.instance.generateShareText(
        product: product,
        overallScore: 50,
        compatibilityScore: 60,
        nutrients: nutrients,
        compatibility: [],
        goodPoints: [],
        watchPoints: [],
        aiRecommendation: null,
      );

      // Verify branding and name
      expect(shareText, contains('DietCompass • AI Food Analysis'));
      expect(shareText, contains('Mystery Beverage'));

      // Verify missing barcode is not rendered
      expect(shareText.contains('Barcode:'), isFalse);

      // Verify missing nutrients are not printed with fake 0s
      expect(shareText.contains('Calories: 0'), isFalse);
      expect(shareText.contains('Sugar: 0'), isFalse);
      expect(shareText.contains('Nutrition Snapshot:'), isFalse);
    });

    testWidgets('ProductShareCard widget renders properly without overflow', (tester) async {
      final product = FoodProduct(
        barcode: '12345678',
        name: 'Greek Yogurt 0% Fat',
        brand: 'Chobani',
        imageUrl: '',
        ingredients: 'Cultured Pasteurized Nonfat Milk',
        allergens: ['Milk'],
        calories: 90,
        protein: 15.0,
        carbohydrates: 6.0,
        fat: 0.0,
        fiber: 0.0,
        sugar: 4.0,
        sodium: 55.0,
      );

      final nutrients = [
        const NutrientStat(label: 'Calories', value: '90', unit: 'kcal', icon: Icons.local_fire_department, color: Colors.purple, badge: 'Low'),
        const NutrientStat(label: 'Protein', value: '15.0', unit: 'g', icon: Icons.fitness_center, color: Colors.green, badge: 'High'),
        const NutrientStat(label: 'Sugar', value: '4.0', unit: 'g', icon: Icons.icecream, color: Colors.green, badge: 'Low Sugar'),
      ];

      final compatibility = [
        const CompatibilityItem(icon: Icons.monitor_weight_outlined, label: 'Weight Management', rating: 'Excellent'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProductShareCard(
                product: product,
                overallScore: 92,
                compatibilityScore: 95,
                nutrients: nutrients,
                compatibility: compatibility,
                goodPoints: const [ProsConsItem(title: 'High Protein', subtitle: '15g per cup')],
                watchPoints: const [ProsConsItem(title: 'Contains Dairy', subtitle: 'Milk allergen')],
                aiRecommendation: 'Great protein-dense snack.',
              ),
            ),
          ),
        ),
      );

      expect(find.text('DietCompass'), findsOneWidget);
      expect(find.text('Greek Yogurt 0% Fat'), findsOneWidget);
      expect(find.text('Chobani'), findsOneWidget);
      expect(find.text('92'), findsOneWidget);
      expect(find.text('95'), findsOneWidget);
      expect(find.text('High Protein'), findsOneWidget);
      expect(find.text('Contains Dairy'), findsOneWidget);
      expect(find.text('Great protein-dense snack.'), findsOneWidget);
    });
  });
}
