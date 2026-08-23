import 'package:flutter/material.dart';
import '../../features/recipe_generator/recipe_detail_screen.dart';

/// DietCompass — Recipe History Item Model
///
/// Encapsulates a fully resolved and generated recipe saved in the user's history,
/// supporting both Product-Centric and Pantry-Centric generation modes.
class RecipeHistoryItem {
  final String id;
  final String recipeId;
  final String title;
  final String description;
  final String imageUrl;
  final List<IngredientItem> ingredients;
  final List<String> instructions;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? fiber;
  final int timeMinutes;
  final String prepTime;
  final String cookTime;
  final int servings;
  final String difficulty;
  final List<String> tags;
  final String recipeSource;
  final String generationMode; // 'product' or 'pantry'
  final String sourceProduct;
  final String normalizedIngredient;
  final List<String> pantryIngredients;
  final bool isBookmarked;
  final bool isViewed;
  final DateTime generatedAt;

  const RecipeHistoryItem({
    required this.id,
    required this.recipeId,
    required this.title,
    this.description = '',
    this.imageUrl = '',
    this.ingredients = const [],
    this.instructions = const [],
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.timeMinutes = 15,
    this.prepTime = '15 mins',
    this.cookTime = '',
    this.servings = 2,
    this.difficulty = 'Easy',
    this.tags = const [],
    this.recipeSource = 'api',
    this.generationMode = 'pantry',
    this.sourceProduct = '',
    this.normalizedIngredient = '',
    this.pantryIngredients = const [],
    this.isBookmarked = false,
    this.isViewed = true,
    required this.generatedAt,
  });

  bool get isVegetarian {
    final lowerTags = tags.map((t) => t.toLowerCase()).toList();
    final lowerTitle = title.toLowerCase();
    return lowerTags.contains('vegetarian') ||
        lowerTags.contains('vegan') ||
        lowerTitle.contains('veg') ||
        !lowerTitle.contains('chicken') &&
            !lowerTitle.contains('beef') &&
            !lowerTitle.contains('meat') &&
            !lowerTitle.contains('pork') &&
            !lowerTitle.contains('fish');
  }

  String get tagsLabel {
    if (tags.isNotEmpty) return tags.join(' • ');
    return 'Healthy • Fresh • Delicious';
  }

  String get contextSubtitle {
    if (generationMode == 'product' && sourceProduct.isNotEmpty) {
      return 'Using: $sourceProduct';
    } else if (pantryIngredients.isNotEmpty) {
      return 'From Pantry (${pantryIngredients.take(2).join(', ')}${pantryIngredients.length > 2 ? '...' : ''})';
    }
    return 'From Pantry';
  }

  String get generatedAtLabel {
    final now = DateTime.now();
    final diff = now.difference(generatedAt);

    final hour = generatedAt.hour > 12
        ? generatedAt.hour - 12
        : (generatedAt.hour == 0 ? 12 : generatedAt.hour);
    final minute = generatedAt.minute.toString().padLeft(2, '0');
    final period = generatedAt.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:$minute $period';

    if (diff.inDays == 0 && now.day == generatedAt.day) {
      return 'Generated at $timeStr';
    } else if (diff.inDays <= 1) {
      return 'Yesterday at $timeStr';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return 'Generated ${months[generatedAt.month - 1]} ${generatedAt.day}, ${generatedAt.year}';
    }
  }

  String get dateGroup {
    final now = DateTime.now();
    final diff = now.difference(generatedAt);

    if (diff.inDays == 0 && now.day == generatedAt.day) {
      return 'Today';
    } else if (diff.inDays <= 1 && (now.day - generatedAt.day == 1 || diff.inHours < 36)) {
      return 'Yesterday';
    } else if (diff.inDays == 2) {
      return '2 Days Ago';
    } else if (diff.inDays < 7) {
      return 'This Week';
    } else {
      return 'Earlier';
    }
  }

  Recipe toRecipe() {
    final defaultImage = imageUrl.isNotEmpty ? imageUrl : '';
    final nutritionFacts = <NutritionFact>[
      NutritionFact(
        icon: Icons.local_fire_department,
        color: const Color(0xFFE0862E),
        label: 'Calories',
        value: '${calories?.toInt() ?? 300}\nkcal',
      ),
      NutritionFact(
        icon: Icons.circle,
        color: const Color(0xFF6C4EF5),
        label: 'Carbs',
        value: '${carbs?.toInt() ?? 45}g',
      ),
      NutritionFact(
        icon: Icons.eco,
        color: const Color(0xFF1E8A4C),
        label: 'Protein',
        value: '${protein?.toInt() ?? 10}g',
      ),
      NutritionFact(
        icon: Icons.opacity,
        color: const Color(0xFFE0B32E),
        label: 'Fat',
        value: '${fat?.toInt() ?? 8}g',
      ),
    ];

    return Recipe(
      id: recipeId,
      images: defaultImage.isNotEmpty ? [defaultImage] : [],
      title: title,
      tags: tags.isNotEmpty ? tags : ['Healthy', 'Quick'],
      description: description.isNotEmpty ? description : 'Delicious and wholesome recipe.',
      prepTime: prepTime.isNotEmpty ? prepTime : '$timeMinutes mins',
      calories: '${calories?.toInt() ?? 300}',
      protein: '${protein?.toInt() ?? 10}g',
      difficulty: difficulty,
      nutritionFacts: nutritionFacts,
      ingredients: ingredients,
      serves: servings,
      instructions: instructions.isNotEmpty
          ? instructions
          : const [
              'Prepare all fresh ingredients.',
              'Combine and cook according to recipe instructions.',
              'Serve warm and enjoy!',
            ],
    );
  }

  RecipeHistoryItem copyWith({
    bool? isBookmarked,
    bool? isViewed,
    DateTime? generatedAt,
  }) {
    return RecipeHistoryItem(
      id: id,
      recipeId: recipeId,
      title: title,
      description: description,
      imageUrl: imageUrl,
      ingredients: ingredients,
      instructions: instructions,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      timeMinutes: timeMinutes,
      prepTime: prepTime,
      cookTime: cookTime,
      servings: servings,
      difficulty: difficulty,
      tags: tags,
      recipeSource: recipeSource,
      generationMode: generationMode,
      sourceProduct: sourceProduct,
      normalizedIngredient: normalizedIngredient,
      pantryIngredients: pantryIngredients,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isViewed: isViewed ?? this.isViewed,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  factory RecipeHistoryItem.fromJson(Map<String, dynamic> json) {
    final nutrition = json['nutrition'] as Map<String, dynamic>?;

    final ingsRaw = json['ingredients'] as List?;
    final ingredients = (ingsRaw != null)
        ? ingsRaw.map((i) {
            if (i is Map<String, dynamic>) {
              return IngredientItem(
                amount: i['amount']?.toString() ?? '',
                name: i['name']?.toString() ?? i['original']?.toString() ?? '',
              );
            }
            return IngredientItem(amount: '', name: i?.toString() ?? '');
          }).toList()
        : <IngredientItem>[];

    final instRaw = json['instructions'] as List?;
    final instructions = (instRaw != null)
        ? instRaw.map((e) => e.toString()).toList()
        : <String>[];

    final tagsRaw = json['tags'] as List?;
    final tags = (tagsRaw != null)
        ? tagsRaw.map((e) => e.toString()).toList()
        : <String>[];

    final pantryRaw = json['pantryIngredients'] as List?;
    final pantryIngredients = (pantryRaw != null)
        ? pantryRaw.map((e) => e.toString()).toList()
        : <String>[];

    DateTime parsedDate;
    try {
      parsedDate = json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'].toString())
          : (json['createdAt'] != null
              ? DateTime.parse(json['createdAt'].toString())
              : DateTime.now());
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return RecipeHistoryItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      recipeId: json['recipeId']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Recipe',
      description: json['description']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? json['image']?.toString() ?? '',
      ingredients: ingredients,
      instructions: instructions,
      calories: (nutrition?['calories'] as num?)?.toDouble() ??
          (json['kcal'] as num?)?.toDouble(),
      protein: (nutrition?['protein'] as num?)?.toDouble() ??
          (json['proteinGrams'] as num?)?.toDouble(),
      carbs: (nutrition?['carbs'] as num?)?.toDouble() ??
          (json['carbsGrams'] as num?)?.toDouble(),
      fat: (nutrition?['fat'] as num?)?.toDouble() ??
          (json['fatGrams'] as num?)?.toDouble(),
      fiber: (nutrition?['fiber'] as num?)?.toDouble() ??
          (json['fiberGrams'] as num?)?.toDouble(),
      timeMinutes: (json['timeMinutes'] as num?)?.toInt() ?? 15,
      prepTime: json['prepTime']?.toString() ?? '15 mins',
      cookTime: json['cookTime']?.toString() ?? '',
      servings: (json['servings'] as num?)?.toInt() ?? 2,
      difficulty: json['difficulty']?.toString() ?? 'Easy',
      tags: tags,
      recipeSource: json['recipeSource']?.toString() ?? 'api',
      generationMode: json['generationMode']?.toString() ?? 'pantry',
      sourceProduct: json['sourceProduct']?.toString() ?? '',
      normalizedIngredient: json['normalizedIngredient']?.toString() ?? '',
      pantryIngredients: pantryIngredients,
      isBookmarked: json['isBookmarked'] == true,
      isViewed: json['isViewed'] != false,
      generatedAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipeId': recipeId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'ingredients': ingredients.map((i) => {'name': i.name, 'amount': i.amount}).toList(),
      'instructions': instructions,
      'nutrition': {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
      },
      'timeMinutes': timeMinutes,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'servings': servings,
      'difficulty': difficulty,
      'tags': tags,
      'recipeSource': recipeSource,
      'generationMode': generationMode,
      'sourceProduct': sourceProduct,
      'normalizedIngredient': normalizedIngredient,
      'pantryIngredients': pantryIngredients,
      'isBookmarked': isBookmarked,
      'isViewed': isViewed,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}
