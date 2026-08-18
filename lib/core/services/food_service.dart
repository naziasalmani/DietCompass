import '../model/food_product.dart';
import 'open_food_facts_service.dart';
import 'usda_food_service.dart';
import 'upc_food_service.dart';
import 'local_food_database_service.dart';

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
  // Open Food Facts → USDA → UPC → Local Database
  // ============================================================

  Future<FoodProduct?> getFoodByBarcode(
    String barcode,
  ) async {
    final cleanBarcode = barcode.trim();

    if (cleanBarcode.isEmpty) {
      return null;
    }

    // 1. Open Food Facts
    try {
      final product =
          await _openFoodFactsService.getProductByBarcode(
        cleanBarcode,
      );

      if (product != null) {
        print(
          '✅ PRODUCT SOURCE: OPEN FOOD FACTS',
        );

        return product;
      }
    } catch (e) {
      print(
        'Open Food Facts failed: $e',
      );
    }

    // 2. USDA
    try {
      final product =
          await _usdaFoodService.getProductByBarcode(
        cleanBarcode,
      );

      if (product != null) {
        print(
          '✅ PRODUCT SOURCE: USDA',
        );

        return product;
      }
    } catch (e) {
      print(
        'USDA failed: $e',
      );
    }

    // 3. UPC
    try {
      final product =
          await _upcFoodService.getProductByBarcode(
        cleanBarcode,
      );

      if (product != null) {
        print(
          '✅ PRODUCT SOURCE: UPC',
        );

        return product;
      }
    } catch (e) {
      print(
        'UPC failed: $e',
      );
    }

    // 4. Local Database
    try {
      final product =
          await _localDatabaseService.getProductByBarcode(
        cleanBarcode,
      );

      if (product != null) {
        print(
          '✅ PRODUCT SOURCE: LOCAL DATABASE',
        );

        return product;
      }
    } catch (e) {
      print(
        'Local database failed: $e',
      );
    }

    print(
      '❌ PRODUCT NOT FOUND: $cleanBarcode',
    );

    return null;
  }

  // ============================================================
  // MULTIPLE NAME SEARCH / OCR
  //
  // Open Food Facts → multiple results
  // USDA → single fallback
  // UPC → single fallback
  // Local Database → single fallback
  //
  // This is used by ProductImageAnalyzer.
  // ============================================================

  Future<List<FoodProduct>> getFoodsByName(
    String name,
  ) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      return [];
    }

    print(
      '🔎 MULTI PRODUCT NAME SEARCH: $cleanName',
    );

    final results = <FoodProduct>[];

    // ------------------------------------------------------------
    // 1. Open Food Facts
    //
    // IMPORTANT:
    // This returns MULTIPLE products instead of only the first
    // result. ProductImageAnalyzer will compare all of them.
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

    // ------------------------------------------------------------
    // If Open Food Facts returned products, those are enough
    // for OCR matching.
    //
    // We don't immediately add USDA/UPC/local results because
    // the OCR analyzer needs comparable product-name candidates,
    // and Open Food Facts gives us the largest result set.
    // ------------------------------------------------------------

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

    if (results.isEmpty) {
      print(
        '❌ PRODUCT NOT FOUND BY NAME: $cleanName',
      );
    }

    return _removeDuplicates(results);
  }

  // ============================================================
  // SINGLE NAME SEARCH
  //
  // Kept for compatibility with the rest of the application.
  //
  // ProductImageAnalyzer should use getFoodsByName() instead.
  // ============================================================

  Future<FoodProduct?> getFoodByName(
    String name,
  ) async {
    final products =
        await getFoodsByName(name);

    if (products.isEmpty) {
      return null;
    }

    return products.first;
  }

  // ============================================================
  // REMOVE DUPLICATE PRODUCTS
  // ============================================================

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