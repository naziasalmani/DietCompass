import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/core/model/food_product.dart';
import 'package:diet_compass/core/services/ingredient_intelligence_service.dart';

void main() {
  group('IngredientIntelligenceService Tests', () {
    final service = IngredientIntelligenceService.instance;

    test('Detects multiple disguised / alternate sugar sources accurately', () {
      final product = FoodProduct(
        barcode: '12345678',
        name: 'Energy Cereal Bar',
        brand: 'SnackCo',
        imageUrl: 'https://example.com/bar.jpg',
        ingredients: 'Whole grain oats, glucose syrup, maltodextrin, invert sugar, palm oil, salt',
        allergens: ['oats'],
        calories: 380.0,
        protein: 5.0,
        carbohydrates: 65.0,
        fat: 10.0,
        fiber: 4.0,
        sugar: 18.0,
        sodium: 0.25,
      );

      final result = service.analyze(product);

      expect(result.hasSugarRelated, isTrue);
      final sugarNames = result.sugarRelatedIngredients.map((e) => e.name.toLowerCase()).toList();
      expect(sugarNames, contains('glucose syrup'));
      expect(sugarNames, contains('maltodextrin'));
      expect(sugarNames, contains('invert sugar'));

      // Check non-accusatory educational explanation
      expect(result.summary, contains('Sugar-related ingredients identified'));
      for (final item in result.sugarRelatedIngredients) {
        expect(item.explanation.isNotEmpty, isTrue);
      }
    });

    test('Detects artificial / non-nutritive sweeteners', () {
      final product = FoodProduct(
        barcode: '99887766',
        name: 'Diet Soda',
        brand: 'FizzCo',
        imageUrl: 'https://example.com/soda.jpg',
        ingredients: 'Carbonated water, caramel color, aspartame, acesulfame potassium, phosphoric acid',
        allergens: [],
        calories: 0.0,
        protein: 0.0,
        carbohydrates: 0.0,
        fat: 0.0,
        fiber: 0.0,
        sugar: 0.0,
        sodium: 0.04,
      );

      final result = service.analyze(product);

      expect(result.hasSweeteners, isTrue);
      final sweetenerNames = result.artificialSweeteners.map((e) => e.name.toLowerCase()).toList();
      expect(sweetenerNames, contains('aspartame'));
      expect(sweetenerNames, contains('acesulfame potassium'));
    });

    test('Detects formulated additives & preservatives objectively', () {
      final product = FoodProduct(
        barcode: '55443322',
        name: 'Packaged Sausage',
        brand: 'MeatCo',
        imageUrl: '',
        ingredients: 'Pork, water, salt, spices, sodium nitrite, monosodium glutamate, bha',
        allergens: [],
        calories: 280.0,
        protein: 14.0,
        carbohydrates: 2.0,
        fat: 24.0,
        fiber: 0.0,
        sugar: 1.0,
        sodium: 0.85,
      );

      final result = service.analyze(product);

      expect(result.hasAdditives, isTrue);
      final additiveNames = result.additives.map((e) => e.name.toLowerCase()).toList();
      expect(additiveNames.any((n) => n.contains('sodium nitrite')), isTrue);
      expect(additiveNames.any((n) => n.contains('monosodium glutamate')), isTrue);
      expect(additiveNames.any((n) => n.contains('butylated hydroxyanisole')), isTrue);
    });

    test('Performs objective Claim Verification for Low Sugar & High Protein', () {
      final conflictingProduct = FoodProduct(
        barcode: '44332211',
        name: 'Sugar-Free Cookie',
        brand: 'SweetTreats',
        imageUrl: '',
        ingredients: 'Wheat flour, maltodextrin, dextrose, palm oil',
        allergens: ['gluten'],
        calories: 320.0,
        protein: 3.0,
        carbohydrates: 55.0,
        fat: 12.0,
        fiber: 1.0,
        sugar: 8.0, // High sugar despite claim
        sodium: 0.15,
        claims: ['No Added Sugar', 'High Protein'],
      );

      final result = service.analyze(conflictingProduct);

      expect(result.hasClaimChecks, isTrue);
      expect(result.claimChecks.length, 2);

      final sugarClaim = result.claimChecks.firstWhere((c) => c.claim == 'No Added Sugar');
      expect(sugarClaim.status, 'Review Recommended');
      expect(sugarClaim.explanation, contains('sugar-related ingredients'));

      final proteinClaim = result.claimChecks.firstWhere((c) => c.claim == 'High Protein');
      expect(proteinClaim.status, 'Review Recommended');
      expect(proteinClaim.explanation, contains('Contains 3.0g protein'));
    });

    test('Data Confidence calculation adheres to completeness standards', () {
      final highConfidenceProduct = FoodProduct(
        barcode: '11223344',
        name: 'Rolled Oats 100% Whole Grain',
        brand: 'Pure Farms',
        imageUrl: 'https://example.com/oats.jpg',
        ingredients: 'Whole grain rolled oats',
        allergens: ['oats'],
        calories: 375.0,
        protein: 13.5,
        carbohydrates: 62.0,
        fat: 7.0,
        fiber: 10.0,
        sugar: 1.0,
        sodium: 0.01,
      );

      expect(highConfidenceProduct.dataConfidence, DataConfidence.high);

      final moderateConfidenceProduct = FoodProduct(
        barcode: '11223344',
        name: 'Rolled Oats',
        brand: 'Pure Farms',
        imageUrl: '',
        ingredients: 'Whole grain rolled oats',
        allergens: [],
        calories: 375.0,
        protein: 13.5,
        carbohydrates: 62.0,
        fat: null,
        fiber: null,
        sugar: null,
        sodium: null,
      );

      expect(moderateConfidenceProduct.dataConfidence, DataConfidence.moderate);

      final lowConfidenceProduct = FoodProduct(
        barcode: '11223344',
        name: 'Unknown Product',
        brand: 'Unknown Brand',
        imageUrl: '',
        ingredients: '',
        allergens: [],
        calories: null,
        protein: null,
        carbohydrates: null,
        fat: null,
        fiber: null,
        sugar: null,
        sodium: null,
      );

      expect(lowConfidenceProduct.dataConfidence, DataConfidence.low);
    });

    test('Detects significant multi-source discrepancy when merging', () {
      final source1 = FoodProduct(
        barcode: '77665544',
        name: 'Fruit Jam',
        brand: 'BerryCo',
        imageUrl: 'https://example.com/jam.jpg',
        ingredients: 'Strawberries, sugar, pectin',
        allergens: [],
        calories: 250.0,
        protein: 0.5,
        carbohydrates: 60.0,
        fat: 0.1,
        fiber: 1.0,
        sugar: 45.0, // Source 1: 45g sugar
        sodium: 0.02,
        source: 'Open Food Facts',
      );

      final source2 = FoodProduct(
        barcode: '77665544',
        name: 'Fruit Jam',
        brand: 'BerryCo',
        imageUrl: '',
        ingredients: '',
        allergens: [],
        calories: 120.0,
        protein: 0.5,
        carbohydrates: 25.0,
        fat: 0.1,
        fiber: 1.0,
        sugar: 10.0, // Source 2: 10g sugar (major conflict)
        sodium: 0.02,
        source: 'USDA Database',
      );

      final merged = source1.mergeWith(source2);

      expect(merged.discrepancies.isNotEmpty, isTrue);
      expect(merged.discrepancies.any((d) => d.contains('Sugar discrepancy')), isTrue);
    });
  });
}
