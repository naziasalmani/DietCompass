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