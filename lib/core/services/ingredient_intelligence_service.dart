import '../model/ai_analysis_model.dart';
import '../model/food_product.dart';

/// Single Source of Truth for Ingredient Intelligence, Disguised / Alternate Sugar Detection,
/// Additive Classification, and Objective Claim Verification in DietCompass.
class IngredientIntelligenceService {
  IngredientIntelligenceService._();
  static final IngredientIntelligenceService instance = IngredientIntelligenceService._();

  // Known sugar-related ingredients & alternate names
  static const Map<String, String> _sugarIngredientsMap = {
    'glucose syrup': 'A liquid sweetener derived from starch that contributes fast-absorbing carbohydrates.',
    'glucose': 'A simple monosaccharide sugar rapidly utilized for cellular energy.',
    'dextrose': 'A simple form of glucose quickly absorbed into the bloodstream.',
    'maltodextrin': 'A complex carbohydrate derived from starch with a high glycemic index that contributes to energy content.',
    'high fructose corn syrup': 'A liquid sweetener made from corn starch composed of glucose and fructose.',
    'corn syrup solids': 'Dehydrated corn syrup contributing concentrated carbohydrate content.',
    'corn syrup': 'A liquid corn-derived sweetener providing carbohydrates.',
    'invert sugar': 'A mixture of glucose and fructose produced by splitting sucrose.',
    'evaporated cane juice': 'A cane-derived sweetener that contributes sugar and calories.',
    'cane sugar': 'Sugar extracted from sugarcane contributing sucrose.',
    'sucrose': 'Standard disaccharide sugar composed of equal parts glucose and fructose.',
    'fructose': 'A simple fruit sugar naturally found in fruit and honey, contributing sweetness and carbohydrate content.',
    'maltose': 'A malt sugar disaccharide consisting of two glucose units.',
    'fruit juice concentrate': 'Concentrated fruit extract providing fruit sugars and natural sweetness.',
    'barley malt': 'A maltose-rich sweetener produced from sprouted barley grains.',
    'rice syrup': 'A sweetener produced by culturing cooked rice with enzymes, rich in glucose.',
    'agave nectar': 'A plant-derived sweetener rich in fructose.',
    'maple syrup': 'A natural sweetener tapped from maple trees containing sucrose and water.',
    'coconut sugar': 'Sugar derived from the sap of flower buds of the coconut palm tree.',
    'date syrup': 'A concentrated syrup prepared from dates containing natural fructose and glucose.',
    'honey': 'A natural sweetener produced by bees containing fructose, glucose, and trace minerals.',
    'molasses': 'A viscous byproduct of refining sugarcane or sugar beets.',
    'sorghum syrup': 'A natural syrup extracted from the crushed stalks of sorghum plants.',
    'isoglucose': 'An alternative regional term for high-fructose glucose syrup.',
    'caramel': 'Heated carbohydrate sweetener used for coloring and sweet flavor.',
    'brown sugar': 'Sucrose sugar product with a distinctive brown color due to the presence of molasses.',
    'raw sugar': 'Minimally processed cane sugar containing residual molasses.',
    'palm sugar': 'A traditional sweetener made from the sap of various palm trees.',
    'demerara': 'A type of unrefined cane sugar with large grains and a pale to golden color.',
    'muscovado': 'An unrefined cane sugar with strong molasses content and dark color.',
    'syrup': 'A concentrated sweet liquid providing carbohydrates.',
    'sugar': 'Standard table sugar providing carbohydrate calories.',
  };

  // Known non-nutritive / low-calorie sweeteners
  static const Map<String, String> _sweetenersMap = {
    'aspartame': 'A low-calorie artificial sweetener approximately 200 times sweeter than sucrose.',
    'sucralose': 'A zero-calorie artificial sweetener made from sucrose through chlorination.',
    'acesulfame potassium': 'A calorie-free sugar substitute frequently blended with other sweeteners.',
    'acesulfame k': 'A calorie-free sweetener often paired with sucralose for balanced sweetness.',
    'saccharin': 'One of the earliest artificial sweeteners providing intense zero-calorie sweetness.',
    'stevia': 'A natural plant-based zero-calorie sweetener extracted from Stevia rebaudiana leaves.',
    'steviol glycosides': 'Purified sweet compounds extracted from the leaves of the stevia plant.',
    'monk fruit': 'A natural zero-calorie sweetener derived from the Siraitia grosvenorii fruit.',
    'erythritol': 'A sugar alcohol that provides sweetness with virtually zero calories and minimal glycemic effect.',
    'xylitol': 'A sugar alcohol commonly used in dental-friendly and reduced-calorie foods.',
    'maltitol': 'A sugar alcohol derived from maltose with roughly 70% the sweetness of sugar.',
    'sorbitol': 'A slowly metabolized sugar alcohol used as a bulk sweetener and humectant.',
    'isomalt': 'A sugar replacer made from beet sugar providing bulk with fewer calories.',
  };

  // Known food additives & preservatives
  static const Map<String, Map<String, String>> _additivesMap = {
    'bha': {
      'name': 'Butylated Hydroxyanisole (BHA)',
      'concern': 'Synthetic antioxidant used to prevent rancidity in fats and oils.',
    },
    'bht': {
      'name': 'Butylated Hydroxytoluene (BHT)',
      'concern': 'Synthetic phenolic antioxidant used to maintain food freshness.',
    },
    'potassium bromate': {
      'name': 'Potassium Bromate',
      'concern': 'Flour treatment agent used in bread baking.',
    },
    'titanium dioxide': {
      'name': 'Titanium Dioxide (E171)',
      'concern': 'Mineral food colorant used for whitening and opacity.',
    },
    'msg': {
      'name': 'Monosodium Glutamate (MSG)',
      'concern': 'Savory flavor enhancer (umami) derived from glutamic acid.',
    },
    'monosodium glutamate': {
      'name': 'Monosodium Glutamate',
      'concern': 'Savory flavor enhancer that stimulates umami taste receptors.',
    },
    'sodium nitrite': {
      'name': 'Sodium Nitrite',
      'concern': 'Preservative and color fixative commonly used in cured meats.',
    },
    'sodium nitrate': {
      'name': 'Sodium Nitrate',
      'concern': 'Curing agent and preservative used in processed foods.',
    },
    'red 40': {
      'name': 'Allura Red AC (Red 40)',
      'concern': 'Synthetic red food dye widely used in beverages and snacks.',
    },
    'yellow 5': {
      'name': 'Tartrazine (Yellow 5)',
      'concern': 'Synthetic lemon-yellow azo food dye.',
    },
    'tartrazine': {
      'name': 'Tartrazine (Yellow 5)',
      'concern': 'Synthetic yellow food coloring used in confectionery and drinks.',
    },
    'yellow 6': {
      'name': 'Sunset Yellow FCF (Yellow 6)',
      'concern': 'Synthetic orange food dye used in processed snacks and cereals.',
    },
    'sunset yellow': {
      'name': 'Sunset Yellow (Yellow 6)',
      'concern': 'Synthetic food dye providing orange-yellow coloration.',
    },
    'carrageenan': {
      'name': 'Carrageenan (E407)',
      'concern': 'Plant-derived polysaccharide thickener and stabilizer extracted from red seaweed.',
    },
    'sodium benzoate': {
      'name': 'Sodium Benzoate',
      'concern': 'Common antimicrobial preservative used in acidic foods and carbonated drinks.',
    },
    'potassium sorbate': {
      'name': 'Potassium Sorbate',
      'concern': 'Preservative widely used to inhibit mold and yeast growth in cheese, yogurt, and baked goods.',
    },
    'tbhq': {
      'name': 'Tertiary Butylhydroquinone (TBHQ)',
      'concern': 'Synthetic antioxidant preservative used to extend the shelf life of unsaturated vegetable oils.',
    },
  };

  // Whole foods & wholesome ingredients
  static const Map<String, String> _wholeFoodsMap = {
    'rolled oats': 'Whole grain oats rich in beta-glucan soluble dietary fiber.',
    'whole grain oats': 'Unrefined whole grain providing steady complex energy and fiber.',
    'oats': 'Nutrient-rich whole cereal grain containing proteins and soluble fiber.',
    'almonds': 'Nutrient-dense tree nuts rich in vitamin E, healthy fats, and magnesium.',
    'chia seeds': 'Plant seeds packed with omega-3 fatty acids, fiber, and protein.',
    'flax seeds': 'Plant seeds high in alpha-linolenic acid (omega-3) and lignans.',
    'lentils': 'Protein- and iron-rich legumes supporting steady energy and satiety.',
    'chickpeas': 'Fiber- and protein-rich legumes beneficial for metabolic health.',
    'quinoa': 'Complete plant protein containing all nine essential amino acids.',
    'olive oil': 'Monounsaturated fat source containing heart-healthy antioxidants.',
    'curd': 'Cultured dairy food providing beneficial probiotic cultures and calcium.',
    'yogurt': 'Fermented dairy food supporting gut microbiome health and protein intake.',
  };

  /// Analyzes product ingredients, classifies ingredient categories, checks claims, and produces objective insights.
  IngredientIntelligenceResult analyze(FoodProduct product) {
    final ingredientsText = product.ingredients.toLowerCase();
    final detectedSugars = <IngredientCategoryItem>[];
    final detectedSweeteners = <IngredientCategoryItem>[];
    final detectedAdditives = <IngredientCategoryItem>[];
    final detectedWholeFoods = <IngredientCategoryItem>[];

    final seenNames = <String>{};

    if (ingredientsText.isNotEmpty) {
      // 1. Scan for sugar-related ingredients
      _sugarIngredientsMap.forEach((key, explanation) {
        if (_containsIngredient(ingredientsText, key)) {
          final formattedName = _formatName(key);
          if (seenNames.add(formattedName.toLowerCase())) {
            detectedSugars.add(
              IngredientCategoryItem(
                name: formattedName,
                category: 'Sugar-Related',
                explanation: explanation,
                badge: 'Sweetening Component',
              ),
            );
          }
        }
      });

      // 2. Scan for artificial / non-nutritive sweeteners
      _sweetenersMap.forEach((key, explanation) {
        if (_containsIngredient(ingredientsText, key)) {
          final formattedName = _formatName(key);
          if (seenNames.add(formattedName.toLowerCase())) {
            detectedSweeteners.add(
              IngredientCategoryItem(
                name: formattedName,
                category: 'Sugar Substitute',
                explanation: explanation,
                badge: 'Low-Calorie Sweetener',
              ),
            );
          }
        }
      });

      // 3. Scan for additives
      _additivesMap.forEach((key, data) {
        if (_containsIngredient(ingredientsText, key)) {
          final fullName = data['name'] ?? key;
          if (seenNames.add(fullName.toLowerCase())) {
            detectedAdditives.add(
              IngredientCategoryItem(
                name: fullName,
                category: 'Food Additive',
                explanation: data['concern'] ?? 'Functional food additive.',
                badge: 'Additive',
              ),
            );
          }
        }
      });

      // 4. Scan for whole food ingredients
      _wholeFoodsMap.forEach((key, explanation) {
        if (_containsIngredient(ingredientsText, key)) {
          final formattedName = _formatName(key);
          if (seenNames.add(formattedName.toLowerCase())) {
            detectedWholeFoods.add(
              IngredientCategoryItem(
                name: formattedName,
                category: 'Whole Food',
                explanation: explanation,
                badge: 'Wholesome',
              ),
            );
          }
        }
      });
    }

    // 5. Perform Claim Checks
    final claimChecks = _evaluateClaims(
      product,
      detectedSugars: detectedSugars,
      detectedSweeteners: detectedSweeteners,
      detectedAdditives: detectedAdditives,
    );

    // 6. Summary generation (educational, objective, non-accusatory)
    String summary = '';
    if (detectedSugars.isNotEmpty) {
      final names = detectedSugars.take(3).map((e) => e.name).join(', ');
      summary = 'Sugar-related ingredients identified in the ingredient list: $names. These ingredients contribute to the total carbohydrate and sugar content.';
    } else if (detectedWholeFoods.isNotEmpty) {
      summary = 'Contains wholesome primary ingredients including ${detectedWholeFoods.map((e) => e.name).take(3).join(', ')}.';
    } else if (ingredientsText.isNotEmpty) {
      summary = 'Standard ingredient formulation with no high-concern synthetic additives detected.';
    } else {
      summary = 'Ingredient details unavailable for this product.';
    }

    return IngredientIntelligenceResult(
      sugarRelatedIngredients: detectedSugars,
      artificialSweeteners: detectedSweeteners,
      additives: detectedAdditives,
      wholeFoodIngredients: detectedWholeFoods,
      claimChecks: claimChecks,
      discrepancies: product.discrepancies,
      summary: summary,
    );
  }

  /// Evaluates front-of-package claims against factual nutrition and detected ingredients objectively.
  List<ClaimVerificationItem> _evaluateClaims(
    FoodProduct product, {
    required List<IngredientCategoryItem> detectedSugars,
    required List<IngredientCategoryItem> detectedSweeteners,
    required List<IngredientCategoryItem> detectedAdditives,
  }) {
    final claims = product.claims;
    final results = <ClaimVerificationItem>[];

    final unitLabel = product.isLiquid ? '100ml' : '100g';
    final sugarGrams = product.sugar;
    final proteinGrams = product.protein;
    final sodiumVal = product.sodium;
    final sodiumMg = sodiumVal != null ? (sodiumVal <= 10.0 ? sodiumVal * 1000.0 : sodiumVal) : null;
    final fiberGrams = product.fiber;

    for (final claim in claims) {
      final cl = claim.toLowerCase().trim();

      // Low Sugar / No Sugar claims
      if (cl.contains('zero sugar') || cl.contains('no sugar') || cl.contains('sugar free') || cl.contains('0% sugar') || cl.contains('no added sugar')) {
        if (detectedSugars.isNotEmpty || (sugarGrams != null && sugarGrams > 1.0)) {
          results.add(
            ClaimVerificationItem(
              claim: claim,
              status: 'Review Recommended',
              explanation: 'The product contains sugar-related ingredients (${detectedSugars.map((s) => s.name).take(2).join(', ')}) or measurable sugars (${sugarGrams?.toStringAsFixed(1) ?? 'present'}g). Check serving size and nutrition label before relying on the claim.',
            ),
          );
        } else {
          results.add(
            ClaimVerificationItem(
              claim: claim,
              status: 'Verified',
              explanation: 'Verified compliant with sugar-free/no-added-sugar criteria based on available data.',
            ),
          );
        }
      } else if (cl.contains('low sugar')) {
        if (sugarGrams != null && sugarGrams > 5.0) {
          results.add(
            ClaimVerificationItem(
              claim: claim,
              status: 'Review Recommended',
              explanation: 'Contains ${sugarGrams.toStringAsFixed(1)}g sugar per $unitLabel. Standard low-sugar guidelines recommend 5g or less per $unitLabel.',
            ),
          );
        } else if (detectedSugars.length > 1) {
          results.add(
            ClaimVerificationItem(
              claim: claim,
              status: 'Review Recommended',
              explanation: 'Multiple sugar-related ingredients detected. Check nutrition facts for exact sugar contribution per serving.',
            ),
          );
        } else {
          results.add(
            ClaimVerificationItem(
              claim: claim,
              status: 'Verified',
              explanation: 'Meets standard criteria for lower sugar content per $unitLabel.',
            ),
          );
        }
      } else if (cl.contains('high protein') || cl.contains('protein rich')) {
        if (proteinGrams != null && proteinGrams < 6.0) {
          results.add(
            ClaimVerificationItem(
              claim: claim,
              status: 'Review Recommended',
              explanation: 'Contains ${proteinGrams.toStringAsFixed(1)}g protein per $unitLabel. Standard high-protein benchmark is at least 10–15g per $unitLabel.',
            ),
          );
        } else if (proteinGrams != null && proteinGrams >= 10.0) {
          results.add(
            ClaimVerificationItem(
              claim: claim,
              status: 'Verified',
              explanation: 'Provides ${proteinGrams.toStringAsFixed(1)}g protein per $unitLabel, supporting high-protein dietary targets.',
            ),
          );
        }
      } else if (cl.contains('low sodium') || cl.contains('low salt')) {
        if (sodiumMg != null && sodiumMg > 140.0) {
          results.add(
            ClaimVerificationItem(
              claim: claim,
              status: 'Review Recommended',
              explanation: 'Contains ${sodiumMg.toStringAsFixed(0)}mg sodium per $unitLabel, exceeding the low-sodium threshold of 140mg.',
            ),
          );
        } else if (sodiumMg != null) {
          results.add(
            ClaimVerificationItem(
              claim: claim,
              status: 'Verified',
              explanation: 'Meets low-sodium criteria with ${sodiumMg.toStringAsFixed(0)}mg sodium per $unitLabel.',
            ),
          );
        }
      } else if (cl.contains('high fiber') || cl.contains('high fibre')) {
        if (fiberGrams != null && fiberGrams < 3.0) {
          results.add(
            ClaimVerificationItem(
              claim: claim,
              status: 'Review Recommended',
              explanation: 'Contains ${fiberGrams.toStringAsFixed(1)}g fiber per $unitLabel. High-fiber threshold is typically at least 5–6g per $unitLabel.',
            ),
          );
        } else if (fiberGrams != null && fiberGrams >= 5.0) {
          results.add(
            ClaimVerificationItem(
              claim: claim,
              status: 'Verified',
              explanation: 'Provides rich dietary fiber (${fiberGrams.toStringAsFixed(1)}g/$unitLabel).',
            ),
          );
        }
      } else if (cl.contains('natural') || cl.contains('100% natural')) {
        if (detectedAdditives.isNotEmpty) {
          results.add(
            ClaimVerificationItem(
              claim: claim,
              status: 'Review Recommended',
              explanation: 'Contains formulated food additives (${detectedAdditives.map((a) => a.name).take(2).join(', ')}). Review ingredient list.',
            ),
          );
        } else {
          results.add(
            ClaimVerificationItem(
              claim: claim,
              status: 'Verified',
              explanation: 'No synthetic or ultra-processed additives detected in the ingredient statement.',
            ),
          );
        }
      }
    }

    return results;
  }

  static bool _containsIngredient(String text, String key) {
    // Exact word boundary matching where possible
    final escaped = RegExp.escape(key);
    final regExp = RegExp('(^|[^a-zA-Z0-9])$escaped([^a-zA-Z0-9]|\$)', caseSensitive: false);
    return regExp.hasMatch(text);
  }

  static String _formatName(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
