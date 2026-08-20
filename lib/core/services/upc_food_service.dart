import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/food_product.dart';

class UPCFoodService {
  static const String _baseUrl = 'https://upc.dev';

  // UPC.dev currently allows basic product lookups without
  // authentication. We can add an API key later if needed.

  /// Get a product using its barcode.
  ///
  /// Supports UPC-A, EAN-13, GTIN-14 and UPC-E.
  Future<FoodProduct?> getProductByBarcode(
    String barcode,
  ) async {
    final cleanBarcode = barcode.trim();

    if (cleanBarcode.isEmpty) {
      return null;
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/v1/product/$cleanBarcode',
      );

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'DietCompass/1.0',
        },
      );

      if (response.statusCode != 200) {
        print(
          'UPC.dev barcode search failed: '
          '${response.statusCode}',
        );
        return null;
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      /*
       * UPC.dev wraps the product information inside its
       * response data object.
       */
      final dynamic rawData = data['data'];

      if (rawData is! Map<String, dynamic>) {
        return null;
      }

      return _convertToFoodProduct(
        rawData,
        fallbackBarcode: cleanBarcode,
      );
    } catch (e) {
      print('UPC.dev barcode search error: $e');
      return null;
    }
  }

  /// Search for a product by name or brand.
  Future<FoodProduct?> getProductByName(
    String name,
  ) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      return null;
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/v1/search',
      ).replace(
        queryParameters: {
          'q': cleanName,
          'limit': '10',
        },
      );

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'DietCompass/1.0',
        },
      );

      if (response.statusCode != 200) {
        print(
          'UPC.dev name search failed: '
          '${response.statusCode}',
        );
        return null;
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      final dynamic rawData = data['data'];

      if (rawData is! Map<String, dynamic>) {
        return null;
      }

      final products = rawData['products'];

      if (products is! List || products.isEmpty) {
        return null;
      }

      for (final item in products) {
        if (item is! Map<String, dynamic>) {
          continue;
        }

        final product = _convertToFoodProduct(item);

        if (product != null) {
          return product;
        }
      }

      return null;
    } catch (e) {
      print('UPC.dev name search error: $e');
      return null;
    }
  }

  FoodProduct? _convertToFoodProduct(
    Map<String, dynamic> data, {
    String fallbackBarcode = '',
  }) {
    final name =
        data['name']?.toString().trim() ?? '';

    if (name.isEmpty) {
      return null;
    }

    final brand =
        data['brand']?.toString().trim() ??
        'Unknown Brand';

    final imageUrl =
        data['image_url']?.toString().trim() ??
        '';

    return FoodProduct(
      barcode:
          data['barcode']?.toString() ??
          data['upc']?.toString() ??
          data['ean']?.toString() ??
          fallbackBarcode,

      name: name,

      brand: brand.isEmpty
          ? 'Unknown Brand'
          : brand,

      imageUrl: imageUrl,

      ingredients:
          data['ingredients']?.toString() ?? '',

      allergens: _parseAllergens(
        data['allergens'],
      ),

      /*
       * UPC.dev basic product lookup is mainly
       * product/catalog information.
       *
       * If nutrition fields aren't available,
       * keep them as 0 rather than inventing values.
       */
      calories: _toDouble(
        data['calories'],
      ),

      protein: _toDouble(
        data['protein'],
      ),

      carbohydrates: _toDouble(
        data['carbohydrates'],
      ),

      fat: _toDouble(
        data['fat'],
      ),

      fiber: _toDouble(
        data['fiber'],
      ),

      sugar: _toDouble(
        data['sugar'],
      ),

      sodium: _toDouble(
        data['sodium'],
      ),

      nutriScore:
          data['nutriScore']?.toString(),

      novaGroup:
          _toInt(data['novaGroup']),
    );
  }

  static double? _toDouble(
    dynamic value,
  ) {
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

  static int? _toInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }

  static List<String> _parseAllergens(
    dynamic value,
  ) {
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