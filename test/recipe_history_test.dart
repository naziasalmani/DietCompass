import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:diet_compass/core/model/recipe_history_item.dart';
import 'package:diet_compass/core/services/recipe_history_service.dart';
import 'package:diet_compass/core/services/storage_service.dart';
import 'package:diet_compass/features/recipe_generator/history_screen.dart';
import 'package:diet_compass/features/recipe_generator/recipe_detail_screen.dart';
import 'package:diet_compass/features/recipe_generator/recipe_generator_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  setUp(() {
    RecipeHistoryService.instance.clearCache();
  });

  group('Recipe History Model & Serialization Tests', () {
    test('RecipeHistoryItem correctly parses JSON and formats fields', () {
      final json = {
        'id': 'rec_123',
        'recipeId': 'sp_634011',
        'title': 'Chocolate Banana Bread',
        'description': 'Delicious chocolate banana bread.',
        'imageUrl': 'https://img.spoonacular.com/recipes/634011-312x231.jpg',
        'timeMinutes': 45,
        'prepTime': '15 mins',
        'servings': 4,
        'difficulty': 'Medium',
        'tags': ['Healthy', 'Dessert'],
        'recipeSource': 'spoonacular',
        'generationMode': 'product',
        'sourceProduct': 'Cadbury Dairy Milk',
        'normalizedIngredient': 'chocolate',
        'nutrition': {
          'calories': 320,
          'protein': 6,
          'carbs': 48,
          'fat': 12,
          'fiber': 3,
        },
        'ingredients': [
          {'name': 'chocolate', 'amount': '100g'},
          {'name': 'banana', 'amount': '2'},
        ],
        'instructions': ['Mix ingredients', 'Bake at 350F'],
        'isBookmarked': true,
        'isViewed': true,
        'generatedAt': DateTime.now().toIso8601String(),
      };

      final item = RecipeHistoryItem.fromJson(json);

      expect(item.id, equals('rec_123'));
      expect(item.recipeId, equals('sp_634011'));
      expect(item.title, equals('Chocolate Banana Bread'));
      expect(item.imageUrl, equals('https://img.spoonacular.com/recipes/634011-312x231.jpg'));
      expect(item.generationMode, equals('product'));
      expect(item.sourceProduct, equals('Cadbury Dairy Milk'));
      expect(item.contextSubtitle, equals('Using: Cadbury Dairy Milk'));
      expect(item.calories, equals(320.0));
      expect(item.protein, equals(6.0));
      expect(item.isBookmarked, isTrue);
      expect(item.dateGroup, equals('Today'));

      // Convert to full Recipe
      final recipe = item.toRecipe();
      expect(recipe.title, equals('Chocolate Banana Bread'));
      expect(recipe.images.first, equals('https://img.spoonacular.com/recipes/634011-312x231.jpg'));
      expect(recipe.ingredients.length, equals(2));
      expect(recipe.instructions.length, equals(2));
      expect(recipe.calories, equals('320'));
      expect(recipe.protein, equals('6g'));
    });

    test('RecipeHistoryItem formats Pantry mode context subtitle', () {
      final item = RecipeHistoryItem(
        id: 'rec_pantry_1',
        recipeId: 'tm_123',
        title: 'Veggie Stir Fry',
        generationMode: 'pantry',
        pantryIngredients: ['tofu', 'broccoli', 'soy sauce'],
        generatedAt: DateTime.now(),
      );

      expect(item.contextSubtitle, equals('From Pantry (tofu, broccoli...)'));
    });
  });

  group('RecipeHistoryService Tests', () {
    test('saveRecipes adds items to in-memory history and moves duplicate to top', () async {
      final card1 = RecipeCardData(
        id: 'rec_1',
        title: 'Recipe One',
        tagline: 'Quick • Tasty',
        description: 'First recipe',
        timeMinutes: 20,
        kcal: 300,
        proteinGrams: 15,
        imageAsset: 'https://example.com/1.jpg',
        whatsInside: [],
      );

      final card2 = RecipeCardData(
        id: 'rec_2',
        title: 'Recipe Two',
        tagline: 'Healthy • Fresh',
        description: 'Second recipe',
        timeMinutes: 10,
        kcal: 250,
        proteinGrams: 8,
        imageAsset: 'https://example.com/2.jpg',
        whatsInside: [],
      );

      // Save batch 1
      await RecipeHistoryService.instance.saveRecipes(
        recipes: [card1],
        generationMode: 'product',
        sourceProduct: 'Dark Chocolate',
      );

      expect(RecipeHistoryService.instance.currentHistory.length, equals(1));
      expect(RecipeHistoryService.instance.currentHistory.first.title, equals('Recipe One'));

      // Save batch 2
      await RecipeHistoryService.instance.saveRecipes(
        recipes: [card2],
        generationMode: 'pantry',
        pantryIngredients: ['eggs', 'toast'],
      );

      expect(RecipeHistoryService.instance.currentHistory.length, equals(2));
      expect(RecipeHistoryService.instance.currentHistory[0].title, equals('Recipe Two'));
      expect(RecipeHistoryService.instance.currentHistory[1].title, equals('Recipe One'));

      // Re-save Recipe One -> should bump to top without duplicates
      await RecipeHistoryService.instance.saveRecipes(
        recipes: [card1],
        generationMode: 'product',
        sourceProduct: 'Dark Chocolate',
      );

      expect(RecipeHistoryService.instance.currentHistory.length, equals(2));
      expect(RecipeHistoryService.instance.currentHistory[0].title, equals('Recipe One'));
      expect(RecipeHistoryService.instance.currentHistory[1].title, equals('Recipe Two'));
    });

    test('toggleBookmark updates bookmark state', () async {
      final card = RecipeCardData(
        id: 'rec_bm',
        title: 'Bookmarkable Recipe',
        tagline: 'Tag',
        description: 'Desc',
        timeMinutes: 15,
        kcal: 300,
        proteinGrams: 10,
        imageAsset: 'https://example.com/bm.jpg',
        whatsInside: [],
      );

      await RecipeHistoryService.instance.saveRecipes(recipes: [card]);
      final savedItem = RecipeHistoryService.instance.currentHistory.first;
      expect(savedItem.isBookmarked, isFalse);

      await RecipeHistoryService.instance.toggleBookmark(savedItem, true);
      expect(RecipeHistoryService.instance.currentHistory.first.isBookmarked, isTrue);
      expect(RecipeHistoryService.instance.savedRecipes.length, equals(1));

      await RecipeHistoryService.instance.toggleBookmark(savedItem, false);
      expect(RecipeHistoryService.instance.currentHistory.first.isBookmarked, isFalse);
      expect(RecipeHistoryService.instance.savedRecipes.length, equals(0));
    });

    test('clearCache clears in-memory history upon logout', () async {
      final card = RecipeCardData(
        id: 'rec_temp',
        title: 'Temporary Recipe',
        tagline: 'Tag',
        description: 'Desc',
        timeMinutes: 15,
        kcal: 300,
        proteinGrams: 10,
        imageAsset: 'https://example.com/temp.jpg',
        whatsInside: [],
      );

      await RecipeHistoryService.instance.saveRecipes(recipes: [card]);
      expect(RecipeHistoryService.instance.currentHistory.length, equals(1));

      RecipeHistoryService.instance.clearCache();
      expect(RecipeHistoryService.instance.currentHistory.length, equals(0));
    });
  });

  group('HistoryScreen UI Tests', () {
    testWidgets('HistoryScreen displays empty state when no history exists', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(recipes: []),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('History'), findsOneWidget);
      expect(find.text('No recipes generated yet'), findsOneWidget);
      expect(find.text('Generate Your First Recipe'), findsOneWidget);
      // Zero demo items
      expect(find.text('Banana Oats Power Bowl'), findsNothing);
      expect(find.text('Apple Cinnamon Oatmeal'), findsNothing);
    });

    testWidgets('HistoryScreen displays real recipes with exact title, context subtitle, and tags', (tester) async {
      final items = [
        RecipeHistoryItem(
          id: '1',
          recipeId: 'sp_101',
          title: 'Silk Chocolate Lava Cake',
          description: 'Molten chocolate lava cake.',
          imageUrl: 'https://img.spoonacular.com/recipes/101.jpg',
          timeMinutes: 25,
          calories: 450,
          protein: 8,
          generationMode: 'product',
          sourceProduct: 'Dairy Milk Silk Chocolate',
          generatedAt: DateTime.now(),
        ),
        RecipeHistoryItem(
          id: '2',
          recipeId: 'tm_202',
          title: 'Veggie Fried Rice',
          description: 'Quick wok fried rice.',
          imageUrl: 'https://www.themealdb.com/images/media/meals/202.jpg',
          timeMinutes: 15,
          calories: 310,
          protein: 12,
          generationMode: 'pantry',
          pantryIngredients: ['rice', 'peas', 'carrots'],
          generatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: HistoryScreen(recipes: items),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Silk Chocolate Lava Cake'), findsOneWidget);
      expect(find.text('Using: Dairy Milk Silk Chocolate'), findsOneWidget);
      expect(find.text('Veggie Fried Rice'), findsOneWidget);
      expect(find.text('From Pantry (rice, peas...)'), findsOneWidget);
      expect(find.text('450 kcal'), findsOneWidget);
      expect(find.text('12g Protein'), findsOneWidget);
    });

    testWidgets('Tapping recipe invokes onRecipeTap callback with exact item', (tester) async {
      RecipeHistoryItem? tapped;
      final testItem = RecipeHistoryItem(
        id: '1',
        recipeId: 'sp_999',
        title: 'Tappable Recipe',
        timeMinutes: 15,
        calories: 300,
        protein: 10,
        generatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HistoryScreen(
            recipes: [testItem],
            onRecipeTap: (r) => tapped = r,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Tappable Recipe'));
      await tester.pump();

      expect(tapped, isNotNull);
      expect(tapped!.recipeId, equals('sp_999'));
      expect(tapped!.title, equals('Tappable Recipe'));
    });
  });
}
