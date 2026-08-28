import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../model/food_product.dart';
import 'auth_service.dart';

/// Persists products added to the user's pantry on this device, strictly scoped per user account.
class PantryStorageService {
  PantryStorageService._();
  static final PantryStorageService instance = PantryStorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Helper to get the current authenticated user's ID
  String _getCurrentUserId([String? explicitUserId]) {
    if (explicitUserId != null && explicitUserId.trim().isNotEmpty) {
      return explicitUserId.trim();
    }
    final user = AuthService.instance.currentUser;
    return user?.id ?? 'guest_user';
  }

  String _getStorageKey([String? explicitUserId]) {
    final uid = _getCurrentUserId(explicitUserId);
    return 'diet_compass_pantry_products_$uid';
  }

  /// Retrieves the list of pantry food products for the specified (or currently authenticated) user.
  Future<List<FoodProduct>> getProducts({String? userId}) async {
    final key = _getStorageKey(userId);
    final raw = await _storage.read(key: key);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((item) => FoodProduct.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      debugPrint('[PantryStorageService] Error decoding pantry items: $e');
      return [];
    }
  }

  /// Checks if a product is in the user's pantry.
  Future<bool> isProductInPantry(FoodProduct product, {String? userId}) async {
    final products = await getProducts(userId: userId);
    final key = _makeProductKey(product.barcode, product.name, product.brand);

    return products.any((item) {
      final itemKey = _makeProductKey(item.barcode, item.name, item.brand);
      return itemKey == key;
    });
  }

  /// Adds a product to the user's persistent pantry.
  Future<void> addProduct(FoodProduct product, {String? userId}) async {
    final products = await getProducts(userId: userId);
    final key = _makeProductKey(product.barcode, product.name, product.brand);

    final alreadySaved = products.any((item) {
      final itemKey = _makeProductKey(item.barcode, item.name, item.brand);
      return itemKey == key;
    });
    if (alreadySaved) return;

    products.add(product);
    final storageKey = _getStorageKey(userId);
    await _storage.write(
      key: storageKey,
      value: jsonEncode(products.map(_toJson).toList()),
    );
  }

  /// Removes a product from the user's persistent pantry.
  Future<void> removeProduct(FoodProduct product, {String? userId}) async {
    await removeProductByName(
      product.name,
      barcode: product.barcode,
      userId: userId,
    );
  }

  /// Removes a product by name or barcode from the user's persistent pantry.
  Future<void> removeProductByName(
    String name, {
    String? barcode,
    String? userId,
  }) async {
    final products = await getProducts(userId: userId);
    final cleanName = name.trim().toLowerCase();
    final cleanBarcode = (barcode ?? '').trim();

    products.removeWhere((item) {
      if (cleanBarcode.isNotEmpty) {
        return item.barcode.trim() == cleanBarcode;
      }
      return item.name.trim().toLowerCase() == cleanName;
    });

    final storageKey = _getStorageKey(userId);
    await _storage.write(
      key: storageKey,
      value: jsonEncode(products.map(_toJson).toList()),
    );
  }

  /// Clears the entire pantry for a specific user (or current user).
  Future<void> clearPantry({String? userId}) async {
    final storageKey = _getStorageKey(userId);
    await _storage.delete(key: storageKey);
  }

  String _makeProductKey(String barcode, String name, String brand) {
    if (barcode.trim().isNotEmpty) {
      return barcode.trim();
    }
    return '${name.trim().toLowerCase()}|${brand.trim().toLowerCase()}';
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
    'nutritionBasis': product.normalizedBasisLabel,
    'nutriScore': product.nutriScore,
    'novaGroup': product.novaGroup,
  };
}
