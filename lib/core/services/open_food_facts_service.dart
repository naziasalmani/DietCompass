import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/food_product.dart';

class OpenFoodFactsService {
  static const String _baseUrl =
      'https://world.openfoodfacts.org/api/v2/product';

  static const String _searchUrl =
      'https://world.openfoodfacts.org/cgi/search.pl';

  static const Map<String, String> _headers = {
    'User-Agent': 'DietCompass/1.0',
  };

  // ============================================================
  // BARCODE SEARCH
  // ============================================================

  /// Fetch a food product using its barcode.
  Future<FoodProduct?> getProductByBarcode(
    String barcode,
  ) async {
    try {
      if (barcode.trim().isEmpty) {
        return null;
      }

      final url = Uri.parse(
        '$_baseUrl/${barcode.trim()}.json',
      );

      final response = await http.get(
        url,
        headers: _headers,
      );

      if (response.statusCode != 200) {
        return null;
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      if (data['status'] != 1) {
        return null;
      }

      final product = data['product'];

      if (product is! Map<String, dynamic>) {
        return null;
      }

      print(
        '========== OPEN FOOD FACTS BARCODE RESPONSE ==========',
      );

      print(
        'Product: ${product['product_name']}',
      );

      print(
        'Brand: ${product['brands']}',
      );

      print(
        'Nutrients: ${product['nutriments']}',
      );

      print(
        'Image: ${product['image_front_url']}',
      );

      print(
        '=======================================================',
      );

      return FoodProduct.fromOpenFoodFacts(data);
    } catch (e) {
      print(
        'Open Food Facts Barcode Error: $e',
      );

      return null;
    }
  }

  // ============================================================
  // NAME SEARCH — MULTIPLE RESULTS
  // ============================================================

  /// Search Open Food Facts using a product name.
  ///
  /// Returns multiple products so that the caller can compare
  /// them and select the best matching product.
  Future<List<FoodProduct>> getProductsByName(
    String name, {
    int pageSize = 20,
  }) async {
    try {
      final trimmedName = name.trim();

      if (trimmedName.isEmpty) {
        return [];
      }

      final url = Uri.parse(
        _searchUrl,
      ).replace(
        queryParameters: {
          'search_terms': trimmedName,
          'search_simple': '1',
          'action': 'process',
          'json': '1',
          'page_size': pageSize.toString(),
          'page': '1',
          'fields':
              'code,product_name,product_name_en,brands,brand_owner,'
              'image_front_url,image_front_small_url,'
              'image_front_thumb_url,image_url,'
              'ingredients_text,ingredients_text_en,allergens,'
              'nutriments,nutriscore_grade,nova_group',
        },
      );

      print(
        '========== OPEN FOOD FACTS NAME SEARCH ==========',
      );

      print('Query: $trimmedName');
      print('URL: $url');

      final response = await http
          .get(
            url,
            headers: _headers,
          )
          .timeout(const Duration(seconds: 7));

      if (response.statusCode == 503 || response.statusCode >= 500) {
        print(
          'Name search HTTP status: '
          '${response.statusCode} (server temporary failure)',
        );

        return [];
      }

      if (response.statusCode != 200) {
        print(
          'Name search HTTP status: '
          '${response.statusCode}',
        );

        return [];
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      final products = data['products'];

      if (products is! List ||
          products.isEmpty) {
        print('No products found for "$trimmedName"');

        return [];
      }

      final results = <FoodProduct>[];

      for (final item in products) {
        if (item is! Map<String, dynamic>) {
          continue;
        }

        final productName =
            item['product_name']?.toString().trim() ?? '';

        if (productName.isEmpty) {
          continue;
        }

        try {
          final product =
              FoodProduct.fromOpenFoodFacts({
            'status': 1,
            'code': item['code'] ?? '',
            'product': item,
          });

          results.add(product);
        } catch (e) {
          print(
            'Could not parse search result: $e',
          );
        }
      }

      print(
        'Products returned: ${results.length}',
      );

      print(
        '=================================================',
      );

      return results;
    } catch (e) {
      print(
        'Open Food Facts Name Search Error: $e',
      );

      return [];
    }
  }

  // ============================================================
  // NAME SEARCH — SINGLE RESULT
  // ============================================================

  /// Backwards-compatible method.
  ///
  /// Returns the first product from the search results.
  ///
  /// For OCR/product identification, prefer getProductsByName()
  /// so that multiple results can be compared.
  Future<FoodProduct?> getProductByName(
    String name,
  ) async {
    final products =
        await getProductsByName(
      name,
      pageSize: 20,
    );

    if (products.isEmpty) {
      return null;
    }

    return products.first;
  }
}