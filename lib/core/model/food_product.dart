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
  final List<String> claims;
  final String? source;
  final List<String> discrepancies;

  final String? nutriScore;
  final int? novaGroup;

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
    this.claims = const [],
    this.source,
    this.discrepancies = const [],
    this.nutriScore,
    this.novaGroup,
  });

  factory FoodProduct.fromOpenFoodFacts(
    Map<String, dynamic> json,
  ) {
    final product = json['product'] ?? {};
    final nutrients = product['nutriments'] ?? {};

    // Extract front-of-package claims if available
    final rawClaims = <String>[];
    if (product['labels_tags'] is List) {
      for (final label in product['labels_tags']) {
        final clean = label.toString().replaceAll('en:', '').replaceAll('-', ' ').trim();
        if (clean.isNotEmpty) rawClaims.add(clean);
      }
    }

    return FoodProduct(
      barcode: json['code']?.toString() ?? '',
      name: _firstNonEmpty([
        product['product_name'],
        product['product_name_en'],
        product['product_name_hi'],
      ], fallback: 'Unknown Product'),
      brand: _firstNonEmpty([
        product['brands'],
        product['brand_owner'],
      ], fallback: 'Unknown Brand'),
      imageUrl: _firstNonEmpty([
        product['image_front_url'],
        product['image_front_small_url'],
        product['image_front_thumb_url'],
        product['image_url'],
        product['image_small_url'],
      ]),
      ingredients: _firstNonEmpty([
        product['ingredients_text'],
        product['ingredients_text_en'],
      ]),
      allergens: _parseAllergens(product['allergens']),
      calories: _toDouble(nutrients['energy-kcal_100g']),
      protein: _toDouble(nutrients['proteins_100g']),
      carbohydrates: _toDouble(nutrients['carbohydrates_100g']),
      fat: _toDouble(nutrients['fat_100g']),
      saturatedFat: _toDouble(nutrients['saturated-fat_100g']),
      fiber: _toDouble(nutrients['fiber_100g']),
      sugar: _toDouble(nutrients['sugars_100g']),
      sodium: _toDouble(nutrients['sodium_100g']),
      salt: _toDouble(nutrients['salt_100g']),
      servingSize: _firstNonEmpty([product['serving_size'], product['serving_quantity']?.toString()]),
      claims: rawClaims,
      source: 'Open Food Facts',
      nutriScore: _firstNonEmpty([
        product['nutriscore_grade'],
        product['nutriscore_score'],
      ]),
      novaGroup: _toInt(product['nova_group']),
    );
  }

  factory FoodProduct.fromJson(Map<String, dynamic> json) {
    final nutrition = json['nutrition'] is Map<String, dynamic>
        ? json['nutrition'] as Map<String, dynamic>
        : json;

    return FoodProduct(
      barcode: json['barcode']?.toString() ?? '',
      name: _firstNonEmpty([
        json['name'],
        json['product_name'],
      ], fallback: 'Unknown Product'),
      brand: _firstNonEmpty([
        json['brand'],
        json['brands'],
      ], fallback: 'Unknown Brand'),
      imageUrl: _firstNonEmpty([
        json['imageUrl'],
        json['image_url'],
      ]),
      ingredients: _firstNonEmpty([
        json['ingredients'],
        json['ingredients_text'],
      ]),
      allergens: _parseAllergens(json['allergens']),
      calories: _toDouble(nutrition['calories'] ?? json['calories']),
      protein: _toDouble(nutrition['protein'] ?? json['protein']),
      carbohydrates: _toDouble(nutrition['carbohydrates'] ?? json['carbohydrates']),
      fat: _toDouble(nutrition['fat'] ?? json['fat']),
      saturatedFat: _toDouble(nutrition['saturatedFat'] ?? json['saturated_fat']),
      fiber: _toDouble(nutrition['fiber'] ?? json['fiber']),
      sugar: _toDouble(nutrition['sugar'] ?? json['sugar']),
      sodium: _toDouble(nutrition['sodium'] ?? json['sodium']),
      salt: _toDouble(nutrition['salt'] ?? json['salt']),
      servingSize: _firstNonEmpty([json['servingSize'], json['serving_size']]),
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

    return FoodProduct(
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
      claims: mergedClaims,
      source: source ?? other.source ?? 'Multi-Source Merged',
      discrepancies: mergedDiscrepancies.toSet().toList(),
      nutriScore: resolvedNutriScore,
      novaGroup: _mergePositiveInt(novaGroup, other.novaGroup),
    );
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
    List<String>? claims,
    String? source,
    List<String>? discrepancies,
    String? nutriScore,
    int? novaGroup,
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
      claims: claims ?? this.claims,
      source: source ?? this.source,
      discrepancies: discrepancies ?? this.discrepancies,
      nutriScore: nutriScore ?? this.nutriScore,
      novaGroup: novaGroup ?? this.novaGroup,
    );
  }

  /// Calculates the product data confidence based on field completeness and verification.
  DataConfidence get dataConfidence {
    int total = 7;
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

  /// Returns true if any major nutrient value is null or <= 0, or if ingredients are missing.
  bool get hasMissingOrZeroNutrients {
    if (calories == null || calories! <= 0) return true;
    if (protein == null || protein! <= 0) return true;
    if (carbohydrates == null || carbohydrates! <= 0) return true;
    if (fat == null || fat! <= 0) return true;
    if (fiber == null || fiber! <= 0) return true;
    if (sugar == null || sugar! <= 0) return true;
    if (sodium == null || sodium! <= 0) return true;
    if (ingredients.trim().isEmpty) return true;
    return false;
  }

  /// Returns true when all primary nutrient fields and metadata are present and non-zero.
  bool get isComplete {
    return !hasMissingOrZeroNutrients &&
        _isValidText(name) &&
        _isValidBrand(brand) &&
        imageUrl.trim().isNotEmpty;
  }

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