import '../model/food_product.dart';
import '../model/personalization_profile.dart';
import '../model/user_profile.dart';
import '../services/personalization_service.dart';
import '../services/profile_service.dart';
import '../../features/recipe_generator/recipe_detail_screen.dart';
import '../../features/recipe_generator/recipe_generator_screen.dart';

/// Validation result detailing whether a recipe or food product is safe and compatible.
class DietaryValidationResult {
  const DietaryValidationResult({
    required this.isCompatible,
    this.rejectionReason,
    this.matchedViolations = const [],
  });

  final bool isCompatible;
  final String? rejectionReason;
  final List<String> matchedViolations;

  static const valid = DietaryValidationResult(isCompatible: true);
}

/// DietCompass — Dietary & Allergy Safety Validator
///
/// Enforces HARD dietary preference and allergy constraints.
/// Zero tolerance for non-compatible recipes or food products.
class DietarySafetyValidator {
  DietarySafetyValidator._();
  static final DietarySafetyValidator instance = DietarySafetyValidator._();

  // Meat & animal flesh keywords (prohibited for Vegetarian & Vegan)
  static final List<RegExp> _meatPatterns = [
    RegExp(r'\b(beef|steak|brisket|veal|ground beef|roast beef|ribeye|sirloin|tenderloin|corned beef)\b', caseSensitive: false),
    RegExp(r'\b(pork|bacon|ham|prosciutto|pancetta|pork belly|pork chop|lard|pepperoni|salami|chorizo)\b', caseSensitive: false),
    RegExp(r'\b(chicken|poultry|chicken breast|chicken thigh|chicken wing|turkey|duck|goose|quail)\b', caseSensitive: false),
    RegExp(r'\b(lamb|mutton|goat meat|goat)\b', caseSensitive: false),
    RegExp(r'\b(sausage|hot dog|frankfurter|bratwurst|meatball|meatloaf|gelatin|animal rennet)\b', caseSensitive: false),
    RegExp(r'\b(beef broth|chicken broth|bone broth|beef stock|chicken stock|pork stock|fish stock)\b', caseSensitive: false),
    RegExp(r'\b(fish sauce|oyster sauce|worcestershire sauce)\b', caseSensitive: false),
  ];

  // Seafood & fish keywords (prohibited for Vegetarian, Vegan, and Non-Pescatarian)
  static final List<RegExp> _seafoodPatterns = [
    RegExp(r'\b(fish|salmon|tuna|cod|tilapia|trout|mackerel|sardine|sardines|anchovy|anchovies|halibut|snapper|sea bass|swordfish)\b', caseSensitive: false),
    RegExp(r'\b(seafood|shrimp|shrimps|prawn|prawns|crab|crabs|lobster|lobsters|crayfish|crawfish)\b', caseSensitive: false),
    RegExp(r'\b(oyster|oysters|clam|clams|mussel|mussels|scallop|scallops|squid|octopus|calamari)\b', caseSensitive: false),
    RegExp(r'\b(caviar|roe|surimi)\b', caseSensitive: false),
  ];

  // Non-vegan dairy & egg keywords (prohibited for Vegan)
  static final List<RegExp> _nonVeganPatterns = [
    RegExp(r'\b(egg|eggs|egg white|egg whites|egg yolk|egg yolks|mayonnaise|mayo|albumin)\b', caseSensitive: false),
    RegExp(r'\b(cow milk|whole milk|skim milk|heavy cream|sour cream|whipped cream|butter|ghee|cheese|cheddar|mozzarella|parmesan|paneer|curd|yogurt|whey|casein|caseinate|lactose)\b', caseSensitive: false),
    RegExp(r'\b(honey|beeswax|royal jelly)\b', caseSensitive: false),
  ];

  // Safe plant terms that should NOT trigger false positives
  static final List<String> _safeExceptions = [
    'chickpea',
    'chickpeas',
    'eggplant',
    'eggplants',
    'cocoa butter',
    'cacao butter',
    'shea butter',
    'peanut butter',
    'almond butter',
    'cashew butter',
    'apple butter',
    'cookie butter',
    'coconut milk',
    'almond milk',
    'oat milk',
    'soy milk',
    'cashew milk',
    'rice milk',
    'plant milk',
    'coconut cream',
    'vegan cheese',
    'vegan butter',
    'vegan mayo',
    'tofu',
    'tempeh',
    'seitan',
    'jackfruit',
    'passionfruit',
    'grapefruit',
    'dragonfruit',
    'butternut squash',
    'meatless',
    'plant-based',
  ];

  /// Resolves the current effective diet type and allergies from active profile.
  ({String dietType, Set<String> allergies, Set<String> dislikedFoods}) getActiveDietaryProfile({
    PersonalizationProfile? personalization,
    UserProfile? profile,
  }) {
    final activePers = personalization ?? PersonalizationService.instance.currentPersonalization;
    final activeProf = profile ?? ProfileService.instance.currentProfile;

    final dietType = (activePers?.dietType ?? activeProf?.dietType ?? 'Balanced').trim();
    final allergies = (activePers?.allergies ?? const <String>{}).toSet();
    final disliked = (activePers?.dislikedFoods ?? const <String>{}).toSet();

    return (dietType: dietType, allergies: allergies, dislikedFoods: disliked);
  }

  /// Validates a [Recipe] model against user dietary preferences and allergies.
  DietaryValidationResult validateRecipe(
    Recipe recipe, {
    PersonalizationProfile? personalization,
    UserProfile? profile,
  }) {
    final active = getActiveDietaryProfile(personalization: personalization, profile: profile);
    final textSegments = [
      recipe.title,
      recipe.description,
      ...recipe.tags,
      ...recipe.ingredients.map((i) => '${i.amount} ${i.name}'),
      ...recipe.instructions,
    ];

    return _validateTextCorpus(textSegments, active.dietType, active.allergies, active.dislikedFoods);
  }

  /// Validates a [RecipeCardData] model against user dietary preferences and allergies.
  DietaryValidationResult validateRecipeCard(
    RecipeCardData card, {
    PersonalizationProfile? personalization,
    UserProfile? profile,
  }) {
    if (card.fullRecipe != null) {
      final res = validateRecipe(card.fullRecipe!, personalization: personalization, profile: profile);
      if (!res.isCompatible) return res;
    }

    final active = getActiveDietaryProfile(personalization: personalization, profile: profile);
    final textSegments = [
      card.title,
      card.tagline,
      card.description,
      card.pantryMatchSummary,
      ...card.whatsInside.map((w) => '${w.title} ${w.subtitle}'),
    ];

    return _validateTextCorpus(textSegments, active.dietType, active.allergies, active.dislikedFoods);
  }

  /// Validates raw recipe JSON returned from API or Spoonacular backend.
  DietaryValidationResult validateRecipeJson(
    Map<String, dynamic> json, {
    PersonalizationProfile? personalization,
    UserProfile? profile,
  }) {
    final active = getActiveDietaryProfile(personalization: personalization, profile: profile);

    final title = json['title']?.toString() ?? '';
    final summary = json['summary']?.toString() ?? json['description']?.toString() ?? '';
    final diets = (json['diets'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];

    final isVegTag = json['vegetarian'] == true || diets.contains('vegetarian');
    final isVeganTag = json['vegan'] == true || diets.contains('vegan');

    final ingredientsRaw = json['ingredients'] as List? ??
        json['extendedIngredients'] as List? ??
        json['usedIngredients'] as List? ??
        [];

    final ingStrings = ingredientsRaw.map((i) {
      if (i is Map) {
        return '${i['name'] ?? ''} ${i['original'] ?? ''} ${i['originalName'] ?? ''}';
      }
      return i.toString();
    }).toList();

    final instructionsRaw = json['instructions'] as List?;
    final instStrings = instructionsRaw != null
        ? instructionsRaw.map((e) => e.toString()).toList()
        : [json['instructions']?.toString() ?? ''];

    final textSegments = [title, summary, ...ingStrings, ...instStrings];

    final result = _validateTextCorpus(textSegments, active.dietType, active.allergies, active.dislikedFoods);
    if (!result.isCompatible) {
      return result;
    }

    // Check tags consistency
    final dietLower = active.dietType.toLowerCase();
    if (dietLower.contains('vegan') && !isVeganTag && json.containsKey('vegan')) {
      if (json['vegan'] == false) {
        return const DietaryValidationResult(
          isCompatible: false,
          rejectionReason: 'Recipe is flagged as non-vegan by provider metadata.',
          matchedViolations: ['non-vegan'],
        );
      }
    } else if (dietLower.contains('vegetarian') && !isVegTag && json.containsKey('vegetarian')) {
      if (json['vegetarian'] == false) {
        return const DietaryValidationResult(
          isCompatible: false,
          rejectionReason: 'Recipe is flagged as non-vegetarian by provider metadata.',
          matchedViolations: ['non-vegetarian'],
        );
      }
    }

    return DietaryValidationResult.valid;
  }

  /// Validates a [FoodProduct] model against user dietary preferences and allergies.
  DietaryValidationResult validateFoodProduct(
    FoodProduct product, {
    PersonalizationProfile? personalization,
    UserProfile? profile,
  }) {
    final active = getActiveDietaryProfile(personalization: personalization, profile: profile);
    final textSegments = [
      product.name,
      product.brand,
      product.ingredients,
      ...product.allergens,
    ];

    return _validateTextCorpus(textSegments, active.dietType, active.allergies, active.dislikedFoods);
  }

  /// Core validation logic inspecting string corpus against dietary constraints and allergies.
  DietaryValidationResult _validateTextCorpus(
    List<String> textSegments,
    String dietType,
    Set<String> allergies,
    Set<String> dislikedFoods,
  ) {
    final rawText = textSegments.join(' ').toLowerCase();

    // Sanitize safe exceptions to prevent false positives (e.g. replace 'chickpeas' with '[safe_pulse]')
    String sanitizedText = rawText;
    for (final safe in _safeExceptions) {
      sanitizedText = sanitizedText.replaceAll(safe, ' ');
    }

    final dietLower = dietType.toLowerCase().trim();
    final violations = <String>[];

    // 1. HARD ALLERGY EXCLUSIONS (Check against raw text to never miss allergens)
    for (final allergy in allergies) {
      final a = allergy.trim().toLowerCase();
      if (a.isEmpty) continue;

      if (a.contains('peanut') && (rawText.contains('peanut') || rawText.contains('groundnut') || rawText.contains('arachis'))) {
        violations.add('Peanut ($allergy allergy)');
      } else if ((a.contains('tree nut') || a.contains('nut')) && !a.contains('peanut') && !a.contains('coconut')) {
        if (RegExp(r'\b(almond|walnut|cashew|pecan|pistachio|hazelnut|macadamia|brazil nut|pine nut)\b', caseSensitive: false).hasMatch(rawText)) {
          violations.add('Tree Nut ($allergy allergy)');
        }
      } else if (a.contains('milk') || a.contains('dairy') || a.contains('lactose')) {
        String nonDairyCleaned = rawText;
        for (final plant in ['coconut milk', 'almond milk', 'oat milk', 'soy milk', 'cashew milk', 'rice milk', 'plant milk', 'peanut butter', 'almond butter', 'cashew butter', 'cocoa butter', 'cacao butter', 'shea butter', 'apple butter', 'vegan butter', 'vegan cheese']) {
          nonDairyCleaned = nonDairyCleaned.replaceAll(plant, ' ');
        }
        if (RegExp(r'\b(milk|dairy|cream|butter|ghee|cheese|paneer|curd|yogurt|whey|casein|caseinate|lactose)\b', caseSensitive: false).hasMatch(nonDairyCleaned)) {
          violations.add('Dairy/Milk ($allergy allergy)');
        }
      } else if (a.contains('egg')) {
        String nonEggCleaned = rawText.replaceAll('eggplant', ' ').replaceAll('eggplants', ' ');
        if (RegExp(r'\b(egg|eggs|egg white|egg whites|egg yolk|egg yolks|mayonnaise|mayo|albumin)\b', caseSensitive: false).hasMatch(nonEggCleaned)) {
          violations.add('Egg ($allergy allergy)');
        }
      } else if (a.contains('gluten') || a.contains('wheat')) {
        if (RegExp(r'\b(wheat|barley|rye|gluten|semolina|spelt|all-purpose flour|wheat flour)\b', caseSensitive: false).hasMatch(rawText)) {
          violations.add('Gluten/Wheat ($allergy allergy)');
        }
      } else if (a.contains('soy')) {
        if (RegExp(r'\b(soy|soya|soybean|soybeans|tofu|tempeh|edamame|soy sauce|soya sauce)\b', caseSensitive: false).hasMatch(rawText)) {
          violations.add('Soy ($allergy allergy)');
        }
      } else if (a.contains('seafood') || a.contains('shellfish') || a.contains('fish')) {
        for (final p in _seafoodPatterns) {
          final match = p.firstMatch(rawText);
          if (match != null) {
            violations.add('${match.group(0)} ($allergy allergy)');
            break;
          }
        }
      } else if (a.contains('sesame') && rawText.contains('sesame')) {
        violations.add('Sesame ($allergy allergy)');
      }
    }

    if (violations.isNotEmpty) {
      return DietaryValidationResult(
        isCompatible: false,
        rejectionReason: 'Contains allergen: ${violations.join(", ")}.',
        matchedViolations: violations,
      );
    }

    // 2. HARD DIETARY PREFERENCE CONSTRAINTS
    final isVegetarian = dietLower.contains('vegetarian') && !dietLower.contains('non');
    final isVegan = dietLower.contains('vegan');
    final isPescatarian = dietLower.contains('pescatarian') || dietLower.contains('pescetarian');

    if (isVegetarian || isVegan) {
      // Check meat
      for (final p in _meatPatterns) {
        final match = p.firstMatch(sanitizedText);
        if (match != null) {
          violations.add(match.group(0)!);
        }
      }

      // Check seafood
      for (final p in _seafoodPatterns) {
        final match = p.firstMatch(sanitizedText);
        if (match != null) {
          violations.add(match.group(0)!);
        }
      }

      if (isVegan) {
        // Check non-vegan animal derivatives
        for (final p in _nonVeganPatterns) {
          final match = p.firstMatch(sanitizedText);
          if (match != null) {
            violations.add(match.group(0)!);
          }
        }
      }
    } else if (isPescatarian) {
      // Meat is prohibited, but seafood is allowed
      for (final p in _meatPatterns) {
        final match = p.firstMatch(sanitizedText);
        if (match != null) {
          violations.add(match.group(0)!);
        }
      }
    }

    if (violations.isNotEmpty) {
      final distinct = violations.toSet().toList();
      return DietaryValidationResult(
        isCompatible: false,
        rejectionReason: 'Contains ${distinct.join(", ")}, which violates user $dietType dietary preference.',
        matchedViolations: distinct,
      );
    }

    return DietaryValidationResult.valid;
  }
}
