class FoodProduct {
  final String barcode;
  final String name;
  final String brand;
  final String imageUrl;
  final String ingredients;
  final List<String> allergens;

  // Nullable because some products may not provide every nutrient.
  final double? calories;
  final double? protein;
  final double? carbohydrates;
  final double? fat;
  final double? fiber;
  final double? sugar;
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

  factory FoodProduct.fromOpenFoodFacts(Map<String, dynamic> json) {
    final product = json['product'] ?? {};
    final nutrients = product['nutriments'] ?? {};

    return FoodProduct(
      barcode: json['code']?.toString() ?? '',
      name: product['product_name']?.toString() ?? 'Unknown Product',
      brand: product['brands']?.toString() ?? 'Unknown Brand',
      imageUrl: product['image_front_url']?.toString() ?? '',
      ingredients: product['ingredients_text']?.toString() ?? '',
      allergens: _parseAllergens(product['allergens']),

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

      nutriScore: product['nutriscore_grade']?.toString(),
      novaGroup: _toInt(product['nova_group']),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  static int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }

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

    return [];
  }
}