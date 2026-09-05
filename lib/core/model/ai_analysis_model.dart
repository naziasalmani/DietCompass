import 'food_product.dart';

/// Item representing a disguised / hidden sugar source
class DisguisedSugarItem {
  const DisguisedSugarItem({required this.name, required this.description});
  final String name;
  final String description;

  factory DisguisedSugarItem.fromJson(Map<String, dynamic> json) {
    return DisguisedSugarItem(
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

/// Item representing a harmful or controversial additive
class HarmfulAdditiveItem {
  const HarmfulAdditiveItem({required this.name, required this.concern});
  final String name;
  final String concern;

  factory HarmfulAdditiveItem.fromJson(Map<String, dynamic> json) {
    return HarmfulAdditiveItem(
      name: json['name']?.toString() ?? '',
      concern: json['concern']?.toString() ?? '',
    );
  }
}

/// Item representing marketing claim verification
class ClaimVerificationItem {
  const ClaimVerificationItem({
    required this.claim,
    required this.status,
    required this.explanation,
  });

  final String claim;
  final String status; // 'Verified', 'Misleading', 'Questionable'
  final String explanation;

  factory ClaimVerificationItem.fromJson(Map<String, dynamic> json) {
    return ClaimVerificationItem(
      claim: json['claim']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Questionable',
      explanation: json['explanation']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'claim': claim,
        'status': status,
        'explanation': explanation,
      };
}

/// Complete AI Intelligence Analysis result
class ProductAiAnalysis {
  const ProductAiAnalysis({
    required this.healthScore,
    required this.summary,
    required this.isSuitable,
    required this.disguisedSugars,
    required this.harmfulAdditives,
    required this.claimVerifications,
    required this.allergenWarnings,
    required this.pros,
    required this.cons,
    required this.healthierAlternatives,
    this.aiInterpretationNote = '',
  });

  final int healthScore;
  final String summary;
  final bool isSuitable;
  final List<DisguisedSugarItem> disguisedSugars;
  final List<HarmfulAdditiveItem> harmfulAdditives;
  final List<ClaimVerificationItem> claimVerifications;
  final List<String> allergenWarnings;
  final List<String> pros;
  final List<String> cons;
  final List<String> healthierAlternatives;
  final String aiInterpretationNote;

  factory ProductAiAnalysis.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(dynamic list, T Function(Map<String, dynamic>) mapper) {
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map((item) => mapper(item))
            .toList();
      }
      return [];
    }

    List<String> parseStringList(dynamic list) {
      if (list is List) {
        return list.map((e) => e.toString()).toList();
      }
      return [];
    }

    return ProductAiAnalysis(
      healthScore: (json['healthScore'] as num?)?.toInt() ?? 70,
      summary: json['summary']?.toString() ?? '',
      isSuitable: json['isSuitable'] == true,
      disguisedSugars: parseList(json['disguisedSugars'], DisguisedSugarItem.fromJson),
      harmfulAdditives: parseList(json['harmfulAdditives'], HarmfulAdditiveItem.fromJson),
      claimVerifications: parseList(json['claimVerifications'], ClaimVerificationItem.fromJson),
      allergenWarnings: parseStringList(json['allergenWarnings']),
      pros: parseStringList(json['pros']),
      cons: parseStringList(json['cons']),
      healthierAlternatives: parseStringList(json['healthierAlternatives']),
      aiInterpretationNote: json['aiInterpretationNote']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'healthScore': healthScore,
        'summary': summary,
        'isSuitable': isSuitable,
        'disguisedSugars': disguisedSugars.map((e) => {'name': e.name, 'description': e.description}).toList(),
        'harmfulAdditives': harmfulAdditives.map((e) => {'name': e.name, 'concern': e.concern}).toList(),
        'claimVerifications': claimVerifications.map((e) => e.toJson()).toList(),
        'allergenWarnings': allergenWarnings,
        'pros': pros,
        'cons': cons,
        'healthierAlternatives': healthierAlternatives,
        'aiInterpretationNote': aiInterpretationNote,
      };
}

/// Item representing dynamic compatibility factor rating
class ProductCompatibilityItem {
  const ProductCompatibilityItem({
    required this.label,
    required this.rating,
    required this.detail,
  });

  final String label;
  final String rating; // 'Excellent', 'Good', 'Consider', 'Safe', 'Incompatible', 'Allergen Alert'
  final String detail;

  factory ProductCompatibilityItem.fromJson(Map<String, dynamic> json) {
    return ProductCompatibilityItem(
      label: json['label']?.toString() ?? '',
      rating: json['rating']?.toString() ?? 'Good',
      detail: json['detail']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'rating': rating,
        'detail': detail,
      };
}

/// Dynamic Personalized Product Compatibility Score result
class ProductCompatibility {
  const ProductCompatibility({
    required this.score,
    required this.status,
    required this.isSuitable,
    required this.allergyAlerts,
    required this.dietaryAlerts,
    required this.positiveFactors,
    required this.concerns,
    required this.summary,
    required this.recommendation,
    required this.items,
  });

  final int? score;
  final String status;
  final bool isSuitable;
  final List<String> allergyAlerts;
  final List<String> dietaryAlerts;
  final List<String> positiveFactors;
  final List<String> concerns;
  final String summary;
  final String recommendation;
  final List<ProductCompatibilityItem> items;

  bool get isCalculated => score != null;

  factory ProductCompatibility.uncalculated({
    String? summary,
    String? recommendation,
  }) {
    return ProductCompatibility(
      score: null,
      status: 'Calculating...',
      isSuitable: true,
      allergyAlerts: const [],
      dietaryAlerts: const [],
      positiveFactors: const [],
      concerns: const [],
      summary: summary ?? 'Preparing your personalized analysis...',
      recommendation: recommendation ?? 'Calculating compatibility score once your profile context is loaded.',
      items: const [],
    );
  }

  factory ProductCompatibility.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic list) {
      if (list is List) {
        return list.map((e) => e.toString()).toList();
      }
      return [];
    }

    List<ProductCompatibilityItem> parseItems(dynamic list) {
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => ProductCompatibilityItem.fromJson(e))
            .toList();
      }
      return [];
    }

    return ProductCompatibility(
      score: (json['score'] as num?)?.toInt(),
      status: json['status']?.toString() ?? 'Calculating...',
      isSuitable: json['isSuitable'] == true,
      allergyAlerts: parseStringList(json['allergyAlerts']),
      dietaryAlerts: parseStringList(json['dietaryAlerts']),
      positiveFactors: parseStringList(json['positiveFactors']),
      concerns: parseStringList(json['concerns']),
      summary: json['summary']?.toString() ?? '',
      recommendation: json['recommendation']?.toString() ?? '',
      items: parseItems(json['items']),
    );
  }

  Map<String, dynamic> toJson() => {
        'score': score,
        'status': status,
        'isSuitable': isSuitable,
        'allergyAlerts': allergyAlerts,
        'dietaryAlerts': dietaryAlerts,
        'positiveFactors': positiveFactors,
        'concerns': concerns,
        'summary': summary,
        'recommendation': recommendation,
        'items': items.map((i) => i.toJson()).toList(),
      };
}

/// Nutrition difference comparison between candidate and scanned product
class ProductNutritionComparison {
  const ProductNutritionComparison({
    required this.sugarDiff,
    required this.proteinDiff,
    required this.fiberDiff,
    required this.calorieDiff,
    required this.sodiumDiff,
    required this.highlights,
    required this.differentiator,
    required this.matchReason,
  });

  final double sugarDiff;
  final double proteinDiff;
  final double fiberDiff;
  final int calorieDiff;
  final int sodiumDiff;
  final List<String> highlights;
  final String differentiator;
  final String matchReason;

  factory ProductNutritionComparison.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic list) {
      if (list is List) {
        return list.map((e) => e.toString()).toList();
      }
      return [];
    }

    return ProductNutritionComparison(
      sugarDiff: (json['sugarDiff'] as num?)?.toDouble() ?? 0.0,
      proteinDiff: (json['proteinDiff'] as num?)?.toDouble() ?? 0.0,
      fiberDiff: (json['fiberDiff'] as num?)?.toDouble() ?? 0.0,
      calorieDiff: (json['calorieDiff'] as num?)?.toInt() ?? 0,
      sodiumDiff: (json['sodiumDiff'] as num?)?.toInt() ?? 0,
      highlights: parseStringList(json['highlights']),
      differentiator: json['differentiator']?.toString() ?? '',
      matchReason: json['matchReason']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'sugarDiff': sugarDiff,
        'proteinDiff': proteinDiff,
        'fiberDiff': fiberDiff,
        'calorieDiff': calorieDiff,
        'sodiumDiff': sodiumDiff,
        'highlights': highlights,
        'differentiator': differentiator,
        'matchReason': matchReason,
      };
}

/// Personalized Similar Product Recommendation result
class PersonalizedRecommendation {
  const PersonalizedRecommendation({
    required this.product,
    required this.compatibility,
    required this.matchReason,
    required this.differentiator,
    this.nutritionComparison,
  });

  final FoodProduct product;
  final ProductCompatibility compatibility;
  final String matchReason;
  final String differentiator;
  final ProductNutritionComparison? nutritionComparison;

  factory PersonalizedRecommendation.fromJson(Map<String, dynamic> json) {
    final prodJson = json['product'] as Map<String, dynamic>? ?? {};
    final nutrition = prodJson['nutrition'] as Map<String, dynamic>? ?? {};
    final compJson = json['compatibility'] as Map<String, dynamic>? ?? {};
    final compObj = json['nutritionComparison'] as Map<String, dynamic>?;

    final foodProduct = FoodProduct(
      barcode: prodJson['barcode']?.toString() ?? '',
      name: prodJson['name']?.toString() ?? 'Alternative Product',
      brand: prodJson['brand']?.toString() ?? '',
      imageUrl: prodJson['imageUrl']?.toString() ?? '',
      ingredients: prodJson['ingredients']?.toString() ?? '',
      allergens: (prodJson['allergens'] as List?)?.map((e) => e.toString()).toList() ?? [],
      calories: (nutrition['calories'] as num?)?.toDouble() ?? (prodJson['calories'] as num?)?.toDouble(),
      protein: (nutrition['protein'] as num?)?.toDouble() ?? (prodJson['protein'] as num?)?.toDouble(),
      carbohydrates: (nutrition['carbohydrates'] as num?)?.toDouble() ?? (prodJson['carbohydrates'] as num?)?.toDouble(),
      fat: (nutrition['fat'] as num?)?.toDouble() ?? (prodJson['fat'] as num?)?.toDouble(),
      fiber: (nutrition['fiber'] as num?)?.toDouble() ?? (prodJson['fiber'] as num?)?.toDouble(),
      sugar: (nutrition['sugar'] as num?)?.toDouble() ?? (prodJson['sugar'] as num?)?.toDouble(),
      sodium: (nutrition['sodium'] as num?)?.toDouble() ?? (prodJson['sodium'] as num?)?.toDouble(),
    );

    return PersonalizedRecommendation(
      product: foodProduct,
      compatibility: ProductCompatibility.fromJson(compJson),
      matchReason: json['matchReason']?.toString() ?? '',
      differentiator: json['differentiator']?.toString() ?? '',
      nutritionComparison: compObj != null ? ProductNutritionComparison.fromJson(compObj) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'compatibility': compatibility.toJson(),
        'matchReason': matchReason,
        'differentiator': differentiator,
        'nutritionComparison': nutritionComparison?.toJson(),
      };
}

/// Combined Factual Product Data + AI Intelligence Result
class ProductAiAnalysisResult {
  const ProductAiAnalysisResult({
    required this.product,
    required this.analysis,
    this.compatibility,
    this.recommendations = const [],
    this.recommendationsSummary = '',
  });

  final FoodProduct product;
  final ProductAiAnalysis analysis;
  final ProductCompatibility? compatibility;
  final List<PersonalizedRecommendation> recommendations;
  final String recommendationsSummary;

  factory ProductAiAnalysisResult.fromJson(Map<String, dynamic> json) {
    final factual = json['factualData'] as Map<String, dynamic>? ?? {};
    final ai = json['aiAnalysis'] as Map<String, dynamic>? ?? {};
    final nutrition = factual['nutrition'] as Map<String, dynamic>? ?? {};
    final comp = json['compatibility'] as Map<String, dynamic>?;
    final recsRaw = json['recommendations'] as List?;

    List<PersonalizedRecommendation> recsList = [];
    if (recsRaw != null) {
      recsList = recsRaw
          .whereType<Map<String, dynamic>>()
          .map((e) => PersonalizedRecommendation.fromJson(e))
          .toList();
    }

    final foodProduct = FoodProduct(
      barcode: factual['barcode']?.toString() ?? '',
      name: factual['name']?.toString() ?? 'Scanned Product',
      brand: factual['brand']?.toString() ?? '',
      imageUrl: factual['imageUrl']?.toString() ?? '',
      ingredients: factual['ingredients']?.toString() ?? '',
      allergens: (factual['allergens'] as List?)?.map((e) => e.toString()).toList() ?? [],
      calories: (nutrition['calories'] as num?)?.toDouble(),
      protein: (nutrition['protein'] as num?)?.toDouble(),
      carbohydrates: (nutrition['carbohydrates'] as num?)?.toDouble(),
      fat: (nutrition['fat'] as num?)?.toDouble(),
      fiber: (nutrition['fiber'] as num?)?.toDouble(),
      sugar: (nutrition['sugar'] as num?)?.toDouble(),
      sodium: (nutrition['sodium'] as num?)?.toDouble(),
    );

    return ProductAiAnalysisResult(
      product: foodProduct,
      analysis: ProductAiAnalysis.fromJson(ai),
      compatibility: comp != null ? ProductCompatibility.fromJson(comp) : null,
      recommendations: recsList,
      recommendationsSummary: json['recommendationsSummary']?.toString() ?? '',
    );
  }
}

/// Message model for AI Nutrition Coach chatbot
class AiCoachChatMessage {
  const AiCoachChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  final String text;
  final bool isUser;
  final DateTime timestamp;
}

/// Item representing an individual ingredient classified by intelligence engine
class IngredientCategoryItem {
  const IngredientCategoryItem({
    required this.name,
    required this.category,
    required this.explanation,
    this.badge = '',
  });

  final String name;
  final String category; // e.g. 'Sugar-Related', 'Artificial Sweetener', 'Additive', 'Whole Food'
  final String explanation;
  final String badge;

  factory IngredientCategoryItem.fromJson(Map<String, dynamic> json) {
    return IngredientCategoryItem(
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      badge: json['badge']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'explanation': explanation,
        'badge': badge,
      };
}

/// Complete Ingredient Intelligence analysis result
class IngredientIntelligenceResult {
  const IngredientIntelligenceResult({
    required this.sugarRelatedIngredients,
    required this.artificialSweeteners,
    required this.additives,
    required this.wholeFoodIngredients,
    required this.claimChecks,
    required this.discrepancies,
    required this.summary,
  });

  final List<IngredientCategoryItem> sugarRelatedIngredients;
  final List<IngredientCategoryItem> artificialSweeteners;
  final List<IngredientCategoryItem> additives;
  final List<IngredientCategoryItem> wholeFoodIngredients;
  final List<ClaimVerificationItem> claimChecks;
  final List<String> discrepancies;
  final String summary;

  bool get hasSugarRelated => sugarRelatedIngredients.isNotEmpty;
  bool get hasAdditives => additives.isNotEmpty;
  bool get hasSweeteners => artificialSweeteners.isNotEmpty;
  bool get hasWholeFoods => wholeFoodIngredients.isNotEmpty;
  bool get hasClaimChecks => claimChecks.isNotEmpty;
  bool get hasDiscrepancies => discrepancies.isNotEmpty;
  bool get hasMeaningfulInsights =>
      hasSugarRelated || hasAdditives || hasSweeteners || hasWholeFoods || hasClaimChecks || hasDiscrepancies;

  factory IngredientIntelligenceResult.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(dynamic list, T Function(Map<String, dynamic>) mapper) {
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => mapper(e))
            .toList();
      }
      return [];
    }

    List<String> parseStringList(dynamic list) {
      if (list is List) {
        return list.map((e) => e.toString()).toList();
      }
      return [];
    }

    return IngredientIntelligenceResult(
      sugarRelatedIngredients: parseList(json['sugarRelatedIngredients'], IngredientCategoryItem.fromJson),
      artificialSweeteners: parseList(json['artificialSweeteners'], IngredientCategoryItem.fromJson),
      additives: parseList(json['additives'], IngredientCategoryItem.fromJson),
      wholeFoodIngredients: parseList(json['wholeFoodIngredients'], IngredientCategoryItem.fromJson),
      claimChecks: parseList(json['claimChecks'], ClaimVerificationItem.fromJson),
      discrepancies: parseStringList(json['discrepancies']),
      summary: json['summary']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'sugarRelatedIngredients': sugarRelatedIngredients.map((i) => i.toJson()).toList(),
        'artificialSweeteners': artificialSweeteners.map((i) => i.toJson()).toList(),
        'additives': additives.map((i) => i.toJson()).toList(),
        'wholeFoodIngredients': wholeFoodIngredients.map((i) => i.toJson()).toList(),
        'claimChecks': claimChecks.map((i) => i.toJson()).toList(),
        'discrepancies': discrepancies,
        'summary': summary,
      };
}
