import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/core/model/food_product.dart';
import 'package:diet_compass/core/services/recipe_service.dart';
import 'package:diet_compass/features/recipe_generator/recipe_generator_screen.dart';
import 'package:diet_compass/features/recipe_generator/recipe_detail_screen.dart';

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

  group('DietCompass Recipe Generator & Product Context Flow Tests', () {
    test(
      'recipe image fallback uses only the matching local recipe assets',
      () {
        expect(
          RecipeService.fallbackRecipeImage('Banana Oats Power Bowl'),
          'assets/images/recipe_banana_oats_power_bowl.jpeg',
        );
        expect(
          RecipeService.fallbackRecipeImage('Apple Cinnamon Oatmeal'),
          'assets/images/recipe_apple_cinnamon_oatmeal.jpeg',
        );
        expect(
          RecipeService.fallbackRecipeImage('Chocolate Banana Oats'),
          'assets/images/recipe_chocolate_banana_oats.jpeg',
        );
        expect(
          RecipeService.fallbackRecipeImage('Savory Vegetable Oats'),
          'assets/images/recipe_savory_veggie_oats.jpeg',
        );
        expect(RecipeService.fallbackRecipeImage('Beef Power Bowl'), isEmpty);
      },
    );

    test(
      'RecipeCardData properly binds full Recipe model with strict ingredient preservation',
      () {
        const card = RecipeCardData(
          id: 'recipe_dairymilk_oats_1',
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
            id: 'recipe_dairymilk_oats_1',
            images: ['https://img.spoonacular.com/recipes/639249-312x231.jpg'],
            title: 'Cadbury Dairy Milk Banana Oat Bowl',
            tags: ['Healthy', 'Quick'],
            description: 'A delicious oatmeal bowl with chocolate shavings.',
            prepTime: '12 min',
            calories: '340 kcal',
            protein: '11g',
            difficulty: 'Easy',
            nutritionFacts: [],
            ingredients: [
              IngredientItem(
                amount: '25g',
                name: 'Cadbury Dairy Milk chocolate chunks',
              ),
              IngredientItem(amount: '1/2 cup', name: 'Rolled Oats'),
            ],
            serves: 1,
            instructions: ['Cook oats in milk and stir in Cadbury Dairy Milk.'],
          ),
        );

        expect(card.fullRecipe, isNotNull);
        expect(card.title.toLowerCase(), contains('dairy milk'));

        final fullRecipe = card.fullRecipe!;
        expect(fullRecipe.title, equals(card.title));
        expect(fullRecipe.calories, contains('${card.kcal}'));
        expect(fullRecipe.protein, contains('${card.proteinGrams}g'));

        // Verify product is in ingredients
        final hasProductInIngs = fullRecipe.ingredients.any(
          (i) =>
              i.name.toLowerCase().contains('dairy milk') ||
              i.name.toLowerCase().contains('cadbury'),
        );
        expect(
          hasProductInIngs,
          isTrue,
          reason: 'Source product must appear in ingredients list',
        );

        // Verify product is in instructions
        final hasProductInSteps = fullRecipe.instructions.any(
          (step) =>
              step.toLowerCase().contains('dairy milk') ||
              step.toLowerCase().contains('chocolate'),
        );
        expect(
          hasProductInSteps,
          isTrue,
          reason: 'Source product must appear in recipe instructions',
        );
      },
    );

    test(
      'RecipeCardData properly binds Maggi Masala Noodles in ingredient and instruction lists',
      () {
        const maggiCard = RecipeCardData(
          id: 'recipe_maggi_1',
          title: 'Healthy Veggie Loaded Maggi Masala Noodles Bowl',
          tagline: 'Veggies • Quick • Wholesome',
          description: 'Nutritious noodle stir-fry.',
          timeMinutes: 12,
          kcal: 360,
          proteinGrams: 12,
          imageAsset: 'https://img.spoonacular.com/recipes/500-312x231.jpg',
          recipeSource: 'spoonacular',
          whatsInside: [],
          fullRecipe: Recipe(
            id: 'recipe_maggi_1',
            images: ['https://img.spoonacular.com/recipes/500-312x231.jpg'],
            title: 'Healthy Veggie Loaded Maggi Masala Noodles Bowl',
            tags: ['Quick', 'Savory'],
            description: 'Nutritious noodle stir-fry.',
            prepTime: '12 min',
            calories: '360 kcal',
            protein: '12g',
            difficulty: 'Easy',
            nutritionFacts: [],
            ingredients: [
              IngredientItem(
                amount: '1 pack',
                name: 'Maggi Masala Noodles with Tastemaker',
              ),
              IngredientItem(amount: '1/2 cup', name: 'Chopped Bell Peppers'),
            ],
            serves: 1,
            instructions: ['Cook Maggi Masala Noodles with vegetables.'],
          ),
        );

        expect(maggiCard.fullRecipe, isNotNull);
        expect(maggiCard.title.toLowerCase(), contains('maggi'));

        final fullRecipe = maggiCard.fullRecipe!;
        expect(fullRecipe.title, equals(maggiCard.title));

        // Verify Maggi is in ingredients
        final hasMaggiInIngs = fullRecipe.ingredients.any(
          (i) => i.name.toLowerCase().contains('maggi'),
        );
        expect(hasMaggiInIngs, isTrue);

        // Verify Maggi is in instructions
        final hasMaggiInSteps = fullRecipe.instructions.any(
          (step) => step.toLowerCase().contains('maggi'),
        );
        expect(hasMaggiInSteps, isTrue);
      },
    );

    testWidgets(
      'BUG 1 & 2 FIX: Recipe Card opens EXACT SAME Recipe Detail with sourceProduct context',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 2600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        const localRecipe = RecipeCardData(
          id: 'recipe_dairymilk_oats_1',
          title: 'Cadbury Dairy Milk Banana Oat Bowl',
          tagline: 'Healthy • Sweet Treat • Quick',
          description: 'A delicious oatmeal bowl with chocolate shavings.',
          timeMinutes: 12,
          kcal: 340,
          proteinGrams: 11,
          imageAsset: 'https://img.spoonacular.com/recipes/639249-312x231.jpg',
          recipeSource: 'spoonacular',
          whatsInside: [
            WhatsInTag(
              icon: Icons.eco_rounded,
              title: 'Antioxidants',
              subtitle: 'From cacao & berries',
              color: Color(0xFF1E8A4C),
            ),
          ],
          fullRecipe: Recipe(
            id: 'recipe_dairymilk_oats_1',
            images: ['https://img.spoonacular.com/recipes/639249-312x231.jpg'],
            title: 'Cadbury Dairy Milk Banana Oat Bowl',
            tags: ['Healthy', 'Quick'],
            description: 'A delicious oatmeal bowl with chocolate shavings.',
            prepTime: '12 min',
            calories: '340 kcal',
            protein: '11g',
            difficulty: 'Easy',
            nutritionFacts: [
              NutritionFact(
                icon: Icons.local_fire_department,
                color: Color(0xFFE0862E),
                label: 'Calories',
                value: '340\nkcal',
              ),
              NutritionFact(
                icon: Icons.eco,
                color: Color(0xFF1E8A4C),
                label: 'Protein',
                value: '11g',
              ),
            ],
            ingredients: [
              IngredientItem(
                amount: '25g',
                name: 'Cadbury Dairy Milk chocolate chunks',
              ),
              IngredientItem(amount: '1/2 cup', name: 'Rolled Oats'),
            ],
            serves: 1,
            instructions: ['Cook oats and fold in Cadbury Dairy Milk.'],
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: RecipeGeneratorScreen(
              sourceProduct: dairyMilk,
              recipes: const [localRecipe],
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // 1. Verify contextual banner is rendered
        expect(find.text('Recipe with ${dairyMilk.name}'), findsOneWidget);
        expect(find.text('USING PRODUCT'), findsOneWidget);

        // 2. Find "View Recipe" button and tap it
        final viewRecipeBtn = find.text('View Recipe').first;
        expect(viewRecipeBtn, findsOneWidget);

        await tester.tap(viewRecipeBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(RecipeDetailScreen), findsOneWidget);
        expect(find.text('Cadbury Dairy Milk Banana Oat Bowl'), findsWidgets);
        expect(find.text('Prep Time'), findsOneWidget);
        expect(find.text('Ingredients'), findsOneWidget);
        expect(find.text('Instructions'), findsOneWidget);
        expect(find.byType(RichText), findsWidgets);
      },
    );

    testWidgets(
      'Normal Recipe Generator mode opens without product and maintains 1-to-1 card consistency',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 2600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        const normalRecipe = RecipeCardData(
          id: 'recipe_smoothie_1',
          title: 'Berry Banana Smoothie Bowl',
          tagline: 'Refreshing • High Protein',
          description: 'A refreshing and vibrant smoothie bowl.',
          timeMinutes: 10,
          kcal: 280,
          proteinGrams: 14,
          imageAsset: 'https://img.spoonacular.com/recipes/945221-312x231.jpg',
          recipeSource: 'spoonacular',
          whatsInside: [
            WhatsInTag(
              icon: Icons.eco_rounded,
              title: 'Antioxidants',
              subtitle: 'Fresh berries',
              color: Color(0xFF1E8A4C),
            ),
          ],
          fullRecipe: Recipe(
            id: 'recipe_smoothie_1',
            images: ['https://img.spoonacular.com/recipes/945221-312x231.jpg'],
            title: 'Berry Banana Smoothie Bowl',
            tags: ['Refreshing', 'Protein'],
            description: 'A refreshing and vibrant smoothie bowl.',
            prepTime: '10 min',
            calories: '280 kcal',
            protein: '14g',
            difficulty: 'Easy',
            nutritionFacts: [
              NutritionFact(
                icon: Icons.local_fire_department,
                color: Color(0xFFE0862E),
                label: 'Calories',
                value: '280\nkcal',
              ),
              NutritionFact(
                icon: Icons.eco,
                color: Color(0xFF1E8A4C),
                label: 'Protein',
                value: '14g',
              ),
            ],
            ingredients: [
              IngredientItem(amount: '1 cup', name: 'Mixed Berries'),
              IngredientItem(amount: '1', name: 'Banana'),
            ],
            serves: 1,
            instructions: ['Blend ingredients together and enjoy.'],
          ),
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: RecipeGeneratorScreen(recipes: [normalRecipe]),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // In normal mode without sourceProduct, banner is not rendered
        expect(find.text('USING PRODUCT'), findsNothing);

        // Tap View Recipe
        final viewRecipeBtn = find.text('View Recipe').first;
        await tester.tap(viewRecipeBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Verify exact recipe detail is displayed
        expect(find.byType(RecipeDetailScreen), findsOneWidget);
        expect(find.text('Berry Banana Smoothie Bowl'), findsWidgets);
        expect(find.text('10 min'), findsWidgets);
        expect(find.text('280 kcal'), findsWidgets);
      },
    );
  });
}
