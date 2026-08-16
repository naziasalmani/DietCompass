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

  Future<FoodProduct?> getFoodByBarcode(String barcode) async {
    final cleanBarcode = barcode.trim();

    if (cleanBarcode.isEmpty) {
      return null;
    }

    // 1. Open Food Facts
    try {
      final product =
          await _openFoodFactsService.getProductByBarcode(cleanBarcode);

      if (product != null) {
        print('✅ PRODUCT SOURCE: OPEN FOOD FACTS');
        return product;
      }
    } catch (e) {
      print('Open Food Facts failed: $e');
    }

    // 2. USDA
    try {
      final product =
          await _usdaFoodService.getProductByBarcode(cleanBarcode);

      if (product != null) {
        print('✅ PRODUCT SOURCE: USDA');
        return product;
      }
    } catch (e) {
      print('USDA failed: $e');
    }

    // 3. UPC
    try {
      final product =
          await _upcFoodService.getProductByBarcode(cleanBarcode);

      if (product != null) {
        print('✅ PRODUCT SOURCE: UPC');
        return product;
      }
    } catch (e) {
      print('UPC failed: $e');
    }

    // 4. YOUR LOCAL DATABASE
    try {
      final product =
          await _localDatabaseService.getProductByBarcode(cleanBarcode);

      if (product != null) {
        print('✅ PRODUCT SOURCE: LOCAL DATABASE');
        return product;
      }
    } catch (e) {
      print('Local database failed: $e');
    }

    print('❌ PRODUCT NOT FOUND: $cleanBarcode');
    return null;
  }

  // ============================================================
  // NAME SEARCH / OCR
  // Open Food Facts → USDA → UPC → Local Database
  // ============================================================

  Future<FoodProduct?> getFoodByName(String name) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      return null;
    }

    print('🔎 FOOD NAME SEARCH: $cleanName');

    // 1. Open Food Facts
    try {
      final product =
          await _openFoodFactsService.getProductByName(cleanName);

      if (product != null) {
        print('✅ NAME SOURCE: OPEN FOOD FACTS');
        return product;
      }
    } catch (e) {
      print('Open Food Facts name search failed: $e');
    }

    // 2. USDA
    try {
      final product =
          await _usdaFoodService.getProductByName(cleanName);

      if (product != null) {
        print('✅ NAME SOURCE: USDA');
        return product;
      }
    } catch (e) {
      print('USDA name search failed: $e');
    }

    // 3. UPC
    try {
      final product =
          await _upcFoodService.getProductByName(cleanName);

      if (product != null) {
        print('✅ NAME SOURCE: UPC');
        return product;
      }
    } catch (e) {
      print('UPC name search failed: $e');
    }

    // 4. YOUR LOCAL DATABASE
    try {
      final product =
          await _localDatabaseService.getProductByName(cleanName);

      if (product != null) {
        print('✅ NAME SOURCE: LOCAL DATABASE');
        return product;
      }
    } catch (e) {
      print('Local database name search failed: $e');
    }

    print('❌ PRODUCT NOT FOUND BY NAME: $cleanName');
    return null;
  }
}