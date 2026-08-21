import 'dart:math' as math;
import '../model/ai_analysis_model.dart';
import '../model/food_product.dart';
import '../model/personalization_profile.dart';
import '../model/user_profile.dart';
import 'food_service.dart';
import 'open_food_facts_service.dart';
import 'personalization_service.dart';
import 'profile_service.dart';

/// Single Source of Truth for Product Compatibility, Nutrition Scoring,
/// Safety Filtering, and Dynamic Recommendations in DietCompass.
class RecommendationService {
  RecommendationService._();
  static final RecommendationService instance = RecommendationService._();

  final FoodService _foodService = FoodService();
  final OpenFoodFactsService _openFoodFactsService = OpenFoodFactsService();

  // =========================================================================
  // 1. SINGLE SOURCE OF TRUTH: COMPATIBILITY CALCULATION
  //
  // Exact deterministic engine aligning with AI Result screen analysis.
  // =========================================================================

  /// Calculates the single unified compatibility score and breakdown for [FoodProduct].
  ProductCompatibility evaluateCompatibility(
    FoodProduct product, {
    PersonalizationProfile? personalization,
    UserProfile? profile,
    String? goalFilter,
  }) {
    final activePersonalization = personalization ??
        PersonalizationService.instance.currentPersonalization;
    final activeProfile = profile ?? ProfileService.instance.currentProfile;

    final ingredientsText = (product.ingredients).toLowerCase();
    final allergensText = product.allergens.join(' ').toLowerCase();
    final combinedText = '$ingredientsText $allergensText';

    final sugarGrams = product.sugar ?? 0.0;
    final rawSodium = product.sodium ?? 0.0;
    // Convert g to mg if needed
    final sodiumMg = rawSodium <= 10.0 ? rawSodium * 1000.0 : rawSodium;
    final proteinGrams = product.protein ?? 0.0;
    final fiberGrams = product.fiber ?? 0.0;
    final calories = product.calories ?? 0.0;
    final fatGrams = product.fat ?? 0.0;
    final carbsGrams = product.carbohydrates ?? 0.0;

    final userDiet = (activePersonalization?.dietType ?? activeProfile?.dietType ?? 'Vegetarian').trim();
    final userAllergies = activePersonalization?.allergies ?? {};
    final userGoals = activePersonalization?.goals ?? {};
    final userConditions = activePersonalization?.healthConditions ?? {};
    final userFocus = activePersonalization?.nutritionFocus ?? {};
    final productAlerts = activePersonalization?.productAlerts ?? {};

    final positiveFactors = <String>[];
    final concerns = <String>[];
    final allergyAlerts = <String>[];
    final dietaryAlerts = <String>[];
    final compatibilityItems = <ProductCompatibilityItem>[];

    int score = 75; // Baseline starting score

    // 1. ALLERGEN CHECKS (Critical Priority)
    const allergenMap = {
      'peanut': ['peanut', 'peanuts', 'arachis', 'groundnut'],
      'peanuts': ['peanut', 'peanuts', 'arachis', 'groundnut'],
      'dairy': ['milk', 'dairy', 'whey', 'casein', 'lactose', 'butter', 'cheese', 'cream', 'curd', 'ghee'],
      'milk': ['milk', 'dairy', 'whey', 'casein', 'lactose', 'butter', 'cheese', 'cream', 'curd', 'ghee'],
      'gluten': ['wheat', 'barley', 'rye', 'gluten', 'spelt', 'semolina', 'maida', 'atta'],
      'wheat': ['wheat', 'flour', 'semolina', 'spelt', 'maida', 'atta'],
      'soy': ['soy', 'soya', 'soybean', 'edamame', 'tofu', 'tempeh'],
      'soya': ['soy', 'soya', 'soybean', 'edamame', 'tofu', 'tempeh'],
      'egg': ['egg', 'eggs', 'albumin', 'ovalbumin', 'egg white', 'egg yolk', 'mayonnaise'],
      'eggs': ['egg', 'eggs', 'albumin', 'ovalbumin', 'egg white', 'egg yolk', 'mayonnaise'],
      'tree nuts': ['almond', 'cashew', 'walnut', 'pecan', 'pistachio', 'hazelnut', 'macadamia', 'brazil nut'],
      'nuts': ['peanut', 'peanuts', 'almond', 'cashew', 'walnut', 'pecan', 'pistachio', 'hazelnut'],
      'fish': ['fish', 'salmon', 'tuna', 'cod', 'anchovy', 'tilapia', 'mackerel'],
      'shellfish': ['shellfish', 'shrimp', 'crab', 'lobster', 'prawn', 'mussel', 'clam', 'oyster'],
      'sesame': ['sesame', 'tahini', 'til'],
      'mustard': ['mustard', 'sarson', 'rai'],
      'celery': ['celery', 'celeriac'],
      'lupin': ['lupin', 'lupine'],
      'sulfites': ['sulfite', 'sulphite', 'sulfur dioxide', 'e220', 'e221', 'e222', 'e223', 'e224', 'e228'],
      'sulphites': ['sulfite', 'sulphite', 'sulfur dioxide', 'e220', 'e221', 'e222', 'e223', 'e224', 'e228'],
    };

    for (final allergen in userAllergies) {
      final lower = allergen.toLowerCase().trim();
      if (lower == 'none of the above' || lower == 'other (specify)' || lower.isEmpty) continue;

      final keywords = allergenMap[lower] ?? [lower];
      final matchFound = keywords.any((kw) => combinedText.contains(kw));

      if (matchFound) {
        allergyAlerts.add('Contains your configured allergen: $allergen');
        concerns.add('High Alert: Ingredient matches documented allergy ($allergen).');
        score -= 50;
      }
    }

    if (allergyAlerts.isNotEmpty) {
      compatibilityItems.add(
        ProductCompatibilityItem(
          label: 'Allergy Safety',
          rating: 'Allergen Alert',
          detail: allergyAlerts.first,
        ),
      );
    } else if (userAllergies.isNotEmpty && !userAllergies.contains('None of the above')) {
      compatibilityItems.add(
        const ProductCompatibilityItem(
          label: 'Allergy Safety',
          rating: 'Safe',
          detail: 'No configured allergens detected in ingredients.',
        ),
      );
    }

    // 2. DIETARY RESTRICTIONS (Major Priority)
    final lowerDiet = userDiet.toLowerCase();
    const animalKeywords = ['beef', 'chicken', 'pork', 'mutton', 'meat', 'gelatin', 'fish', 'poultry', 'lard', 'tallow', 'collagen', 'salmon', 'tuna', 'shrimp', 'prawn'];
    const dairyEggKeywords = ['milk', 'dairy', 'whey', 'casein', 'lactose', 'egg', 'eggs', 'butter', 'honey', 'curd', 'cheese', 'ghee'];

    if (lowerDiet == 'vegan') {
      final hasAnimal = animalKeywords.any((k) => combinedText.contains(k));
      final hasDairyEgg = dairyEggKeywords.any((k) => combinedText.contains(k));
      if (hasAnimal || hasDairyEgg) {
        dietaryAlerts.add('Conflicts with your Vegan diet (contains animal or dairy/egg ingredients)');
        concerns.add('Incompatible with Vegan lifestyle.');
        score -= 40;
        compatibilityItems.add(
          const ProductCompatibilityItem(
            label: 'Vegan Compliance',
            rating: 'Incompatible',
            detail: 'Contains animal derivatives or dairy/egg ingredients.',
          ),
        );
      } else {
        positiveFactors.add('Fully complies with your Vegan diet');
        score += 8;
        compatibilityItems.add(
          const ProductCompatibilityItem(
            label: 'Vegan Compliance',
            rating: 'Excellent',
            detail: 'Plant-based composition compliant with vegan diet.',
          ),
        );
      }
    } else if (lowerDiet == 'vegetarian') {
      final hasAnimal = animalKeywords.any((k) => combinedText.contains(k));
      if (hasAnimal) {
        dietaryAlerts.add('Conflicts with your Vegetarian diet (contains animal derivatives/gelatin/meat)');
        concerns.add('Incompatible with Vegetarian diet.');
        score -= 40;
        compatibilityItems.add(
          const ProductCompatibilityItem(
            label: 'Dietary Preference',
            rating: 'Incompatible',
            detail: 'Contains non-vegetarian ingredients or gelatin.',
          ),
        );
      } else {
        positiveFactors.add('Complies with your Vegetarian diet');
        score += 8;
        compatibilityItems.add(
          const ProductCompatibilityItem(
            label: 'Dietary Preference',
            rating: 'Excellent',
            detail: 'Vegetarian-friendly ingredients.',
          ),
        );
      }
    } else if (lowerDiet == 'eggetarian') {
      final hasAnimal = animalKeywords.any((k) => combinedText.contains(k));
      if (hasAnimal) {
        dietaryAlerts.add('Conflicts with your Eggetarian diet');
        concerns.add('Incompatible with Eggetarian diet.');
        score -= 40;
      } else {
        positiveFactors.add('Complies with your Eggetarian diet');
        score += 8;
      }
    } else if (lowerDiet.contains('gluten-free') || lowerDiet.contains('celiac')) {
      final hasGluten = ['wheat', 'barley', 'rye', 'gluten', 'spelt', 'semolina'].any((k) => combinedText.contains(k));
      if (hasGluten) {
        dietaryAlerts.add('Contains gluten ingredients conflicting with your Gluten-Free diet');
        concerns.add('High risk: contains gluten/wheat.');
        score -= 45;
      } else {
        positiveFactors.add('Gluten-free ingredient composition');
        score += 8;
      }
    } else if (lowerDiet.contains('keto') || lowerDiet.contains('low carb')) {
      if (carbsGrams > 15 || sugarGrams > 4) {
        concerns.add('High carbohydrate/sugar content exceeds Keto limits.');
        score -= 20;
      } else {
        positiveFactors.add('Low net carbohydrate profile suitable for Keto/Low-Carb');
        score += 10;
      }
    }

    // 3. HEALTH CONDITIONS (High Priority)
    for (final condition in userConditions) {
      final lowerCond = condition.toLowerCase();
      if (lowerCond.contains('diabetes') || lowerCond.contains('pre-diabetes') || lowerCond.contains('blood sugar')) {
        if (sugarGrams > 8) {
          concerns.add('Contains elevated sugar that may impact blood glucose.');
          score -= 20;
          compatibilityItems.add(
            ProductCompatibilityItem(
              label: 'Blood Sugar Impact',
              rating: 'Consider',
              detail: '${sugarGrams.toStringAsFixed(1)}g sugar per 100g.',
            ),
          );
        } else if (sugarGrams <= 3 && fiberGrams >= 3) {
          positiveFactors.add('Low sugar and good fiber support steady blood glucose control.');
          score += 10;
          compatibilityItems.add(
            const ProductCompatibilityItem(
              label: 'Blood Sugar Impact',
              rating: 'Excellent',
              detail: 'Low sugar and beneficial fiber support glycemic control.',
            ),
          );
        }
      }
      if (lowerCond.contains('hypertension') || lowerCond.contains('blood pressure') || lowerCond.contains('heart')) {
        if (sodiumMg > 350) {
          concerns.add('Elevated sodium (${sodiumMg.toStringAsFixed(0)}mg/100g) exceeds heart-healthy targets.');
          score -= 18;
          compatibilityItems.add(
            ProductCompatibilityItem(
              label: 'Heart Health',
              rating: 'Consider',
              detail: '${sodiumMg.toStringAsFixed(0)}mg sodium per 100g.',
            ),
          );
        } else if (sodiumMg > 0 && sodiumMg <= 140) {
          positiveFactors.add('Low sodium content supports cardiovascular & blood pressure goals.');
          score += 8;
          compatibilityItems.add(
            const ProductCompatibilityItem(
              label: 'Heart Health',
              rating: 'Excellent',
              detail: 'Low sodium content aligns with cardiovascular guidelines.',
            ),
          );
        }
      }
      if (lowerCond.contains('cholesterol')) {
        if (fatGrams > 15) {
          concerns.add('Higher total fat content may impact lipid management.');
          score -= 12;
        } else if (fiberGrams >= 4) {
          positiveFactors.add('Rich in dietary fiber which aids in cholesterol management.');
          score += 8;
        }
      }
    }

    // 4. USER GOALS & NUTRITION FOCUS
    final combinedGoals = {...userGoals, ...userFocus, if (goalFilter != null) goalFilter}.map((g) => g.toLowerCase()).toSet();

    if (combinedGoals.any((g) => g.contains('weight loss') || g.contains('weight management') || g.contains('calorie'))) {
      if (calories > 350 || sugarGrams > 15) {
        concerns.add('Calorie density or sugar content may slow Weight Loss progress.');
        score -= 12;
      } else if (calories > 0 && calories <= 220 && fiberGrams >= 3) {
        positiveFactors.add('Calorie-conscious with filling fiber directly supporting weight goals.');
        score += 10;
      }
    }

    if (combinedGoals.any((g) => g.contains('muscle') || g.contains('high protein') || g.contains('protein'))) {
      if (proteinGrams >= 10) {
        positiveFactors.add('High protein content (${proteinGrams.toStringAsFixed(1)}g/100g) supports muscle synthesis and recovery.');
        score += 14;
      } else if (proteinGrams > 0 && proteinGrams < 4) {
        concerns.add('Low in protein (${proteinGrams.toStringAsFixed(1)}g), providing minimal support for muscle growth.');
        score -= 8;
      }
    }

    if (combinedGoals.any((g) => g.contains('digestion') || g.contains('gut') || g.contains('fibre') || g.contains('fiber'))) {
      if (fiberGrams >= 4) {
        positiveFactors.add('Excellent dietary fiber (${fiberGrams.toStringAsFixed(1)}g/100g) supports digestive regularity.');
        score += 12;
      } else if (fiberGrams > 0 && fiberGrams < 2) {
        concerns.add('Low dietary fiber content.');
        score -= 6;
      }
    }

    if (combinedGoals.any((g) => g.contains('low sugar') || g.contains('sugar'))) {
      if (sugarGrams <= 3 && product.sugar != null) {
        positiveFactors.add('Low sugar formulation (${sugarGrams.toStringAsFixed(1)}g/100g).');
        score += 10;
      } else if (sugarGrams > 12) {
        concerns.add('High sugar content (${sugarGrams.toStringAsFixed(1)}g/100g) conflicting with low sugar target.');
        score -= 15;
      }
    }

    // 5. PRODUCT ALERTS
    if (productAlerts['Warn me about high sugar products'] == true && sugarGrams > 12) {
      concerns.add('High sugar alert triggered (${sugarGrams.toStringAsFixed(1)}g sugar per 100g).');
      score -= 6;
    }
    if (productAlerts['Warn me about high sodium'] == true && sodiumMg > 400) {
      concerns.add('High sodium alert triggered (${sodiumMg.toStringAsFixed(0)}mg sodium per 100g).');
      score -= 6;
    }
    if (productAlerts['Warn me about ultra-processed foods'] == true && product.novaGroup == 4) {
      concerns.add('Ultra-processed formulation alert triggered.');
      score -= 6;
    }

    // 6. MISSING DATA CONFIDENCE FACTOR
    final completeness = _calculateDataCompleteness(product);
    if (completeness < 0.6) {
      score = (score * (0.75 + (completeness * 0.25))).round();
    }

    // 7. HARD CAPS & BOUNDS
    if (allergyAlerts.isNotEmpty) {
      score = score.clamp(5, 25);
    } else if (dietaryAlerts.isNotEmpty) {
      score = score.clamp(5, 35);
    } else {
      score = score.clamp(10, 99);
    }

    // 8. STATUS & RECOMMENDATION
    String status = 'Good Match';
    String recommendation = 'Suitable for your regular diet.';
    bool isSuitable = true;

    if (allergyAlerts.isNotEmpty) {
      status = 'Incompatible / Allergy Risk';
      recommendation = 'Avoid this product due to direct allergen conflict with your profile.';
      isSuitable = false;
    } else if (dietaryAlerts.isNotEmpty) {
      status = 'Incompatible / Dietary Conflict';
      recommendation = 'Does not align with your selected dietary lifestyle ($userDiet).';
      isSuitable = false;
    } else if (score >= 80) {
      status = 'Excellent Match';
      recommendation = 'Strongly recommended. Aligns with your nutrition goals and dietary preferences.';
    } else if (score >= 60) {
      status = 'Good Match';
      recommendation = 'Balanced option suitable for regular consumption.';
    } else {
      status = 'Review Compatibility';
      recommendation = 'Consider portion size or explore healthier alternatives.';
    }

    // Default item factors if empty
    if (compatibilityItems.isEmpty) {
      compatibilityItems.add(
        ProductCompatibilityItem(
          label: 'Overall Alignment',
          rating: score >= 75 ? 'Good' : 'Consider',
          detail: '$score% personalized compatibility score.',
        ),
      );
    }

    final summary = isSuitable
        ? (positiveFactors.isNotEmpty
            ? positiveFactors.take(2).join('. ')
            : 'Product analyzed against your profile with a $score% match.')
        : (concerns.isNotEmpty ? concerns.first : 'Conflicts detected with your profile.');

    return ProductCompatibility(
      score: score,
      status: status,
      isSuitable: isSuitable,
      allergyAlerts: allergyAlerts,
      dietaryAlerts: dietaryAlerts,
      positiveFactors: positiveFactors.isNotEmpty ? positiveFactors : ['Nutrition analyzed'],
      concerns: concerns,
      summary: summary,
      recommendation: recommendation,
      items: compatibilityItems,
    );
  }

  /// Calculates the single compatibility score percentage (e.g. 52).
  int calculateCompatibilityScore(
    FoodProduct product, {
    PersonalizationProfile? personalization,
    UserProfile? profile,
    String? goalFilter,
  }) {
    return evaluateCompatibility(
      product,
      personalization: personalization,
      profile: profile,
      goalFilter: goalFilter,
    ).score;
  }

  // =========================================================================
  // 2. SEPARATE GENERAL NUTRITION SCORE (e.g. 45/100 or 89/100)
  // =========================================================================

  /// Calculates General Product Nutrition Score (distinct from Personal Compatibility).
  int calculateNutritionScore(FoodProduct product) {
    final protein = product.protein ?? 0.0;
    final fiber = product.fiber ?? 0.0;
    final sugar = product.sugar ?? 0.0;
    final fat = product.fat ?? 0.0;
    final sodium = product.sodium ?? 0.0;
    final sodiumMg = sodium <= 10.0 ? sodium * 1000.0 : sodium;

    int score = 50;
    if (protein > 5) score += 10;
    if (fiber > 3) score += 10;
    if (sugar > 12) score -= 10;
    if (fat > 20) score -= 5;
    if (sodiumMg > 600 || sodium > 0.6) score -= 5;

    return score.clamp(0, 100);
  }

  // =========================================================================
  // 3. SAFETY FILTERING & RANKING
  // =========================================================================

  /// Excludes any product violating allergens or dietary restrictions.
  List<FoodProduct> filterCompatibleProducts(
    List<FoodProduct> products, {
    PersonalizationProfile? personalization,
    UserProfile? profile,
  }) {
    final activePersonalization = personalization ??
        PersonalizationService.instance.currentPersonalization;
    final activeProfile = profile ?? ProfileService.instance.currentProfile;

    return products.where((p) {
      if (p.name.trim().isEmpty || p.name.trim().toLowerCase() == 'unknown product') {
        return false;
      }
      final comp = evaluateCompatibility(p, personalization: activePersonalization, profile: activeProfile);
      return comp.isSuitable && comp.allergyAlerts.isEmpty && comp.dietaryAlerts.isEmpty;
    }).toList();
  }

  /// Ranks products strictly by their single compatibility score descending.
  List<FoodProduct> rankProducts(
    List<FoodProduct> products, {
    PersonalizationProfile? personalization,
    UserProfile? profile,
    String? goalFilter,
    bool strictFilter = true,
  }) {
    final candidates = strictFilter
        ? filterCompatibleProducts(products, personalization: personalization, profile: profile)
        : products;

    final scored = candidates.map((p) {
      final comp = evaluateCompatibility(
        p,
        personalization: personalization,
        profile: profile,
        goalFilter: goalFilter,
      );
      return MapEntry(p, comp.score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }

  // =========================================================================
  // 4. DYNAMIC RECOMMENDATIONS & SEARCH
  // =========================================================================

  Future<List<FoodProduct>> getRecommendedProducts({
    PersonalizationProfile? personalization,
    UserProfile? profile,
    String? categoryOrGoal,
  }) async {
    final activePersonalization = personalization ??
        PersonalizationService.instance.currentPersonalization;
    final activeProfile = profile ?? ProfileService.instance.currentProfile;

    final userGoals = activePersonalization?.goals ?? {};
    final userDiet = activePersonalization?.dietType ?? activeProfile?.dietType ?? 'Vegetarian';

    final searchTerms = _determineSearchKeywords(
      categoryOrGoal: categoryOrGoal,
      goals: userGoals,
      dietType: userDiet,
    );

    final rawResults = <FoodProduct>[];

    final fetchFutures = searchTerms.map((term) async {
      try {
        return await _openFoodFactsService.getProductsByName(term, pageSize: 12);
      } catch (_) {
        return <FoodProduct>[];
      }
    });

    final batchResults = await Future.wait(fetchFutures);
    for (final batch in batchResults) {
      rawResults.addAll(batch);
    }

    if (rawResults.length < 5 && searchTerms.isNotEmpty) {
      try {
        final fallback = await _foodService.getFoodsByName(searchTerms.first);
        rawResults.addAll(fallback);
      } catch (_) {}
    }

    final unique = _removeDuplicates(rawResults);

    return rankProducts(
      unique,
      personalization: activePersonalization,
      profile: activeProfile,
      goalFilter: categoryOrGoal,
      strictFilter: true,
    );
  }

  Future<List<FoodProduct>> searchProducts(
    String query, {
    PersonalizationProfile? personalization,
    UserProfile? profile,
  }) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];

    final activePersonalization = personalization ??
        PersonalizationService.instance.currentPersonalization;
    final activeProfile = profile ?? ProfileService.instance.currentProfile;

    final results = await _foodService.getFoodsByName(clean);
    if (results.isEmpty) {
      final directOff = await _openFoodFactsService.getProductsByName(clean, pageSize: 25);
      results.addAll(directOff);
    }

    final unique = _removeDuplicates(results);

    return rankProducts(
      unique,
      personalization: activePersonalization,
      profile: activeProfile,
      strictFilter: false,
    );
  }

  // =========================================================================
  // 5. SMART PANTRY ADVICE
  // =========================================================================

  SmartPantryAdviceResult calculateSmartPantryAdvice(List<FoodProduct> pantryItems) {
    if (pantryItems.isEmpty) {
      return const SmartPantryAdviceResult(
        highSugarCount: 0,
        highSodiumCount: 0,
        ultraProcessedCount: 0,
        adviceMessage: 'Add items to your pantry to receive personalized smart pantry advice.',
      );
    }

    int highSugarCount = 0;
    int highSodiumCount = 0;
    int ultraProcessedCount = 0;

    for (final p in pantryItems) {
      if ((p.sugar ?? 0) > 15.0) highSugarCount++;
      if ((p.sodium ?? 0) > 0.6 || (p.sodium ?? 0) > 600) highSodiumCount++;
      if (p.novaGroup == 4) ultraProcessedCount++;
    }

    String adviceMessage;
    if (highSugarCount > 0) {
      adviceMessage = 'Your pantry has $highSugarCount high-sugar item${highSugarCount > 1 ? 's' : ''}. Want healthier alternatives?';
    } else if (highSodiumCount > 0) {
      adviceMessage = 'Your pantry has $highSodiumCount high-sodium item${highSodiumCount > 1 ? 's' : ''}. Consider low-sodium options.';
    } else if (ultraProcessedCount > 0) {
      adviceMessage = 'Your pantry contains $ultraProcessedCount ultra-processed item${ultraProcessedCount > 1 ? 's' : ''}. Try whole-food substitutes.';
    } else {
      adviceMessage = 'Great job! Your pantry items align well with healthy nutrition goals.';
    }

    return SmartPantryAdviceResult(
      highSugarCount: highSugarCount,
      highSodiumCount: highSodiumCount,
      ultraProcessedCount: ultraProcessedCount,
      adviceMessage: adviceMessage,
    );
  }

  // =========================================================================
  // 6. DYNAMIC HIGHLIGHTS, TAGS & EXPLANATIONS
  // =========================================================================

  List<String> generateHighlights(FoodProduct product) {
    final highlights = <String>[];
    if ((product.fiber ?? 0) >= 4) {
      highlights.add('High in Fiber');
    } else if ((product.fiber ?? 0) >= 2) {
      highlights.add('Source of Fiber');
    }

    if ((product.protein ?? 0) >= 10) {
      highlights.add('High Protein');
    } else if ((product.protein ?? 0) >= 5) {
      highlights.add('Good Protein');
    }

    if (product.sugar != null && product.sugar! <= 3) {
      highlights.add('Low Sugar');
    }

    if (product.sodium != null && product.sodium! <= 0.14) {
      highlights.add('Low Sodium');
    }

    if (product.novaGroup == 1) {
      highlights.add('Minimally Processed');
    }

    if (highlights.isEmpty) {
      highlights.add('Nutrition Analyzed');
    }

    return highlights.take(3).toList();
  }

  List<String> generateTags(FoodProduct product, ProductCompatibility comp, String dietType) {
    final tags = <String>[];
    if ((product.fiber ?? 0) >= 3) tags.add('High Fiber');
    if ((product.sugar ?? 0) <= 5 && product.sugar != null) tags.add('Low Sugar');
    if ((product.protein ?? 0) >= 7) tags.add('High Protein');
    if (product.novaGroup == 1 || product.novaGroup == 2) tags.add('Natural');

    if (dietType.toLowerCase() == 'vegan' && comp.isSuitable) {
      tags.add('Vegan Safe');
    } else if (dietType.toLowerCase() == 'vegetarian' && comp.isSuitable) {
      tags.add('Vegetarian');
    }

    if (tags.length < 2) {
      if (comp.score >= 80) tags.add('Top Match');
      tags.add('Heart Friendly');
    }

    return tags.toSet().take(3).toList();
  }

  // =========================================================================
  // 7. HELPER METHODS
  // =========================================================================

  double _calculateDataCompleteness(FoodProduct product) {
    int total = 6;
    int filled = 0;
    if (product.calories != null) filled++;
    if (product.protein != null) filled++;
    if (product.fiber != null) filled++;
    if (product.sugar != null) filled++;
    if (product.fat != null) filled++;
    if (product.sodium != null) filled++;
    return filled / total;
  }

  List<String> _determineSearchKeywords({
    String? categoryOrGoal,
    required Set<String> goals,
    required String dietType,
  }) {
    final filter = (categoryOrGoal ?? '').toLowerCase().trim();

    if (filter == 'high_protein' || filter.contains('protein')) {
      return ['protein bar', 'greek yogurt', 'paneer', 'lentils', 'almonds', 'chickpeas', 'edamame'];
    }
    if (filter == 'low_sugar' || filter.contains('sugar')) {
      return ['rolled oats', 'almond milk', 'peanut butter unsweetened', 'green tea', 'chia seeds', 'plain curd'];
    }
    if (filter == 'immunity' || filter.contains('immunity')) {
      return ['green tea', 'turmeric', 'amla', 'almonds', 'honey', 'chia seeds'];
    }
    if (filter == 'gluten_free' || filter.contains('gluten')) {
      return ['gluten free oats', 'quinoa', 'almond flour', 'rice cakes', 'millet'];
    }
    if (filter == 'dairy') {
      return ['milk', 'curd', 'yogurt', 'cheese', 'paneer', 'butter'];
    }
    if (filter == 'breakfast') {
      return ['oats', 'muesli', 'granola', 'cereal', 'whole wheat bread'];
    }
    if (filter == 'snacks') {
      return ['roasted nuts', 'protein bar', 'almonds', 'peanuts', 'rice cakes', 'crackers'];
    }
    if (filter == 'beverages') {
      return ['green tea', 'almond milk', 'coconut water', 'oat milk', 'black coffee'];
    }
    if (filter == 'cooking') {
      return ['olive oil', 'quinoa', 'brown rice', 'lentils', 'rolled oats'];
    }

    final candidates = <String>[];
    for (final g in goals) {
      final gl = g.toLowerCase();
      if (gl.contains('protein')) candidates.addAll(['protein snack', 'lentils', 'roasted chickpeas']);
      if (gl.contains('sugar')) candidates.addAll(['rolled oats', 'unsweetened peanut butter']);
      if (gl.contains('fibre') || gl.contains('fiber')) candidates.addAll(['chia seeds', 'muesli', 'rolled oats']);
      if (gl.contains('weight')) candidates.addAll(['rolled oats', 'green tea', 'quinoa']);
    }

    if (candidates.isEmpty) {
      if (dietType.toLowerCase() == 'vegan') {
        return ['almond milk', 'rolled oats', 'chia seeds', 'quinoa', 'tofu'];
      }
      return ['rolled oats', 'muesli', 'green tea', 'almonds', 'greek yogurt'];
    }

    return candidates.toSet().toList();
  }

  List<FoodProduct> _removeDuplicates(List<FoodProduct> products) {
    final seen = <String>{};
    final unique = <FoodProduct>[];

    for (final product in products) {
      final key = product.barcode.trim().isNotEmpty
          ? 'barcode:${product.barcode.trim()}'
          : 'name:${product.name.toLowerCase().trim()}|brand:${product.brand.toLowerCase().trim()}';

      if (seen.add(key)) {
        unique.add(product);
      }
    }
    return unique;
  }
}

/// Smart Pantry Advice calculation result
class SmartPantryAdviceResult {
  final int highSugarCount;
  final int highSodiumCount;
  final int ultraProcessedCount;
  final String adviceMessage;

  const SmartPantryAdviceResult({
    required this.highSugarCount,
    required this.highSodiumCount,
    required this.ultraProcessedCount,
    required this.adviceMessage,
  });
}
