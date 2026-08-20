import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../../features/recipe_generator/recipe_generator_screen.dart';
import '../../features/recipe_generator/recipe_detail_screen.dart';

/// DietCompass — Recipe Generation Service (Phase 6D)
/// Communicates with backend `/api/recipes/generate` and `/api/recipes/:id`
class RecipeService {
  RecipeService._();
  static final RecipeService instance = RecipeService._();

  /// Generates personalized recipes using user's pantry ingredients and Spoonacular API
  Future<List<RecipeCardData>> generateRecipes({
    List<String> ingredients = const [],
    List<Map<String, dynamic>> pantryItems = const [],
    String craving = '',
    String mealType = '',
    int? maxTime,
    int number = 6,
  }) async {
    final payload = {
      'ingredients': ingredients,
      'pantryItems': pantryItems,
      'craving': craving,
      'mealType': mealType,
      'maxTime': maxTime,
      'number': number,
    };

    final response = await ApiService.instance.post(
      '/recipes/generate',
      body: payload,
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>? ?? response.data!;
      final list = data['recipes'] as List?;
      if (list != null) {
        return list
            .whereType<Map<String, dynamic>>()
            .map((json) => _parseRecipeCard(json))
            .toList();
      }
      return [];
    }

    throw ApiException(
      response.message ?? 'Failed to generate recipes from pantry.',
      statusCode: response.statusCode,
      code: response.errorCode,
    );
  }

  /// Fetches full recipe details by ID
  Future<Recipe> getRecipeDetails(dynamic recipeId) async {
    final response = await ApiService.instance.get(
      '/recipes/$recipeId',
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>? ?? response.data!;
      return _parseRecipeDetail(data);
    }

    throw ApiException(
      response.message ?? 'Failed to load recipe details.',
      statusCode: response.statusCode,
      code: response.errorCode,
    );
  }

  RecipeCardData _parseRecipeCard(Map<String, dynamic> json) {
    final whatsInRaw = json['whatsInside'] as List?;
    final whatsInside = (whatsInRaw != null)
        ? whatsInRaw.whereType<Map<String, dynamic>>().map((t) {
            Color color;
            try {
              final hex = t['color']?.toString().replaceFirst('#', '0xFF') ?? '0xFF1E8A4C';
              color = Color(int.parse(hex));
            } catch (_) {
              color = const Color(0xFF1E8A4C);
            }

            IconData icon = Icons.eco_rounded;
            final iconStr = t['icon']?.toString() ?? '';
            if (iconStr.contains('fitness') || iconStr.contains('protein')) {
              icon = Icons.fitness_center_rounded;
            } else if (iconStr.contains('bolt') || iconStr.contains('energy')) {
              icon = Icons.bolt_rounded;
            } else if (iconStr.contains('heart') || iconStr.contains('favorite')) {
              icon = Icons.favorite_rounded;
            } else if (iconStr.contains('shopping') || iconStr.contains('weight')) {
              icon = Icons.shopping_bag_rounded;
            }

            return WhatsInTag(
              icon: icon,
              title: t['title']?.toString() ?? 'Healthy Choice',
              subtitle: t['subtitle']?.toString() ?? 'Nutrient rich',
              color: color,
            );
          }).toList()
        : <WhatsInTag>[
            const WhatsInTag(
              icon: Icons.eco_rounded,
              title: 'Nutrient Rich',
              subtitle: 'Whole food ingredients',
              color: Color(0xFF1E8A4C),
            )
          ];

    return RecipeCardData(
      id: json['id'],
      title: json['title']?.toString() ?? 'Delicious Recipe',
      tagline: json['tagline']?.toString() ?? 'Healthy • Fresh • Delicious',
      description: json['description']?.toString() ?? '',
      timeMinutes: (json['timeMinutes'] as num?)?.toInt() ?? 15,
      kcal: (json['kcal'] as num?)?.toInt() ?? 300,
      proteinGrams: (json['proteinGrams'] as num?)?.toInt() ?? 10,
      imageAsset: json['imageAsset']?.toString() ?? 'assets/images/recipe_banana_oats_power_bowl.jpeg',
      whatsInside: whatsInside,
      recommended: json['recommended'] == true,
      usedIngredientCount: (json['usedIngredientCount'] as num?)?.toInt() ?? 0,
      missedIngredientCount: (json['missedIngredientCount'] as num?)?.toInt() ?? 0,
      pantryMatchSummary: json['pantryMatchSummary']?.toString() ?? '',
    );
  }

  Recipe _parseRecipeDetail(Map<String, dynamic> json) {
    final imagesRaw = json['images'] as List?;
    final images = (imagesRaw != null && imagesRaw.isNotEmpty)
        ? imagesRaw.map((e) => e.toString()).toList()
        : [json['imageAsset']?.toString() ?? 'assets/images/recipe_banana_oats_power_bowl.jpeg'];

    final tagsRaw = json['tags'] as List?;
    final tags = (tagsRaw != null && tagsRaw.isNotEmpty)
        ? tagsRaw.map((e) => e.toString()).toList()
        : (json['tagline']?.toString().split('•').map((s) => s.trim()).toList() ?? ['Healthy', 'Quick']);

    final ingsRaw = json['ingredients'] as List?;
    final ingredients = (ingsRaw != null)
        ? ingsRaw.whereType<Map<String, dynamic>>().map((i) {
            return IngredientItem(
              amount: i['amount']?.toString() ?? '',
              name: i['name']?.toString() ?? i['original']?.toString() ?? '',
            );
          }).toList()
        : <IngredientItem>[];

    final instructionsRaw = json['instructions'] as List?;
    final instructions = (instructionsRaw != null && instructionsRaw.isNotEmpty)
        ? instructionsRaw.map((e) => e.toString()).toList()
        : [
            'Prepare all fresh ingredients.',
            'Combine and cook according to recipe instructions.',
            'Serve warm and enjoy!',
          ];

    final nutritionFacts = <NutritionFact>[
      NutritionFact(
        icon: Icons.local_fire_department,
        color: const Color(0xFFE0862E),
        label: 'Calories',
        value: '${json['kcal'] ?? 300}\nkcal',
      ),
      NutritionFact(
        icon: Icons.circle,
        color: const Color(0xFF6C4EF5),
        label: 'Carbs',
        value: '${json['carbsGrams'] ?? 45}g',
      ),
      NutritionFact(
        icon: Icons.eco,
        color: const Color(0xFF1E8A4C),
        label: 'Protein',
        value: '${json['proteinGrams'] ?? 10}g',
      ),
      NutritionFact(
        icon: Icons.opacity,
        color: const Color(0xFFE0B32E),
        label: 'Fat',
        value: '${json['fatGrams'] ?? 8}g',
      ),
      NutritionFact(
        icon: Icons.grass,
        color: const Color(0xFF1E8A4C),
        label: 'Fiber',
        value: '${json['fiberGrams'] ?? 5}g',
      ),
      NutritionFact(
        icon: Icons.icecream,
        color: const Color(0xFFE0525C),
        label: 'Sugar',
        value: '${json['sugarGrams'] ?? 6}g',
      ),
      NutritionFact(
        icon: Icons.shield_outlined,
        color: const Color(0xFF3B82F6),
        label: 'Sodium',
        value: '${json['sodiumMg'] ?? 120}mg',
      ),
    ];

    return Recipe(
      id: json['id'],
      images: images,
      title: json['title']?.toString() ?? 'Personalized Recipe',
      tags: tags,
      description: json['description']?.toString() ?? '',
      prepTime: '${json['timeMinutes'] ?? 15} min',
      calories: '${json['kcal'] ?? 300} kcal',
      protein: '${json['proteinGrams'] ?? 10}g',
      difficulty: 'Easy',
      nutritionFacts: nutritionFacts,
      ingredients: ingredients,
      serves: (json['servings'] as num?)?.toInt() ?? 1,
      instructions: instructions,
    );
  }
}
