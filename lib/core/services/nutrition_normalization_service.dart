import '../model/food_product.dart';
import 'product_category_service.dart';

/// Represents a parsed physical measurement (e.g. "300 ml", "1.5 L", "40 g").
class ServingMeasurement {
  const ServingMeasurement({
    required this.quantity,
    required this.unit,
  });

  final double quantity;
  final String unit; // 'g', 'ml', 'l', 'cl', 'dl', 'kg', 'oz', 'fl oz'

  /// Returns the measurement quantity converted to base standard metric units (g or ml).
  double get inStandardUnits {
    final u = unit.toLowerCase().trim();
    if (u == 'l' || u == 'liter' || u == 'litre' || u == 'litres' || u == 'liters') {
      return quantity * 1000.0;
    }
    if (u == 'cl') {
      return quantity * 10.0;
    }
    if (u == 'dl') {
      return quantity * 100.0;
    }
    if (u == 'kg' || u == 'kilogram' || u == 'kilograms') {
      return quantity * 1000.0;
    }
    if (u == 'fl oz' || u == 'floz' || u == 'fl. oz.' || u == 'fl. oz') {
      return quantity * 29.5735;
    }
    if (u == 'oz' || u == 'ounce' || u == 'ounces') {
      return quantity * 28.3495;
    }
    return quantity;
  }

  /// True if the unit represents a fluid / volume measurement.
  bool get isFluid {
    final u = unit.toLowerCase().trim();
    return u == 'ml' ||
        u == 'l' ||
        u == 'cl' ||
        u == 'dl' ||
        u == 'fl oz' ||
        u == 'floz' ||
        u == 'fl. oz.' ||
        u == 'fl. oz' ||
        u == 'liter' ||
        u == 'litre' ||
        u == 'liters' ||
        u == 'litres' ||
        u == 'cup' ||
        u == 'cups';
  }
}

/// Represents the normalized nutrition data and its corresponding serving basis.
class NormalizedNutrition {
  const NormalizedNutrition({
    required this.isLiquid,
    required this.nutritionBasis,
    this.calories,
    this.protein,
    this.carbohydrates,
    this.fat,
    this.saturatedFat,
    this.fiber,
    this.sugar,
    this.sodium,
    this.salt,
    this.packageSize,
    this.servingSize,
  });

  final bool isLiquid;
  final String nutritionBasis; // "Per 100 ml" or "Per 100 g"
  final double? calories;
  final double? protein;
  final double? carbohydrates;
  final double? fat;
  final double? saturatedFat;
  final double? fiber;
  final double? sugar;
  final double? sodium; // in mg
  final double? salt;
  final String? packageSize;
  final String? servingSize;
}

/// Single source of truth for nutrition normalization and serving-basis handling across DietCompass.
class NutritionNormalizationService {
  NutritionNormalizationService._();
  static final NutritionNormalizationService instance = NutritionNormalizationService._();

  /// Determines if a product is a liquid / beverage based on multi-source metadata, units, and category.
  /// Determines if a product is a liquid / beverage based on multi-source metadata, units, and category.
  bool isLiquidProduct({
    String? name,
    String? brand,
    String? ingredients,
    String? servingSize,
    String? packageSize,
    String? category,
    List<String>? categoriesTags,
    String? quantityUnit,
    String? nutritionDataPer,
  }) {
    final cleanName = (name ?? '').toLowerCase().trim();
    final cleanBrand = (brand ?? '').toLowerCase().trim();
    final cleanIng = (ingredients ?? '').toLowerCase().trim();

    // 1. Semantic Category Check from ProductCategoryService (Highest Priority)
    if (cleanName.isNotEmpty) {
      final tempProd = FoodProduct(
        barcode: '',
        name: name ?? '',
        brand: brand ?? '',
        imageUrl: '',
        ingredients: ingredients ?? '',
        allergens: const [],
        calories: null,
        protein: null,
        carbohydrates: null,
        fat: null,
        fiber: null,
        sugar: null,
        sodium: null,
      );
      final cat = ProductCategoryService.instance.classifyProduct(tempProd);

      // Definite solid food categories -> NEVER liquid
      if (cat == FoodCategoryType.biscuitsCookies ||
          cat == FoodCategoryType.chipsSavorySnacks ||
          cat == FoodCategoryType.breakfastCerealOats ||
          cat == FoodCategoryType.instantNoodlesPasta ||
          cat == FoodCategoryType.breadBakery ||
          cat == FoodCategoryType.proteinEnergyBars ||
          cat == FoodCategoryType.chocolateConfectionery ||
          cat == FoodCategoryType.nutSeedButters ||
          cat == FoodCategoryType.butterDairySpreads ||
          cat == FoodCategoryType.iceCreamFrozen) {
        return false;
      }

      // Definite beverage categories -> ALWAYS liquid
      if (cat == FoodCategoryType.carbonatedBeverage ||
          cat == FoodCategoryType.fruitJuiceSmoothies ||
          cat == FoodCategoryType.plantMilk ||
          cat == FoodCategoryType.teaCoffee) {
        return true;
      }

      if (cat == FoodCategoryType.milkYogurtDairy) {
        if (_hasDrinkKeywords(cleanName) || _hasDrinkKeywords(cleanBrand)) {
          return true;
        }
        return false;
      }
    }

    // 2. High-precision Solid Food Keywords in product name or brand
    if (_hasSolidFoodKeywords(cleanName) || _hasSolidFoodKeywords(cleanBrand)) {
      return false;
    }

    // 3. High-precision Drink / Beverage Keywords in product name or brand
    if (_hasDrinkKeywords(cleanName) || _hasDrinkKeywords(cleanBrand)) {
      return true;
    }

    // 4. Physical unit analysis from servingSize and packageSize
    final servingMeasurement = parseMeasurement(servingSize);
    final packageMeasurement = parseMeasurement(packageSize);

    if (servingMeasurement != null) {
      if (servingMeasurement.isFluid) return true;
      return false; // has explicit mass unit (g, kg, oz) -> solid
    }
    if (packageMeasurement != null) {
      if (packageMeasurement.isFluid) return true;
      return false; // has explicit mass unit (g, kg, oz) -> solid
    }

    // 5. OpenFoodFacts Category Tags (Exact / specific tags only, avoiding umbrella tags like 'en:plant-based-foods-and-beverages')
    if (categoriesTags != null && categoriesTags.isNotEmpty) {
      for (final tag in categoriesTags) {
        final cleanTag = tag.toLowerCase().replaceAll('en:', '').trim();
        // Solid tags
        if (cleanTag == 'noodles' ||
            cleanTag == 'instant-noodles' ||
            cleanTag == 'pastas' ||
            cleanTag == 'chips-and-fries' ||
            cleanTag == 'crisps' ||
            cleanTag == 'potato-crisps' ||
            cleanTag == 'biscuits' ||
            cleanTag == 'cookies' ||
            cleanTag == 'chocolates' ||
            cleanTag == 'cereals-and-potatoes' ||
            cleanTag == 'breads' ||
            cleanTag == 'energy-bars' ||
            cleanTag == 'snacks') {
          return false;
        }
        // Liquid tags (exact beverage families, excluding the generic 'en:plant-based-foods-and-beverages' umbrella)
        if (cleanTag == 'beverages' ||
            cleanTag == 'carbonated-drinks' ||
            cleanTag == 'soft-drinks' ||
            cleanTag == 'sodas' ||
            cleanTag == 'fruit-juices' ||
            cleanTag == 'juices' ||
            cleanTag == 'smoothies' ||
            cleanTag == 'waters' ||
            cleanTag == 'mineral-waters' ||
            cleanTag == 'iced-teas' ||
            cleanTag == 'coffees' ||
            cleanTag == 'plant-milks' ||
            cleanTag == 'milks' ||
            cleanTag == 'drinking-yogurts' ||
            cleanTag == 'energy-drinks' ||
            cleanTag == 'sports-drinks') {
          return true;
        }
      }
    }

    // 6. Explicit quantity unit
    final u = (quantityUnit ?? '').toLowerCase().trim();
    if (u == 'ml' || u == 'l' || u == 'cl' || u == 'dl' || u == 'fl oz' || u == 'floz') {
      return true;
    }
    if (u == 'g' || u == 'gm' || u == 'kg' || u == 'oz') {
      return false;
    }

    // 7. Generic ingredients keyword check (fallback only)
    if (_hasDrinkKeywords(cleanIng) && !_hasSolidFoodKeywords(cleanIng)) {
      return true;
    }

    return false;
  }

  bool _hasSolidFoodKeywords(String text) {
    final lower = text.toLowerCase();
    final solidPatterns = [
      r'\bnoodles?\b',
      r'\bramen\b',
      r'\bpasta\b',
      r'\bmacaroni\b',
      r'\bspaghetti\b',
      r'\bchips?\b',
      r'\bcrisps?\b',
      r'\bnachos?\b',
      r'\bnamkeen\b',
      r'\bbhujia\b',
      r'\bsev\b',
      r'\bbiscuits?\b',
      r'\bcookies?\b',
      r'\bwafers?\b',
      r'\bchocolates?\b',
      r'\bcand(?:y|ies)\b',
      r'\boats?\b',
      r'\boatmeal\b',
      r'\bcereal\b',
      r'\bmuesli\b',
      r'\bgranola\b',
      r'\bbread\b',
      r'\bbuns?\b',
      r'\bcake\b',
      r'\bmuffins?\b',
      r'\bbars?\b',
      r'\bflour\b',
      r'\batta\b',
      r'\bmaida\b',
      r'\brice\b',
      r'\bdal\b',
      r'\blentils?\b',
      r'\bpeanuts?\b',
      r'\balmonds?\b',
      r'\bcashews?\b',
      r'\bwalnuts?\b',
      r'\bpopcorn\b',
      r'\bpuffs?\b',
      r'\bmix\b',
    ];

    for (final pattern in solidPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(lower)) return true;
    }
    return false;
  }

  bool _hasDrinkKeywords(String text) {
    final lower = text.toLowerCase();
    final drinkKeywords = [
      r'\bsprite\b',
      r'\bcoca-cola\b',
      r'\bcoca cola\b',
      r'\bcoke\b',
      r'\bpepsi\b',
      r'\bfanta\b',
      r'\bmirinda\b',
      r'\blimca\b',
      r'\b7up\b',
      r'\bmountain dew\b',
      r'\bthums up\b',
      r'\bsoft drink\b',
      r'\bcarbonated drink\b',
      r'\baerated drink\b',
      r'\bfizzy drink\b',
      r'\bsoda\b',
      r'\bcola\b',
      r'\bfruit juice\b',
      r'\bmango drink\b',
      r'\bapple juice\b',
      r'\borange juice\b',
      r'\bfrooti\b',
      r'\bmaaza\b',
      r'\bslice mango\b',
      r'\btropicana\b',
      r'\bsmoothie\b',
      r'\bmilkshake\b',
      r'\blassi\b',
      r'\bchaas\b',
      r'\bbuttermilk\b',
      r'\btoned milk\b',
      r'\bcow milk\b',
      r'\bfull cream milk\b',
      r'\bsoya milk\b',
      r'\bsoy milk\b',
      r'\balmond milk\b',
      r'\boat milk\b',
      r'\bplant milk\b',
      r'\benergy drink\b',
      r'\bsports drink\b',
      r'\bcoconut water\b',
      r'\blemonade\b',
      r'\biced tea\b',
      r'\bgreen tea\b',
      r'\bblack tea\b',
      r'\bbrewed coffee\b',
      r'\bcold coffee\b',
      r'\bespresso\b',
      r'\bmineral water\b',
      r'\bsparkling water\b',
      r'\btonic water\b',
      r'\bnectar\b',
      r'\bbeverage\b',
    ];

    for (final pattern in drinkKeywords) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(lower)) return true;
    }
    return false;
  }

  /// Parses a string measurement like "300 ml", "1.5 L", "40g", "1 bottle (250 ml)", "2 biscuits (25g)".
  ServingMeasurement? parseMeasurement(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final clean = text.trim();

    // Match patterns like "300 ml", "1.5 L", "250ml", "40 g", "1 bottle (300 ml)"
    final regex = RegExp(
      r'([0-9]+(?:\.[0-9]+)?)\s*(ml|l|liter|litre|litres|liters|g|gm|gram|grams|kg|fl\s*oz|floz|oz|cup|cups)\b',
      caseSensitive: false,
    );

    final match = regex.firstMatch(clean);
    if (match != null) {
      final qtyStr = match.group(1);
      final unitStr = match.group(2);
      if (qtyStr != null && unitStr != null) {
        final q = double.tryParse(qtyStr);
        if (q != null && q > 0) {
          String normalizedUnit = unitStr.toLowerCase().trim();
          if (normalizedUnit == 'gm' || normalizedUnit == 'gram' || normalizedUnit == 'grams') {
            normalizedUnit = 'g';
          } else if (normalizedUnit == 'litre' || normalizedUnit == 'litres' || normalizedUnit == 'liters' || normalizedUnit == 'liter') {
            normalizedUnit = 'l';
          } else if (normalizedUnit == 'floz' || normalizedUnit == 'fl oz') {
            normalizedUnit = 'fl oz';
          }
          return ServingMeasurement(quantity: q, unit: normalizedUnit);
        }
      }
    }
    return null;
  }

  /// Normalizes all nutrition values to standard "Per 100 ml" (for liquids) or "Per 100 g" (for solids).
  NormalizedNutrition normalize({
    required double? calories,
    required double? protein,
    required double? carbohydrates,
    required double? fat,
    double? saturatedFat,
    required double? fiber,
    required double? sugar,
    required double? sodium,
    double? salt,
    String? servingSize,
    String? packageSize,
    String? sourceBasis, // '100g', '100ml', 'serving', 'package', null
    bool? isLiquidOverride,
    String? productName,
    String? brand,
    String? ingredients,
    List<String>? categoriesTags,
    String? quantityUnit,
  }) {
    final isLiquid = isLiquidOverride ??
        isLiquidProduct(
          name: productName,
          brand: brand,
          ingredients: ingredients,
          servingSize: servingSize,
          packageSize: packageSize,
          categoriesTags: categoriesTags,
          quantityUnit: quantityUnit,
          nutritionDataPer: sourceBasis,
        );

    final targetBasisLabel = isLiquid ? 'Per 100 ml' : 'Per 100 g';

    // 1. Calculate normalization scaling factor
    double scaleFactor = 1.0;
    bool shouldScale = false;

    final cleanSourceBasis = (sourceBasis ?? '').toLowerCase().trim();

    if (cleanSourceBasis == 'serving' || cleanSourceBasis == 'per serving') {
      final measurement = parseMeasurement(servingSize);
      if (measurement != null) {
        final standardAmount = measurement.inStandardUnits;
        if (standardAmount > 0 && (standardAmount - 100.0).abs() > 0.001) {
          scaleFactor = 100.0 / standardAmount;
          shouldScale = true;
        }
      }
    } else if (cleanSourceBasis == 'package' || cleanSourceBasis == 'per package') {
      final measurement = parseMeasurement(packageSize) ?? parseMeasurement(servingSize);
      if (measurement != null) {
        final standardAmount = measurement.inStandardUnits;
        if (standardAmount > 0 && (standardAmount - 100.0).abs() > 0.001) {
          scaleFactor = 100.0 / standardAmount;
          shouldScale = true;
        }
      }
    }

    // 2. Apply scaling factor to all available nutrients
    double? normCal = calories != null ? (shouldScale ? calories * scaleFactor : calories) : null;
    double? normProt = protein != null ? (shouldScale ? protein * scaleFactor : protein) : null;
    double? normCarb = carbohydrates != null ? (shouldScale ? carbohydrates * scaleFactor : carbohydrates) : null;
    double? normFat = fat != null ? (shouldScale ? fat * scaleFactor : fat) : null;
    double? normSatFat = saturatedFat != null ? (shouldScale ? saturatedFat * scaleFactor : saturatedFat) : null;
    double? normFiber = fiber != null ? (shouldScale ? fiber * scaleFactor : fiber) : null;
    double? normSugar = sugar != null ? (shouldScale ? sugar * scaleFactor : sugar) : null;
    double? normSodium = sodium != null ? (shouldScale ? sodium * scaleFactor : sodium) : null;
    double? normSalt = salt != null ? (shouldScale ? salt * scaleFactor : salt) : null;

    // Ensure sodium is in mg (if raw value was in grams e.g. <= 10.0g such as 0.004g, 0.05g, 0.58g, 1.0g)
    if (normSodium != null && normSodium! <= 10.0 && normSodium! > 0) {
      normSodium = normSodium! * 1000.0;
    }
    // If salt is present but sodium is missing, calculate sodium from salt (salt / 2.5 * 1000 mg)
    if (normSodium == null && normSalt != null && normSalt! > 0) {
      normSodium = normSalt! <= 10.0 ? (normSalt! / 2.5) * 1000.0 : (normSalt! / 2.5);
    }

    return NormalizedNutrition(
      isLiquid: isLiquid,
      nutritionBasis: targetBasisLabel,
      calories: normCal != null ? _roundToOneDecimal(normCal) : null,
      protein: normProt != null ? _roundToOneDecimal(normProt) : null,
      carbohydrates: normCarb != null ? _roundToOneDecimal(normCarb) : null,
      fat: normFat != null ? _roundToOneDecimal(normFat) : null,
      saturatedFat: normSatFat != null ? _roundToOneDecimal(normSatFat) : null,
      fiber: normFiber != null ? _roundToOneDecimal(normFiber) : null,
      sugar: normSugar != null ? _roundToOneDecimal(normSugar) : null,
      sodium: normSodium != null ? _roundToOneDecimal(normSodium) : null,
      salt: normSalt != null ? _roundToOneDecimal(normSalt) : null,
      packageSize: packageSize,
      servingSize: servingSize,
    );
  }

  double _roundToOneDecimal(double val) {
    return (val * 10.0).roundToDouble() / 10.0;
  }
}
