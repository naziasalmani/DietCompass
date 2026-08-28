import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/core/data/hardcoded_recipes.dart';
import 'package:diet_compass/core/services/recipe_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DietCompass Hardcoded / Fallback Recipes Integration Tests', () {
    test('1. Hardcoded Recipe Catalog preserves all 6 curated recipes with full fields', () {
      expect(HardcodedRecipeCatalog.recipes.length, 6);

      final titles = HardcodedRecipeCatalog.recipes.map((r) => r.title).toList();
      expect(titles, contains('Banana Oats Power Bowl'));
      expect(titles, contains('Chocolate Banana Overnight Oats'));
      expect(titles, contains('Apple Cinnamon Oatmeal Bowl'));
      expect(titles, contains('Savory Spinach & Mushroom Oats'));
      expect(titles, contains('High-Protein Green Egg Scramble'));
      expect(titles, contains('Pasta Primavera with Fresh Vegetables'));

      for (final recipe in HardcodedRecipeCatalog.recipes) {
        expect(recipe.id, isNotNull);
        expect(recipe.title.isNotEmpty, isTrue);
        expect(recipe.timeMinutes, greaterThan(0));
        expect(recipe.kcal, greaterThan(0));
        expect(recipe.proteinGrams, greaterThan(0));
        expect(recipe.whatsInside.length, greaterThanOrEqualTo(3));
        expect(recipe.fullRecipe, isNotNull);
        expect(recipe.fullRecipe!.ingredients.length, greaterThanOrEqualTo(4));
        expect(recipe.fullRecipe!.instructions.length, greaterThanOrEqualTo(3));
        expect(recipe.fullRecipe!.nutritionFacts.length, greaterThanOrEqualTo(5));
      }
    });

    test('2. Explicit Search Query Matching: matches only relevant hardcoded candidates', () {
      // Search: "chocolate"
      final chocolateMatches = HardcodedRecipeCatalog.findMatchingSearch('chocolate');
      expect(chocolateMatches.length, 1);
      expect(chocolateMatches.first.title, 'Chocolate Banana Overnight Oats');
      expect(chocolateMatches.any((r) => r.title.contains('Pasta Primavera')), isFalse);

      // Search: "banana"
      final bananaMatches = HardcodedRecipeCatalog.findMatchingSearch('banana');
      final bananaTitles = bananaMatches.map((r) => r.title).toList();
      expect(bananaTitles, contains('Banana Oats Power Bowl'));
      expect(bananaTitles, contains('Chocolate Banana Overnight Oats'));
      expect(bananaTitles, isNot(contains('Pasta Primavera with Fresh Vegetables')));

      // Search: "oats"
      final oatsMatches = HardcodedRecipeCatalog.findMatchingSearch('oats');
      expect(oatsMatches.length, 4);
      final oatsTitles = oatsMatches.map((r) => r.title).toList();
      expect(oatsTitles, contains('Banana Oats Power Bowl'));
      expect(oatsTitles, contains('Chocolate Banana Overnight Oats'));
      expect(oatsTitles, contains('Apple Cinnamon Oatmeal Bowl'));
      expect(oatsTitles, contains('Savory Spinach & Mushroom Oats'));

      // Search: "egg"
      final eggMatches = HardcodedRecipeCatalog.findMatchingSearch('egg');
      expect(eggMatches.length, 1);
      expect(eggMatches.first.title, 'High-Protein Green Egg Scramble');

      // Search: "pasta"
      final pastaMatches = HardcodedRecipeCatalog.findMatchingSearch('pasta');
      expect(pastaMatches.length, 1);
      expect(pastaMatches.first.title, 'Pasta Primavera with Fresh Vegetables');

      // Search: "spinach"
      final spinachMatches = HardcodedRecipeCatalog.findMatchingSearch('spinach');
      final spinachTitles = spinachMatches.map((r) => r.title).toList();
      expect(spinachTitles, contains('Savory Spinach & Mushroom Oats'));
      expect(spinachTitles, contains('High-Protein Green Egg Scramble'));
    });

    test('3. RecipeService.fallbackRecipeImage resolves proper assets for all 6 recipes', () {
      expect(
        RecipeService.fallbackRecipeImage('Banana Oats Power Bowl'),
        'assets/images/recipe_banana_oats_power_bowl.jpeg',
      );
      expect(
        RecipeService.fallbackRecipeImage('Chocolate Banana Overnight Oats'),
        'assets/images/recipe_chocolate_banana_oats.jpeg',
      );
      expect(
        RecipeService.fallbackRecipeImage('Apple Cinnamon Oatmeal Bowl'),
        'assets/images/recipe_apple_cinnamon_oatmeal.jpeg',
      );
      expect(
        RecipeService.fallbackRecipeImage('Savory Spinach & Mushroom Oats'),
        'assets/images/recipe_savory_veggie_oats.jpeg',
      );
      expect(
        RecipeService.fallbackRecipeImage('High-Protein Green Egg Scramble'),
        'assets/images/recipe_veggie_omelette.jpeg',
      );
      expect(
        RecipeService.fallbackRecipeImage('Pasta Primavera with Fresh Vegetables'),
        'assets/images/recipe_protein_pancakes.jpeg',
      );
    });

    test('4. ID & Title Lookup resolves full Recipe structure seamlessly', () async {
      final hardcodedOats = HardcodedRecipeCatalog.findByIdOrTitle('hardcoded_banana_oats');
      expect(hardcodedOats, isNotNull);
      expect(hardcodedOats!.title, 'Banana Oats Power Bowl');

      final hardcodedChocolate = HardcodedRecipeCatalog.findByIdOrTitle('Chocolate Banana Overnight Oats');
      expect(hardcodedChocolate, isNotNull);
      expect(hardcodedChocolate!.id, 'hardcoded_chocolate_banana_oats');

      final resolvedDetail = await RecipeService.instance.getRecipeDetails('hardcoded_pasta_primavera');
      expect(resolvedDetail.title, 'Pasta Primavera with Fresh Vegetables');
      expect(resolvedDetail.ingredients.isNotEmpty, isTrue);
      expect(resolvedDetail.instructions.isNotEmpty, isTrue);
    });
  });
}
