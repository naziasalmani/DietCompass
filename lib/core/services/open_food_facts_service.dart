import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/food_product.dart';

class OpenFoodFactsService {
  static const String _baseUrl =
      'https://world.openfoodfacts.org/api/v2/product';

  /// Fetch a food product using its barcode.
  Future<FoodProduct?> getProductByBarcode(String barcode) async {
    try {
      final url = Uri.parse('$_baseUrl/$barcode.json');

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'DietCompass/1.0',
        },
      );

      if (response.statusCode != 200) {
        return null;
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (data['status'] != 1) {
        return null;
      }

      print('========== OPEN FOOD FACTS RESPONSE ==========');
print(data['product']['nutriments']);
print('==============================================');

      return FoodProduct.fromOpenFoodFacts(data);
    } catch (e) {
      print('Open Food Facts Error: $e');
      return null;
    }
  }

  /// Search for a food product using its name.
  Future<FoodProduct?> getProductByName(String name) async {
    try {
      if (name.trim().isEmpty) {
        return null;
      }

      final query = Uri.encodeQueryComponent(name.trim());

      final url = Uri.parse(
        'https://world.openfoodfacts.org/cgi/search.pl'
        '?search_terms=$query'
        '&search_simple=1'
        '&action=process'
        '&json=1'
        '&page_size=1',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'DietCompass/1.0',
        },
      );

      if (response.statusCode != 200) {
        return null;
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      final products = data['products'];

      if (products is! List || products.isEmpty) {
        return null;
      }

      final productData =
          products.first as Map<String, dynamic>;

      return FoodProduct.fromOpenFoodFacts({
        'status': 1,
        'product': productData,
      });
    } catch (e) {
      print('Open Food Facts Name Search Error: $e');
      return null;
    }
  }
}