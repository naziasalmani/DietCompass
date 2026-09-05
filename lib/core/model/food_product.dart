import '../services/nutrition_normalization_service.dart';

enum DataConfidence {
  high,
  moderate,
  low,
}

extension DataConfidenceExtension on DataConfidence {
  String get label {
    switch (this) {
      case DataConfidence.high:
        return 'High';
      case DataConfidence.moderate:
        return 'Moderate';
      case DataConfidence.low:
        return 'Low';
    }
  }

  String get description {
    switch (this) {
      case DataConfidence.high:
        return 'Complete nutrition and ingredient data verified across sources.';
      case DataConfidence.moderate:
        return 'Key nutrition facts available; some secondary details missing.';
      case DataConfidence.low:
        return 'Limited nutrition or ingredient data available. Verify product label.';
    }
  }
}

class FoodProduct {
  final String barcode;
  final String name;
  final String brand;
  final String imageUrl;
  final String ingredients;
  final List<String> allergens;

  // Nullable nutrients - NEVER assumed to be 0 when missing.
  final double? calories;
  final double? protein;
  final double? carbohydrates;
  final double? fat;
  final double? saturatedFat;
  final double? fiber;
  final double? sugar;
  final double? sodium;
  final double? salt;

  final String? servingSize;
  final String? packageSize;
  final String? nutritionBasis; // e.g. "Per 100 ml" or "Per 100 g"
  final List<String> claims;
  final String? source;
  final List<String> discrepancies;

  final String? nutriScore;
  final int? novaGroup;
  final DateTime? cachedAt;
  final String? completenessStatus;

  FoodProduct({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.ingredients,
    required this.allergens,
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    this.saturatedFat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    this.salt,
    this.servingSize,
    this.packageSize,
    this.nutritionBasis,
    this.claims = const [],
    this.source,
    this.discrepancies = const [],
    this.nutriScore,
    this.novaGroup,
    this.cachedAt,
    this.completenessStatus,
  });

  /// True if the product is liquid / beverage.
  bool get isLiquid => NutritionNormalizationService.instance.isLiquidProduct(
        name: name,
        brand: brand,
        ingredients: ingredients,
        servingSize: servingSize,
        packageSize: packageSize,
      );

  /// Returns the dynamically verified serving basis label: "Per 100 ml" for liquids, "Per 100 g" for solids.
  String get normalizedBasisLabel => isLiquid ? 'Per 100 ml' : 'Per 100 g';

  factory FoodProduct.fromOpenFoodFacts(
    Map<String, dynamic> json,
  ) {
    final product = json['product'] is Map<String, dynamic>
        ? json['product'] as Map<String, dynamic>
        : json;
    final nutrients = product['nutriments'] is Map<String, dynamic>
        ? product['nutriments'] as Map<String, dynamic>
        : <String, dynamic>{};

    final rawName = _firstNonEmpty([
      product['product_name'],
      product['product_name_en'],
      product['product_name_hi'],
      product['name'],
    ], fallback: 'Unknown Product');

    final rawBrand = _firstNonEmpty([
      product['brands'],
      product['brand_owner'],
      product['brand'],
    ], fallback: 'Unknown Brand');

    final rawIngredients = _firstNonEmpty([
      product['ingredients_text'],
      product['ingredients_text_en'],
      product['ingredients'],
    ]);

    final rawServingSize = _firstNonEmpty([
      product['serving_size'],
      product['serving_quantity']?.toString(),
      product['servingSize'],
    ]);

    final rawPackageSize = _firstNonEmpty([
      product['quantity'],
      product['net_weight'],
      product['product_quantity']?.toString(),
      product['packageSize'],
    ]);

    final rawQuantityUnit = product['product_quantity_unit']?.toString() ??
        product['serving_quantity_unit']?.toString();

    final nutritionDataPer = product['nutrition_data_per']?.toString();

    final rawCategoriesTags = product['categories_tags'] is List
        ? (product['categories_tags'] as List).map((e) => e.toString()).toList()
        : <String>[];

    // Extract front-of-package claims if available
    final rawClaims = <String>[];
    if (product['labels_tags'] is List) {
      for (final label in product['labels_tags']) {
        final clean = label.toString().replaceAll('en:', '').replaceAll('-', ' ').trim();
        if (clean.isNotEmpty) rawClaims.add(clean);
      }
    }
    if (product['claims'] is List) {
      for (final c in product['claims']) {
        if (c != null && c.toString().isNotEmpty) rawClaims.add(c.toString());
      }
    }

    // 1. Determine if product is liquid / beverage
    final isLiquid = NutritionNormalizationService.instance.isLiquidProduct(
      name: rawName,
      brand: rawBrand,
      ingredients: rawIngredients,
      servingSize: rawServingSize,
      packageSize: rawPackageSize,
      categoriesTags: rawCategoriesTags,
      quantityUnit: rawQuantityUnit,
      nutritionDataPer: nutritionDataPer,
    );

    // 2. Determine source nutrition basis
    final is100mlBasis = nutritionDataPer == '100ml' ||
        (isLiquid && nutrients.containsKey('sugars_100ml')) ||
        (isLiquid && nutrients.containsKey('energy-kcal_100ml'));
    final is100gBasis = nutritionDataPer == '100g' ||
        (!isLiquid && nutrients.containsKey('sugars_100g')) ||
        (!isLiquid && nutrients.containsKey('energy-kcal_100g'));
    final isServingBasis = nutritionDataPer == 'serving' && !is100mlBasis && !is100gBasis;

    final resolvedSourceBasis = isServingBasis
        ? 'serving'
        : (is100mlBasis ? '100ml' : (is100gBasis ? '100g' : (isLiquid ? '100ml' : '100g')));

    // 3. Extract nutrient with strict target-basis priority
    double? extractNutrient(String baseKey) {
      if (isLiquid) {
        // Preferred for liquids: *_100ml
        final v100ml = _toDouble(nutrients['${baseKey}_100ml']);
        if (v100ml != null) return v100ml;

        // When nutrition_data_per is 100ml, OFF stores 100ml values in _100g or _value
        if (is100mlBasis) {
          final v100g = _toDouble(nutrients['${baseKey}_100g']) ??
              _toDouble(nutrients['${baseKey}_value']) ??
              _toDouble(nutrients[baseKey]);
          if (v100g != null) return v100g;
        }

        // Fallback to _100g if present
        final v100g = _toDouble(nutrients['${baseKey}_100g']);
        if (v100g != null) return v100g;

        // Fallback to direct value if not serving basis
        if (!isServingBasis) {
          final vDirect = _toDouble(nutrients['${baseKey}_value']) ??
              _toDouble(nutrients[baseKey]) ??
              _toDouble(product[baseKey]);
          if (vDirect != null) return vDirect;
        }

        // Fallback to serving value
        return _toDouble(nutrients['${baseKey}_serving']);
      } else {
        // Preferred for solids: *_100g
        final v100g = _toDouble(nutrients['${baseKey}_100g']);
        if (v100g != null) return v100g;

        if (is100gBasis) {
          final vDirect100 = _toDouble(nutrients['${baseKey}_value']) ??
              _toDouble(nutrients[baseKey]);
          if (vDirect100 != null) return vDirect100;
        }

        // Fallback to _100ml if present
        final v100ml = _toDouble(nutrients['${baseKey}_100ml']);
        if (v100ml != null) return v100ml;

        // Fallback to direct value if not serving basis
        if (!isServingBasis) {
          final vDirect = _toDouble(nutrients['${baseKey}_value']) ??
              _toDouble(nutrients[baseKey]) ??
              _toDouble(product[baseKey]);
          if (vDirect != null) return vDirect;
        }

        // Fallback to serving value
        return _toDouble(nutrients['${baseKey}_serving']);
      }
    }

    double? rawCalories = extractNutrient('energy-kcal') ?? _toDouble(product['calories']);
    if (rawCalories == null) {
      final energyKj = extractNutrient('energy') ?? extractNutrient('energy-kj');
      if (energyKj != null && energyKj > 0) {
        rawCalories = energyKj / 4.184;
      }
    }

    double? rawProtein = extractNutrient('proteins') ?? extractNutrient('protein') ?? _toDouble(product['protein']);
    double? rawCarbs = extractNutrient('carbohydrates') ?? extractNutrient('carbohydrate') ?? _toDouble(product['carbohydrates']);
    double? rawFat = extractNutrient('fat') ?? _toDouble(product['fat']);
    double? rawSatFat = extractNutrient('saturated-fat') ?? extractNutrient('saturated_fat') ?? _toDouble(product['saturatedFat']) ?? _toDouble(product['saturated_fat']);
    double? rawFiber = extractNutrient('fiber') ?? extractNutrient('fibre') ?? _toDouble(product['fiber']);
    double? rawSugar = extractNutrient('sugars') ?? extractNutrient('sugar') ?? _toDouble(product['sugar']);
    double? rawSodium = extractNutrient('sodium') ?? _toDouble(product['sodium']);
    double? rawSalt = extractNutrient('salt') ?? _toDouble(product['salt']);

    final normalized = NutritionNormalizationService.instance.normalize(
      calories: rawCalories,
      protein: rawProtein,
      carbohydrates: rawCarbs,
      fat: rawFat,
      saturatedFat: rawSatFat,
      fiber: rawFiber,
      sugar: rawSugar,
      sodium: rawSodium,
      salt: rawSalt,
      servingSize: rawServingSize,
      packageSize: rawPackageSize,
      sourceBasis: resolvedSourceBasis,
      isLiquidOverride: isLiquid,
      productName: rawName,
      brand: rawBrand,
      ingredients: rawIngredients,
      categoriesTags: rawCategoriesTags,
      quantityUnit: rawQuantityUnit,
    );

    return FoodProduct(
      barcode: json['code']?.toString() ?? product['barcode']?.toString() ?? '',
      name: rawName,
      brand: rawBrand,
      imageUrl: _firstNonEmpty([
        product['image_front_url'],
        product['image_front_small_url'],
        product['image_front_thumb_url'],
        product['image_url'],
        product['image_small_url'],
        product['imageUrl'],
      ]),
      ingredients: rawIngredients,
      allergens: _parseAllergens(product['allergens']),
      calories: normalized.calories,
      protein: normalized.protein,
      carbohydrates: normalized.carbohydrates,
      fat: normalized.fat,
      saturatedFat: normalized.saturatedFat,
      fiber: normalized.fiber,
      sugar: normalized.sugar,
      sodium: normalized.sodium,
      salt: normalized.salt,
      servingSize: rawServingSize,
      packageSize: rawPackageSize,
      nutritionBasis: normalized.nutritionBasis,
      claims: rawClaims,
      source: product['source']?.toString() ?? 'Open Food Facts',
      discrepancies: (product['discrepancies'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      nutriScore: _firstNonEmpty([
        product['nutriscore_grade'],
        product['nutriscore_score'],
        product['nutriScore'],
      ]),
      novaGroup: _toInt(product['nova_group'] ?? product['novaGroup']),
    );
  }

  factory FoodProduct.fromJson(Map<String, dynamic> json) {
    final nutrition = json['nutrition'] is Map<String, dynamic>
        ? json['nutrition'] as Map<String, dynamic>
        : json;

    final rawName = _firstNonEmpty([
      json['name'],
      json['product_name'],
    ], fallback: 'Unknown Product');

    final rawBrand = _firstNonEmpty([
      json['brand'],
      json['brands'],
    ], fallback: 'Unknown Brand');

    final rawIngredients = _firstNonEmpty([
      json['ingredients'],
      json['ingredients_text'],
    ]);

    final rawServingSize = _firstNonEmpty([json['servingSize'], json['serving_size']]);
    final rawPackageSize = _firstNonEmpty([json['packageSize'], json['package_size'], json['quantity']]);
    final rawNutritionBasis = _firstNonEmpty([json['nutritionBasis'], json['nutrition_basis']]);

    final rawCalories = _toDouble(nutrition['calories'] ?? json['calories']);
    final rawProtein = _toDouble(nutrition['protein'] ?? json['protein']);
    final rawCarbohydrates = _toDouble(nutrition['carbohydrates'] ?? json['carbohydrates']);
    final rawFat = _toDouble(nutrition['fat'] ?? json['fat']);
    final rawSaturatedFat = _toDouble(nutrition['saturatedFat'] ?? json['saturated_fat']);
    final rawFiber = _toDouble(nutrition['fiber'] ?? json['fiber']);
    final rawSugar = _toDouble(nutrition['sugar'] ?? json['sugar']);
    final rawSodium = _toDouble(nutrition['sodium'] ?? json['sodium']);
    final rawSalt = _toDouble(nutrition['salt'] ?? json['salt']);

    final normalized = NutritionNormalizationService.instance.normalize(
      calories: rawCalories,
      protein: rawProtein,
      carbohydrates: rawCarbohydrates,
      fat: rawFat,
      saturatedFat: rawSaturatedFat,
      fiber: rawFiber,
      sugar: rawSugar,
      sodium: rawSodium,
      salt: rawSalt,
      servingSize: rawServingSize,
      packageSize: rawPackageSize,
      sourceBasis: rawNutritionBasis,
      productName: rawName,
      brand: rawBrand,
      ingredients: rawIngredients,
    );

    return FoodProduct(
      barcode: json['barcode']?.toString() ?? '',
      name: rawName,
      brand: rawBrand,
      imageUrl: _firstNonEmpty([
        json['imageUrl'],
        json['image_url'],
      ]),
      ingredients: rawIngredients,
      allergens: _parseAllergens(json['allergens']),
      calories: normalized.calories,
      protein: normalized.protein,
      carbohydrates: normalized.carbohydrates,
      fat: normalized.fat,
      saturatedFat: normalized.saturatedFat,
      fiber: normalized.fiber,
      sugar: normalized.sugar,
      sodium: normalized.sodium,
      salt: normalized.salt,
      servingSize: rawServingSize,
      packageSize: rawPackageSize,
      nutritionBasis: normalized.nutritionBasis,
      claims: (json['claims'] as List?)?.map((e) => e.toString()).toList() ?? [],
      source: json['source']?.toString(),
      discrepancies: (json['discrepancies'] as List?)?.map((e) => e.toString()).toList() ?? [],
      nutriScore: _firstNonEmpty([
        json['nutriScore'],
        json['nutriscore'],
      ]),
      novaGroup: _toInt(json['novaGroup'] ?? json['nova_group']),
    );
  }

  // ------------------------------------------------------------
  // Merge this product with another source (e.g. USDA, UPC, Local DB).
  //
  // Non-null and non-zero (> 0) values from this product take precedence.
  // Any null, 0/0.0, or empty values are backfilled from [other].
  // Detects significant discrepancies between sources.
  // ------------------------------------------------------------
  FoodProduct mergeWith(FoodProduct? other) {
    if (other == null) return this;

    final resolvedName = _isValidText(name)
        ? name
        : (_isValidText(other.name) ? other.name : name);

    final resolvedBrand = _isValidBrand(brand)
        ? brand
        : (_isValidBrand(other.brand) ? other.brand : brand);

    final resolvedImage = imageUrl.trim().isNotEmpty
        ? imageUrl
        : other.imageUrl.trim();

    final resolvedIngredients = ingredients.trim().isNotEmpty
        ? ingredients
        : other.ingredients.trim();

    final resolvedAllergens =
        allergens.isNotEmpty ? allergens : other.allergens;

    final resolvedNutriScore = (nutriScore != null && nutriScore!.trim().isNotEmpty)
        ? nutriScore
        : other.nutriScore;

    final mergedDiscrepancies = List<String>.from(discrepancies);

    // Detect nutrient conflicts if both sources supply positive values that diverge significantly (>30%)
    _checkDiscrepancy('Sugar', sugar, other.sugar, mergedDiscrepancies, source, other.source);
    _checkDiscrepancy('Calories', calories, other.calories, mergedDiscrepancies, source, other.source);
    _checkDiscrepancy('Sodium', sodium, other.sodium, mergedDiscrepancies, source, other.source);
    _checkDiscrepancy('Protein', protein, other.protein, mergedDiscrepancies, source, other.source);

    final mergedClaims = {...claims, ...other.claims}.toList();

    final mergedProduct = FoodProduct(
      barcode: barcode.trim().isNotEmpty
          ? barcode.trim()
          : other.barcode.trim(),
      name: resolvedName,
      brand: resolvedBrand,
      imageUrl: resolvedImage,
      ingredients: resolvedIngredients,
      allergens: resolvedAllergens,
      calories: _mergePositiveDouble(calories, other.calories),
      protein: _mergePositiveDouble(protein, other.protein),
      carbohydrates: _mergePositiveDouble(carbohydrates, other.carbohydrates),
      fat: _mergePositiveDouble(fat, other.fat),
      saturatedFat: _mergePositiveDouble(saturatedFat, other.saturatedFat),
      fiber: _mergePositiveDouble(fiber, other.fiber),
      sugar: _mergePositiveDouble(sugar, other.sugar),
      sodium: _mergePositiveDouble(sodium, other.sodium),
      salt: _mergePositiveDouble(salt, other.salt),
      servingSize: _firstNonEmpty([servingSize, other.servingSize]),
      packageSize: _firstNonEmpty([packageSize, other.packageSize]),
      nutritionBasis: NutritionNormalizationService.instance.isLiquidProduct(
        name: resolvedName,
        brand: resolvedBrand,
        ingredients: resolvedIngredients,
        servingSize: _firstNonEmpty([servingSize, other.servingSize]),
        packageSize: _firstNonEmpty([packageSize, other.packageSize]),
      ) ? 'Per 100 ml' : 'Per 100 g',
      claims: mergedClaims,
      source: source ?? other.source ?? 'Multi-Source Merged',
      discrepancies: mergedDiscrepancies.toSet().toList(),
      nutriScore: resolvedNutriScore,
      novaGroup: _mergePositiveInt(novaGroup, other.novaGroup),
    );

    return mergedProduct;
  }

  FoodProduct copyWith({
    String? barcode,
    String? name,
    String? brand,
    String? imageUrl,
    String? ingredients,
    List<String>? allergens,
    double? calories,
    double? protein,
    double? carbohydrates,
    double? fat,
    double? saturatedFat,
    double? fiber,
    double? sugar,
    double? sodium,
    double? salt,
    String? servingSize,
    String? packageSize,
    String? nutritionBasis,
    List<String>? claims,
    String? source,
    List<String>? discrepancies,
    String? nutriScore,
    int? novaGroup,
    DateTime? cachedAt,
    String? completenessStatus,
  }) {
    return FoodProduct(
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      ingredients: ingredients ?? this.ingredients,
      allergens: allergens ?? this.allergens,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbohydrates: carbohydrates ?? this.carbohydrates,
      fat: fat ?? this.fat,
      saturatedFat: saturatedFat ?? this.saturatedFat,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      sodium: sodium ?? this.sodium,
      salt: salt ?? this.salt,
      servingSize: servingSize ?? this.servingSize,
      packageSize: packageSize ?? this.packageSize,
      nutritionBasis: nutritionBasis ?? this.nutritionBasis,
      claims: claims ?? this.claims,
      source: source ?? this.source,
      discrepancies: discrepancies ?? this.discrepancies,
      nutriScore: nutriScore ?? this.nutriScore,
      novaGroup: novaGroup ?? this.novaGroup,
      cachedAt: cachedAt ?? this.cachedAt,
      completenessStatus: completenessStatus ?? this.completenessStatus,
    );
  }

  /// Calculates the product data confidence based on field completeness and verification.
  DataConfidence get dataConfidence {
    int filled = 0;

    if (calories != null) filled++;
    if (protein != null) filled++;
    if (carbohydrates != null) filled++;
    if (fat != null) filled++;
    if (fiber != null) filled++;
    if (sugar != null) filled++;
    if (sodium != null) filled++;

    final hasIngredients = ingredients.trim().isNotEmpty;
    final hasName = _isValidText(name);

    if (filled >= 5 && hasIngredients && hasName && discrepancies.isEmpty) {
      return DataConfidence.high;
    } else if (filled >= 3 && (hasIngredients || hasName)) {
      return DataConfidence.moderate;
    } else {
      return DataConfidence.low;
    }
  }

  /// Returns true if any nutritional value was provided.
  bool get hasNutritionData =>
      calories != null ||
      protein != null ||
      carbohydrates != null ||
      fat != null ||
      saturatedFat != null ||
      fiber != null ||
      sugar != null ||
      sodium != null;

  /// Returns true if essential required nutrient values are missing (null), invalid (<0), or suspicious.
  /// Smartly distinguishes between null/missing/suspicious values vs legitimate zero nutrition values
  /// (e.g. 0g sugar in plain water or meat or diet drinks, 0g fiber in pure oil or dairy).
  bool get hasMissingOrZeroNutrients {
    if (!_isValidText(name)) return true;
    if (calories == null || calories! < 0) return true;
    if (protein == null || protein! < 0) return true;
    if (carbohydrates == null || carbohydrates! < 0) return true;
    if (fat == null || fat! < 0) return true;

    // Ingredients check (unless product is plain water)
    if (ingredients.trim().isEmpty && !name.toLowerCase().contains('water')) {
      return true;
    }

    // Suspicious zero calories when macros indicate high density
    if (calories == 0 && (protein! > 3 || carbohydrates! > 3 || fat! > 3)) {
      return true;
    }

    // Suspicious non-zero calories with all zero primary macros
    if (calories! > 50 && protein == 0 && carbohydrates == 0 && fat == 0) {
      return true;
    }

    // Suspicious zero sugar if carbohydrates are high and sugar ingredients are present
    if (carbohydrates! > 15 && sugar == 0 && _hasSugarInIngredients(ingredients)) {
      return true;
    }

    return false;
  }

  static bool _hasSugarInIngredients(String text) {
    if (text.isEmpty) return false;
    final lower = text.toLowerCase();
    return lower.contains('sugar') ||
        lower.contains('syrup') ||
        lower.contains('dextrose') ||
        lower.contains('fructose') ||
        lower.contains('honey') ||
        lower.contains('chocolate');
  }

  /// Returns true when all primary nutrient fields and metadata are present and valid.
  bool get isComplete {
    return !hasMissingOrZeroNutrients &&
        _isValidText(name) &&
        _isValidBrand(brand);
  }

  Map<String, dynamic> toJson() => {
        'barcode': barcode,
        'name': name,
        'brand': brand,
        'imageUrl': imageUrl,
        'ingredients': ingredients,
        'allergens': allergens,
        'calories': calories,
        'protein': protein,
        'carbohydrates': carbohydrates,
        'fat': fat,
        'saturatedFat': saturatedFat,
        'fiber': fiber,
        'sugar': sugar,
        'sodium': sodium,
        'salt': salt,
        'servingSize': servingSize,
        'packageSize': packageSize,
        'nutritionBasis': nutritionBasis,
        'claims': claims,
        'source': source,
        'discrepancies': discrepancies,
        'nutriScore': nutriScore,
        'novaGroup': novaGroup,
      };

  static void _checkDiscrepancy(

    String nutrientName,
    double? valA,
    double? valB,

    List<String> discrepancies,
    String? sourceA,
    String? sourceB,
  ) {
    if (valA != null && valB != null && valA > 0 && valB > 0) {
      final diff = (valA - valB).abs();
      final maxVal = valA > valB ? valA : valB;
      if (maxVal > 0 && (diff / maxVal) > 0.40 && diff >= 2.0) {
        discrepancies.add(
          '$nutrientName discrepancy: ${valA.toStringAsFixed(1)} (${sourceA ?? 'Primary'}) vs ${valB.toStringAsFixed(1)} (${sourceB ?? 'Secondary'}). Please verify product label.',
        );
      }
    }
  }

  static bool _isValidText(String text) {
    final trimmed = text.trim();
    return trimmed.isNotEmpty && trimmed.toLowerCase() != 'unknown product';
  }

  static bool _isValidBrand(String text) {
    final trimmed = text.trim();
    return trimmed.isNotEmpty && trimmed.toLowerCase() != 'unknown brand';
  }

  static double? _mergePositiveDouble(double? primary, double? fallback) {
    if (primary != null && primary > 0) return primary;
    if (fallback != null && fallback > 0) return fallback;
    return primary ?? fallback;
  }

  static int? _mergePositiveInt(int? primary, int? fallback) {
    if (primary != null && primary > 0) return primary;
    if (fallback != null && fallback > 0) return fallback;
    return primary ?? fallback;
  }

  static String _firstNonEmpty(
    List<dynamic> values, {
    String fallback = '',
  }) {
    for (final value in values) {
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString().trim());
  }

  static List<String> _parseAllergens(dynamic value) {
    if (value == null) return [];
    if (value is String) {
      return value
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }
}