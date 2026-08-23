import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'auth_service.dart';
import 'personalization_service.dart';
import 'profile_service.dart';

import '../model/food_product.dart';
import '../model/personalization_profile.dart';
import '../model/user_profile.dart';
import 'dietary_safety_validator.dart';
import '../../features/recipe_generator/recipe_generator_screen.dart';
import '../../features/recipe_generator/recipe_detail_screen.dart';

/// DietCompass — Recipe Generation Service (Phase 6D)
/// Communicates with backend `/api/recipes/generate` and `/api/recipes/:id`
class RecipeService {
  RecipeService._();
  static final RecipeService instance = RecipeService._();

  /// Generates personalized recipes using user's pantry ingredients and Spoonacular API
  /// Normalizes a FoodProduct into its generic culinary category
  static String normalizeProductCategory(FoodProduct product) {
    final name = (product.name).toLowerCase();
    final brand = (product.brand).toLowerCase();
    final combined = '$name $brand';
    final lower = '$combined ${product.ingredients}'.toLowerCase();

    // 1. Chocolates & Confectionery
    if (combined.contains('chocolate') || combined.contains('dairy milk') || combined.contains('silk') ||
        combined.contains('bournville') || combined.contains('kitkat') || combined.contains('snickers') ||
        combined.contains('cocoa') || combined.contains('cacao') || combined.contains('fudge')) {
      return 'chocolate';
    }

    // 2. Noodles & Pasta
    if (combined.contains('maggi') || combined.contains('noodle') || combined.contains('ramen') ||
        combined.contains('pasta') || combined.contains('spaghetti') || combined.contains('macaroni') ||
        combined.contains('penne') || combined.contains('fusilli') || combined.contains('chowmein')) {
      return 'noodles';
    }
    if (lower.contains('lays') || lower.contains("lay's") || lower.contains('potato chips') || lower.contains('chips') || lower.contains('crisps') || lower.contains('doritos') || lower.contains('pringles')) {
      return 'potato chips';
    }
    if (lower.contains('oreo') || lower.contains('cookie') || lower.contains('cookies') || lower.contains('biscuit') || lower.contains('biscuits')) {
      return 'cookies';
    }
    if (lower.contains('nutella') || lower.contains('hazelnut spread')) {
      return 'hazelnut spread';
    }
    if (lower.contains('peanut butter') || lower.contains('pb')) {
      return 'peanut butter';
    }
    if (lower.contains('amul butter') || lower.contains('butter')) {
      return 'butter';
    }
    if (lower.contains('paneer') || lower.contains('cottage cheese')) {
      return 'paneer';
    }
    if (lower.contains('cheese') || lower.contains('cheddar') || lower.contains('mozzarella')) {
      return 'cheese';
    }
    if (lower.contains('yogurt') || lower.contains('curd') || lower.contains('dahi')) {
      return 'yogurt';
    }
    if (lower.contains('oats') || lower.contains('oatmeal') || lower.contains('rolled oats')) {
      return 'oats';
    }
    if (lower.contains('bread') || lower.contains('toast')) {
      return 'bread';
    }
    if (lower.contains('egg') || lower.contains('eggs')) {
      return 'eggs';
    }
    if (lower.contains('milk')) {
      return 'milk';
    }
    return product.name.trim();
  }

  /// Generates personalized recipes using user's pantry ingredients and Spoonacular API
  Future<List<RecipeCardData>> generateRecipes({
    String mode = '',
    List<String> ingredients = const [],
    List<String> pantryItems = const [],
    String craving = '',
    String mealType = '',
    int? maxTime,
    int number = 6,
    FoodProduct? sourceProduct,
    PersonalizationProfile? personalization,
    UserProfile? profile,
    bool allowDemoFallback = false,
  }) async {
    final active = DietarySafetyValidator.instance.getActiveDietaryProfile(
      personalization: personalization,
      profile: profile,
    );

    final activePers = personalization ?? PersonalizationService.instance.currentPersonalization;
    final activeProf = profile ?? ProfileService.instance.currentProfile;
    final userId = activeProf?.id ?? AuthService.instance.currentUser?.id ?? 'authenticated_user';

    debugPrint('\n==============================================');
    debugPrint('[RECIPE PROFILE]');
    debugPrint('userId = $userId');
    debugPrint('diet = ${active.dietType}');
    debugPrint('goal = ${activePers?.goals.isNotEmpty == true ? activePers!.goals.join(', ') : 'None'}');
    debugPrint('allergies = [${active.allergies.join(', ')}]');
    debugPrint('==============================================\n');

    final isProductMode = mode == 'product' || (mode.isEmpty && sourceProduct != null);
    final effectiveMode = isProductMode ? 'product' : 'pantry';
    final normalizedCategory = (isProductMode && sourceProduct != null)
        ? normalizeProductCategory(sourceProduct)
        : '';
    final effectiveCraving = craving.isNotEmpty ? craving : normalizedCategory;

    final payload = <String, dynamic>{
      'mode': effectiveMode,
      'craving': effectiveCraving,
      'primaryIngredient': normalizedCategory,
      'mealType': mealType,
      'dietType': active.dietType,
      'allergies': active.allergies.toList(),
      'maxTime': maxTime,
      'number': number,
    };

    if (isProductMode && sourceProduct != null) {
      payload['sourceProduct'] = {
        'name': sourceProduct.name,
        'brand': sourceProduct.brand,
        'barcode': sourceProduct.barcode,
        'imageUrl': sourceProduct.imageUrl,
        'ingredients': sourceProduct.ingredients,
        'nutriScore': sourceProduct.nutriScore,
        'calories': sourceProduct.calories,
        'protein': sourceProduct.protein,
        'carbs': sourceProduct.carbohydrates,
        'fat': sourceProduct.fat,
        'fiber': sourceProduct.fiber,
        'sugar': sourceProduct.sugar,
        'sodium': sourceProduct.sodium,
      };

      debugPrint('\n==============================================');
      debugPrint('[RECIPE MODE]');
      debugPrint('mode = product\n');
      debugPrint('[PRODUCT NORMALIZATION]');
      debugPrint('originalProduct = ${sourceProduct.name}');
      debugPrint('normalizedIngredient = $normalizedCategory\n');
      debugPrint('[RECIPE SEARCH]');
      debugPrint('searchQuery = ${effectiveCraving.isNotEmpty ? effectiveCraving : normalizedCategory}');
      debugPrint('pantryIngredients = IGNORED');
      debugPrint('==============================================\n');
    } else {
      payload['ingredients'] = ingredients;
      payload['pantryItems'] = pantryItems;

      debugPrint('\n==============================================');
      debugPrint('[RECIPE MODE]');
      debugPrint('mode = pantry\n');
      debugPrint('[PANTRY RECIPE SEARCH]');
      debugPrint('pantryIngredients = ${ingredients.join(', ')}');
      debugPrint('==============================================\n');
    }

    final effectiveQuery = effectiveCraving.isNotEmpty ? effectiveCraving : normalizedCategory;

    debugPrint('\n[RECIPE REQUEST DEBUG]');
    debugPrint('endpoint = /recipes/generate');
    debugPrint('mode = $effectiveMode');
    debugPrint('sourceProduct = ${sourceProduct?.name ?? 'none'}');
    debugPrint('searchQuery = ${effectiveQuery.isNotEmpty ? effectiveQuery : 'none'}');
    debugPrint('pantryIngredients = ${isProductMode ? '[]' : ingredients.toString()}');
    debugPrint('diet = ${active.dietType}');
    debugPrint('mealType = ${mealType.isNotEmpty ? mealType : 'none'}');
    debugPrint('goal = ${personalization?.goals.join(', ') ?? 'none'}');

    List<RecipeCardData> candidates = [];
    String receivedSource = 'unknown';
    int rawCount = 0;

    try {
      final response = await ApiService.instance.post(
        '/recipes/generate',
        body: payload,
        requiresAuth: true,
      );

      final bodyStr = response.rawBody ?? jsonEncode(response.data ?? {});
      final bodyLen = bodyStr.length;
      final previewBody = bodyLen > 10000 ? '${bodyStr.substring(0, 10000)}... (truncated)' : bodyStr;

      debugPrint('\n[RECIPE RAW RESPONSE DEBUG]');
      debugPrint('statusCode = ${response.statusCode}');
      debugPrint('contentType = ${response.contentType ?? 'application/json'}');
      debugPrint('responseBodyLength = $bodyLen');
      debugPrint('responseBody = $previewBody');

      final rootMap = response.data;
      final rootType = rootMap != null ? rootMap.runtimeType.toString() : 'null';
      final rootKeys = rootMap != null ? rootMap.keys.toList().toString() : '[]';

      debugPrint('\n[RECIPE JSON STRUCTURE]');
      debugPrint('rootType = $rootType');
      debugPrint('rootKeys = $rootKeys');

      if (response.success && response.data != null) {
        final dynamic nestedData = response.data!['data'];
        final Map<String, dynamic> dataMap = (nestedData is Map<String, dynamic>)
            ? nestedData
            : response.data!;

        debugPrint('[RECIPE PARSER TRACE] Reading recipes from dataMap keys: ${dataMap.keys.toList()}');

        receivedSource = dataMap['recipeSource']?.toString() ?? 'api';
        final list = dataMap['recipes'] as List?;
        if (list != null) {
          rawCount = list.length;
          debugPrint('[RECIPE PARSER TRACE] dataMap["recipes"] found with length $rawCount');
          for (var i = 0; i < list.length; i++) {
            final item = list[i];
            if (item is Map<String, dynamic>) {
              try {
                final card = _parseRecipeCard(item, defaultSource: receivedSource);
                candidates.add(card);
              } catch (e, st) {
                debugPrint('\n[RECIPE PARSER ERROR]');
                debugPrint('recipeIndex = $i');
                debugPrint('error = $e');
                debugPrint('stackTrace = $st');
              }
            } else {
              debugPrint('\n[RECIPE PARSER ERROR]');
              debugPrint('recipeIndex = $i');
              debugPrint('error = Item is not a Map<String, dynamic>, got: ${item.runtimeType}');
            }
          }
        } else {
          debugPrint('\n[RECIPE PARSER MISSING FIELD]');
          debugPrint('expectedField = recipes');
          debugPrint('availableFields = ${dataMap.keys.toList()}');
        }
      }

      debugPrint('\n[RECIPE RAW RESPONSE]');
      debugPrint('statusCode = ${response.statusCode}');
      debugPrint('rawRecipeCount = $rawCount');
    } catch (e, st) {
      debugPrint('\n[RECIPE PARSER ERROR]');
      debugPrint('error = API request failed: $e');
      debugPrint('stackTrace = $st');
      debugPrint('\n[RECIPE RAW RESPONSE]');
      debugPrint('statusCode = 500');
      debugPrint('rawRecipeCount = 0');
    }

    debugPrint('\n[RECIPE PARSING]');
    debugPrint('parsedRecipeCount = ${candidates.length}');

    // Hard Constraint Safety Validation: reject any recipe violating dietary preferences or allergies
    final validCandidates = candidates.where((card) {
      final safety = DietarySafetyValidator.instance.validateRecipeCard(
        card,
        personalization: personalization,
        profile: profile,
      );
      return safety.isCompatible;
    }).toList();

    debugPrint('\n[RECIPE FILTERING]');
    debugPrint('finalRecipeCount = ${validCandidates.length}');



    if (validCandidates.isNotEmpty) {
      final first = validCandidates.first;
      final ingsStr = first.fullRecipe?.ingredients.map((i) => i.name).join(', ') ?? '';
      debugPrint('\n[FLUTTER RECIPE RESULT]');
      debugPrint('source = ${first.recipeSource.isNotEmpty ? first.recipeSource : receivedSource}');
      debugPrint('recipeCount = ${validCandidates.length}');
      debugPrint('recipe[0].id = ${first.id}');
      debugPrint('recipe[0].title = ${first.title}');
      debugPrint('recipe[0].image = ${first.imageAsset}');
      debugPrint('recipe[0].ingredients = $ingsStr');
      debugPrint('==============================================\n');
      return validCandidates;
    }

    debugPrint('\n[FLUTTER RECIPE RESULT]');
    debugPrint('source = none');
    debugPrint('recipeCount = 0');
    debugPrint('recipe[0].id = none');
    debugPrint('recipe[0].title = No suitable recipes found');
    debugPrint('recipe[0].image = none');
    debugPrint('recipe[0].ingredients = none');
    debugPrint('==============================================\n');

    // In normal production flow: when API returns 0 results / fails, return empty list
    return [];
  }


  /// Fetches full recipe details by ID
  Future<Recipe> getRecipeDetails(dynamic recipeId) async {
    try {
      final response = await ApiService.instance.get(
        '/recipes/${Uri.encodeComponent(recipeId.toString())}',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>? ?? response.data!;
        return _parseRecipeDetail(data);
      }
    } catch (_) {}

    throw ApiException(
      'Failed to load recipe details.',
      statusCode: 404,
      code: 'RECIPE_NOT_FOUND',
    );
  }

  RecipeCardData _parseRecipeCard(Map<String, dynamic> json, {String defaultSource = 'api'}) {
    final recipeId = json['id'];
    final title = json['title']?.toString() ?? 'Delicious Recipe';
    final rawImage = json['image']?.toString() ?? json['imageAsset']?.toString() ?? '';
    final recipeSource = json['recipeSource']?.toString() ?? defaultSource;

    // Strict Image ID validation: If image URL is from Spoonacular, ensure the ID in URL matches recipe.id
    String validImage = rawImage;
    if (recipeId != null && rawImage.contains('img.spoonacular.com/recipes/')) {
      final match = RegExp(r'recipes/(\d+)-').firstMatch(rawImage);
      if (match != null && match.group(1) != null) {
        final imgId = int.tryParse(match.group(1)!);
        final recId = (recipeId is int) ? recipeId : int.tryParse(recipeId.toString());
        if (imgId != null && recId != null && imgId != recId) {
          debugPrint('[RECIPE IMAGE DEBUG] Warning: Image ID $imgId does not match recipe ID $recId for "$title". Using neutral placeholder.');
          validImage = '';
        }
      }
    }

    final recipeImage = validImage.isNotEmpty ? validImage : '';
    debugPrint('[RECIPE IMAGE DEBUG] recipeId: $recipeId | recipeTitle: $title | recipeImage: $recipeImage');

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

    final fullRecipe = _parseRecipeDetail(json, fallbackImage: recipeImage);

    return RecipeCardData(
      id: json['id'],
      title: title,
      tagline: json['tagline']?.toString() ?? 'Healthy • Fresh • Delicious',
      description: json['description']?.toString() ?? '',
      timeMinutes: (json['timeMinutes'] as num?)?.toInt() ?? 15,
      kcal: (json['kcal'] as num?)?.toInt() ?? 300,
      proteinGrams: (json['proteinGrams'] as num?)?.toInt() ?? 10,
      imageAsset: recipeImage,
      recipeSource: recipeSource,
      whatsInside: whatsInside,
      recommended: json['recommended'] == true,
      usedIngredientCount: (json['usedIngredientCount'] as num?)?.toInt() ?? 0,
      missedIngredientCount: (json['missedIngredientCount'] as num?)?.toInt() ?? 0,
      pantryMatchSummary: json['pantryMatchSummary']?.toString() ?? '',
      fullRecipe: fullRecipe,
    );
  }


  Recipe _parseRecipeDetail(Map<String, dynamic> json, {String? fallbackImage}) {
    final title = json['title']?.toString() ?? 'Personalized Recipe';
    final rawImage = json['image']?.toString() ?? json['imageAsset']?.toString() ?? fallbackImage ?? '';
    final defaultImg = rawImage.isNotEmpty ? rawImage : '';

    final imagesRaw = json['images'] as List?;
    final images = (imagesRaw != null && imagesRaw.isNotEmpty)
        ? imagesRaw.map((e) => e.toString()).toList()
        : [defaultImg];

    final tagsRaw = json['tags'] as List?;
    final tags = (tagsRaw != null && tagsRaw.isNotEmpty)
        ? tagsRaw.map((e) => e.toString()).toList()
        : (json['tagline']?.toString().split('•').map((s) => s.trim()).toList() ?? ['Healthy', 'Quick']);

    final ingsRaw = json['ingredients'] as List?;
    final ingredients = (ingsRaw != null)
        ? ingsRaw.map((i) {
            if (i is Map<String, dynamic>) {
              return IngredientItem(
                amount: i['amount']?.toString() ?? '',
                name: i['name']?.toString() ?? i['original']?.toString() ?? '',
              );
            } else if (i is String) {
              return IngredientItem(
                amount: '',
                name: i,
              );
            }
            return IngredientItem(
              amount: '',
              name: i?.toString() ?? '',
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
      title: title,
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

