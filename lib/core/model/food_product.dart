class FoodProduct {
  final String barcode;
  final String name;
  final String brand;
  final String imageUrl;
  final String ingredients;
  final List<String> allergens;

  // Nullable because Open Food Facts may not provide every nutrient.
  final double? calories;
  final double? protein;
  final double? carbohydrates;
  final double? fat;
  final double? fiber;
  final double? sugar;

  // Open Food Facts stores sodium_100g in g/100g.
  final double? sodium;

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
    required this.fiber,
    required this.sugar,
    required this.sodium,
    this.nutriScore,
    this.novaGroup,
  });

  factory FoodProduct.fromOpenFoodFacts(
    Map<String, dynamic> json,
  ) {
    final product = json['product'] ?? {};
    final nutrients = product['nutriments'] ?? {};

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

      // Try several possible image fields.
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

      allergens: _parseAllergens(
        product['allergens'],
      ),

      calories: _toDouble(
        nutrients['energy-kcal_100g'],
      ),

      protein: _toDouble(
        nutrients['proteins_100g'],
      ),

      carbohydrates: _toDouble(
        nutrients['carbohydrates_100g'],
      ),

      fat: _toDouble(
        nutrients['fat_100g'],
      ),

      fiber: _toDouble(
        nutrients['fiber_100g'],
      ),

      sugar: _toDouble(
        nutrients['sugars_100g'],
      ),

      sodium: _toDouble(
        nutrients['sodium_100g'],
      ),

      nutriScore: _firstNonEmpty([
        product['nutriscore_grade'],
        product['nutriscore_score'],
      ]),

      novaGroup: _toInt(
        product['nova_group'],
      ),
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
      fiber: _toDouble(nutrition['fiber'] ?? json['fiber']),
      sugar: _toDouble(nutrition['sugar'] ?? json['sugar']),
      sodium: _toDouble(nutrition['sodium'] ?? json['sodium']),
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
      fiber: _mergePositiveDouble(fiber, other.fiber),
      sugar: _mergePositiveDouble(sugar, other.sugar),
      sodium: _mergePositiveDouble(sodium, other.sodium),
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
    double? fiber,
    double? sugar,
    double? sodium,
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
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      sodium: sodium ?? this.sodium,
      nutriScore: nutriScore ?? this.nutriScore,
      novaGroup: novaGroup ?? this.novaGroup,
    );
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

  // ------------------------------------------------------------
  // Return the first non-empty value from a list.
  // ------------------------------------------------------------
  static String _firstNonEmpty(
    List<dynamic> values, {
    String fallback = '',
  }) {
    for (final value in values) {
      if (value == null) {
        continue;
      }

      final text = value.toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    return fallback;
  }

  // ------------------------------------------------------------
  // Convert dynamic API values into nullable double.
  //
  // IMPORTANT:
  // Missing value = null
  // NOT 0.0
  // ------------------------------------------------------------
  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return double.tryParse(text);
  }

  // ------------------------------------------------------------
  // Convert dynamic API values into nullable int.
  // ------------------------------------------------------------
  static int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString().trim(),
    );
  }

  // ------------------------------------------------------------
  // Parse allergens safely.
  // ------------------------------------------------------------
  static List<String> _parseAllergens(dynamic value) {
    if (value == null) {
      return [];
    }

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