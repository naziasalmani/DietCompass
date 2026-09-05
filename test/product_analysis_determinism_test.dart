import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/core/model/food_product.dart';
import 'package:diet_compass/core/model/personalization_profile.dart';
import 'package:diet_compass/core/model/user_profile.dart';
import 'package:diet_compass/core/model/scan_history_item.dart';
import 'package:diet_compass/core/services/product_analysis_engine.dart';
import 'package:diet_compass/core/services/recommendation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleProduct = FoodProduct(
    barcode: '8901234567890',
    name: 'Bournville Dark Chocolate',
    brand: 'Cadbury',
    imageUrl: 'https://example.com/bournville.jpg',
    ingredients: 'Sugar, Cocoa Solids, Cocoa Butter, Milk Solids, Emulsifiers (E442, E476), Flavourings',
    allergens: ['Milk'],
    calories: 520,
    protein: 6.5,
    carbohydrates: 58.0,
    fat: 30.0,
    saturatedFat: 18.0,
    fiber: 7.0,
    sugar: 46.0,
    sodium: 50,
  );

  final samplePersonalization = PersonalizationProfile(
    id: 'p1',
    userId: 'test_user_123',
    dietType: 'Vegetarian',
    allergies: {'Peanuts'},
    goals: {'Low Sugar Diet'},
    healthConditions: {'Diabetes'},
    nutritionFocus: {'Sugar'},
  );

  final sampleProfile = const UserProfile(
    id: 'test_user_123',
    email: 'test@example.com',
    fullName: 'Test User',
    username: 'testuser',
    phone: '1234567890',
    countryCode: '+1',
    accountType: 'free',
    dietType: 'Vegetarian',
    isPersonalizationComplete: true,
  );

  group('DietCompass Deterministic Product Analysis Tests', () {
    test('TEST 1: Same product + same user profile ALWAYS produces identical analysis', () {
      final analysis1 = ProductAnalysisEngine.instance.analyzeProduct(
        sampleProduct,
        personalization: samplePersonalization,
        profile: sampleProfile,
        forceReanalyze: true,
      );

      final analysis2 = ProductAnalysisEngine.instance.analyzeProduct(
        sampleProduct,
        personalization: samplePersonalization,
        profile: sampleProfile,
      );

      expect(analysis1.overallScore, equals(analysis2.overallScore));
      expect(analysis1.compatibilityScore, equals(analysis2.compatibilityScore));
      expect(analysis1.whatsGood.length, equals(analysis2.whatsGood.length));
      expect(analysis1.watchOutFor.length, equals(analysis2.watchOutFor.length));

      for (int i = 0; i < analysis1.whatsGood.length; i++) {
        expect(analysis1.whatsGood[i].title, equals(analysis2.whatsGood[i].title));
        expect(analysis1.whatsGood[i].subtitle, equals(analysis2.whatsGood[i].subtitle));
      }

      for (int i = 0; i < analysis1.watchOutFor.length; i++) {
        expect(analysis1.watchOutFor[i].title, equals(analysis2.watchOutFor[i].title));
        expect(analysis1.watchOutFor[i].subtitle, equals(analysis2.watchOutFor[i].subtitle));
      }
    });

    test('TEST 2: Historical scan retains stored canonical analysis without recalculating', () {
      final analysis = ProductAnalysisEngine.instance.analyzeProduct(
        sampleProduct,
        personalization: samplePersonalization,
        profile: sampleProfile,
        forceReanalyze: true,
      );

      final historyItem = ScanHistoryItem(
        id: 'scan_1',
        userId: 'test_user_123',
        barcode: sampleProduct.barcode,
        productName: sampleProduct.name,
        brand: sampleProduct.brand,
        score: analysis.overallScore,
        ingredients: sampleProduct.ingredients,
        allergens: sampleProduct.allergens,
        canonicalAnalysisJson: analysis.toJson(),
        scannedAt: DateTime.now(),
      );

      final reconstructed1 = historyItem.toCanonicalAnalysis();
      final reconstructed2 = historyItem.toCanonicalAnalysis();

      expect(reconstructed1.overallScore, equals(analysis.overallScore));
      expect(reconstructed1.compatibilityScore, equals(analysis.compatibilityScore));
      expect(reconstructed1.watchOutFor.length, equals(analysis.watchOutFor.length));
      expect(reconstructed2.overallScore, equals(reconstructed1.overallScore));
      expect(reconstructed2.compatibilityScore, equals(reconstructed1.compatibilityScore));
    });

    test('TEST 3: Profile change (Vegetarian -> Vegan) updates compatibility deterministically', () {
      final vegPersonalization = PersonalizationProfile(
        id: 'p1',
        userId: 'test_user_123',
        dietType: 'Vegetarian',
        allergies: {},
        goals: {},
      );

      final veganPersonalization = PersonalizationProfile(
        id: 'p1',
        userId: 'test_user_123',
        dietType: 'Vegan',
        allergies: {},
        goals: {},
      );

      final vegAnalysis = ProductAnalysisEngine.instance.analyzeProduct(
        sampleProduct,
        personalization: vegPersonalization,
        profile: sampleProfile,
        forceReanalyze: true,
      );

      // Product contains Milk Solids -> Incompatible with Vegan
      final veganAnalysis = ProductAnalysisEngine.instance.analyzeProduct(
        sampleProduct,
        personalization: veganPersonalization,
        profile: sampleProfile,
        forceReanalyze: true,
      );

      expect(vegAnalysis.compatibility.isSuitable, isTrue);
      expect(veganAnalysis.compatibility.isSuitable, isFalse);
      expect(veganAnalysis.compatibility.dietaryAlerts.first, contains('Vegan'));
    });

    test('TEST 4: Detailed "Watch Out For" findings (Allergens, Hidden Sugars, Additives) preserved', () {
      final allergyPersonalization = PersonalizationProfile(
        id: 'p1',
        userId: 'test_user_123',
        dietType: 'Balanced',
        allergies: {'Milk'},
        goals: {},
      );

      final analysis = ProductAnalysisEngine.instance.analyzeProduct(
        sampleProduct,
        personalization: allergyPersonalization,
        profile: sampleProfile,
        forceReanalyze: true,
      );

      final titles = analysis.watchOutFor.map((w) => w.title).toList();

      expect(titles.any((t) => t.contains('Allergen Alert')), isTrue);
      expect(titles.any((t) => t.contains('Hidden Sugar')), isTrue);
      expect(titles.any((t) => t.contains('Additive Concern')), isTrue);
    });

    test('TEST 5: Uncalculated compatibility returns null score without fake 75/50 fallbacks', () {
      final uncalculated = RecommendationService.instance.evaluateCompatibility(
        sampleProduct,
        personalization: null,
        profile: null,
      );

      expect(uncalculated.score, isNull);
      expect(uncalculated.status, equals('Calculating...'));
      expect(uncalculated.score != 75, isTrue);
      expect(uncalculated.score != 50, isTrue);
    });
  });
}
