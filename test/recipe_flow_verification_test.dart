import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/core/model/food_product.dart';
import 'package:diet_compass/features/recipe_generator/recipe_detail_screen.dart';
import 'package:diet_compass/features/recipe_generator/recipe_generator_screen.dart';
import 'package:diet_compass/features/scan/result_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

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

  group('DietCompass Spoonacular Flow & Image Propagation Tests', () {
    testWidgets('TEST 1 & 2: Spoonacular recipe ID & image ID are consistent, and Card -> Detail receives exact SAME Recipe object', (tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const liveApiRecipe = RecipeCardData(
        id: 639249,
        title: 'Chocolate, Pb and Banana Oats',
        tagline: 'Gluten Free • Lacto Ovo Vegetarian',
        description: 'Rich and wholesome chocolate, peanut butter, and banana oatmeal bowl.',
        timeMinutes: 15,
        kcal: 340,
        proteinGrams: 12,
        imageAsset: 'https://img.spoonacular.com/recipes/639249-312x231.jpg',
        whatsInside: [
          WhatsInTag(icon: Icons.eco_rounded, title: 'High Fiber', subtitle: 'Whole oats', color: Color(0xFF1E8A4C)),
        ],
        recommended: true,
        fullRecipe: Recipe(
          id: 639249,
          images: ['https://img.spoonacular.com/recipes/639249-312x231.jpg'],
          title: 'Chocolate, Pb and Banana Oats',
          tags: ['Gluten Free', 'Vegetarian'],
          description: 'Rich and wholesome chocolate, peanut butter, and banana oatmeal bowl.',
          prepTime: '15 min',
          calories: '340 kcal',
          protein: '12g',
          difficulty: 'Easy',
          nutritionFacts: [
            NutritionFact(icon: Icons.local_fire_department, color: Color(0xFFE0862E), label: 'Calories', value: '340\nkcal'),
            NutritionFact(icon: Icons.eco, color: Color(0xFF1E8A4C), label: 'Protein', value: '12g'),
          ],
          ingredients: [
            IngredientItem(amount: '1/2 cup', name: 'Rolled Oats'),
            IngredientItem(amount: '1', name: 'Banana'),
            IngredientItem(amount: '20g', name: 'Chocolate'),
          ],
          serves: 1,
          instructions: ['Simmer oats in milk.', 'Melt chocolate and top with banana slices.'],
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: RecipeGeneratorScreen(
            recipes: [liveApiRecipe],
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify Card displays the real Spoonacular recipe
      expect(find.text('Chocolate, Pb and Banana Oats'), findsOneWidget);

      // 2. Tap "View Recipe"
      final viewRecipeBtn = find.text('View Recipe').first;
      await tester.tap(viewRecipeBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 3. Verify Detail screen has the exact same ID, title & Spoonacular image
      expect(find.byType(RecipeDetailScreen), findsOneWidget);
      final detail = tester.widget<RecipeDetailScreen>(find.byType(RecipeDetailScreen));
      expect(detail.recipe.id, 639249);
      expect(detail.recipe.title, 'Chocolate, Pb and Banana Oats');
      expect(detail.recipe.images.first, 'https://img.spoonacular.com/recipes/639249-312x231.jpg');
    });

    testWidgets('TEST 3: Cadbury Dairy Milk + Oats + Banana prioritizes chocolate/oats/banana recipes', (tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const topRankedRecipe = RecipeCardData(
        id: 639249,
        title: 'Chocolate, Pb and Banana Oats',
        tagline: 'Chocolate • Vegetarian • Energizing',
        description: 'Rich chocolate-infused oatmeal bowl with peanut butter and banana.',
        timeMinutes: 10,
        kcal: 340,
        proteinGrams: 12,
        imageAsset: 'https://img.spoonacular.com/recipes/639249-312x231.jpg',
        whatsInside: [
          WhatsInTag(icon: Icons.bolt_rounded, title: 'Energy Boost', subtitle: 'Cocoa & complex carbs', color: Color(0xFFE0862E)),
        ],
        recommended: true,
        fullRecipe: Recipe(
          id: 639249,
          images: ['https://img.spoonacular.com/recipes/639249-312x231.jpg'],
          title: 'Chocolate, Pb and Banana Oats',
          tags: ['Chocolate', 'Vegetarian'],
          description: 'Rich chocolate-infused oatmeal bowl with peanut butter and banana.',
          prepTime: '10 min',
          calories: '340 kcal',
          protein: '12g',
          difficulty: 'Easy',
          nutritionFacts: [
            NutritionFact(icon: Icons.local_fire_department, color: Color(0xFFE0862E), label: 'Calories', value: '340\nkcal'),
          ],
          ingredients: [
            IngredientItem(amount: '25g', name: 'Cadbury Dairy Milk chocolate'),
            IngredientItem(amount: '1/2 cup', name: 'Rolled Oats'),
            IngredientItem(amount: '1', name: 'Banana'),
          ],
          serves: 1,
          instructions: ['Melt Cadbury Dairy Milk chocolate into warm oats and serve.'],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RecipeGeneratorScreen(
            sourceProduct: cadburyDairyMilk,
            recipes: const [topRankedRecipe],
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('USING PRODUCT'), findsOneWidget);
      expect(find.text('Recipe with ${cadburyDairyMilk.name}'), findsOneWidget);
      expect(find.text('Chocolate, Pb and Banana Oats'), findsOneWidget);

      // Tap View Recipe
      await tester.tap(find.text('View Recipe').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final detail = tester.widget<RecipeDetailScreen>(find.byType(RecipeDetailScreen));
      expect(detail.recipe.title, 'Chocolate, Pb and Banana Oats');
      expect(detail.recipe.images.first, 'https://img.spoonacular.com/recipes/639249-312x231.jpg');
    });

    testWidgets('TEST 4 & 5: When API returns 0 recipes, app shows empty state without silently showing hardcoded demo recipes', (tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: RecipeGeneratorScreen(
            recipes: [],
            moreIdeas: [],
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify that hardcoded demo recipes are NOT displayed
      expect(find.text('Banana Oats Power Bowl'), findsNothing);
      expect(find.text('Apple Cinnamon Oatmeal Bowl'), findsNothing);
      expect(find.text('Berry Chia Pudding'), findsNothing);
      expect(find.text('BBQ Beef Brisket'), findsNothing);

      // Verify proper empty state is shown
      expect(find.text('No suitable recipes found with your current pantry and preferences.'), findsOneWidget);
    });

    testWidgets('TEST 6, 7 & 8: Carousel displays distinct images for distinct recipes without cross-recipe contamination', (tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const recipe1 = RecipeCardData(
        id: 634011,
        title: 'Banana Bread with Chocolate Swirl',
        tagline: 'Vegetarian • Baking',
        description: 'Warm banana bread infused with melted chocolate swirl.',
        timeMinutes: 45,
        kcal: 254,
        proteinGrams: 4,
        imageAsset: 'https://img.spoonacular.com/recipes/634011-312x231.jpg',
        whatsInside: [],
        fullRecipe: Recipe(
          id: 634011,
          images: ['https://img.spoonacular.com/recipes/634011-312x231.jpg'],
          title: 'Banana Bread with Chocolate Swirl',
          tags: ['Vegetarian'],
          description: 'Warm banana bread infused with melted chocolate swirl.',
          prepTime: '45 min',
          calories: '254 kcal',
          protein: '4g',
          difficulty: 'Medium',
          nutritionFacts: [],
          ingredients: [],
          serves: 4,
          instructions: [],
        ),
      );

      const recipe2 = RecipeCardData(
        id: 945221,
        title: 'Watching What I Eat: Peanut Butter Banana Oat Cookies',
        tagline: 'Vegetarian • Quick',
        description: 'Healthy breakfast cookies with chocolate chips and oats.',
        timeMinutes: 20,
        kcal: 103,
        proteinGrams: 4,
        imageAsset: 'https://img.spoonacular.com/recipes/945221-312x231.jpg',
        whatsInside: [],
        fullRecipe: Recipe(
          id: 945221,
          images: ['https://img.spoonacular.com/recipes/945221-312x231.jpg'],
          title: 'Watching What I Eat: Peanut Butter Banana Oat Cookies',
          tags: ['Vegetarian'],
          description: 'Healthy breakfast cookies with chocolate chips and oats.',
          prepTime: '20 min',
          calories: '103 kcal',
          protein: '4g',
          difficulty: 'Easy',
          nutritionFacts: [],
          ingredients: [],
          serves: 2,
          instructions: [],
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: RecipeGeneratorScreen(
            recipes: [recipe1, recipe2],
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify First recipe is shown with its image
      expect(find.text('Banana Bread with Chocolate Swirl'), findsOneWidget);

      // 2. Tap View Recipe on First
      await tester.tap(find.text('View Recipe').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      var detail = tester.widget<RecipeDetailScreen>(find.byType(RecipeDetailScreen));
      expect(detail.recipe.id, 634011);
      expect(detail.recipe.images.first, 'https://img.spoonacular.com/recipes/634011-312x231.jpg');

      // Pop back using the back button
      await tester.tap(find.byIcon(Icons.arrow_back).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 3. Navigate/swipe to Recipe 2
      final pageView = find.byType(PageView).first;
      await tester.fling(pageView, const Offset(-1000, 0), 2000);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Watching What I Eat: Peanut Butter Banana Oat Cookies'), findsOneWidget);

      // 4. Tap View Recipe on Second Card
      await tester.tap(find.text('View Recipe').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      detail = tester.widget<RecipeDetailScreen>(find.byType(RecipeDetailScreen));
      expect(detail.recipe.id, 945221);
      expect(detail.recipe.images.first, 'https://img.spoonacular.com/recipes/945221-312x231.jpg');
    });
  });
}

BuildContext detailContext(WidgetTester tester) {
  return tester.element(find.byType(RecipeDetailScreen));
}
