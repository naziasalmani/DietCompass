import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../model/food_product.dart';
import '../model/health_compass_data.dart';
import '../model/scan_history_item.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'ingredient_intelligence_service.dart';
import 'product_category_service.dart';
import 'recommendation_service.dart';
import 'storage_service.dart';

/// DietCompass — Scan History Service
///
/// Multi-tier synchronization layer for user scan history:
/// 1. Instant local persistence in encrypted secure storage per user.
/// 2. Asynchronous cloud sync with backend `/api/scan-history`.
/// 3. Reactive UI updates via ChangeNotifier.
class ScanHistoryService extends ChangeNotifier {
  ScanHistoryService._();
  static final ScanHistoryService instance = ScanHistoryService._();

  List<ScanHistoryItem> _cachedHistory = [];

  /// In-memory cached scan history for synchronous UI access.
  List<ScanHistoryItem> get currentHistory => List.unmodifiable(_cachedHistory);

  /// Clears in-memory scan history cache upon logout or user session switch.
  void clearCache() {
    _cachedHistory.clear();
    notifyListeners();
  }

  /// Helper to get the current authenticated user's ID
  String _getCurrentUserId() {
    final user = AuthService.instance.currentUser;
    return user?.id ?? 'guest_user';
  }

  /// Load scan history from local secure storage
  Future<List<ScanHistoryItem>> _loadFromLocalStorage() async {
    try {
      final userId = _getCurrentUserId();
      final jsonStr = await StorageService.instance.getLocalScanHistory(userId);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr);
        final items = list
            .whereType<Map<String, dynamic>>()
            .map((j) => ScanHistoryItem.fromJson(j))
            .toList();
        if (items.isNotEmpty) {
          _cachedHistory = List.from(items);
          notifyListeners();
        }
        return items;
      }
    } catch (e) {
      debugPrint('[ScanHistoryService] Local storage read error: $e');
    }
    return _cachedHistory;
  }

  /// Persist current in-memory history to local secure storage
  Future<void> _saveToLocalStorage() async {
    try {
      final userId = _getCurrentUserId();
      final jsonStr = jsonEncode(
        _cachedHistory.map((item) => item.toJson()).toList(),
      );
      await StorageService.instance.saveLocalScanHistory(userId, jsonStr);
    } catch (e) {
      debugPrint('[ScanHistoryService] Local storage write error: $e');
    }
  }

  /// Fetches scan history for the authenticated user from local storage and the backend.
  Future<List<ScanHistoryItem>> getScanHistory({
    bool forceRefresh = false,
    int? limit,
  }) async {
    // If local cache is empty, load from encrypted on-device storage first
    if (_cachedHistory.isEmpty) {
      await _loadFromLocalStorage();
    }

    if (!forceRefresh && _cachedHistory.isNotEmpty && limit == null) {
      return _cachedHistory;
    }

    final userId = _getCurrentUserId();

    try {
      final endpoint =
          limit != null ? '/scan-history?limit=$limit' : '/scan-history';

      final response = await ApiService.instance.get(
        endpoint,
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final resData =
            response.data!['data'] as Map<String, dynamic>? ?? response.data!;
        final rawScans = resData['scans'] as List<dynamic>? ?? [];
        final totalCount = (resData['totalCount'] is num)
            ? (resData['totalCount'] as num).toInt()
            : rawScans.length;

        final items = rawScans
            .whereType<Map<String, dynamic>>()
            .map((json) => ScanHistoryItem.fromJson(json))
            .toList();

        if (limit == null || _cachedHistory.isEmpty) {
          _cachedHistory = List.from(items);
        } else {
          // Merge items into cached history
          for (final item in items) {
            final idx = _cachedHistory.indexWhere((c) =>
                (item.barcode.isNotEmpty && c.barcode == item.barcode) ||
                (c.productName.toLowerCase() == item.productName.toLowerCase() &&
                    c.brand.toLowerCase() == item.brand.toLowerCase()));
            if (idx >= 0) {
              _cachedHistory[idx] = item;
            } else {
              _cachedHistory.add(item);
            }
          }
        }

        await _saveToLocalStorage();
        notifyListeners();

        if (limit != null && limit <= 10) {
          debugPrint('\n==============================================');
          debugPrint('[HOME RECENT SCANS]');
          debugPrint('userId = $userId');
          debugPrint('historyCount = ${items.length}');
          debugPrint(
              'latestScan = ${items.isNotEmpty ? items.first.productName : 'None'}');
          debugPrint('==============================================\n');
        }

        debugPrint('\n==============================================');
        debugPrint('[SCAN HISTORY]');
        debugPrint('userId = $userId');
        debugPrint('totalHistoryCount = $totalCount');
        debugPrint('==============================================\n');

        return items;
      }
    } catch (e) {
      debugPrint('[ScanHistoryService] Cloud sync error (using local storage): $e');
    }

    return _cachedHistory;
  }

  /// Persists a successfully resolved product scan to local storage and the backend.
  Future<ScanHistoryItem?> saveScan(
    FoodProduct product, {
    int? score,
  }) async {
    if (product.name.trim().isEmpty) return null;

    final userId = _getCurrentUserId();
    final now = DateTime.now();

    final nutrients = <String, dynamic>{
      if (product.calories != null) 'calories': product.calories,
      if (product.protein != null) 'protein': product.protein,
      if (product.carbohydrates != null)
        'carbohydrates': product.carbohydrates,
      if (product.fat != null) 'fat': product.fat,
      if (product.fiber != null) 'fiber': product.fiber,
      if (product.sugar != null) 'sugar': product.sugar,
      if (product.sodium != null) 'sodium': product.sodium,
    };

    // 1. Create immediate local record
    var localItem = ScanHistoryItem(
      id: 'local_${now.millisecondsSinceEpoch}',
      userId: userId,
      barcode: product.barcode.trim(),
      productName: product.name.trim(),
      brand: product.brand.trim(),
      imageUrl: product.imageUrl.trim(),
      score: score ?? 85,
      ingredients: product.ingredients.trim(),
      allergens: List.from(product.allergens),
      nutrients: nutrients,
      scannedAt: now,
    );

    // 2. Update in-memory cache immediately (remove duplicate, insert at front)
    _cachedHistory.removeWhere((item) =>
        (localItem.barcode.isNotEmpty && item.barcode == localItem.barcode) ||
        (item.productName.toLowerCase() == localItem.productName.toLowerCase() &&
            item.brand.toLowerCase() == localItem.brand.toLowerCase()));
    _cachedHistory.insert(0, localItem);

    // 3. Save to encrypted device storage immediately
    await _saveToLocalStorage();

    // 4. Notify all UI listeners immediately (HomeScreen, ScanScreen, ScanHistoryScreen)
    notifyListeners();

    debugPrint('\n==============================================');
    debugPrint('[SCAN HISTORY SAVE]');
    debugPrint('userId = $userId');
    debugPrint('productName = ${localItem.productName}');
    debugPrint(
        'productId/barcode = ${localItem.barcode.isNotEmpty ? localItem.barcode : 'N/A'}');
    debugPrint('timestamp = ${localItem.scannedAt.toIso8601String()}');
    debugPrint('==============================================\n');

    // 5. Cloud sync in background
    try {
      final payload = {
        'productName': product.name.trim(),
        'brand': product.brand.trim(),
        'barcode': product.barcode.trim(),
        'imageUrl': product.imageUrl.trim(),
        'score': score ?? 85,
        'ingredients': product.ingredients.trim(),
        'allergens': product.allergens,
        'nutrients': nutrients,
      };

      final response = await ApiService.instance.post(
        '/scan-history',
        body: payload,
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final resData =
            response.data!['data'] as Map<String, dynamic>? ?? response.data!;
        final scanJson = resData['scan'] as Map<String, dynamic>? ?? resData;
        final serverItem = ScanHistoryItem.fromJson(scanJson);

        // Update local cache with server record ID
        final idx = _cachedHistory.indexOf(localItem);
        if (idx >= 0) {
          _cachedHistory[idx] = serverItem;
        }
        await _saveToLocalStorage();
        notifyListeners();
        return serverItem;
      }
    } catch (e) {
      debugPrint('[ScanHistoryService] Backend sync error (scan is saved locally): $e');
    }

    return localItem;
  }

  /// Dynamically computes the 5 "Your Health Compass" metrics strictly from the authenticated user's scan history.
  HealthCompassData computeHealthCompass({List<ScanHistoryItem>? customHistory}) {
    final history = customHistory ?? _cachedHistory;
    if (history.isEmpty) {
      return HealthCompassData.empty();
    }

    // 1. AVERAGE COMPATIBILITY
    // Real arithmetic mean of all compatibility scores belonging to the authenticated user
    final totalScore = history.fold<int>(0, (sum, item) => sum + item.score);
    final avgScore = (totalScore / history.length).round().clamp(0, 100);

    // 2. PRODUCTS ANALYZED (Count of unique real products analyzed by the current user)
    final uniqueProductsMap = <String, FoodProduct>{};
    final uniqueProductNames = <String>[];

    for (final item in history) {
      final key = item.barcode.isNotEmpty
          ? item.barcode.trim()
          : '${item.productName.trim().toLowerCase()}_${item.brand.trim().toLowerCase()}';
      if (!uniqueProductsMap.containsKey(key)) {
        final product = item.toFoodProduct();
        uniqueProductsMap[key] = product;
        uniqueProductNames.add(item.productName.trim());
      }
    }
    final productsAnalyzedCount = uniqueProductsMap.length;

    // 3. INGREDIENTS FLAGGED
    // Real ingredients flagged across user's analyzed products via IngredientIntelligenceService + allergens + elevated sodium
    final flaggedIngredients = <String>{};
    for (final product in uniqueProductsMap.values) {
      final intel = IngredientIntelligenceService.instance.analyze(product);

      // Sugar-related ingredients
      for (final s in intel.sugarRelatedIngredients) {
        if (s.name.trim().isNotEmpty) {
          flaggedIngredients.add(s.name.trim().toLowerCase());
        }
      }
      // Food additives & preservatives
      for (final a in intel.additives) {
        if (a.name.trim().isNotEmpty) {
          flaggedIngredients.add(a.name.trim().toLowerCase());
        }
      }
      // Low-calorie / artificial sweeteners
      for (final sw in intel.artificialSweeteners) {
        if (sw.name.trim().isNotEmpty) {
          flaggedIngredients.add(sw.name.trim().toLowerCase());
        }
      }
      // Product Allergens
      for (final allergen in product.allergens) {
        if (allergen.trim().isNotEmpty) {
          flaggedIngredients.add(allergen.trim().toLowerCase());
        }
      }
      // Elevated sodium alert (>= 400 mg / 100g)
      final sodiumVal = product.sodium;
      if (sodiumVal != null) {
        final sodiumMg = sodiumVal <= 10.0 ? sodiumVal * 1000.0 : sodiumVal;
        if (sodiumMg >= 400.0) {
          flaggedIngredients.add('high sodium');
        }
      }
    }

    // 4. BETTER ALTERNATIVES
    // Count of real healthier alternatives / recommendations available for analyzed products
    final uniqueAlternatives = <String>{};
    for (final product in uniqueProductsMap.values) {
      try {
        final category = ProductCategoryService.instance.classifyProduct(product);
        final fallbacks = RecommendationService.instance.getCategoryFallbackProducts(category);
        final currentScore = RecommendationService.instance.calculateCompatibilityScore(product);
        final alts = RecommendationService.instance.filterAndRankAlternatives(
          currentProduct: product,
          candidates: fallbacks,
          limit: 6,
        );
        for (final alt in alts) {
          final isHigherScore = alt.compatibility.score > currentScore;
          final hasNutrImprovement = alt.nutritionComparison != null &&
              (alt.nutritionComparison!.sugarDiff > 0 ||
                  alt.nutritionComparison!.proteinDiff > 0 ||
                  alt.nutritionComparison!.fiberDiff > 0 ||
                  alt.nutritionComparison!.calorieDiff > 0 ||
                  alt.nutritionComparison!.sodiumDiff > 0);
          if (isHigherScore || hasNutrImprovement) {
            final altKey = alt.product.barcode.isNotEmpty
                ? alt.product.barcode
                : '${alt.product.name.trim().toLowerCase()}_${alt.product.brand.trim().toLowerCase()}';
            uniqueAlternatives.add(altKey);
          }
        }
      } catch (e) {
        debugPrint('[ScanHistoryService] Health compass alt calculation error: $e');
      }
    }

    // 5. SCANS THIS WEEK
    // Real product scans performed by the current user during the last 7 days
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final scansThisWeek = history.where((item) {
      return item.scannedAt.isAfter(sevenDaysAgo) &&
          item.scannedAt.isBefore(now.add(const Duration(minutes: 5)));
    }).length;

    return HealthCompassData(
      averageCompatibility: avgScore,
      productsAnalyzed: productsAnalyzedCount,
      ingredientsFlagged: flaggedIngredients.length,
      betterAlternatives: uniqueAlternatives.length,
      scansThisWeek: scansThisWeek,
      flaggedIngredientNames: flaggedIngredients.toList(),
      uniqueProductNames: uniqueProductNames,
    );
  }
}

