import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/core/services/recipe_history_service.dart';
import 'package:diet_compass/core/model/recipe_history_item.dart';
import 'package:diet_compass/features/recipe_generator/recipe_generator_screen.dart';
import 'package:diet_compass/features/profile/saved_recipes_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DietCompass Unified Save Recipe / History / Profile Flow Tests', () {
    setUp(() {
      RecipeHistoryService.instance.clearCache();
    });

    test('1. RecipeHistoryService correctly bookmarks and un-bookmarks recipes', () async {
      final card = RecipeCardData(
        id: 'rec_101',
        title: 'Farfalle Pasta with Fresh Tomatoes',
        tagline: '20 min • 380 kcal',
        description: 'Fresh Mediterranean farfalle dish.',
        timeMinutes: 20,
        kcal: 380,
        proteinGrams: 14,
        imageAsset: 'https://img.spoonacular.com/recipes/farfalle.jpg',
        whatsInside: const [],
      );

      // Verify initially not saved
      expect(RecipeHistoryService.instance.isRecipeSaved('rec_101', card.title), isFalse);
      expect(RecipeHistoryService.instance.savedRecipes.length, equals(0));

      // Save recipe
      await RecipeHistoryService.instance.saveOrBookmarkRecipeCard(
        card,
        bookmarked: true,
      );

      expect(RecipeHistoryService.instance.isRecipeSaved('rec_101', card.title), isTrue);
      expect(RecipeHistoryService.instance.savedRecipes.length, equals(1));
      expect(RecipeHistoryService.instance.savedRecipes.first.title, equals('Farfalle Pasta with Fresh Tomatoes'));
      expect(RecipeHistoryService.instance.savedRecipes.first.imageUrl, equals('https://img.spoonacular.com/recipes/farfalle.jpg'));

      // Toggle bookmark off
      final savedItem = RecipeHistoryService.instance.savedRecipes.first;
      await RecipeHistoryService.instance.toggleBookmark(savedItem, false);

      expect(RecipeHistoryService.instance.isRecipeSaved('rec_101', card.title), isFalse);
      expect(RecipeHistoryService.instance.savedRecipes.length, equals(0));
    });

    testWidgets('2. SavedRecipesScreen displays empty state when no recipes are saved (no hardcoded samples)', (tester) async {
      RecipeHistoryService.instance.clearCache();

      await tester.pumpWidget(
        MaterialApp(
          home: SavedRecipesScreen(
            recipes: const [],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Ensure NO hardcoded items like Banana Oats appear
      expect(find.text('Banana Oats Power Bowl'), findsNothing);
      expect(find.text('Apple Cinnamon Oatmeal'), findsNothing);

      // Verify empty state is displayed
      expect(find.text('No saved recipes yet'), findsOneWidget);
      expect(find.text('Explore Recipes'), findsOneWidget);
    });

    testWidgets('3. SavedRecipesScreen renders real saved recipes with correct image and details', (tester) async {
      final item = RecipeHistoryItem(
        id: 'rec_202',
        recipeId: 'rec_202',
        title: 'Spinach Chickpea Curry',
        description: 'Flavorful spiced curry with spinach.',
        imageUrl: 'https://img.spoonacular.com/recipes/spinach_curry.jpg',
        timeMinutes: 25,
        calories: 420,
        protein: 16,
        tags: ['Vegetarian', 'Dinner'],
        isBookmarked: true,
        generatedAt: DateTime.now(),
      );

      final recipeItem = RecipeItem.fromHistoryItem(item);

      await tester.pumpWidget(
        MaterialApp(
          home: SavedRecipesScreen(
            recipes: [recipeItem],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Verify recipe title and stats
      expect(find.text('Spinach Chickpea Curry'), findsOneWidget);
      expect(find.text('25 min'), findsOneWidget);
      expect(find.text('420 kcal'), findsOneWidget);
      expect(find.text('16g Protein'), findsOneWidget);
      expect(find.text('No saved recipes yet'), findsNothing);
    });
  });
}
