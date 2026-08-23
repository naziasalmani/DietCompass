/**
 * DietCompass — Product to Culinary Category Normalizer
 * Normalizes branded/packaged products into clean culinary categories and queries
 */

const KNOWN_PRODUCT_MAPPINGS = [
  {
    triggers: ['dairy milk', 'chocolate', 'cadbury', 'cocoa', 'cacao', 'choc', 'hershey', 'kitkat', 'snickers', 'm&m', 'galaxy', 'lindt', 'bournville', '5 star', 'perk', 'munch', 'milkybar', 'toblerone'],
    primaryCategory: 'chocolate',
    aliases: ['chocolate', 'milk chocolate', 'dark chocolate', 'cocoa', 'cacao'],
    keywords: ['chocolate', 'cocoa', 'cacao', 'cadbury', 'dairy milk'],
  },
  {
    triggers: ['maggi', 'noodle', 'noodles', 'ramen', 'pasta', 'macaroni', 'spaghetti', 'indomie', 'top ramen', 'wai wai', 'penne', 'fettuccine', 'yippee', 'chow mein'],
    primaryCategory: 'noodles',
    aliases: ['noodles', 'instant noodles', 'ramen', 'pasta'],
    keywords: ['noodles', 'noodle', 'ramen', 'pasta', 'maggi'],
  },
  {
    triggers: ['lays', "lay's", 'potato chips', 'chips', 'crisps', 'doritos', 'pringles', 'nachos', 'tortilla chips', 'kurkure', 'bingo', 'potato wafers'],
    primaryCategory: 'potato chips',
    aliases: ['potato chips', 'chips', 'crisps'],
    keywords: ['chips', 'potato chips', 'crisps', 'potatoes'],
  },
  {
    triggers: ['oreo', 'cookie', 'cookies', 'biscuit', 'biscuits', 'parle-g', 'parle g', 'hide & seek', 'bourbon', 'good day', 'digestive', 'marie', 'wafer', 'custard cream'],
    primaryCategory: 'cookies',
    aliases: ['cookies', 'biscuits', 'cookie'],
    keywords: ['cookies', 'biscuits', 'oreo', 'cookie'],
  },
  {
    triggers: ['nutella', 'hazelnut spread', 'chocolate spread', 'choco spread'],
    primaryCategory: 'hazelnut spread',
    aliases: ['hazelnut spread', 'chocolate spread', 'spread'],
    keywords: ['nutella', 'hazelnut spread', 'chocolate spread'],
  },
  {
    triggers: ['peanut butter', 'pb', 'almond butter', 'cashew butter', 'nut butter'],
    primaryCategory: 'peanut butter',
    aliases: ['peanut butter', 'nut butter'],
    keywords: ['peanut butter', 'peanuts', 'pb'],
  },
  {
    triggers: ['amul butter', 'butter', 'unsalted butter', 'salted butter', 'ghee'],
    primaryCategory: 'butter',
    aliases: ['butter', 'ghee'],
    keywords: ['butter', 'ghee'],
  },
  {
    triggers: ['paneer', 'cottage cheese'],
    primaryCategory: 'paneer',
    aliases: ['paneer', 'cottage cheese'],
    keywords: ['paneer', 'cottage cheese'],
  },
  {
    triggers: ['cheese', 'cheddar', 'mozzarella', 'parmesan', 'processed cheese', 'cream cheese', 'feta', 'gouda'],
    primaryCategory: 'cheese',
    aliases: ['cheese', 'cheddar', 'mozzarella'],
    keywords: ['cheese', 'processed cheese', 'cheddar'],
  },
  {
    triggers: ['yogurt', 'yoghurt', 'curd', 'dahi', 'greek yogurt', 'lassi'],
    primaryCategory: 'yogurt',
    aliases: ['yogurt', 'greek yogurt', 'curd'],
    keywords: ['yogurt', 'curd', 'dahi'],
  },
  {
    triggers: ['oats', 'oatmeal', 'rolled oats', 'quaker', 'steel cut oats', 'instant oats', 'muesli', 'granola', 'corn flakes', 'chocos', 'cereal'],
    primaryCategory: 'oats',
    aliases: ['oats', 'oatmeal', 'rolled oats'],
    keywords: ['oats', 'oatmeal', 'oat', 'rolled oats'],
  },
  {
    triggers: ['bread', 'toast', 'loaf', 'bun', 'pita', 'bagel', 'brioche', 'sourdough'],
    primaryCategory: 'bread',
    aliases: ['bread', 'toast'],
    keywords: ['bread', 'toast'],
  },
  {
    triggers: ['egg', 'eggs', 'egg whites'],
    primaryCategory: 'egg',
    aliases: ['egg', 'eggs'],
    keywords: ['egg', 'eggs'],
  },
  {
    triggers: ['milk', 'dairy', 'amul milk', 'whole milk', 'skim milk', 'almond milk', 'soy milk', 'oat milk', 'coconut milk'],
    primaryCategory: 'milk',
    aliases: ['milk', 'dairy'],
    keywords: ['milk', 'dairy'],
  },
  {
    triggers: ['rice', 'basmati', 'brown rice', 'jasmine rice'],
    primaryCategory: 'rice',
    aliases: ['rice', 'basmati'],
    keywords: ['rice', 'basmati'],
  },
  {
    triggers: ['honey', 'maple syrup', 'agave', 'jaggery'],
    primaryCategory: 'honey',
    aliases: ['honey', 'syrup'],
    keywords: ['honey', 'maple syrup'],
  },
];

const BRAND_NOISE_WORDS = [
  'cadbury', 'nestle', "nestlé", 'amul', 'britannia', 'kellogg', "kellogg's",
  'quaker', 'lays', "lay's", 'parle', 'haldiram', "haldiram's", 'doritos',
  'pringles', 'oreo', 'hershey', "hershey's", 'pepsi', 'coca-cola', 'coke',
  'organic', 'fresh', 'natural', 'classic', 'original', 'masala', 'special',
  'premium', 'rich', 'creamy', 'crunchy', 'pure', 'delight', 'pack', 'bar',
  'crispy', 'baked', 'roasted', 'silk', '2-minute', 'minute'
];

/**
 * Normalizes a product into its generic culinary category/ingredient
 * Priority: 1. Category metadata, 2. Brand + Name taxonomy, 3. Ingredients text, 4. Brand-stripped term
 */
const normalizeProductForRecipe = (sourceProduct) => {
  if (!sourceProduct) {
    return {
      originalProduct: '',
      normalizedIngredient: '',
      recipeSearchQuery: '',
    };
  }

  const rawName = (typeof sourceProduct === 'string' ? sourceProduct : sourceProduct?.name || '').trim();
  const rawBrand = (typeof sourceProduct === 'object' ? sourceProduct?.brand || '' : '').trim();
  const rawCategory = (typeof sourceProduct === 'object' ? (sourceProduct?.category || sourceProduct?.categories || sourceProduct?.categoryTags || '') : '').toString();
  const rawIngredients = (typeof sourceProduct === 'object' ? sourceProduct?.ingredients || '' : '').toString();

  // 1. Check Product Name against taxonomy (Highest specificity)
  const nameLower = rawName.toLowerCase();
  for (const mapping of KNOWN_PRODUCT_MAPPINGS) {
    for (const trigger of mapping.triggers) {
      if (nameLower.includes(trigger)) {
        return {
          originalProduct: rawName,
          normalizedIngredient: mapping.primaryCategory,
          recipeSearchQuery: mapping.primaryCategory,
        };
      }
    }
  }

  // 2. Check Category metadata (Open Food Facts / Database tags)
  const categoryLower = rawCategory.toLowerCase();
  if (categoryLower) {
    for (const mapping of KNOWN_PRODUCT_MAPPINGS) {
      for (const trigger of mapping.triggers) {
        if (categoryLower.includes(trigger)) {
          return {
            originalProduct: rawName,
            normalizedIngredient: mapping.primaryCategory,
            recipeSearchQuery: mapping.primaryCategory,
          };
        }
      }
    }
  }

  // 3. Check Name + Brand against taxonomy
  const nameBrandLower = `${rawBrand} ${rawName}`.toLowerCase();
  for (const mapping of KNOWN_PRODUCT_MAPPINGS) {
    for (const trigger of mapping.triggers) {
      if (nameBrandLower.includes(trigger)) {
        return {
          originalProduct: rawName,
          normalizedIngredient: mapping.primaryCategory,
          recipeSearchQuery: mapping.primaryCategory,
        };
      }
    }
  }

  // 4. Check Ingredients text against taxonomy
  const ingredientsLower = rawIngredients.toLowerCase();
  if (ingredientsLower) {
    for (const mapping of KNOWN_PRODUCT_MAPPINGS) {
      for (const trigger of mapping.triggers) {
        if (ingredientsLower.includes(trigger)) {
          return {
            originalProduct: rawName,
            normalizedIngredient: mapping.primaryCategory,
            recipeSearchQuery: mapping.primaryCategory,
          };
        }
      }
    }
  }

  // 5. Strip brand noise words
  let cleaned = nameBrandLower;
  for (const brand of BRAND_NOISE_WORDS) {
    const reg = new RegExp(`\\b${brand}\\b`, 'gi');
    cleaned = cleaned.replace(reg, '');
  }

  cleaned = cleaned.replace(/[^a-zA-Z0-9\s]/g, ' ').replace(/\s+/g, ' ').trim();
  const fallbackCategory = cleaned || rawName.toLowerCase();

  return {
    originalProduct: rawName,
    normalizedIngredient: fallbackCategory,
    recipeSearchQuery: fallbackCategory,
  };
};


/**
 * Normalizes a source product object or name to a clean culinary description
 */
const normalizeSourceProduct = (sourceProduct) => {
  if (!sourceProduct) {
    return {
      originalName: '',
      primaryCategory: '',
      aliases: [],
      keywords: [],
      cleanQuery: '',
    };
  }

  const normalized = normalizeProductForRecipe(sourceProduct);
  const matchedMapping = KNOWN_PRODUCT_MAPPINGS.find(
    (m) => m.primaryCategory === normalized.normalizedIngredient
  );

  return {
    originalName: normalized.originalProduct,
    primaryCategory: normalized.normalizedIngredient,
    aliases: matchedMapping ? matchedMapping.aliases : [normalized.normalizedIngredient],
    keywords: matchedMapping ? matchedMapping.keywords : [normalized.normalizedIngredient],
    cleanQuery: normalized.recipeSearchQuery,
  };
};


/**
 * Cleans pantry ingredients by stripping branded terms or source product mentions
 */
const cleanPantryIngredients = (pantryItems = [], sourceProduct = null) => {
  const normalized = normalizeSourceProduct(sourceProduct);
  const sourceLower = normalized.originalName.toLowerCase();
  const catLower = normalized.primaryCategory.toLowerCase();

  const cleaned = [];
  for (const item of pantryItems) {
    const name = (typeof item === 'string' ? item : item?.name || item?.label || '').trim();
    if (!name) continue;
    const lower = name.toLowerCase();

    // Skip if pantry item is the same as source product
    if (sourceLower && (lower === sourceLower || sourceLower.includes(lower) || lower.includes(sourceLower))) {
      continue;
    }
    if (catLower && lower === catLower) {
      continue;
    }

    // Strip brand noise
    let itemClean = lower;
    for (const brand of BRAND_NOISE_WORDS) {
      const reg = new RegExp(`\\b${brand}\\b`, 'gi');
      itemClean = itemClean.replace(reg, '');
    }
    itemClean = itemClean.replace(/[^a-zA-Z0-9\s]/g, ' ').replace(/\s+/g, ' ').trim();

    if (itemClean.length > 1) {
      cleaned.push(itemClean);
    }
  }

  return [...new Set(cleaned)];
};

/**
 * Build prioritized search query attempts for Edamam / Spoonacular
 * e.g. for Cadbury Dairy Milk + Banana + Oats + Breakfast:
 * Attempt 1: "chocolate banana oats"
 * Attempt 2: "chocolate banana"
 * Attempt 3: "chocolate oats"
 * Attempt 4: "chocolate breakfast"
 */
const buildPrioritizedQueries = ({ sourceProduct, pantryIngredients = [], mealType = '', craving = '' }) => {
  const normalized = normalizeSourceProduct(sourceProduct);
  const primaryCat = normalized.primaryCategory || craving || '';
  const cleanPantry = cleanPantryIngredients(pantryIngredients, sourceProduct);
  const meal = mealType ? mealType.toLowerCase().trim() : '';

  const queries = [];
  const seen = new Set();

  const addQuery = (q) => {
    const trimmed = q.trim();
    if (trimmed && !seen.has(trimmed.toLowerCase())) {
      seen.add(trimmed.toLowerCase());
      queries.push(trimmed);
    }
  };

  if (primaryCat) {
    // Attempt 1: Product category + Top 2 pantry ingredients
    if (cleanPantry.length >= 2) {
      addQuery(`${primaryCat} ${cleanPantry[0]} ${cleanPantry[1]}`);
    }

    // Attempt 2: Product category + 1st pantry ingredient
    if (cleanPantry.length >= 1) {
      addQuery(`${primaryCat} ${cleanPantry[0]}`);
    }

    // Attempt 3: Product category + 2nd pantry ingredient
    if (cleanPantry.length >= 2) {
      addQuery(`${primaryCat} ${cleanPantry[1]}`);
    }

    // Attempt 4: Product category + Meal Type (e.g. "chocolate breakfast")
    if (meal) {
      addQuery(`${primaryCat} ${meal}`);
    }

    // Attempt 5: Product category alone
    addQuery(primaryCat);
  } else if (craving) {
    if (cleanPantry.length >= 1) {
      addQuery(`${craving} ${cleanPantry[0]}`);
    }
    addQuery(craving);
  } else {
    // No source product, use pantry ingredients
    if (cleanPantry.length >= 2) {
      addQuery(`${cleanPantry[0]} ${cleanPantry[1]}`);
    }
    if (cleanPantry.length >= 1) {
      addQuery(cleanPantry[0]);
    }
    if (meal) {
      addQuery(meal);
    }
  }

  return {
    queries,
    primaryCategory: primaryCat,
    normalized,
    cleanPantry,
  };
};

module.exports = {
  normalizeProductForRecipe,
  normalizeSourceProduct,
  cleanPantryIngredients,
  buildPrioritizedQueries,
  KNOWN_PRODUCT_MAPPINGS,
};

