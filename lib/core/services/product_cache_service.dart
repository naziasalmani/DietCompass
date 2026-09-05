import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../model/food_product.dart';

/// DietCompass — Persistent Product Cache Service
/// Caches canonical FoodProduct objects locally keyed by normalized barcode.
/// Prevents redundant external food API calls (Open Food Facts, USDA, UPC, Gemini)
/// across app restarts while serving deterministic, instant product lookups.
class ProductCacheService {
  ProductCacheService._();
  static final ProductCacheService instance = ProductCacheService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Default cache freshness threshold: 7 days.
  static const Duration defaultFreshnessDuration = Duration(days: 7);

  /// Fast in-memory cache for the active session.
  final Map<String, FoodProduct> _memoryCache = {};

  String _storageKey(String barcode) {
    final clean = barcode.trim();
    return 'dc_product_cache_$clean';
  }

  /// Normalizes and cleans a barcode string.
  String normalizeBarcode(String rawBarcode) {
    return rawBarcode.trim();
  }

  /// Inspect the local Product Cache for a normalized barcode BEFORE external network calls.
  /// Returns cached product immediately if valid, sufficiently complete, and fresh.
  Future<FoodProduct?> getProduct(
    String barcode, {
    Duration maxAge = defaultFreshnessDuration,
  }) async {
    final cleanBarcode = normalizeBarcode(barcode);
    if (cleanBarcode.isEmpty) return null;

    debugPrint('[CACHE] Checking product cache for barcode: $cleanBarcode');

    // 1. Fast in-memory lookup
    if (_memoryCache.containsKey(cleanBarcode)) {
      final cached = _memoryCache[cleanBarcode]!;
      if (_isValidAndFresh(cached, maxAge)) {
        debugPrint('[CACHE HIT] Product found locally: $cleanBarcode');
        debugPrint('[CACHE] Returning cached product without external API calls');
        return cached;
      }
    }

    // 2. Persistent local secure storage lookup
    try {
      final key = _storageKey(cleanBarcode);
      final rawJson = await _storage.read(key: key);
      if (rawJson == null || rawJson.isEmpty) {
        debugPrint('[CACHE MISS] Product not found locally: $cleanBarcode');
        return null;
      }

      final Map<String, dynamic> jsonMap = jsonDecode(rawJson);
      final product = FoodProduct.fromJson(jsonMap);

      if (_isValidAndFresh(product, maxAge)) {
        debugPrint('[CACHE HIT] Product found locally: $cleanBarcode');
        debugPrint('[CACHE] Returning cached product without external API calls');
        _memoryCache[cleanBarcode] = product;
        return product;
      } else {
        debugPrint('[CACHE MISS] Product found locally but stale or incomplete: $cleanBarcode');
        return null;
      }
    } catch (e) {
      debugPrint('[CACHE] Error reading product cache for $cleanBarcode: $e');
      debugPrint('[CACHE MISS] Product not found locally: $cleanBarcode');
      return null;
    }
  }

  /// Save the final merged canonical product to persistent cache.
  Future<void> saveProduct(FoodProduct product) async {
    final cleanBarcode = normalizeBarcode(product.barcode);
    if (cleanBarcode.isEmpty) return;

    final canonicalProduct = product.copyWith(
      barcode: cleanBarcode,
      cachedAt: DateTime.now(),
      completenessStatus: product.hasMissingOrZeroNutrients ? 'partial' : 'complete',
    );

    _memoryCache[cleanBarcode] = canonicalProduct;

    try {
      final key = _storageKey(cleanBarcode);
      final jsonString = jsonEncode(canonicalProduct.toJson());
      await _storage.write(key: key, value: jsonString);
      debugPrint('[CACHE SAVE] Saving final canonical product: $cleanBarcode');
    } catch (e) {
      debugPrint('[CACHE] Error saving product to cache for $cleanBarcode: $e');
    }
  }

  /// Removes a cached product from memory and persistent storage.
  Future<void> clearProduct(String barcode) async {
    final cleanBarcode = normalizeBarcode(barcode);
    if (cleanBarcode.isEmpty) return;
    _memoryCache.remove(cleanBarcode);
    try {
      await _storage.delete(key: _storageKey(cleanBarcode));
    } catch (e) {
      debugPrint('[CACHE] Error clearing product cache for $cleanBarcode: $e');
    }
  }

  /// Checks whether a cached product is valid, sufficiently complete, and fresh.
  bool _isValidAndFresh(FoodProduct product, Duration maxAge) {
    if (product.name.trim().isEmpty || product.name.toLowerCase() == 'unknown product') {
      return false;
    }

    if (product.hasMissingOrZeroNutrients) {
      return false;
    }

    if (product.cachedAt != null) {
      final age = DateTime.now().difference(product.cachedAt!);
      if (age > maxAge) {
        return false;
      }
    }

    return true;
  }
}
