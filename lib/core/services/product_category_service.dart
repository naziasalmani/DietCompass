import '../model/food_product.dart';

/// Major food category families for category-aware alternatives and same-purpose recommendations
enum FoodCategoryType {
  chocolateConfectionery,
  carbonatedBeverage,
  breakfastCerealOats,
  chipsSavorySnacks,
  instantNoodlesPasta,
  butterDairySpreads,
  nutSeedButters,
  breadBakery,
  proteinEnergyBars,
  biscuitsCookies,
  iceCreamFrozen,
  fruitJuiceSmoothies,
  milkYogurtDairy,
  plantMilk,
  teaCoffee,
  cookingOilsFats,
  saucesCondiments,
  generalPackagedFood,
}

extension FoodCategoryTypeExtension on FoodCategoryType {
  String get displayName {
    switch (this) {
      case FoodCategoryType.chocolateConfectionery:
        return 'Chocolates & Confectionery';
      case FoodCategoryType.carbonatedBeverage:
        return 'Soft Drinks & Carbonated Beverages';
      case FoodCategoryType.breakfastCerealOats:
        return 'Oats & Breakfast Cereals';
      case FoodCategoryType.chipsSavorySnacks:
        return 'Chips & Savory Snacks';
      case FoodCategoryType.instantNoodlesPasta:
        return 'Instant Noodles & Pasta';
      case FoodCategoryType.butterDairySpreads:
        return 'Butter & Dairy Spreads';
      case FoodCategoryType.nutSeedButters:
        return 'Nut & Seed Butters';
      case FoodCategoryType.breadBakery:
        return 'Breads & Baked Goods';
      case FoodCategoryType.proteinEnergyBars:
        return 'Protein & Energy Bars';
      case FoodCategoryType.biscuitsCookies:
        return 'Biscuits & Cookies';
      case FoodCategoryType.iceCreamFrozen:
        return 'Ice Creams & Frozen Desserts';
      case FoodCategoryType.fruitJuiceSmoothies:
        return 'Fruit Juices & Smoothies';
      case FoodCategoryType.milkYogurtDairy:
        return 'Milk & Dairy Yogurt';
      case FoodCategoryType.plantMilk:
        return 'Plant-Based Milks';
      case FoodCategoryType.teaCoffee:
        return 'Teas & Coffees';
      case FoodCategoryType.cookingOilsFats:
        return 'Cooking Oils & Fats';
      case FoodCategoryType.saucesCondiments:
        return 'Sauces & Condiments';
      case FoodCategoryType.generalPackagedFood:
        return 'Packaged Foods';
    }
  }
}

/// Service that classifies packaged food products into semantic categories
/// and ensures that "Better Alternatives" recommendations are strictly same-category/same-purpose.
class ProductCategoryService {
  ProductCategoryService._();
  static final ProductCategoryService instance = ProductCategoryService._();

  /// Classifies a [FoodProduct] into its most accurate semantic [FoodCategoryType].
  FoodCategoryType classifyProduct(FoodProduct product) {
    final name = product.name.toLowerCase();
    final brand = product.brand.toLowerCase();
    final ingredients = product.ingredients.toLowerCase();
    final combinedText = '$name $brand $ingredients';

    // 1. Protein & Energy Bars (high specificity)
    if (_matchesKeywords(name, ['protein bar', 'energy bar', 'granola bar', 'nutrition bar', 'cereal bar', 'workout bar']) ||
        (combinedText.contains('bar') && (combinedText.contains('protein') || combinedText.contains('energy')) && !name.contains('chocolate bar') && !name.contains('dairy milk'))) {
      return FoodCategoryType.proteinEnergyBars;
    }

    // 2. Biscuits & Cookies
    if (_matchesKeywords(name, ['biscuit', 'biscuits', 'cookie', 'cookies', 'cracker', 'crackers', 'wafer', 'wafers', 'digestive', 'bourbon', 'oreo', 'parle-g', 'good day', 'marie gold', 'rusk'])) {
      return FoodCategoryType.biscuitsCookies;
    }

    // 3. Chocolate & Confectionery
    if (_matchesKeywords(name, ['chocolate', 'chocolates', 'cocoa bar', 'dark chocolate', 'milk chocolate', 'dairy milk', 'kitkat', '5 star', 'snickers', 'munch', 'perk', 'toblerone', 'ferrero', 'cadbury', 'bournville', 'amul dark']) ||
        (name.contains('choco') && !name.contains('cookie') && !name.contains('biscuit') && !name.contains('cereal') && !name.contains('oats') && !name.contains('shake') && !name.contains('ice cream'))) {
      return FoodCategoryType.chocolateConfectionery;
    }

    // 4. Carbonated Beverages / Soft Drinks / Colas
    if (_matchesKeywords(name, ['thums up', 'coca cola', 'coke', 'pepsi', 'sprite', 'fanta', 'mirinda', 'limca', 'mountain dew', '7up', 'soda', 'cola', 'carbonated', 'soft drink', 'fizzy drink', 'ginger ale', 'diet coke', 'coke zero', 'diet pepsi', 'pepsi black'])) {
      return FoodCategoryType.carbonatedBeverage;
    }

    // 5. Breakfast Cereals & Oats
    if (_matchesKeywords(name, ['oats', 'oatmeal', 'rolled oats', 'steel cut oats', 'muesli', 'granola', 'corn flakes', 'chocos', 'breakfast cereal', 'wheat flakes', 'quaker', 'saffola oats', 'kellogg'])) {
      return FoodCategoryType.breakfastCerealOats;
    }

    // 6. Chips & Savory Snacks
    if (_matchesKeywords(name, ['chips', 'potato chips', 'crisps', 'nachos', 'kurkure', 'lays', 'doritos', 'bingo', 'namkeen', 'bhujia', 'sev', 'banana chips', 'popped chips', 'tortilla chips', 'puffs', 'salted peanut'])) {
      return FoodCategoryType.chipsSavorySnacks;
    }

    // 7. Instant Noodles & Pasta
    if (_matchesKeywords(name, ['noodles', 'instant noodles', 'maggi', 'yippee', 'top ramen', 'pasta', 'macaroni', 'spaghetti', 'ramen', 'hakka noodles', 'vermicelli', 'sewai'])) {
      return FoodCategoryType.instantNoodlesPasta;
    }

    // 8. Nut & Seed Butters
    if (_matchesKeywords(name, ['peanut butter', 'almond butter', 'cashew butter', 'hazelnut butter', 'seed butter', 'sunflower butter', 'nutella', 'choco spread'])) {
      return FoodCategoryType.nutSeedButters;
    }

    // 9. Butter & Dairy Spreads
    if (_matchesKeywords(name, ['butter', 'table butter', 'salted butter', 'unsalted butter', 'margarine', 'ghee', 'cheese spread', 'mayo', 'mayonnaise', 'amul butter', 'nandini butter'])) {
      return FoodCategoryType.butterDairySpreads;
    }

    // 10. Breads & Bakery
    if (_matchesKeywords(name, ['bread', 'brown bread', 'whole wheat bread', 'multigrain bread', 'white bread', 'sourdough', 'bun', 'buns', 'bagel', 'croissant', 'pav', 'tortilla wrap', 'pita'])) {
      return FoodCategoryType.breadBakery;
    }

    // 11. Ice Cream & Frozen Desserts
    if (_matchesKeywords(name, ['ice cream', 'icecream', 'gelato', 'kulfi', 'frozen dessert', 'sorbet', 'cornetto', 'magnum', 'sundae', 'popsicle'])) {
      return FoodCategoryType.iceCreamFrozen;
    }

    // 12. Fruit Juices & Smoothies
    if (_matchesKeywords(name, ['juice', 'fruit juice', 'smoothie', 'real fruit', 'tropicana', 'b natural', 'mixed fruit juice', 'apple juice', 'orange juice', 'mango nectar', 'frooti', 'maaza', 'slice'])) {
      return FoodCategoryType.fruitJuiceSmoothies;
    }

    // 13. Plant-Based Milks
    if (_matchesKeywords(name, ['almond milk', 'soya milk', 'soy milk', 'oat milk', 'coconut milk', 'cashew milk', 'plant milk', 'vegan milk'])) {
      return FoodCategoryType.plantMilk;
    }

    // 14. Milk & Dairy Yogurt
    if (_matchesKeywords(name, ['milk', 'toned milk', 'cow milk', 'full cream milk', 'curd', 'dahi', 'yogurt', 'yoghurt', 'greek yogurt', 'lassi', 'chaas', 'buttermilk', 'paneer', 'cheese'])) {
      return FoodCategoryType.milkYogurtDairy;
    }

    // 15. Teas & Coffees
    if (_matchesKeywords(name, ['tea', 'green tea', 'black tea', 'herbal tea', 'masala chai', 'coffee', 'espresso', 'nescafe', 'bru', 'instant coffee', 'cold coffee'])) {
      return FoodCategoryType.teaCoffee;
    }

    // 16. Cooking Oils & Fats
    if (_matchesKeywords(name, ['oil', 'olive oil', 'coconut oil', 'mustard oil', 'sunflower oil', 'groundnut oil', 'sesame oil', 'canola oil', 'rice bran oil'])) {
      return FoodCategoryType.cookingOilsFats;
    }

    // 17. Sauces & Condiments
    if (_matchesKeywords(name, ['sauce', 'ketchup', 'tomato sauce', 'chilli sauce', 'soy sauce', 'vinaigrette', 'salad dressing', 'schezwan sauce', 'dip'])) {
      return FoodCategoryType.saucesCondiments;
    }

    // Secondary Ingredient-based classification fallback
    if (ingredients.contains('cocoa') || ingredients.contains('chocolate')) {
      return FoodCategoryType.chocolateConfectionery;
    }
    if (ingredients.contains('carbonated water') || ingredients.contains('carbonated')) {
      return FoodCategoryType.carbonatedBeverage;
    }
    if (ingredients.contains('oat') || ingredients.contains('oats')) {
      return FoodCategoryType.breakfastCerealOats;
    }
    if (ingredients.contains('potato') && (ingredients.contains('oil') || ingredients.contains('salt'))) {
      return FoodCategoryType.chipsSavorySnacks;
    }
    if (ingredients.contains('wheat flour') && ingredients.contains('yeast')) {
      return FoodCategoryType.breadBakery;
    }

    return FoodCategoryType.generalPackagedFood;
  }

  /// Returns `true` only if both products belong to the exact same category or closely related compatible family.
  /// Strictly prevents cross-category recommendations (e.g. Oats or Soda for Chocolate).
  bool isProductSimilarCategory(FoodProduct current, FoodProduct alternative) {
    final catA = classifyProduct(current);
    final catB = classifyProduct(alternative);

    if (catA == FoodCategoryType.generalPackagedFood || catB == FoodCategoryType.generalPackagedFood) {
      // If either is general, do a keyword overlap check on product names
      return _hasSemanticOverlap(current.name, alternative.name);
    }

    return areCategoriesCompatible(catA, catB);
  }

  /// Checks if two [FoodCategoryType]s are functionally compatible for substitution.
  bool areCategoriesCompatible(FoodCategoryType a, FoodCategoryType b) {
    if (a == b) return true;

    // Closely related sibling pairs that are valid substitutes
    const compatiblePairs = [
      {FoodCategoryType.milkYogurtDairy, FoodCategoryType.plantMilk},
      {FoodCategoryType.butterDairySpreads, FoodCategoryType.nutSeedButters},
      {FoodCategoryType.biscuitsCookies, FoodCategoryType.proteinEnergyBars},
    ];

    for (final pair in compatiblePairs) {
      if (pair.contains(a) && pair.contains(b)) {
        return true;
      }
    }

    return false;
  }

  /// Returns high-quality search keywords to query candidate healthier products in the same category.
  List<String> getCategorySearchKeywords(FoodCategoryType category, {String? originalName}) {
    switch (category) {
      case FoodCategoryType.chocolateConfectionery:
        return [
          'dark chocolate',
          'amul dark chocolate',
          'sugar free chocolate',
          'bournville dark chocolate',
          'cocoa dark chocolate',
          'lindt excellence',
        ];
      case FoodCategoryType.carbonatedBeverage:
        return [
          'diet coke',
          'coke zero',
          'pepsi black',
          'diet pepsi',
          'zero sugar soda',
          'sparkling water flavoured',
        ];
      case FoodCategoryType.breakfastCerealOats:
        return [
          'rolled oats',
          'quaker oats',
          'saffola oats',
          'true elements oats',
          'organic steel cut oats',
          'muesli fruit and nut',
          'unsweetened muesli',
        ];
      case FoodCategoryType.chipsSavorySnacks:
        return [
          'baked chips',
          'popped potato chips',
          'roasted namkeen',
          'lentil chips',
          'true elements roasted seeds',
          'makhana roasted',
        ];
      case FoodCategoryType.instantNoodlesPasta:
        return [
          'whole wheat noodles',
          'millet noodles',
          'atta noodles',
          'whole wheat pasta',
          'quinoa pasta',
        ];
      case FoodCategoryType.butterDairySpreads:
        return [
          'organic butter',
          'unsalted butter',
          'clarified butter ghee',
          'olive oil spread',
        ];
      case FoodCategoryType.nutSeedButters:
        return [
          'unsweetened peanut butter',
          'almond butter pure',
          'organic peanut butter',
          'natural peanut butter crunchy',
        ];
      case FoodCategoryType.breadBakery:
        return [
          'whole wheat bread 100%',
          'multigrain brown bread',
          'sourdough bread',
          'organic whole grain bread',
        ];
      case FoodCategoryType.proteinEnergyBars:
        return [
          'high protein bar',
          'yoga bar protein',
          'whole truth protein bar',
          'ritebite max protein',
          'clean energy bar',
        ];
      case FoodCategoryType.biscuitsCookies:
        return [
          'digestive biscuits',
          'nutrichoice digestive',
          'oat cookies unsweetened',
          'whole wheat biscuits',
          'sugar free cookies',
        ];
      case FoodCategoryType.iceCreamFrozen:
        return [
          'low calorie ice cream',
          'sugar free ice cream',
          'frozen greek yogurt',
          'fruit sorbet natural',
        ];
      case FoodCategoryType.fruitJuiceSmoothies:
        return [
          '100% orange juice no added sugar',
          'raw cold pressed juice',
          'cold pressed fruit juice',
          'unsweetened apple juice',
        ];
      case FoodCategoryType.milkYogurtDairy:
        return [
          'greek yogurt unsweetened',
          'toned milk',
          'low fat dahi',
          'organic cow milk',
          'epigamia greek yogurt',
        ];
      case FoodCategoryType.plantMilk:
        return [
          'unsweetened almond milk',
          'organic soy milk',
          'unsweetened oat milk',
          'raw pressery almond milk',
        ];
      case FoodCategoryType.teaCoffee:
        return [
          'organic green tea',
          'chamomile herbal tea',
          'pure black coffee',
          'matcha green tea',
        ];
      case FoodCategoryType.cookingOilsFats:
        return [
          'extra virgin olive oil',
          'cold pressed coconut oil',
          'cold pressed mustard oil',
          'avocado oil',
        ];
      case FoodCategoryType.saucesCondiments:
        return [
          'low sugar ketchup',
          'organic tomato paste',
          'olive oil salad dressing',
          'apple cider vinegar dressing',
        ];
      case FoodCategoryType.generalPackagedFood:
        if (originalName != null && originalName.trim().isNotEmpty) {
          final words = originalName.trim().split(' ').take(2).join(' ');
          return [words, originalName.trim()];
        }
        return ['healthy snack', 'whole food'];
    }
  }

  static bool _matchesKeywords(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (text.contains(kw)) return true;
    }
    return false;
  }

  static bool _hasSemanticOverlap(String a, String b) {
    final wordsA = a.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 3).toSet();
    final wordsB = b.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 3).toSet();
    return wordsA.intersection(wordsB).isNotEmpty;
  }
}
