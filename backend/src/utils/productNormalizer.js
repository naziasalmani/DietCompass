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
    triggers: ['chilli', 'chili', 'chillies', 'chilies', 'green chilli', 'red chilli', 'chilli powder', 'capsicum', 'peppers'],
    primaryCategory: 'chilli',
    aliases: ['chilli', 'chili', 'peppers', 'chilis'],
    keywords: ['chilli', 'chili', 'chilies', 'chillies', 'peppers'],
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

  // 3. Check Ingredients Text
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

  // 4. Strip Brand Noise Words from Product Name
  let cleaned = nameLower;
  for (const brand of BRAND_NOISE_WORDS) {
    const reg = new RegExp(`\\b${brand}\\b`, 'gi');
    cleaned = cleaned.replace(reg, '');
  }
  cleaned = cleaned.replace(/[^a-zA-Z0-9\s]/g, ' ').replace(/\s+/g, ' ').trim();

  // Fallback term
  const finalQuery = cleaned.length > 2 ? cleaned : 'food';

  return {
    originalProduct: rawName,
    normalizedIngredient: finalQuery,
    recipeSearchQuery: finalQuery,
  };
};

/**
 * Normalizes sourceProduct safely for all service consumers
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
 * Matches a recipe against user's pantry ingredients using robust semantic dictionary
 * Returns the array of matching pantry ingredients (empty if 0 matches)
 */
const getMatchingPantryIngredients = (recipe, pantryIngredients = []) => {
  if (!recipe || !Array.isArray(pantryIngredients) || pantryIngredients.length === 0) {
    return [];
  }

  const title = (recipe.title || '').toLowerCase();
  const summary = (recipe.summary || recipe.description || '').toLowerCase();
  const ings = (recipe.ingredients || recipe.extendedIngredients || recipe.ingredientLines || [])
    .map((i) => (typeof i === 'string' ? i : `${i.name || i.original || i.text || ''}`))
    .join(' ')
    .toLowerCase();
  const corpus = `${title} ${summary} ${ings}`;

  const matched = [];
  for (const pantryItem of pantryIngredients) {
    const raw = (typeof pantryItem === 'string' ? pantryItem : pantryItem?.name || pantryItem?.label || '').toLowerCase().trim();
    if (!raw || raw.length < 2) continue;

    // Stem / alias dictionary for comprehensive culinary matching
    const aliases = [raw];
    if (raw === 'noodle') aliases.push('noodles', 'ramen', 'pasta', 'spaghetti', 'chow mein', 'macaroni', 'penne', 'fusilli');
    else if (raw === 'noodles') aliases.push('noodle', 'ramen', 'pasta', 'spaghetti', 'chow mein', 'macaroni');
    else if (raw === 'rice') aliases.push('rice', 'basmati', 'risotto', 'fried rice', 'pulao', 'pilaf', 'jasmine rice');
    else if (raw === 'chilli' || raw === 'chili') aliases.push('chilli', 'chili', 'chilies', 'chillies', 'peppers', 'pepper', 'capsicum', 'jalapeno', 'paprika', 'cayenne', 'hot sauce');
    else if (raw === 'oat' || raw === 'oats') aliases.push('oats', 'oat', 'oatmeal', 'porridge', 'granola', 'muesli');
    else if (raw === 'egg' || raw === 'eggs') aliases.push('egg', 'eggs', 'omelette', 'scramble', 'scrambled');
    else if (raw === 'banana' || raw === 'bananas') aliases.push('banana', 'bananas');
    else if (raw === 'tomato' || raw === 'tomatoes') aliases.push('tomato', 'tomatoes', 'cherry tomato');
    else if (raw === 'potato' || raw === 'potatoes') aliases.push('potato', 'potatoes', 'tater');
    else if (raw === 'milk') aliases.push('milk', 'dairy');
    else if (raw === 'cheese') aliases.push('cheese', 'cheddar', 'mozzarella', 'parmesan', 'feta');
    else if (raw === 'bread') aliases.push('bread', 'toast', 'bun', 'pita', 'bagel');
    else if (raw === 'spinach') aliases.push('spinach', 'palak', 'greens');
    else if (raw === 'mushroom' || raw === 'mushrooms') aliases.push('mushroom', 'mushrooms');
    else if (raw.endsWith('s')) aliases.push(raw.substring(0, raw.length - 1));
    else aliases.push(`${raw}s`);

    if (raw === 'egg' || raw === 'eggs') {
      const cleanCorpusNoEggplant = corpus.replace(/\begg\s*plants?\b/gi, '');
      if (!/\beggs?\b/i.test(cleanCorpusNoEggplant) && !/\b(omelette|scramble|scrambled)\b/i.test(cleanCorpusNoEggplant)) {
        continue;
      }
    }

    let isMatch = false;
    for (const alias of aliases) {
      const escaped = alias.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      if (new RegExp(`\\b${escaped}\\b`, 'i').test(corpus)) {
        isMatch = true;
        break;
      }
    }

    if (isMatch) {
      matched.push(raw);
    }
  }

  return [...new Set(matched)];
};

/**
 * Builds diverse search query attempts across individual pantry ingredients and sensible combinations
 * Ensures NO single ingredient dominates and all pantry items receive search opportunities.
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
    if (cleanPantry.length >= 2) {
      addQuery(`${primaryCat} ${cleanPantry[0]} ${cleanPantry[1]}`);
    }
    if (cleanPantry.length >= 1) {
      addQuery(`${primaryCat} ${cleanPantry[0]}`);
    }
    if (cleanPantry.length >= 2) {
      addQuery(`${primaryCat} ${cleanPantry[1]}`);
    }
    if (meal) {
      addQuery(`${primaryCat} ${meal}`);
    }
    addQuery(primaryCat);
  } else if (craving) {
    if (cleanPantry.length >= 1) {
      addQuery(`${craving} ${cleanPantry[0]}`);
    }
    addQuery(craving);
  } else {
    // PANTRY MODE: Generate diverse individual & combination queries for ALL pantry items
    // 1. Every individual pantry ingredient alone
    for (const p of cleanPantry) {
      addQuery(p);
    }

    // 2. Sensible pairs across pantry items
    for (let i = 0; i < cleanPantry.length; i++) {
      for (let j = i + 1; j < cleanPantry.length; j++) {
        addQuery(`${cleanPantry[i]} ${cleanPantry[j]}`);
      }
    }

    // 3. With meal type
    if (meal) {
      for (const p of cleanPantry.slice(0, 3)) {
        addQuery(`${p} ${meal}`);
      }
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
  getMatchingPantryIngredients,
  buildPrioritizedQueries,
  KNOWN_PRODUCT_MAPPINGS,
};
