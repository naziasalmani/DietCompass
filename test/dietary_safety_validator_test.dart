import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/core/model/food_product.dart';
import 'package:diet_compass/core/model/personalization_profile.dart';
import 'package:diet_compass/core/model/user_profile.dart';
import 'package:diet_compass/core/services/dietary_safety_validator.dart';
import 'package:diet_compass/core/services/recipe_service.dart';
import 'package:diet_compass/core/services/recommendation_service.dart';
import 'package:diet_compass/features/recipe_generator/recipe_detail_screen.dart';
import 'package:diet_compass/features/recipe_generator/recipe_generator_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  const vegetarianProfile = UserProfile(
    id: 'user_veg_1',
    fullName: 'Vegetarian User',
    username: 'veg_user',
    email: 'veg@dietcompass.com',
    phone: '9876543210',
    countryCode: '+91',
    accountType: 'individual',
    dietType: 'Vegetarian',
  );

  const nonVegProfile = UserProfile(
    id: 'user_nonveg_1',
    fullName: 'Non-Vegetarian User',
    username: 'nonveg_user',
    email: 'nonveg@dietcompass.com',
    phone: '9876543210',
    countryCode: '+91',
    accountType: 'individual',
    dietType: 'Non-Vegetarian',
  );

  final cadburyDairyMilk = FoodProduct(
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

  final maggiNoodles = FoodProduct(
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

  group('DietCompass Dietary Safety & Hard Constraint Verification', () {
    test('TEST 1: Vegetarian profile rejects meat/seafood recipes via DietarySafetyValidator', () {
      const brisketRecipe = Recipe(
        id: 'recipe_brisket',
        images: ['assets/images/recipe_banana_oats_power_bowl.jpeg'],
        title: 'BBQ Beef Brisket',
        tags: ['BBQ', 'Dinner', 'High Protein'],
        description: 'Slow-cooked smoky beef brisket with savory BBQ sauce.',
        prepTime: '45 min',
        calories: '520 kcal',
        protein: '45g',
        difficulty: 'Medium',
        nutritionFacts: [],
        ingredients: [
          IngredientItem(amount: '500g', name: 'Beef Brisket'),
          IngredientItem(amount: '1/2 cup', name: 'BBQ Sauce'),
          IngredientItem(amount: '1 cup', name: 'Beef Stock'),
        ],
        serves: 4,
        instructions: ['Sear the beef brisket on high heat.', 'Slow cook with beef stock and BBQ sauce.'],
      );

      final result = DietarySafetyValidator.instance.validateRecipe(
        brisketRecipe,
        profile: vegetarianProfile,
      );

      expect(result.isCompatible, isFalse);
      expect(result.rejectionReason, contains('violates user Vegetarian dietary preference'));
      expect(result.matchedViolations, contains('beef'));
    });

    test('TEST 2: Vegetarian user generating recipes from Cadbury Dairy Milk receives 100% vegetarian recipes', () {
      const vegCard = RecipeCardData(
        id: 'recipe_chocolate_oats',
        title: 'Cadbury Dairy Milk Banana Oat Bowl',
        tagline: 'Healthy • Sweet Treat • Quick',
        description: 'A delicious oatmeal bowl with chocolate shavings.',
        timeMinutes: 12,
        kcal: 340,
        proteinGrams: 11,
        imageAsset: 'https://img.spoonacular.com/recipes/639249-312x231.jpg',
        recipeSource: 'themealdb',
        whatsInside: [],
        fullRecipe: Recipe(
          id: 'recipe_chocolate_oats',
          images: ['https://img.spoonacular.com/recipes/639249-312x231.jpg'],
          title: 'Cadbury Dairy Milk Banana Oat Bowl',
          tags: ['Vegetarian', 'Quick'],
          description: 'A delicious oatmeal bowl with chocolate shavings.',
          prepTime: '12 min',
          calories: '340 kcal',
          protein: '11g',
          difficulty: 'Easy',
          nutritionFacts: [],
          ingredients: [
            IngredientItem(amount: '25g', name: 'Cadbury Dairy Milk chocolate chunks'),
            IngredientItem(amount: '1/2 cup', name: 'Rolled Oats'),
            IngredientItem(amount: '1', name: 'Banana'),
            IngredientItem(amount: '1 cup', name: 'Milk'),
          ],
          serves: 1,
          instructions: ['Cook oats in milk and stir in Cadbury Dairy Milk.'],
        ),
      );

      final safety = DietarySafetyValidator.instance.validateRecipeCard(
        vegCard,
        profile: vegetarianProfile,
      );
      expect(safety.isCompatible, isTrue, reason: '${vegCard.title} must be 100% vegetarian');
    });


    test('TEST 3: Product recommendation filter strictly removes meat/fish/seafood products for Vegetarian user', () {
      final mixedProducts = [
        cadburyDairyMilk,
        FoodProduct(
          barcode: '1111',
          name: 'Smoked Chicken Breast Slices',
          brand: 'MeatDelight',
          imageUrl: 'https://example.com/chicken.jpg',
          ingredients: 'Chicken meat, water, salt, spices, sodium nitrite',
          allergens: const [],
          calories: 120.0,
          protein: 22.0,
          carbohydrates: 1.0,
          fat: 2.5,
          fiber: 0.0,
          sugar: 0.0,
          sodium: 0.6,
        ),
        FoodProduct(
          barcode: '2222',
          name: 'Canned Tuna in Olive Oil',
          brand: 'OceanCatch',
          imageUrl: 'https://example.com/tuna.jpg',
          ingredients: 'Yellowfin tuna, extra virgin olive oil, sea salt',
          allergens: const ['Fish'],
          calories: 190.0,
          protein: 26.0,
          carbohydrates: 0.0,
          fat: 9.0,
          fiber: 0.0,
          sugar: 0.0,
          sodium: 0.4,
        ),
        FoodProduct(
          barcode: '3333',
          name: 'Organic Rolled Oats',
          brand: 'PureGrain',
          imageUrl: 'https://example.com/oats.jpg',
          ingredients: '100% Whole Grain Rolled Oats',
          allergens: const [],
          calories: 380.0,
          protein: 13.0,
          carbohydrates: 68.0,
          fat: 6.5,
          fiber: 10.0,
          sugar: 1.0,
          sodium: 0.01,
        ),
      ];

      final compatible = RecommendationService.instance.filterCompatibleProducts(
        mixedProducts,
        profile: vegetarianProfile,
      );

      expect(compatible.any((p) => p.name.contains('Chicken')), isFalse);
      expect(compatible.any((p) => p.name.contains('Tuna')), isFalse);
      expect(compatible.any((p) => p.name.contains('Cadbury')), isTrue);
      expect(compatible.any((p) => p.name.contains('Oats')), isTrue);
    });

    test('TEST 4: Non-vegetarian API/AI result is rejected and replaced with valid vegetarian recipe', () async {
      // Direct raw JSON test representing third-party Spoonacular / Gemini meat response
      final rawMeatJson = {
        'id': 999123,
        'title': 'Slow-Cooked BBQ Beef Brisket with Garlic Mash',
        'summary': 'Tender brisket simmered in rich beef broth.',
        'readyInMinutes': 50,
        'calories': 550,
        'protein': 48,
        'extendedIngredients': [
          {'name': 'beef brisket', 'amount': '500g'},
          {'name': 'beef broth', 'amount': '2 cups'},
        ],
        'instructions': ['Slow cook beef brisket until fork-tender.'],
      };

      final validation = DietarySafetyValidator.instance.validateRecipeJson(
        rawMeatJson,
        profile: vegetarianProfile,
      );

      expect(validation.isCompatible, isFalse);
      expect(validation.matchedViolations.contains('beef') || validation.matchedViolations.contains('beef broth'), isTrue);
    });

    test('TEST 5: Changing profile to Non-Vegetarian allows meat recipes where appropriate', () {
      const brisketRecipe = Recipe(
        id: 'recipe_brisket',
        images: ['assets/images/recipe_banana_oats_power_bowl.jpeg'],
        title: 'BBQ Beef Brisket',
        tags: ['BBQ', 'Dinner', 'High Protein'],
        description: 'Slow-cooked smoky beef brisket with savory BBQ sauce.',
        prepTime: '45 min',
        calories: '520 kcal',
        protein: '45g',
        difficulty: 'Medium',
        nutritionFacts: [],
        ingredients: [
          IngredientItem(amount: '500g', name: 'Beef Brisket'),
          IngredientItem(amount: '1/2 cup', name: 'BBQ Sauce'),
        ],
        serves: 4,
        instructions: ['Slow cook beef brisket.'],
      );

      final result = DietarySafetyValidator.instance.validateRecipe(
        brisketRecipe,
        profile: nonVegProfile,
      );

      expect(result.isCompatible, isTrue);
    });

    testWidgets('TEST 6: Vegetarian UI Flow: RecipeGeneratorScreen generates and opens only vegetarian recipes with source product', (tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const mockCard = RecipeCardData(
        id: 'recipe_dairymilk_oats_1',
        title: 'Cadbury Dairy Milk Banana Oat Bowl',
        tagline: 'Healthy • Sweet Treat • Quick',
        description: 'A delicious oatmeal bowl with chocolate shavings.',
        timeMinutes: 12,
        kcal: 340,
        proteinGrams: 11,
        imageAsset: 'assets/images/recipe_chocolate_banana_oats.jpeg',
        recipeSource: 'themealdb',
        whatsInside: [
          WhatsInTag(icon: Icons.eco_rounded, title: 'Antioxidants', subtitle: 'From cacao & berries', color: Color(0xFF1E8A4C)),
        ],
        fullRecipe: Recipe(
          id: 'recipe_dairymilk_oats_1',
          images: ['assets/images/recipe_chocolate_banana_oats.jpeg'],
          title: 'Cadbury Dairy Milk Banana Oat Bowl',
          tags: ['Healthy', 'Quick'],
          description: 'A delicious oatmeal bowl with chocolate shavings.',
          prepTime: '12 min',
          calories: '340 kcal',
          protein: '11g',
          difficulty: 'Easy',
          nutritionFacts: [],
          ingredients: [
            IngredientItem(amount: '25g', name: 'Cadbury Dairy Milk chocolate chunks'),
            IngredientItem(amount: '1/2 cup', name: 'Rolled Oats'),
          ],
          serves: 1,
          instructions: ['Cook oats and fold in Cadbury Dairy Milk.'],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RecipeGeneratorScreen(
            sourceProduct: cadburyDairyMilk,
            recipes: const [mockCard],
          ),
        ),
      );

      await tester.pump();

      await tester.pump(const Duration(milliseconds: 500));

      // 1. Verify Card contains Cadbury Dairy Milk and no meat
      expect(find.text('USING PRODUCT'), findsOneWidget);
      expect(find.text('Recipe with Cadbury Dairy Milk'), findsOneWidget);
      expect(find.text('BBQ Beef Brisket'), findsNothing);
      expect(find.text('Chicken'), findsNothing);

      // 2. Tap View Recipe
      final viewBtn = find.text('View Recipe').first;
      await tester.tap(viewBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 3. Verify Detail screen is 100% vegetarian
      expect(find.byType(RecipeDetailScreen), findsOneWidget);
      final detail = tester.widget<RecipeDetailScreen>(find.byType(RecipeDetailScreen));
      final safety = DietarySafetyValidator.instance.validateRecipe(detail.recipe, profile: vegetarianProfile);
      expect(safety.isCompatible, isTrue);
      expect(detail.recipe.title, contains('Cadbury Dairy Milk'));
      expect(find.text('BBQ Beef Brisket'), findsNothing);
    });

    test('TEST 7 (Allergens): Peanut and Dairy allergy are hard exclusions', () {
      final peanutAllergyProfile = PersonalizationProfile(
        id: 'pers_peanut',
        userId: 'u1',
        dietType: 'Vegetarian',
        allergies: const {'Peanuts'},
      );

      const peanutRecipe = Recipe(
        id: 'r_peanut',
        images: [],
        title: 'Peanut Butter Banana Smoothie',
        tags: ['Quick'],
        description: 'Smoothie with peanut butter.',
        prepTime: '5 min',
        calories: '280 kcal',
        protein: '8g',
        difficulty: 'Easy',
        nutritionFacts: [],
        ingredients: [
          IngredientItem(amount: '2 tbsp', name: 'Peanut Butter'),
          IngredientItem(amount: '1', name: 'Banana'),
        ],
        serves: 1,
        instructions: ['Blend peanut butter with banana and ice.'],
      );

      final peanutVal = DietarySafetyValidator.instance.validateRecipe(
        peanutRecipe,
        personalization: peanutAllergyProfile,
      );

      expect(peanutVal.isCompatible, isFalse);
      expect(peanutVal.rejectionReason, contains('allergen'));
    });
  });
}
