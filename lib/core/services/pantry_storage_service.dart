import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../model/food_product.dart';

/// Persists products added to the user's pantry on this device.
class PantryStorageService {
  PantryStorageService._();
  static final PantryStorageService instance = PantryStorageService._();

  static const _storageKey = 'diet_compass_pantry_products';
  static const _storage = FlutterSecureStorage();

  Future<List<FoodProduct>> getProducts() async {
    final raw = await _storage.read(key: _storageKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((item) => FoodProduct.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> isProductInPantry(FoodProduct product) async {
    final products = await getProducts();
    final key = product.barcode.trim().isNotEmpty
        ? product.barcode.trim()
        : '${product.name.trim().toLowerCase()}|${product.brand.trim().toLowerCase()}';

    return products.any((item) {
      final itemKey = item.barcode.trim().isNotEmpty
          ? item.barcode.trim()
          : '${item.name.trim().toLowerCase()}|${item.brand.trim().toLowerCase()}';
      return itemKey == key;
    });
  }

  Future<void> addProduct(FoodProduct product) async {
    final products = await getProducts();
    final key = product.barcode.trim().isNotEmpty
        ? product.barcode.trim()
        : '${product.name.trim().toLowerCase()}|${product.brand.trim().toLowerCase()}';

    final alreadySaved = products.any((item) {
      final itemKey = item.barcode.trim().isNotEmpty
          ? item.barcode.trim()
          : '${item.name.trim().toLowerCase()}|${item.brand.trim().toLowerCase()}';
      return itemKey == key;
    });
    if (alreadySaved) return;

    products.add(product);
    await _storage.write(
      key: _storageKey,
      value: jsonEncode(products.map(_toJson).toList()),
    );
  }

  Map<String, dynamic> _toJson(FoodProduct product) => {
        'barcode': product.barcode,
        'name': product.name,
        'brand': product.brand,
        'imageUrl': product.imageUrl,
        'ingredients': product.ingredients,
        'allergens': product.allergens,
        'calories': product.calories,
        'protein': product.protein,
        'carbohydrates': product.carbohydrates,
        'fat': product.fat,
        'fiber': product.fiber,
        'sugar': product.sugar,
        'sodium': product.sodium,
        'nutriScore': product.nutriScore,
        'novaGroup': product.novaGroup,
      };
}
