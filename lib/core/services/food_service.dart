import '../model/food_product.dart';
import 'open_food_facts_service.dart';
import 'usda_food_service.dart';
import 'upc_food_service.dart';
import 'local_food_database_service.dart';
import 'ai_service.dart';
import 'product_cache_service.dart';

class FoodService {
  final OpenFoodFactsService _openFoodFactsService =
      OpenFoodFactsService();

  final USDAFoodService _usdaFoodService =
      USDAFoodService();

  final UPCFoodService _upcFoodService =
      UPCFoodService();

  final LocalFoodDatabaseService _localDatabaseService =
      LocalFoodDatabaseService();

  // ============================================================
  // BARCODE SEARCH
  // Cascading Multi-API: Product Cache → Open Food Facts → USDA → UPC → Local Database → Gemini AI
  // Keeps non-null & non-zero values from API 1 and enriches zero/missing values from subsequent APIs.
  // Saves the final canonical merged product to the Product Cache.
  // ============================================================

  Future<FoodProduct?> getFoodByBarcode(
    String barcode,
  ) async {
    final cleanBarcode = barcode.trim();

    if (cleanBarcode.isEmpty) {
      return null;
    }

    // 0. DietCompass Product Cache (Check persistent local cache before any network calls)
    final cachedProduct = await ProductCacheService.instance.getProduct(cleanBarcode);
    if (cachedProduct != null) {
      return cachedProduct;
    }

    FoodProduct? mergedProduct;

    // 1. Open Food Facts (Primary API)
    try {
      print('[FOOD API] Querying Open Food Facts...');
      final product =
          await _openFoodFactsService.getProductByBarcode(
        cleanBarcode,
      );

      if (product != null) {
        print(
          '✅ PRODUCT SOURCE: OPEN FOOD FACTS (Barcode: $cleanBarcode)',
        );

        mergedProduct = product;

        // If product already has all positive nutrients and is complete, save to cache and return early
        if (mergedProduct.isComplete && !mergedProduct.hasMissingOrZeroNutrients) {
          await ProductCacheService.instance.saveProduct(mergedProduct);
          return mergedProduct;
        }

        print(
          'ℹ️ [FoodService] Open Food Facts has zero/missing values. Querying subsequent APIs for enrichment...',
        );
      }
    } catch (e) {
      print(
        'Open Food Facts failed: $e',
      );
    }

    // 2. USDA FoodData Central (Enrich missing/zero fields)
    if (mergedProduct == null || mergedProduct.hasMissingOrZeroNutrients) {
      try {
        print('[FOOD API] Querying USDA for enrichment...');
        var usdaProduct =
            await _usdaFoodService.getProductByBarcode(
          cleanBarcode,
        );

        if (usdaProduct == null &&
            mergedProduct != null &&
            mergedProduct.name.isNotEmpty &&
            mergedProduct.name.toLowerCase() != 'unknown product') {
          usdaProduct =
              await _usdaFoodService.getProductByName(
            mergedProduct.name,
          );
        }

        if (usdaProduct != null) {
          print(
            '✅ PRODUCT SOURCE: USDA (Enriched/Found)',
          );

          mergedProduct = mergedProduct == null
              ? usdaProduct
              : mergedProduct.mergeWith(usdaProduct);

          if (mergedProduct.isComplete && !mergedProduct.hasMissingOrZeroNutrients) {
            await ProductCacheService.instance.saveProduct(mergedProduct);
            return mergedProduct;
          }
        }
      } catch (e) {
        print(
          'USDA failed: $e',
        );
      }
    }

    // 3. UPC.dev (Enrich remaining zero/missing fields)
    if (mergedProduct == null || mergedProduct.hasMissingOrZeroNutrients) {
      try {
        print('[FOOD API] Querying UPC for enrichment...');
        var upcProduct =
            await _upcFoodService.getProductByBarcode(
          cleanBarcode,
        );

        if (upcProduct == null &&
            mergedProduct != null &&
            mergedProduct.name.isNotEmpty &&
            mergedProduct.name.toLowerCase() != 'unknown product') {
          upcProduct =
              await _upcFoodService.getProductByName(
            mergedProduct.name,
          );
        }

        if (upcProduct != null) {
          print(
            '✅ PRODUCT SOURCE: UPC (Enriched/Found)',
          );

          mergedProduct = mergedProduct == null
              ? upcProduct
              : mergedProduct.mergeWith(upcProduct);

          if (mergedProduct.isComplete && !mergedProduct.hasMissingOrZeroNutrients) {
            await ProductCacheService.instance.saveProduct(mergedProduct);
            return mergedProduct;
          }
        }
      } catch (e) {
        print(
          'UPC failed: $e',
        );
      }
    }

    // 4. Local Database (Final local database fallback / enrichment)
    if (mergedProduct == null || mergedProduct.hasMissingOrZeroNutrients) {
      try {
        print('[LOCAL DB] Querying local food database...');
        var localProduct =
            await _localDatabaseService.getProductByBarcode(
          cleanBarcode,
        );

        if (localProduct == null &&
            mergedProduct != null &&
            mergedProduct.name.isNotEmpty &&
            mergedProduct.name.toLowerCase() != 'unknown product') {
          localProduct =
              await _localDatabaseService.getProductByName(
            mergedProduct.name,
          );
        }

        if (localProduct != null) {
          print(
            '✅ PRODUCT SOURCE: LOCAL DATABASE (Enriched/Found)',
          );

          mergedProduct = mergedProduct == null
              ? localProduct
              : mergedProduct.mergeWith(localProduct);

          if (mergedProduct.isComplete && !mergedProduct.hasMissingOrZeroNutrients) {
            await ProductCacheService.instance.saveProduct(mergedProduct);
            return mergedProduct;
          }
        }
      } catch (e) {
        print(
          'Local database failed: $e',
        );
      }
    }

    // 5. Gemini AI Fallback & Enrichment (when information is unavailable in any API)
    if (mergedProduct == null || mergedProduct.hasMissingOrZeroNutrients) {
      try {
        print('[GEMINI AI] Querying Gemini AI fallback...');
        final geminiProduct = await AiService.instance.lookupProductWithGemini(
          barcode: cleanBarcode,
          partialProduct: mergedProduct,
        );

        if (geminiProduct != null) {
          print('✅ PRODUCT SOURCE: GEMINI AI (Enriched/Found)');
          mergedProduct = mergedProduct == null
              ? geminiProduct
              : mergedProduct.mergeWith(geminiProduct);
        }
      } catch (e) {
        print('Gemini AI fallback failed: $e');
      }
    }

    if (mergedProduct != null) {
      await ProductCacheService.instance.saveProduct(mergedProduct);
      return mergedProduct;
    }

    print(
      '❌ PRODUCT NOT FOUND: $cleanBarcode',
    );

    return null;
  }

  // ============================================================
  // ENRICH PRODUCT HELPER
  // ============================================================

  /// Enriches a [FoodProduct] by querying fallback sources (USDA, UPC, Local DB, Gemini AI)
  /// to fill in any missing, null, or zero nutrition and metadata values.
  Future<FoodProduct> enrichProduct(FoodProduct product) async {
    if (product.isComplete && !product.hasMissingOrZeroNutrients) {
      return product;
    }

    var enriched = product;

    // 1. Try USDA
    if (enriched.hasMissingOrZeroNutrients) {
      try {
        FoodProduct? usdaProduct;
        if (enriched.barcode.trim().isNotEmpty) {
          usdaProduct =
              await _usdaFoodService.getProductByBarcode(enriched.barcode);
        }
        if (usdaProduct == null &&
            enriched.name.trim().isNotEmpty &&
            enriched.name.toLowerCase() != 'unknown product') {
          usdaProduct =
              await _usdaFoodService.getProductByName(enriched.name);
        }
        if (usdaProduct != null) {
          enriched = enriched.mergeWith(usdaProduct);
          if (enriched.isComplete && !enriched.hasMissingOrZeroNutrients) {
            return enriched;
          }
        }
      } catch (e) {
        print('USDA product enrichment error: $e');
      }
    }

    // 2. Try UPC.dev
    if (enriched.hasMissingOrZeroNutrients) {
      try {
        FoodProduct? upcProduct;
        if (enriched.barcode.trim().isNotEmpty) {
          upcProduct =
              await _upcFoodService.getProductByBarcode(enriched.barcode);
        }
        if (upcProduct == null &&
            enriched.name.trim().isNotEmpty &&
            enriched.name.toLowerCase() != 'unknown product') {
          upcProduct =
              await _upcFoodService.getProductByName(enriched.name);
        }
        if (upcProduct != null) {
          enriched = enriched.mergeWith(upcProduct);
          if (enriched.isComplete && !enriched.hasMissingOrZeroNutrients) {
            return enriched;
          }
        }
      } catch (e) {
        print('UPC product enrichment error: $e');
      }
    }

    // 3. Try Local DB
    if (enriched.hasMissingOrZeroNutrients) {
      try {
        FoodProduct? localProduct;
        if (enriched.barcode.trim().isNotEmpty) {
          localProduct =
              await _localDatabaseService.getProductByBarcode(enriched.barcode);
        }
        if (localProduct == null &&
            enriched.name.trim().isNotEmpty &&
            enriched.name.toLowerCase() != 'unknown product') {
          localProduct =
              await _localDatabaseService.getProductByName(enriched.name);
        }
        if (localProduct != null) {
          enriched = enriched.mergeWith(localProduct);
          if (enriched.isComplete && !enriched.hasMissingOrZeroNutrients) {
            return enriched;
          }
        }
      } catch (e) {
        print('Local DB product enrichment error: $e');
      }
    }

    // 4. Try Gemini AI Fallback
    if (enriched.hasMissingOrZeroNutrients) {
      try {
        final geminiProduct = await AiService.instance.lookupProductWithGemini(
          partialProduct: enriched,
        );
        if (geminiProduct != null) {
          print('✅ [FoodService] Enriched missing fields from Gemini AI');
          enriched = enriched.mergeWith(geminiProduct);
        }
      } catch (e) {
        print('Gemini AI enrichment step error: $e');
      }
    }

    return enriched;
  }

  // ============================================================
  // MULTIPLE NAME SEARCH / OCR / USER SEARCH
  //
  // Open Food Facts → multiple results
  // USDA → single fallback
  // UPC → single fallback
  // Local Database → single fallback
  // ============================================================

  /// General product search across food databases (Open Food Facts, USDA, UPC, Local DB, AI)
  Future<List<FoodProduct>> searchProducts(
    String query, {
    int pageSize = 20,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    print('🔎 [FoodService] Searching products: "$cleanQuery"');
    final results = <FoodProduct>[];

    // 1. Open Food Facts
    try {
      final offProducts = await _openFoodFactsService.getProductsByName(
        cleanQuery,
        pageSize: pageSize,
      );
      if (offProducts.isNotEmpty) {
        results.addAll(offProducts);
      }
    } catch (e) {
      print('Open Food Facts search error: $e');
    }

    // 2. USDA Fallback if empty
    if (results.isEmpty) {
      try {
        final usdaProduct = await _usdaFoodService.getProductByName(cleanQuery);
        if (usdaProduct != null) {
          results.add(usdaProduct);
        }
      } catch (e) {
        print('USDA search error: $e');
      }
    }

    // 3. Local DB Fallback if still empty
    if (results.isEmpty) {
      try {
        final localProduct = await _localDatabaseService.getProductByName(cleanQuery);
        if (localProduct != null) {
          results.add(localProduct);
        }
      } catch (e) {
        print('Local DB search error: $e');
      }
    }

    // 4. UPC Fallback
    if (results.isEmpty) {
      try {
        final upcProduct = await _upcFoodService.getProductByName(cleanQuery);
        if (upcProduct != null) {
          results.add(upcProduct);
        }
      } catch (e) {
        print('UPC search error: $e');
      }
    }

    // 5. Gemini AI Fallback
    if (results.isEmpty) {
      try {
        final geminiProduct = await AiService.instance.lookupProductWithGemini(name: cleanQuery);
        if (geminiProduct != null) {
          results.add(geminiProduct);
        }
      } catch (e) {
        print('Gemini search error: $e');
      }
    }

    return _removeDuplicates(results);
  }

  Future<List<FoodProduct>> getFoodsByName(
    String name, {
    bool isOcr = false,
  }) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      return [];
    }

    if (isOcr && !_isMeaningfulProductQuery(cleanName)) {
      print(
        '🚫 Ignoring noisy OCR product query: "$cleanName"',
      );
      return [];
    }

    print(
      '🔎 MULTI PRODUCT NAME SEARCH: $cleanName',
    );

    final results = <FoodProduct>[];

    // ------------------------------------------------------------
    // 1. Open Food Facts
    // ------------------------------------------------------------

    try {
      final products =
          await _openFoodFactsService.getProductsByName(
        cleanName,
        pageSize: 20,
      );

      if (products.isNotEmpty) {
        print(
          '✅ NAME SOURCE: OPEN FOOD FACTS '
          '(${products.length} results)',
        );

        results.addAll(products);
      }
    } catch (e) {
      print(
        'Open Food Facts multi-name search failed: $e',
      );
    }

    if (results.isNotEmpty) {
      return _removeDuplicates(results);
    }

    // ------------------------------------------------------------
    // 2. USDA FALLBACK
    // ------------------------------------------------------------

    try {
      final product =
          await _usdaFoodService.getProductByName(
        cleanName,
      );

      if (product != null) {
        print(
          '✅ NAME SOURCE: USDA',
        );

        results.add(product);
      }
    } catch (e) {
      print(
        'USDA name search failed: $e',
      );
    }

    // ------------------------------------------------------------
    // 3. UPC FALLBACK
    // ------------------------------------------------------------

    try {
      final product =
          await _upcFoodService.getProductByName(
        cleanName,
      );

      if (product != null) {
        print(
          '✅ NAME SOURCE: UPC',
        );

        results.add(product);
      }
    } catch (e) {
      print(
        'UPC name search failed: $e',
      );
    }

    // ------------------------------------------------------------
    // 4. LOCAL DATABASE FALLBACK
    // ------------------------------------------------------------

    try {
      final product =
          await _localDatabaseService.getProductByName(
        cleanName,
      );

      if (product != null) {
        print(
          '✅ NAME SOURCE: LOCAL DATABASE',
        );

        results.add(product);
      }
    } catch (e) {
      print(
        'Local database name search failed: $e',
      );
    }

    // ------------------------------------------------------------
    // 5. GEMINI AI FALLBACK
    // ------------------------------------------------------------

    if (results.isEmpty) {
      try {
        print('🤖 [FoodService] Searching Gemini AI by product name: "$cleanName"...');
        final geminiProduct = await AiService.instance.lookupProductWithGemini(
          name: cleanName,
        );

        if (geminiProduct != null) {
          print('✅ NAME SOURCE: GEMINI AI');
          results.add(geminiProduct);
        }
      } catch (e) {
        print('Gemini AI name search error: $e');
      }
    }

    if (results.isEmpty) {
      print(
        '❌ PRODUCT NOT FOUND BY NAME: $cleanName',
      );
    }

    return _removeDuplicates(results);
  }

  // ============================================================
  // SINGLE NAME SEARCH
  // ============================================================

  Future<FoodProduct?> getFoodByName(
    String name,
  ) async {
    final products =
        await getFoodsByName(name);

    if (products.isEmpty) {
      return null;
    }

    final product = products.first;
    if (product.hasMissingOrZeroNutrients) {
      return await enrichProduct(product);
    }

    return product;
  }

  // ============================================================
  // REMOVE DUPLICATE PRODUCTS
  // ============================================================

  bool _isMeaningfulProductQuery(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (normalized.isEmpty || normalized.length < 3) {
      return false;
    }

    final words = normalized
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 1)
        .where((word) => word != 'buy')
        .where((word) => word != 'visit')
        .where((word) => word != 'save')
        .where((word) => word != 'more')
        .where((word) => word != 'share')
        .where((word) => word != 'online')
        .where((word) => word != 'lowest')
        .where((word) => word != 'price')
        .where((word) => word != 'offer')
        .where((word) => word != 'shop')
        .toList();

    if (words.length < 2) {
      return false;
    }

    return true;
  }

  List<FoodProduct> _removeDuplicates(
    List<FoodProduct> products,
  ) {
    final seen = <String>{};
    final unique = <FoodProduct>[];

    for (final product in products) {
      // Prefer barcode as unique identifier.
      // If barcode is unavailable, use name + brand.
      final key = product.barcode.trim().isNotEmpty
          ? 'barcode:${product.barcode.trim()}'
          : 'name:${product.name.toLowerCase().trim()}'
              '|brand:${product.brand.toLowerCase().trim()}';

      if (seen.add(key)) {
        unique.add(product);
      }
    }

    return unique;
  }
}