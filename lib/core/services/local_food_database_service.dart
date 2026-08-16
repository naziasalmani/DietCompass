import 'dart:convert';

import 'package:flutter/services.dart';

import '../model/food_product.dart';

class LocalFoodDatabaseService {
  static const String _databasePath =
      'lib/core/services/food_database.json';

  Future<List<FoodProduct>> _loadProducts() async {
    try {
      final jsonString = await rootBundle.loadString(_databasePath);

      final List<dynamic> data = jsonDecode(jsonString);

      return data
          .map(
            (item) => FoodProduct.fromOpenFoodFacts({
              'status': 1,
              'product': item,
            }),
          )
          .toList();
    } catch (e) {
      print('Local Food Database Error: $e');
      return [];
    }
  }

  Future<FoodProduct?> getProductByBarcode(String barcode) async {
    final cleanBarcode = barcode.trim();

    if (cleanBarcode.isEmpty) {
      return null;
    }

    final products = await _loadProducts();

    try {
      return products.firstWhere(
        (product) =>
            product.barcode.trim() == cleanBarcode,
      );
    } catch (_) {
      return null;
    }
  }

  Future<FoodProduct?> getProductByName(String name) async {
    final cleanName = name.trim().toLowerCase();

    if (cleanName.isEmpty) {
      return null;
    }

    final products = await _loadProducts();

    try {
      return products.firstWhere(
        (product) {
          final productName = product.name.toLowerCase();
          final brand = product.brand.toLowerCase();

          return productName.contains(cleanName) ||
              cleanName.contains(productName) ||
              brand.contains(cleanName);
        },
      );
    } catch (_) {
      return null;
    }
  }
}