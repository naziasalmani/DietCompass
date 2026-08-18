import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/food_product.dart';

class USDAFoodService {
  // Replace this with your own Data.gov API key.
  static const String _apiKey = 'gMhZc1ZStMR8uppaAqHxuLXGAjTb6zLlgrQnsael';

  static const String _baseUrl =
      'https://api.nal.usda.gov/fdc/v1';

  /// Search USDA FoodData Central by barcode / GTIN / UPC.
  Future<FoodProduct?> getProductByBarcode(String barcode) async {
    if (barcode.trim().isEmpty) {
      return null;
    }

    try {
      final query = Uri.encodeQueryComponent(barcode.trim());

      final url = Uri.parse(
        '$_baseUrl/foods/search'
        '?api_key=$_apiKey'
        '&query=$query'
        '&dataType=Branded'
        '&pageSize=10',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        print(
          'USDA barcode search failed: ${response.statusCode}',
        );
        return null;
      }

      final data =
          jsonDecode(response.body) as Map<String, dynamic>;

      final foods = data['foods'];

      if (foods is! List || foods.isEmpty) {
        return null;
      }

      // Look for an exact GTIN/UPC match first.
      for (final item in foods) {
        if (item is! Map<String, dynamic>) continue;

        final gtin = item['gtinUpc']?.toString().trim();

        if (gtin == barcode.trim()) {
          return _convertToFoodProduct(item);
        }
      }

      // If USDA returned results but no exact match,
      // don't blindly return the first product.
      return null;
    } catch (e) {
      print('USDA barcode search error: $e');
      return null;
    }
  }

  /// Search USDA FoodData Central by product name.
  Future<FoodProduct?> getProductByName(String name) async {
    if (name.trim().isEmpty) {
      return null;
    }

    try {
      final query = Uri.encodeQueryComponent(name.trim());

      final url = Uri.parse(
        '$_baseUrl/foods/search'
        '?api_key=$_apiKey'
        '&query=$query'
        '&dataType=Branded'
        '&pageSize=10',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        print(
          'USDA name search failed: ${response.statusCode}',
        );
        return null;
      }

      final data =
          jsonDecode(response.body) as Map<String, dynamic>;

      final foods = data['foods'];

      if (foods is! List || foods.isEmpty) {
        return null;
      }

      // Prefer a branded result.
      for (final item in foods) {
        if (item is! Map<String, dynamic>) continue;

        final description =
            item['description']?.toString().trim() ?? '';

        if (description.isNotEmpty) {
          return _convertToFoodProduct(item);
        }
      }

      return null;
    } catch (e) {
      print('USDA name search error: $e');
      return null;
    }
  }

  FoodProduct _convertToFoodProduct(
    Map<String, dynamic> item,
  ) {
    final nutrients = item['foodNutrients'];

    double nutrientValue(String nutrientName) {
      if (nutrients is! List) return 0.0;

      for (final nutrient in nutrients) {
        if (nutrient is! Map<String, dynamic>) continue;

        final name =
            nutrient['nutrientName']?.toString().toLowerCase() ?? '';

        if (name == nutrientName.toLowerCase()) {
          final value = nutrient['value'];

          if (value is num) {
            return value.toDouble();
          }

          return double.tryParse(
                value?.toString() ?? '',
              ) ??
              0.0;
        }
      }

      return 0.0;
    }

    final description =
        item['description']?.toString() ?? 'Unknown Product';

    final brandOwner =
        item['brandOwner']?.toString() ?? 'Unknown Brand';

    return FoodProduct(
      barcode: item['gtinUpc']?.toString() ?? '',
      name: description,
      brand: brandOwner,
      imageUrl: '',
      ingredients:
          item['ingredients']?.toString() ?? '',
      allergens: [],

      // USDA branded nutrition values are generally
      // provided per 100g / 100ml depending on the record.
      calories: nutrientValue('Energy'),
      protein: nutrientValue('Protein'),
      carbohydrates:
          nutrientValue('Carbohydrate, by difference'),
      fat: nutrientValue('Total lipid (fat)'),
      fiber:
          nutrientValue('Fiber, total dietary'),
      sugar:
          nutrientValue('Sugars, total including NLEA'),
      sodium: nutrientValue('Sodium'),

      nutriScore: null,
      novaGroup: null,
    );
  }
}