import '../model/food_product.dart';
import '../model/pantry_category.dart';
import 'product_category_service.dart';

/// Centralized service for classifying food items into Pantry categories.
/// Follows semantic grocery taxonomy priority:
/// 1. Product category / type metadata
/// 2. Product-name semantic classification
/// 3. Known brand & product patterns
/// 4. Ingredient & description analysis
/// 5. General keyword classification
/// 6. Universal fallback -> Other (NEVER Grains & Cereals)
class PantryCategoryService {
  PantryCategoryService._();
  static final PantryCategoryService instance = PantryCategoryService._();

  /// Classifies a [FoodProduct] into its most appropriate [PantryCategory].
  PantryCategory classifyProduct(FoodProduct product) {
    return classifyRaw(
      name: product.name,
      brand: product.brand,
      ingredients: product.ingredients,
      categoryMetadata: '',
    );
  }

  /// Classifies raw product metadata and text strings into a [PantryCategory].
  PantryCategory classifyRaw({
    required String name,
    String brand = '',
    String ingredients = '',
    String categoryMetadata = '',
  }) {
    final cleanName = name.trim().toLowerCase();
    final cleanBrand = brand.trim().toLowerCase();
    final cleanIngredients = ingredients.trim().toLowerCase();
    final cleanMetadata = categoryMetadata.trim().toLowerCase();
    final combined = '$cleanName $cleanBrand $cleanIngredients $cleanMetadata';

    if (cleanName.isEmpty && cleanBrand.isEmpty && cleanIngredients.isEmpty) {
      return PantryCategory.other;
    }

    // -------------------------------------------------------------------------
    // 1. HIGH-PRIORITY PRODUCT CATEGORY & BRAND SEMANTICS
    // -------------------------------------------------------------------------

    // A. SNACKS (Chips, crisps, puffs, namkeen, wafers, popcorn, crackers, nuts)
    // NOTE: Checked before grains and vegetables to prevent potato chips / corn chips
    // from being misclassified as raw grains or vegetables.
    if (_isSnack(cleanName, cleanBrand, combined)) {
      return PantryCategory.snacks;
    }

    // B. FROZEN FOODS (Frozen peas, frozen nuggets, french fries, frozen meals)
    // Checked early so frozen produce or frozen meats are classified as Frozen Foods.
    if (_isFrozenFood(cleanName, cleanBrand, combined)) {
      return PantryCategory.frozenFoods;
    }

    // C. READY-TO-EAT / INSTANT FOODS (Instant noodles, instant pasta, ready meals, cup noodles)
    // NOTE: Checked before grains to ensure Maggi / instant noodles are categorized as instant foods.
    if (_isReadyToEat(cleanName, cleanBrand, combined)) {
      return PantryCategory.readyToEatInstant;
    }

    // D. SWEETS & DESSERTS (Chocolates, candies, cakes, ice creams, mithai)
    if (_isSweetOrDessert(cleanName, cleanBrand, combined)) {
      return PantryCategory.sweetsDesserts;
    }

    // E. BEVERAGES (Soft drinks, juices, waters, teas, coffees, plant milks)
    if (_isBeverage(cleanName, cleanBrand, combined)) {
      return PantryCategory.beverages;
    }

    // F. COOKING ESSENTIALS (Cooking oils, ghee, sugar, baking powder, yeast)
    // Checked before condiments and spices so cooking oils (mustard oil, olive oil) are cooking essentials.
    if (_isCookingEssential(cleanName, cleanBrand, combined)) {
      return PantryCategory.cookingEssentials;
    }

    // G. CONDIMENTS & SAUCES (Ketchup, mayonnaise, mustard sauce, salad dressings, vinegars, dips)
    if (_isCondimentOrSauce(cleanName, cleanBrand, combined)) {
      return PantryCategory.condimentsSauces;
    }

    // H. SPICES & SEASONINGS (Turmeric, chilli powder, whole/ground spices, mustard seeds, salt, herbs)
    if (_isSpiceOrSeasoning(cleanName, cleanBrand, combined)) {
      return PantryCategory.spicesSeasonings;
    }

    // I. BAKERY (Breads, buns, bagels, croissants, pav, pita, tortillas)
    if (_isBakery(cleanName, cleanBrand, combined)) {
      return PantryCategory.bakery;
    }

    // J. PULSES & LEGUMES (Dal, lentils, chickpeas, beans, rajma, chana, soya chunks)
    if (_isPulseOrLegume(cleanName, cleanBrand, combined)) {
      return PantryCategory.pulsesLegumes;
    }

    // K. GRAINS & CEREALS (Raw rice, oats, wheat flour, cereal, cornflakes, muesli, quinoa)
    if (_isGrainOrCereal(cleanName, cleanBrand, combined)) {
      return PantryCategory.grainsCereals;
    }

    // L. DAIRY & EGGS (Milk, butter, cheese, yogurt, dahi, paneer, eggs)
    if (_isDairyOrEgg(cleanName, cleanBrand, combined)) {
      return PantryCategory.dairyEggs;
    }

    // M. MEAT & SEAFOOD (Chicken, mutton, beef, pork, fish, prawns, seafood)
    if (_isMeatOrSeafood(cleanName, cleanBrand, combined)) {
      return PantryCategory.meatSeafood;
    }

    // N. FRUITS & VEGETABLES (Fresh whole produce)
    if (_isFruitOrVegetable(cleanName, cleanBrand, combined)) {
      return PantryCategory.fruitsVegetables;
    }

    // -------------------------------------------------------------------------
    // 2. PRODUCT CATEGORY SERVICE TYPE MAPPING (Secondary verification)
    // -------------------------------------------------------------------------
    try {
      final tempProd = FoodProduct(
        barcode: '',
        name: name,
        brand: brand,
        imageUrl: '',
        ingredients: ingredients,
        allergens: const [],
        calories: null,
        protein: null,
        carbohydrates: null,
        fat: null,
        fiber: null,
        sugar: null,
        sodium: null,
      );
      final catType = ProductCategoryService.instance.classifyProduct(tempProd);
      final mapped = _mapFoodCategoryType(catType);
      if (mapped != PantryCategory.other) {
        return mapped;
      }
    } catch (_) {}

    // -------------------------------------------------------------------------
    // 3. UNIVERSAL FALLBACK
    // -------------------------------------------------------------------------
    return PantryCategory.other;
  }

  // ---------------------------------------------------------------------------
  // Category Classifier Helpers
  // ---------------------------------------------------------------------------

  bool _isSnack(String name, String brand, String combined) {
    const snackBrands = [
      'lays',
      "lay's",
      'kurkure',
      'bingo',
      'doritos',
      'pringles',
      'cheetos',
      'uncle chipps',
      'crax',
      'haldiram',
      'bikaji',
      'balaji',
      'cornitos',
      'sunbites',
      'parle',
      'britannia',
      'act ii',
    ];

    for (final b in snackBrands) {
      if (brand.contains(b) || name.contains(b)) {
        // Exception: Parle/Britannia breads or dairy are handled separately
        if (!name.contains('bread') && !name.contains('milk') && !name.contains('cheese') && !name.contains('butter')) {
          return true;
        }
      }
    }

    const snackKeywords = [
      'chips',
      'potato chips',
      'potato wafers',
      'wafer',
      'wafers',
      'crisps',
      'nachos',
      'tortilla chips',
      'banana chips',
      'popped chips',
      'puffs',
      'namkeen',
      'bhujia',
      'sev',
      'chivda',
      'murukku',
      'snack mix',
      'trail mix',
      'popcorn',
      'roasted makhana',
      'makhana',
      'salted peanut',
      'roasted peanut',
      'roasted almond',
      'cracker',
      'crackers',
      'pretzels',
      'biscuit',
      'biscuits',
      'cookie',
      'cookies',
      'snack',
      'snacks',
    ];

    return _matchesAny(name, snackKeywords) ||
        (cleanContains(combined, 'potato chip') || cleanContains(combined, 'namkeen') || cleanContains(combined, 'crisp'));
  }

  bool _isReadyToEat(String name, String brand, String combined) {
    const instantBrands = [
      'maggi',
      'yippee',
      'top ramen',
      'wai wai',
      "ching's",
      'chings',
      'cup noodles',
      'nissin',
      'buldak',
      'samyang',
      'mama',
      'knorr instant',
      'mtr 3 minute',
      'mtr ready to eat',
    ];

    for (final b in instantBrands) {
      if (brand.contains(b) || name.contains(b)) {
        return true;
      }
    }

    const instantKeywords = [
      'instant noodles',
      '2-minute noodles',
      '2 minute noodles',
      'ramen',
      'cup noodles',
      'instant pasta',
      'instant soup',
      'instant mix',
      'ready to eat',
      'ready-to-eat',
      'heat and eat',
      'instant poha',
      'instant upma',
      'instant oats',
      'instant meal',
      'meal kit',
      'noodles',
    ];

    return _matchesAny(name, instantKeywords);
  }

  bool _isSweetOrDessert(String name, String brand, String combined) {
    const sweetKeywords = [
      'chocolate',
      'chocolates',
      'dark chocolate',
      'milk chocolate',
      'dairy milk',
      'kitkat',
      '5 star',
      'snickers',
      'munch',
      'perk',
      'toblerone',
      'ferrero',
      'cadbury',
      'bournville',
      'candy',
      'candies',
      'gummy',
      'gummies',
      'toffee',
      'lollipop',
      'caramel',
      'marshmallow',
      'halwa',
      'gulab jamun',
      'rasgulla',
      'ladoo',
      'kaju katli',
      'jalebi',
      'barfi',
      'mithai',
      'cake',
      'pastry',
      'brownie',
      'ice cream',
      'icecream',
      'gelato',
      'kulfi',
      'sorbet',
      'sundae',
      'popsicle',
      'pudding',
      'custard',
      'sweet',
      'sweets',
      'dessert',
      'desserts',
      'nutella',
      'choco spread',
    ];

    return _matchesAny(name, sweetKeywords) || _matchesAny(brand, ['cadbury', 'ferrero', 'hershey', 'nestle chocolate', 'lindt', 'amul dark']);
  }

  bool _isBeverage(String name, String brand, String combined) {
    const beverageBrands = [
      'coca cola',
      'coca-cola',
      'coke',
      'sprite',
      'pepsi',
      'fanta',
      'mirinda',
      'limca',
      'mountain dew',
      '7up',
      'thums up',
      'red bull',
      'monster energy',
      'tropicana',
      'real juice',
      'frooti',
      'maaza',
      'slice',
      'paper boat',
      'minute maid',
      'lipton',
      'tata tea',
      'nescafe',
      'bru',
      'starbucks',
      'bisleri',
      'aquafina',
      'kinley',
      'raw pressery',
    ];

    for (final b in beverageBrands) {
      if (brand.contains(b) || name.contains(b)) {
        return true;
      }
    }

    const beverageKeywords = [
      'soda',
      'cola',
      'soft drink',
      'carbonated',
      'fizzy drink',
      'energy drink',
      'juice',
      'fruit juice',
      'smoothie',
      'nectar',
      'squash',
      'cordial',
      'iced tea',
      'kombucha',
      'coconut water',
      'mineral water',
      'sparkling water',
      'water bottle',
      'tea',
      'green tea',
      'black tea',
      'chai',
      'tea bags',
      'coffee',
      'instant coffee',
      'ground coffee',
      'espresso',
      'cold brew',
      'plant milk',
      'almond milk',
      'soya milk',
      'soy milk',
      'oat milk',
      'drink',
      'beverage',
    ];

    return _matchesAny(name, beverageKeywords);
  }

  bool _isCondimentOrSauce(String name, String brand, String combined) {
    if (name.contains('mustard oil') || name.contains('mustard seed') || name.contains('mustard seeds')) {
      return false;
    }
    const condimentKeywords = [
      'ketchup',
      'tomato ketchup',
      'tomato sauce',
      'mustard sauce',
      'mustard paste',
      'dijon mustard',
      'yellow mustard',
      'mustard',
      'mayonnaise',
      'mayo',
      'soy sauce',
      'soya sauce',
      'chilli sauce',
      'hot sauce',
      'sriracha',
      'schezwan sauce',
      'barbecue sauce',
      'bbq sauce',
      'salad dressing',
      'dip',
      'salsa',
      'relish',
      'chutney',
      'pickle',
      'achar',
      'hummus',
      'tahini',
      'vinegar',
      'apple cider vinegar',
      'condiment',
      'sauce',
    ];

    return _matchesAny(name, condimentKeywords) || _matchesAny(brand, ['heinz', "kisan", 'kissan', 'veeba', "hellmann's", 'hellmanns']);
  }

  bool _isSpiceOrSeasoning(String name, String brand, String combined) {
    const spiceKeywords = [
      'turmeric',
      'haldi',
      'chilli powder',
      'chili powder',
      'red chilli',
      'chili flakes',
      'garam masala',
      'coriander powder',
      'dhaniya',
      'cumin',
      'jeera',
      'black pepper',
      'peppercorn',
      'cardamom',
      'elaichi',
      'cinnamon',
      'dalchini',
      'cloves',
      'laung',
      'nutmeg',
      'mustard seeds',
      'rai',
      'fenugreek',
      'methi',
      'asafoetida',
      'hing',
      'bay leaf',
      'tej patta',
      'oregano',
      'thyme',
      'basil',
      'rosemary',
      'parsley',
      'paprika',
      'peri peri',
      'chaat masala',
      'amchur',
      'seasoning',
      'spices',
      'spice',
      'herbs',
      'rock salt',
      'black salt',
      'sea salt',
      'table salt',
      'salt',
    ];

    return _matchesAny(name, spiceKeywords) || _matchesAny(brand, ['everest', 'mdh', 'catch spices', 'tata sampann masala', 'badshah']);
  }

  bool _isBakery(String name, String brand, String combined) {
    const bakeryKeywords = [
      'bread',
      'white bread',
      'brown bread',
      'whole wheat bread',
      'multigrain bread',
      'sourdough',
      'bun',
      'buns',
      'burger bun',
      'hot dog bun',
      'bagel',
      'bagels',
      'croissant',
      'croissants',
      'pav',
      'ladi pav',
      'pita bread',
      'pita',
      'tortilla wrap',
      'tortilla',
      'naan',
      'kulcha',
      'roti',
      'chapati',
      'paratha',
      'brioche',
      'muffin',
      'muffins',
      'toast',
      'rusk',
      'bakery',
    ];

    return _matchesAny(name, bakeryKeywords);
  }

  bool _isPulseOrLegume(String name, String brand, String combined) {
    const pulseKeywords = [
      'dal',
      'daal',
      'lentil',
      'lentils',
      'chickpea',
      'chickpeas',
      'chana',
      'kabuli chana',
      'kala chana',
      'moong',
      'mung',
      'toor dal',
      'tuvar dal',
      'urad dal',
      'masoor dal',
      'rajma',
      'kidney beans',
      'black beans',
      'soya chunks',
      'soybeans',
      'edamame',
      'peas',
      'split peas',
      'legume',
      'legumes',
      'beans',
    ];

    return _matchesAny(name, pulseKeywords);
  }

  bool _isGrainOrCereal(String name, String brand, String combined) {
    const grainKeywords = [
      'rice',
      'basmati',
      'brown rice',
      'jasmine rice',
      'oats',
      'oatmeal',
      'rolled oats',
      'steel cut oats',
      'wheat',
      'flour',
      'atta',
      'maida',
      'whole wheat flour',
      'cereal',
      'breakfast cereal',
      'corn flakes',
      'cornflakes',
      'muesli',
      'granola',
      'quinoa',
      'barley',
      'millet',
      'ragi',
      'jowar',
      'bajra',
      'couscous',
      'semolina',
      'sooji',
      'suji',
      'poha',
      'flattened rice',
      'grain',
      'grains',
    ];

    return _matchesAny(name, grainKeywords) || _matchesAny(brand, ['quaker', 'kellogg', 'saffola oats', 'aashirvaad', 'fortune atta']);
  }

  bool _isDairyOrEgg(String name, String brand, String combined) {
    const dairyKeywords = [
      'milk',
      'toned milk',
      'cow milk',
      'full cream milk',
      'skimmed milk',
      'dairy',
      'curd',
      'dahi',
      'yogurt',
      'yoghurt',
      'greek yogurt',
      'lassi',
      'chaas',
      'buttermilk',
      'butter',
      'salted butter',
      'unsalted butter',
      'amul butter',
      'cheese',
      'cheddar',
      'mozzarella',
      'parmesan',
      'paneer',
      'cottage cheese',
      'cream',
      'heavy cream',
      'whipping cream',
      'condensed milk',
      'egg',
      'eggs',
      'egg whites',
    ];

    return _matchesAny(name, dairyKeywords) || _matchesAny(brand, ['amul', 'mother dairy', 'nandini', 'epigamia', 'nestle milk', 'britannia cheese']);
  }

  bool _isMeatOrSeafood(String name, String brand, String combined) {
    const meatKeywords = [
      'chicken',
      'chicken breast',
      'chicken thigh',
      'mutton',
      'lamb',
      'beef',
      'pork',
      'bacon',
      'ham',
      'sausage',
      'sausages',
      'salami',
      'fish',
      'salmon',
      'tuna',
      'prawns',
      'shrimp',
      'crab',
      'lobster',
      'seafood',
      'meat',
      'poultry',
    ];

    return _matchesAny(name, meatKeywords);
  }

  bool _isCookingEssential(String name, String brand, String combined) {
    const essentialKeywords = [
      'oil',
      'cooking oil',
      'mustard oil',
      'sunflower oil',
      'olive oil',
      'groundnut oil',
      'coconut oil',
      'sesame oil',
      'canola oil',
      'ghee',
      'desi ghee',
      'sugar',
      'brown sugar',
      'jaggery',
      'gur',
      'baking powder',
      'baking soda',
      'yeast',
      'cornstarch',
      'corn starch',
      'cocoa powder',
      'vanilla extract',
    ];

    return _matchesAny(name, essentialKeywords) || _matchesAny(brand, ['fortune oil', 'dhara', 'saffola gold', 'nature fresh']);
  }

  bool _isFrozenFood(String name, String brand, String combined) {
    const frozenKeywords = [
      'frozen peas',
      'frozen vegetables',
      'frozen veg',
      'frozen nuggets',
      'frozen fries',
      'french fries',
      'frozen pizza',
      'frozen paratha',
      'frozen samosa',
      'frozen kebab',
      'frozen fish',
      'frozen',
    ];

    return _matchesAny(name, frozenKeywords) || _matchesAny(brand, ['mccain', 'safal', 'godrej yummiez', 'itc master chef']);
  }

  bool _isFruitOrVegetable(String name, String brand, String combined) {
    const produceKeywords = [
      'apple',
      'banana',
      'orange',
      'mango',
      'grape',
      'grapes',
      'strawberry',
      'berries',
      'blueberry',
      'lemon',
      'lime',
      'pineapple',
      'watermelon',
      'papaya',
      'guava',
      'pomegranate',
      'tomato',
      'potato',
      'onion',
      'garlic',
      'ginger',
      'spinach',
      'palak',
      'lettuce',
      'cabbage',
      'cauliflower',
      'broccoli',
      'carrot',
      'cucumber',
      'capsicum',
      'bell pepper',
      'mushroom',
      'zucchini',
      'avocado',
      'fresh fruit',
      'fresh vegetable',
      'vegetable',
      'vegetables',
      'fruit',
      'fruits',
    ];

    return _matchesAny(name, produceKeywords);
  }

  PantryCategory _mapFoodCategoryType(FoodCategoryType type) {
    switch (type) {
      case FoodCategoryType.chipsSavorySnacks:
      case FoodCategoryType.biscuitsCookies:
      case FoodCategoryType.proteinEnergyBars:
        return PantryCategory.snacks;
      case FoodCategoryType.instantNoodlesPasta:
        return PantryCategory.readyToEatInstant;
      case FoodCategoryType.chocolateConfectionery:
      case FoodCategoryType.iceCreamFrozen:
      case FoodCategoryType.nutSeedButters:
        return PantryCategory.sweetsDesserts;
      case FoodCategoryType.carbonatedBeverage:
      case FoodCategoryType.fruitJuiceSmoothies:
      case FoodCategoryType.teaCoffee:
      case FoodCategoryType.plantMilk:
        return PantryCategory.beverages;
      case FoodCategoryType.milkYogurtDairy:
      case FoodCategoryType.butterDairySpreads:
        return PantryCategory.dairyEggs;
      case FoodCategoryType.breadBakery:
        return PantryCategory.bakery;
      case FoodCategoryType.breakfastCerealOats:
        return PantryCategory.grainsCereals;
      case FoodCategoryType.saucesCondiments:
        return PantryCategory.condimentsSauces;
      case FoodCategoryType.cookingOilsFats:
        return PantryCategory.cookingEssentials;
      case FoodCategoryType.generalPackagedFood:
        return PantryCategory.other;
    }
  }

  bool _matchesAny(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (cleanContains(text, kw)) return true;
    }
    return false;
  }

  static bool cleanContains(String text, String search) {
    final t = text.toLowerCase();
    final s = search.toLowerCase();
    if (!t.contains(s)) return false;

    // Word boundary check
    final pattern = RegExp('(^|[^a-z0-9])${RegExp.escape(s)}([^a-z0-9]|\$)');
    return pattern.hasMatch(t);
  }
}
