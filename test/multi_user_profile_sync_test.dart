import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/core/model/food_product.dart';
import 'package:diet_compass/core/model/personalization_profile.dart';
import 'package:diet_compass/core/model/user_profile.dart';
import 'package:diet_compass/core/services/dietary_safety_validator.dart';
import 'package:diet_compass/core/services/personalization_service.dart';
import 'package:diet_compass/core/services/profile_service.dart';
import 'package:diet_compass/core/services/recommendation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DietCompass Multi-User Personalization & State Synchronization Tests', () {
    setUp(() {
      PersonalizationService.instance.clearCache();
      ProfileService.instance.clearCache();
      RecommendationService.instance.clearCompatibilityCache();
    });

    test('TEST 1: User A (Vegetarian, Weight Loss, No Allergies) Flow', () {
      final userAProfile = UserProfile(
        id: 'user_a_123',
        fullName: 'User A',
        username: 'usera',
        email: 'usera@test.com',
        phone: '1234567890',
        countryCode: '+1',
        accountType: 'individual',
        dietType: 'Vegetarian',
        isPersonalizationComplete: true,
      );

      final userAPersonalization = PersonalizationProfile(
        id: 'pers_a_123',
        userId: 'user_a_123',
        fullName: 'User A',
        dietType: 'Vegetarian',
        goals: {'Weight Loss'},
        allergies: {},
        isCompleted: true,
      );

      // Verify active dietary profile for User A
      final activeA = DietarySafetyValidator.instance.getActiveDietaryProfile(
        personalization: userAPersonalization,
        profile: userAProfile,
      );

      expect(activeA.dietType, 'Vegetarian');
      expect(activeA.allergies.isEmpty, true);

      // Scanned product with meat
      final chickenProduct = FoodProduct(
        barcode: '111111',
        name: 'Grilled Chicken Breast',
        brand: 'Healthy Farm',
        imageUrl: 'https://images.openfoodfacts.org/chicken.jpg',
        ingredients: 'Chicken breast, olive oil, salt, black pepper',
        allergens: const [],
        calories: 165,
        protein: 31,
        carbohydrates: 0,
        fat: 3.6,
        fiber: 0,
        sugar: 0,
        sodium: 74,
      );

      final validationA = DietarySafetyValidator.instance.validateFoodProduct(
        chickenProduct,
        personalization: userAPersonalization,
        profile: userAProfile,
      );

      expect(validationA.isCompatible, false);
      expect(validationA.matchedViolations.any((v) => v.contains('chicken')), true);

      // Compatibility score for User A on chicken is heavily penalized due to Vegetarian diet
      final compA = RecommendationService.instance.evaluateCompatibility(
        chickenProduct,
        personalization: userAPersonalization,
        profile: userAProfile,
      );

      expect(compA.isSuitable, false);
      expect(compA.score, lessThan(40));
    });

    test('TEST 2: Logout Clears User A State & Memory Caches', () {
      PersonalizationService.instance.clearCache();
      ProfileService.instance.clearCache();
      RecommendationService.instance.clearCompatibilityCache();

      expect(PersonalizationService.instance.currentPersonalization, isNull);
      expect(ProfileService.instance.currentProfile, isNull);
    });

    test('TEST 3: User B (Non-Vegetarian, Maintain Weight, Peanut Allergy) Flow', () {
      final userBProfile = UserProfile(
        id: 'user_b_456',
        fullName: 'User B',
        username: 'userb',
        email: 'userb@test.com',
        phone: '9876543210',
        countryCode: '+1',
        accountType: 'individual',
        dietType: 'Non-Vegetarian',
        isPersonalizationComplete: true,
      );

      final userBPersonalization = PersonalizationProfile(
        id: 'pers_b_456',
        userId: 'user_b_456',
        fullName: 'User B',
        dietType: 'Non-Vegetarian',
        goals: {'Maintain Weight'},
        allergies: {'Peanut'},
        isCompleted: true,
      );

      // Verify active dietary profile for User B
      final activeB = DietarySafetyValidator.instance.getActiveDietaryProfile(
        personalization: userBPersonalization,
        profile: userBProfile,
      );

      expect(activeB.dietType, 'Non-Vegetarian');
      expect(activeB.allergies.contains('Peanut'), true);

      // 1. Meat product: Should be COMPATIBLE for User B
      final chickenProduct = FoodProduct(
        barcode: '111111',
        name: 'Grilled Chicken Breast',
        brand: 'Healthy Farm',
        imageUrl: 'https://images.openfoodfacts.org/chicken.jpg',
        ingredients: 'Chicken breast, olive oil, salt, black pepper',
        allergens: const [],
        calories: 165,
        protein: 31,
        carbohydrates: 0,
        fat: 3.6,
        fiber: 0,
        sugar: 0,
        sodium: 74,
      );

      final validationBChicken = DietarySafetyValidator.instance.validateFoodProduct(
        chickenProduct,
        personalization: userBPersonalization,
        profile: userBProfile,
      );

      expect(validationBChicken.isCompatible, true);

      final compBChicken = RecommendationService.instance.evaluateCompatibility(
        chickenProduct,
        personalization: userBPersonalization,
        profile: userBProfile,
      );

      expect(compBChicken.isSuitable, true);
      expect(compBChicken.score, greaterThanOrEqualTo(70));

      // 2. Peanut product: Should be INCOMPATIBLE for User B due to Peanut allergy
      final peanutProduct = FoodProduct(
        barcode: '222222',
        name: 'Peanut Butter Crunch',
        brand: 'NuttyCo',
        imageUrl: 'https://images.openfoodfacts.org/peanut.jpg',
        ingredients: 'Roasted peanuts, palm oil, sugar, sea salt',
        allergens: const ['Peanuts'],
        calories: 200,
        protein: 8,
        carbohydrates: 6,
        fat: 16,
        fiber: 2,
        sugar: 3,
        sodium: 120,
      );

      final validationBPeanut = DietarySafetyValidator.instance.validateFoodProduct(
        peanutProduct,
        personalization: userBPersonalization,
        profile: userBProfile,
      );

      expect(validationBPeanut.isCompatible, false);
      expect(validationBPeanut.rejectionReason!.toLowerCase().contains('peanut'), true);

      final compBPeanut = RecommendationService.instance.evaluateCompatibility(
        peanutProduct,
        personalization: userBPersonalization,
        profile: userBProfile,
      );

      expect(compBPeanut.isSuitable, false);
      expect(compBPeanut.score, lessThan(40));
      expect(compBPeanut.allergyAlerts.any((a) => a.toLowerCase().contains('peanut')), true);
    });

    test('TEST 4: Profile Update Flow: User B switches Diet from Non-Vegetarian to Vegetarian', () {
      final userBUpdatedPers = PersonalizationProfile(
        id: 'pers_b_456',
        userId: 'user_b_456',
        fullName: 'User B',
        dietType: 'Vegetarian',
        goals: {'Maintain Weight'},
        allergies: {'Peanut'},
        isCompleted: true,
      );

      final userBUpdatedProfile = UserProfile(
        id: 'user_b_456',
        fullName: 'User B',
        username: 'userb',
        email: 'userb@test.com',
        phone: '9876543210',
        countryCode: '+1',
        accountType: 'individual',
        dietType: 'Vegetarian',
        isPersonalizationComplete: true,
      );

      RecommendationService.instance.clearCompatibilityCache();

      final activeBUpdated = DietarySafetyValidator.instance.getActiveDietaryProfile(
        personalization: userBUpdatedPers,
        profile: userBUpdatedProfile,
      );

      expect(activeBUpdated.dietType, 'Vegetarian');
      expect(activeBUpdated.allergies.contains('Peanut'), true);

      final chickenProduct = FoodProduct(
        barcode: '111111',
        name: 'Grilled Chicken Breast',
        brand: 'Healthy Farm',
        imageUrl: 'https://images.openfoodfacts.org/chicken.jpg',
        ingredients: 'Chicken breast, olive oil, salt, black pepper',
        allergens: const [],
        calories: 165,
        protein: 31,
        carbohydrates: 0,
        fat: 3.6,
        fiber: 0,
        sugar: 0,
        sodium: 74,
      );

      final validationPostUpdate = DietarySafetyValidator.instance.validateFoodProduct(
        chickenProduct,
        personalization: userBUpdatedPers,
        profile: userBUpdatedProfile,
      );

      expect(validationPostUpdate.isCompatible, false);
    });
  });
}
