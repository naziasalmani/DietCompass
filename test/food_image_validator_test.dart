import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/core/services/food_image_validator.dart';
import 'package:diet_compass/core/model/food_product.dart';

void main() {
  group('FoodImageValidator Tests', () {
    final validator = FoodImageValidator.instance;

    test('Test A & B & C: Keyboard / Laptop sticker text is REJECTED', () {
      final ocrText = '''
intel
CORE i5
8th Gen
CTRL + ALT DELETE
      ''';

      final candidate = FoodProduct(
        barcode: 'ocr_intel_123',
        name: 'Core i5 8th Gen Tech Energy Bar',
        brand: 'Intel',
        imageUrl: '',
        ingredients: 'None',
        allergens: [],
        calories: 150,
        protein: 4,
        carbohydrates: 20,
        fat: 5,
        fiber: 0,
        sugar: 0,
        sodium: 0,
      );

      final result = validator.validateTextAndCandidate(
        ocrText: ocrText,
        candidateProduct: candidate,
        geminiIsFoodProduct: false, // Gemini reported not food
      );

      expect(result.isFoodProduct, isFalse);
      expect(result.rejectionReason, contains('Gemini indicated non-food'));
    });

    test('Test E & F: Keyboard text without food evidence is REJECTED even if candidate created', () {
      final ocrText = 'CTRL + ALT DELETE\nWINDOW SYSTEM';

      final candidate = FoodProduct(
        barcode: '',
        name: 'CTRL ALT DELETE Snack',
        brand: '',
        imageUrl: '',
        ingredients: '',
        allergens: [],
        calories: 0,
        protein: 0,
        carbohydrates: 0,
        fat: 0,
        fiber: 0,
        sugar: 0,
        sodium: 0,
      );

      final result = validator.validateTextAndCandidate(
        ocrText: ocrText,
        candidateProduct: candidate,
        geminiIsFoodProduct: true,
      );

      expect(result.isFoodProduct, isFalse);
      expect(result.rejectionReason, contains('No food packaging, ingredients list, or nutrition facts label was detected'));
    });

    test('Test G & H: Clear nutrition facts or ingredients label is ACCEPTED', () {
      final ocrText = '''
Dairy Milk Chocolate
Nutrition Facts
Serving Size 1 bar (43g)
Calories 220
Total Fat 13g
Sodium 35mg
Total Carbohydrate 25g
Protein 3g
Ingredients: Milk chocolate, sugar, cocoa butter, milk, chocolate liquor.
      ''';

      final candidate = FoodProduct(
        barcode: '',
        name: 'Dairy Milk',
        brand: 'Cadbury',
        imageUrl: '',
        ingredients: 'Milk chocolate, sugar, cocoa butter',
        allergens: ['milk'],
        calories: 220,
        protein: 3,
        carbohydrates: 25,
        fat: 13,
        fiber: 1,
        sugar: 15,
        sodium: 0.035,
      );

      final result = validator.validateTextAndCandidate(
        ocrText: ocrText,
        candidateProduct: candidate,
        geminiIsFoodProduct: true,
      );

      expect(result.isFoodProduct, isTrue);
    });

    test('Test K: Real food product with unusual name is ACCEPTED with evidence', () {
      final ocrText = '''
CTRL + ALT DELETE
ENERGY DRINK
Serving Size 250ml
Calories 110
Ingredients: Carbonated water, high fructose corn syrup, citric acid, caffeine.
Nutrition Information per 100ml
      ''';

      final candidate = FoodProduct(
        barcode: '',
        name: 'CTRL + ALT DELETE',
        brand: 'Cyber Energy',
        imageUrl: '',
        ingredients: 'Carbonated water, high fructose corn syrup, citric acid',
        allergens: [],
        calories: 110,
        protein: 0,
        carbohydrates: 28,
        fat: 0,
        fiber: 0,
        sugar: 27,
        sodium: 0.01,
      );

      final result = validator.validateTextAndCandidate(
        ocrText: ocrText,
        candidateProduct: candidate,
        geminiIsFoodProduct: true,
      );

      expect(result.isFoodProduct, isTrue, reason: 'Unusual product name with valid food evidence MUST be accepted');
    });

    test('Test L: Valid food scan followed by keyboard image state test', () {
      final keyboardText = 'Intel Core i7 Windows 11';
      final res = validator.validateTextAndCandidate(
        ocrText: keyboardText,
        candidateProduct: null,
      );

      expect(res.isFoodProduct, isFalse);
    });
  });
}
