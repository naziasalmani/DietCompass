import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../model/food_product.dart';

/// Result of food-product image evidence validation.
class FoodImageValidationResult {
  final bool isFoodProduct;
  final double confidence;
  final String evidence;
  final String? rejectionReason;
  final FoodProduct? product;

  const FoodImageValidationResult({
    required this.isFoodProduct,
    this.confidence = 0.0,
    this.evidence = 'none',
    this.rejectionReason,
    this.product,
  });

  factory FoodImageValidationResult.valid({
    required FoodProduct product,
    required String evidence,
    double confidence = 1.0,
  }) {
    return FoodImageValidationResult(
      isFoodProduct: true,
      confidence: confidence,
      evidence: evidence,
      product: product,
    );
  }

  factory FoodImageValidationResult.invalid({
    required String reason,
    double confidence = 0.0,
  }) {
    return FoodImageValidationResult(
      isFoodProduct: false,
      confidence: confidence,
      evidence: 'none',
      rejectionReason: reason,
      product: null,
    );
  }
}

/// DietCompass — Food Image & Evidence Validator
/// Grounded validation gate that enforces real visual & textual food evidence
/// BEFORE any FoodProduct object is created or nutrition analysis is executed.
class FoodImageValidator {
  FoodImageValidator._();
  static final FoodImageValidator instance = FoodImageValidator._();

  /// Evaluates recognized OCR text for structural food evidence.
  /// Does NOT rely on hardcoded product name blacklists or generic text filters.
  bool hasFoodEvidence(RecognizedText recognizedText) {
    final rawText = recognizedText.text.trim();
    if (rawText.isEmpty) return false;

    final lowerText = rawText.toLowerCase();

    // 1. Check for Nutrition Facts panel markers
    final hasNutritionMarkers = _hasNutritionFactsEvidence(lowerText);

    // 2. Check for Ingredients list markers
    final hasIngredientMarkers = _hasIngredientsListEvidence(lowerText);

    // 3. Check for specific Food / Beverage / Serving markers
    final hasFoodServingMarkers = _hasFoodServingEvidence(lowerText);

    if (hasNutritionMarkers || hasIngredientMarkers || hasFoodServingMarkers) {
      return true;
    }

    return false;
  }

  /// Checks if OCR text contains clear nutrition facts panel markers.
  bool _hasNutritionFactsEvidence(String lowerText) {
    return lowerText.contains('nutrition facts') ||
        lowerText.contains('per 100g') ||
        lowerText.contains('per 100 ml') ||
        lowerText.contains('servings per') ||
        lowerText.contains('serving size') ||
        lowerText.contains('% daily value') ||
        lowerText.contains('% dv') ||
        (lowerText.contains('calories') && lowerText.contains('total fat')) ||
        (lowerText.contains('kcal') && lowerText.contains('protein')) ||
        (lowerText.contains('carbohydrate') && lowerText.contains('sodium'));
  }

  /// Checks if OCR text contains an authentic ingredients list structure.
  bool _hasIngredientsListEvidence(String lowerText) {
    if (lowerText.contains('ingredients:') ||
        lowerText.contains('ingredients;') ||
        lowerText.contains('contains:') ||
        lowerText.contains('may contain') ||
        lowerText.contains('ingredienser') ||
        lowerText.contains('zutaten') ||
        lowerText.contains('ingrédients')) {
      return true;
    }

    final foodIngredientTerms = [
      'water', 'sugar', 'salt', 'flour', 'milk', 'oil', 'cocoa', 'wheat',
      'syrup', 'starch', 'flavor', 'flavour', 'acid', 'lecithin', 'butter',
      'cream', 'whey', 'extract', 'powder', 'yeast', 'vinegar', 'juice'
    ];

    int matchCount = 0;
    for (final term in foodIngredientTerms) {
      if (lowerText.contains(term)) {
        matchCount++;
      }
    }

    return matchCount >= 3;
  }

  /// Checks for serving size or packaged food indicators.
  bool _hasFoodServingEvidence(String lowerText) {
    return lowerText.contains('net wt') ||
        lowerText.contains('net weight') ||
        lowerText.contains('best before') ||
        lowerText.contains('expiry date') ||
        lowerText.contains('use by') ||
        RegExp(r'\b\d+\s*(g|ml|kg|l|oz|fl\s*oz)\b').hasMatch(lowerText);
  }

  /// Helper for text-only validation (e.g., unit testing or string-only OCR inputs).
  FoodImageValidationResult validateTextAndCandidate({
    required String ocrText,
    FoodProduct? candidateProduct,
    bool geminiIsFoodProduct = true,
  }) {
    if (!geminiIsFoodProduct) {
      return FoodImageValidationResult.invalid(
        reason: 'Gemini indicated non-food image.',
      );
    }

    final recognizedText = RecognizedText(
      text: ocrText,
      blocks: [
        TextBlock(
          text: ocrText,
          lines: [
            TextLine(
              text: ocrText,
              elements: [],
              boundingBox: Rect.zero,
              recognizedLanguages: [],
              cornerPoints: [],
              confidence: 1.0,
              angle: 0.0,
            )
          ],
          boundingBox: Rect.zero,
          recognizedLanguages: [],
          cornerPoints: [],
        )
      ],
    );

    if (candidateProduct != null) {
      return validateCandidateProduct(
        product: candidateProduct,
        recognizedText: recognizedText,
      );
    }

    final hasEvidence = hasFoodEvidence(recognizedText);
    if (hasEvidence) {
      return FoodImageValidationResult(
        isFoodProduct: true,
        confidence: 0.9,
        evidence: 'textual food evidence found',
      );
    }

    return FoodImageValidationResult.invalid(
      reason: 'Insufficient visual food evidence in image text.',
    );
  }

  /// Performs full food-product consistency validation on a candidate product.
  FoodImageValidationResult validateCandidateProduct({
    required FoodProduct product,
    required RecognizedText recognizedText,
    double matchConfidence = 1.0,
  }) {
    debugPrint('[IMAGE VALIDATION] Starting food-product validation');
    debugPrint('[PRODUCT] Candidate product: "${product.name}" (Brand: "${product.brand}")');

    // If candidate product was found by a valid barcode, barcode evidence is strong!
    if (product.barcode.trim().isNotEmpty && product.barcode.trim().length >= 8) {
      debugPrint('[IMAGE VALIDATION] isFoodProduct = true');
      debugPrint('[IMAGE VALIDATION] evidence = valid barcode (${product.barcode})');
      debugPrint('[IMAGE VALIDATION] Product identity accepted');
      debugPrint('[PRODUCT] Verification result: PASSED');
      return FoodImageValidationResult.valid(
        product: product,
        evidence: 'barcode: ${product.barcode}',
        confidence: 1.0,
      );
    }

    // Check if image text contains supporting food evidence
    final foodEvidenceFound = hasFoodEvidence(recognizedText);

    if (foodEvidenceFound) {
      debugPrint('[IMAGE VALIDATION] isFoodProduct = true');
      debugPrint('[IMAGE VALIDATION] confidence = ${matchConfidence.toStringAsFixed(2)}');
      debugPrint('[IMAGE VALIDATION] evidence = food packaging / ingredients / nutrition label panel');
      debugPrint('[IMAGE VALIDATION] Product identity accepted');
      debugPrint('[PRODUCT] Verification result: PASSED');
      return FoodImageValidationResult.valid(
        product: product,
        evidence: 'visible food label / ingredients / nutrition panel',
        confidence: matchConfidence,
      );
    }

    // Check if candidate product comes from a verified food database with complete nutrition facts
    if (product.name.trim().isNotEmpty &&
        product.name.toLowerCase() != 'unknown product' &&
        product.ingredients.trim().isNotEmpty &&
        !product.hasMissingOrZeroNutrients &&
        matchConfidence >= 0.70) {
      debugPrint('[IMAGE VALIDATION] isFoodProduct = true');
      debugPrint('[IMAGE VALIDATION] confidence = ${matchConfidence.toStringAsFixed(2)}');
      debugPrint('[IMAGE VALIDATION] evidence = verified food database match (${product.name})');
      debugPrint('[IMAGE VALIDATION] Product identity accepted');
      debugPrint('[PRODUCT] Verification result: PASSED');
      return FoodImageValidationResult.valid(
        product: product,
        evidence: 'verified food database match (${product.name})',
        confidence: matchConfidence,
      );
    }

    // Insufficient food evidence -> REJECT.
    debugPrint('[IMAGE VALIDATION] isFoodProduct = false');
    debugPrint('[IMAGE VALIDATION] confidence = ${matchConfidence.toStringAsFixed(2)}');
    debugPrint('[IMAGE VALIDATION] evidence = none');
    debugPrint('[IMAGE VALIDATION] REJECTED: candidate product not supported by image evidence');
    debugPrint('[PRODUCT] Verification result: REJECTED');

    return FoodImageValidationResult.invalid(
      reason: 'No food packaging, ingredients list, or nutrition facts label was detected in this image.',
      confidence: matchConfidence,
    );
  }
}
