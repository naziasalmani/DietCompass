import 'package:flutter_test/flutter_test.dart';
import 'package:diet_compass/core/model/food_product.dart';
import 'package:diet_compass/core/services/nutrition_normalization_service.dart';

void main() {
  group('Nutrition Normalization & Serving Basis Tests', () {
    final service = NutritionNormalizationService.instance;

    test('Detects liquid products accurately based on name, serving size, or category', () {
      // Sprite bottle
      expect(
        service.isLiquidProduct(
          name: 'Sprite Lemon-Lime Sparkling Beverage',
          servingSize: '300 ml',
          packageSize: '1.5 L',
        ),
        isTrue,
      );

      // Coca-Cola
      expect(
        service.isLiquidProduct(name: 'Coca-Cola Original Taste', servingSize: '250 ml'),
        isTrue,
      );

      // Fruit Juice
      expect(
        service.isLiquidProduct(name: 'Tropicana 100% Orange Juice', packageSize: '1 L'),
        isTrue,
      );

      // Milk
      expect(
        service.isLiquidProduct(name: 'Amul Taaza Toned Milk', servingSize: '200 ml'),
        isTrue,
      );

      // Solid food: Biscuits
      expect(
        service.isLiquidProduct(name: 'Parle-G Glucose Biscuits', servingSize: '25 g'),
        isFalse,
      );

      // Solid food: Potato Chips
      expect(
        service.isLiquidProduct(name: "Lay's Classic Salted", packageSize: '50 g'),
        isFalse,
      );
    });

    test('REGRESSION: Exact barcode 5449000012203 (Low Sugar Sprite in Europe/Turkey) correctly preserves 3.1g sugar per 100ml', () {
      // Real OpenFoodFacts payload for barcode 5449000012203
      final rawOffPayload = {
        'code': '5449000012203',
        'product': {
          'product_name': 'Sprite',
          'brands': 'Sprite',
          'quantity': '1 L',
          'serving_size': '250 ml',
          'serving_quantity': 250,
          'nutrition_data_per': '100ml',
          'categories_tags': [
            'en:beverages-and-beverages-preparations',
            'en:beverages',
            'en:carbonated-drinks',
            'en:artificially-sweetened-beverages',
            'en:sodas',
            'en:Lemon-flavoured soft drinks'
          ],
          'nutriments': {
            'carbohydrates': 3.1,
            'carbohydrates_100g': 3.1,
            'carbohydrates_serving': 7.75,
            'carbohydrates_unit': 'g',
            'carbohydrates_value': 3.1,
            'energy': 56,
            'energy-kcal': 13,
            'energy-kcal_100g': 13,
            'energy-kcal_serving': 32.5,
            'energy-kcal_unit': 'kcal',
            'energy-kcal_value': 13,
            'fat': 0,
            'fat_100g': 0,
            'fat_serving': 0,
            'fat_unit': 'g',
            'fat_value': 0,
            'fiber': 0,
            'fiber_100g': 0,
            'proteins': 0,
            'proteins_100g': 0,
            'proteins_serving': 0,
            'proteins_unit': 'g',
            'salt': 0.01,
            'salt_100g': 0.01,
            'salt_serving': 0.025,
            'sodium': 0.004,
            'sodium_100g': 0.004,
            'sodium_serving': 0.01,
            'sugars': 3.1,
            'sugars_100g': 3.1,
            'sugars_serving': 7.75,
            'sugars_unit': 'g',
            'sugars_value': 3.1,
          },
        },
      };

      final product = FoodProduct.fromOpenFoodFacts(rawOffPayload);

      // Verify product form and basis
      expect(product.isLiquid, isTrue);
      expect(product.normalizedBasisLabel, 'Per 100 ml');

      // Verify exact values are per 100 ml and NOT corrupted to 1.2g
      expect(product.sugar, 3.1);
      expect(product.carbohydrates, 3.1);
      expect(product.calories, 13.0);
      expect(product.protein, 0.0);
      expect(product.fat, 0.0);
      expect(product.sodium, 4.0); // 0.004g converted to 4.0mg
      expect(product.servingSize, '250 ml');
      expect(product.packageSize, '1 L');
    });

    test('Full-sugar Sprite (10.7g sugar/100ml) accurately yields 10.7g per 100ml', () {
      final offPayload = {
        'code': '5449000000996',
        'product': {
          'product_name': 'Sprite 1.5 L',
          'brands': 'Coca-Cola',
          'quantity': '1.5 l',
          'serving_size': '300 ml',
          'nutrition_data_per': '100ml',
          'categories_tags': ['en:beverages', 'en:carbonated-drinks', 'en:sodas'],
          'nutriments': {
            'energy-kcal_100ml': 40.0,
            'proteins_100ml': 0.0,
            'carbohydrates_100ml': 10.7,
            'sugars_100ml': 10.7,
            'fat_100ml': 0.0,
            'sodium_100ml': 0.01,
          },
        },
      };

      final product = FoodProduct.fromOpenFoodFacts(offPayload);

      expect(product.isLiquid, isTrue);
      expect(product.normalizedBasisLabel, 'Per 100 ml');
      expect(product.sugar, 10.7);
      expect(product.carbohydrates, 10.7);
      expect(product.calories, 40.0);
      expect(product.sodium, 10.0);
      expect(product.packageSize, '1.5 l');
      expect(product.servingSize, '300 ml');
    });

    test('Normalizes per-serving beverage data (250 ml serving with 26.75g sugar) to 10.7g per 100ml', () {
      final offPayload = {
        'code': '123456789012',
        'product': {
          'product_name': 'Sprite Can',
          'brands': 'Coca-Cola',
          'serving_size': '250 ml',
          'nutrition_data_per': 'serving',
          'categories_tags': ['en:beverages', 'en:sodas'],
          'nutriments': {
            'energy-kcal_serving': 100.0,
            'proteins_serving': 0.0,
            'carbohydrates_serving': 26.75,
            'sugars_serving': 26.75,
            'fat_serving': 0.0,
            'sodium_serving': 0.025, // 0.025g (25mg) in OFF format
          },
        },
      };

      final product = FoodProduct.fromOpenFoodFacts(offPayload);

      expect(product.isLiquid, isTrue);
      expect(product.normalizedBasisLabel, 'Per 100 ml');
      // 26.75 * (100 / 250) = 10.7
      expect(product.sugar, 10.7);
      expect(product.carbohydrates, 10.7);
      // 100 * (100 / 250) = 40.0
      expect(product.calories, 40.0);
      // 25 * (100 / 250) = 10.0
      expect(product.sodium, 10.0);
    });

    test('Normalizes 25g biscuit serving with 5g sugar to 20.0g per 100g', () {
      final normalized = service.normalize(
        calories: 115.0,
        protein: 1.5,
        carbohydrates: 18.0,
        fat: 4.0,
        fiber: 0.5,
        sugar: 5.0,
        sodium: 50.0,
        productName: 'Chocolate Chip Cookies',
        servingSize: '25 g',
        sourceBasis: 'serving',
      );

      expect(normalized.isLiquid, isFalse);
      expect(normalized.nutritionBasis, 'Per 100 g');
      // 5.0 * (100 / 25) = 20.0
      expect(normalized.sugar, 20.0);
      // 115.0 * (100 / 25) = 460.0
      expect(normalized.calories, 460.0);
      expect(normalized.fat, 16.0);
    });

    test('Does not double-convert values that are already per 100g / 100ml', () {
      final normalized = service.normalize(
        calories: 454.0,
        protein: 6.9,
        carbohydrates: 77.3,
        fat: 13.0,
        fiber: 2.0,
        sugar: 25.5,
        sodium: 296.0,
        productName: 'Parle-G Original Glucose Biscuits',
        servingSize: '25 g',
        packageSize: '800 g',
        sourceBasis: '100g',
      );

      expect(normalized.isLiquid, isFalse);
      expect(normalized.nutritionBasis, 'Per 100 g');
      expect(normalized.sugar, 25.5);
      expect(normalized.calories, 454.0);
      expect(normalized.sodium, 296.0);
    });

    test('Converts sodium in grams to milligrams (e.g. 0.05g -> 50mg)', () {
      final normalized = service.normalize(
        calories: 40.0,
        protein: 0.0,
        carbohydrates: 10.0,
        fat: 0.0,
        fiber: 0.0,
        sugar: 10.0,
        sodium: 0.05, // in grams
        productName: 'Sparkling Lemon Drink',
        sourceBasis: '100ml',
      );

      expect(normalized.sodium, 50.0);
    });

    test('FoodProduct.fromJson preserves normalizedBasisLabel and properties', () {
      final json = {
        'barcode': '12345678',
        'name': 'Oat Milk Unsweetened',
        'brand': 'Oatly',
        'servingSize': '250 ml',
        'packageSize': '1 L',
        'nutrition': {
          'calories': 45.0,
          'protein': 1.0,
          'carbohydrates': 6.5,
          'fat': 1.5,
          'fiber': 0.8,
          'sugar': 0.0,
          'sodium': 40.0,
        },
      };

      final product = FoodProduct.fromJson(json);

      expect(product.isLiquid, isTrue);
      expect(product.normalizedBasisLabel, 'Per 100 ml');
      expect(product.calories, 45.0);
      expect(product.sugar, 0.0);
    });

    test('SOLID PRODUCT: Maggi Masala Noodles displays Per 100 g and corresponds to 100g basis', () {
      final maggiOffPayload = {
        'code': '8901058852394',
        'product': {
          'product_name': 'MAGGI 2-Minute Masala Noodles',
          'brands': 'Nestlé',
          'quantity': '70 g',
          'serving_size': '70 g',
          'serving_quantity': 70,
          'nutrition_data_per': '100g',
          'categories_tags': [
            'en:plant-based-foods-and-beverages',
            'en:plant-based-foods',
            'en:cereals-and-potatoes',
            'en:cereals-and-their-products',
            'en:noodles',
            'en:instant-noodles'
          ],
          'nutriments': {
            'energy-kcal_100g': 384.0,
            'proteins_100g': 8.2,
            'carbohydrates_100g': 59.6,
            'fat_100g': 12.5,
            'sugars_100g': 1.8,
            'sodium_100g': 1.0, // 1.0 g -> 1000 mg
            'salt_100g': 2.5,
          },
        },
      };

      final product = FoodProduct.fromOpenFoodFacts(maggiOffPayload);

      expect(product.isLiquid, isFalse);
      expect(product.normalizedBasisLabel, 'Per 100 g');
      expect(product.calories, 384.0);
      expect(product.protein, 8.2);
      expect(product.carbohydrates, 59.6);
      expect(product.fat, 12.5);
      expect(product.sugar, 1.8);
      expect(product.sodium, 1000.0);
    });

    test('SOLID PRODUCT: Lay’s Classic Salted Chips displays Per 100 g and corresponds to 100g basis', () {
      final laysOffPayload = {
        'code': '8901491101837',
        'product': {
          'product_name': "Lay's Classic Salted Potato Chips",
          'brands': "Lay's, PepsiCo",
          'quantity': '50 g',
          'serving_size': '30 g',
          'serving_quantity': 30,
          'nutrition_data_per': '100g',
          'categories_tags': [
            'en:plant-based-foods-and-beverages',
            'en:snacks',
            'en:salty-snacks',
            'en:appetizers',
            'en:chips-and-fries',
            'en:crisps',
            'en:potato-crisps'
          ],
          'nutriments': {
            'energy-kcal_100g': 544.0,
            'proteins_100g': 6.8,
            'carbohydrates_100g': 52.5,
            'fat_100g': 34.3,
            'sugars_100g': 0.8,
            'sodium_100g': 0.58, // 0.58 g -> 580 mg
          },
        },
      };

      final product = FoodProduct.fromOpenFoodFacts(laysOffPayload);

      expect(product.isLiquid, isFalse);
      expect(product.normalizedBasisLabel, 'Per 100 g');
      expect(product.calories, 544.0);
      expect(product.protein, 6.8);
      expect(product.carbohydrates, 52.5);
      expect(product.fat, 34.3);
      expect(product.sugar, 0.8);
      expect(product.sodium, 580.0);
    });

    test('SOLID PRODUCT: Cadbury Dairy Milk Chocolate with milk-chocolates tag displays Per 100 g', () {
      final chocoPayload = {
        'code': '7622210286124',
        'product': {
          'product_name': 'Cadbury Dairy Milk Silk Chocolate',
          'brands': 'Cadbury, Mondelez',
          'quantity': '150 g',
          'serving_size': '20 g',
          'nutrition_data_per': '100g',
          'categories_tags': [
            'en:sweet-snacks',
            'en:cocoa-and-its-products',
            'en:chocolates',
            'en:milk-chocolates'
          ],
          'nutriments': {
            'energy-kcal_100g': 532.0,
            'proteins_100g': 7.8,
            'carbohydrates_100g': 58.5,
            'fat_100g': 30.5,
            'sugars_100g': 56.0,
            'sodium_100g': 0.15,
          },
        },
      };

      final product = FoodProduct.fromOpenFoodFacts(chocoPayload);

      expect(product.isLiquid, isFalse);
      expect(product.normalizedBasisLabel, 'Per 100 g');
      expect(product.sugar, 56.0);
      expect(product.calories, 532.0);
    });
  });
}
