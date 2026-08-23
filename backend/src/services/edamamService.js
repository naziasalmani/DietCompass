const https = require('https');
const { buildPrioritizedQueries, cleanPantryIngredients } = require('../utils/productNormalizer');
const { validateRecipeSafety } = require('../utils/dietarySafetyValidator');
const { rankAndScoreRecipes } = require('../utils/recipeScorer');

/**
 * Execute HTTP GET request
 */
const httpGet = (url) => {
  return new Promise((resolve, reject) => {
    https
      .get(url, (res) => {
        let data = '';
        res.on('data', (chunk) => (data += chunk));
        res.on('end', () => {
          try {
            if (res.statusCode >= 200 && res.statusCode < 300) {
              resolve(JSON.parse(data));
            } else {
              const err = new Error(`HTTP ${res.statusCode}: ${data}`);
              err.statusCode = res.statusCode;
              reject(err);
            }
          } catch (e) {
            reject(new Error(`Failed to parse JSON response: ${e.message}`));
          }
        });
      })
      .on('error', (err) => reject(err));
  });
};

/**
 * Map diet preference to Edamam health query parameters
 */
const mapDietToEdamamHealth = (dietType) => {
  if (!dietType || typeof dietType !== 'string') return [];
  const d = dietType.toLowerCase().trim();

  const health = [];
  if (d.includes('vegan')) health.push('vegan');
  else if (d.includes('vegetarian')) health.push('vegetarian');
  else if (d.includes('pescatarian') || d.includes('pescetarian')) health.push('pescatarian');

  if (d.includes('gluten') && d.includes('free')) health.push('gluten-free');
  if (d.includes('dairy') && d.includes('free')) health.push('dairy-free');
  if (d.includes('keto')) health.push('keto-friendly');
  if (d.includes('paleo')) health.push('paleo');

  return health;
};

/**
 * Map user allergies to Edamam health query parameters
 */
const mapAllergiesToEdamamHealth = (allergies = []) => {
  if (!Array.isArray(allergies)) return [];
  const mapped = [];

  for (const allergy of allergies) {
    const a = allergy.toLowerCase();
    if (a.includes('peanut')) mapped.push('peanut-free');
    else if (a.includes('tree nut') || a.includes('almond') || a.includes('cashew') || a.includes('walnut')) mapped.push('tree-nut-free');
    else if (a.includes('dairy') || a.includes('milk') || a.includes('lactose')) mapped.push('dairy-free');
    else if (a.includes('egg')) mapped.push('egg-free');
    else if (a.includes('gluten') || a.includes('wheat')) mapped.push('gluten-free');
    else if (a.includes('soy')) mapped.push('soy-free');
    else if (a.includes('fish')) mapped.push('fish-free');
    else if (a.includes('shellfish') || a.includes('crustacean')) mapped.push('shellfish-free');
    else if (a.includes('sesame')) mapped.push('sesame-free');
  }

  return [...new Set(mapped)];
};

/**
 * Build "WhatsIn" nutrition benefit tags for the Flutter UI
 */
const buildWhatsInsideTags = (recipe) => {
  const tags = [];
  const protein = recipe.proteinGrams || 0;
  const fiber = recipe.fiberGrams || 0;
  const calories = recipe.kcal || 0;
  const sugar = recipe.sugarGrams || 0;
  const fat = recipe.fatGrams || 0;

  if (fiber >= 5) {
    tags.push({
      icon: 'eco_rounded',
      title: 'High in Fiber',
      subtitle: `${fiber}g fiber for gut health`,
      color: '#1E8A4C',
    });
  }

  if (protein >= 10) {
    tags.push({
      icon: 'fitness_center_rounded',
      title: 'High Protein',
      subtitle: `${protein}g protein per serving`,
      color: '#E0862E',
    });
  }

  if (sugar <= 5) {
    tags.push({
      icon: 'shield_outlined',
      title: 'Low Sugar',
      subtitle: `${sugar}g natural sugar`,
      color: '#6C4EF5',
    });
  } else if (calories <= 340) {
    tags.push({
      icon: 'shopping_bag_rounded',
      title: 'Weight Friendly',
      subtitle: `${calories} kcal balanced portion`,
      color: '#6C4EF5',
    });
  }

  if (fat <= 8) {
    tags.push({
      icon: 'favorite_rounded',
      title: 'Heart Healthy',
      subtitle: 'Low saturated fat',
      color: '#E0525C',
    });
  }

  if (tags.length === 0) {
    tags.push({
      icon: 'eco_rounded',
      title: 'Nutrient Rich',
      subtitle: 'Balanced whole food nutrition',
      color: '#1E8A4C',
    });
  }

  return tags.slice(0, 4);
};

/**
 * Format a raw Edamam recipe into the common internal Recipe model
 * Preserves ONE recipe object (uri, label, image, url, ingredients, nutrients)
 */
const normalizeEdamamRecipe = (hitRecipe, userPantry = []) => {
  if (!hitRecipe) return null;

  // Validate Image: must be non-empty valid URL
  const imageUrl = hitRecipe.images?.REGULAR?.url || hitRecipe.images?.LARGE?.url || hitRecipe.image || '';
  if (!imageUrl || typeof imageUrl !== 'string' || (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://'))) {
    return null; // Reject recipe with invalid image
  }

  const servings = Math.max(1, Math.round(hitRecipe.yield || 1));
  const nutrients = hitRecipe.totalNutrients || {};

  const getPerServingNutrient = (code, fallback = 0) => {
    const item = nutrients[code];
    if (item && typeof item.quantity === 'number') {
      return Math.max(0, Math.round(item.quantity / servings));
    }
    return fallback;
  };

  const kcal = getPerServingNutrient('ENERC_KCAL', Math.round((hitRecipe.calories || 300) / servings));
  const proteinGrams = getPerServingNutrient('PROCNT', 10);
  const carbsGrams = getPerServingNutrient('CHOCDF', 45);
  const fatGrams = getPerServingNutrient('FAT', 8);
  const fiberGrams = getPerServingNutrient('FIBTG', 5);
  const sugarGrams = getPerServingNutrient('SUGAR', 6);
  const sodiumMg = getPerServingNutrient('NA', 120);

  // Ingredients breakdown
  const rawIngLines = Array.isArray(hitRecipe.ingredientLines) ? hitRecipe.ingredientLines : [];
  const rawIngObjects = Array.isArray(hitRecipe.ingredients) ? hitRecipe.ingredients : [];

  const extendedIngredients = rawIngObjects.length > 0
    ? rawIngObjects.map((i) => ({
        name: i.food || i.text || '',
        amount: `${i.quantity ? Math.round(i.quantity * 10) / 10 : ''} ${i.measure || ''}`.trim() || 'As desired',
        original: i.text || `${i.quantity || ''} ${i.measure || ''} ${i.food || ''}`.trim(),
      }))
    : rawIngLines.map((line) => ({
        name: line,
        amount: 'As desired',
        original: line,
      }));

  // Identify matching pantry ingredients
  const usedIngredients = [];
  const missedIngredients = [];
  const ingCorpus = extendedIngredients.map((i) => i.name.toLowerCase()).join(' ');

  for (const pantryItem of userPantry) {
    const p = (typeof pantryItem === 'string' ? pantryItem : pantryItem?.name || '').toLowerCase().trim();
    if (p.length > 2) {
      if (ingCorpus.includes(p)) {
        usedIngredients.push(pantryItem);
      }
    }
  }

  // Instructions
  let instructions = [];
  if (Array.isArray(hitRecipe.instructionLines) && hitRecipe.instructionLines.length > 0) {
    instructions = hitRecipe.instructionLines;
  } else if (typeof hitRecipe.instructions === 'string' && hitRecipe.instructions.length > 0) {
    instructions = hitRecipe.instructions.split(/\r?\n|\. /).map((s) => s.trim()).filter((s) => s.length > 3);
  } else if (rawIngLines.length > 0) {
    instructions = [
      `Gather ingredients: ${rawIngLines.slice(0, 3).join(', ')}.`,
      'Combine ingredients and prepare according to desired taste and texture.',
      hitRecipe.url ? `View full preparation notes at original source: ${hitRecipe.url}` : 'Serve warm and fresh!',
    ];
  } else {
    instructions = ['Prepare ingredients as desired.', 'Cook according to personal preference.', 'Serve fresh and enjoy!'];
  }

  const diets = [
    ...(hitRecipe.dietLabels || []),
    ...(hitRecipe.healthLabels || []).filter((h) => ['Vegetarian', 'Vegan', 'Pescatarian', 'Gluten-Free', 'Dairy-Free'].includes(h)),
  ];

  const tagline = diets.length > 0
    ? diets.slice(0, 3).join(' • ')
    : 'Healthy • Fresh • Nutritious';

  const description = (hitRecipe.source ? `Curated from ${hitRecipe.source}. ` : '') +
    (hitRecipe.cuisineType ? `A delicious ${hitRecipe.cuisineType.join('/')} recipe ` : 'A balanced, nutritious recipe ') +
    `packed with ${kcal} kcal and ${proteinGrams}g protein.`;

  const stableId = hitRecipe.uri;

  const normalized = {
    id: stableId,
    sourceRecipeId: stableId,
    recipeSource: 'edamam',
    sourceRecipeUrl: hitRecipe.url || hitRecipe.shareAs || '',
    sourceImageUrl: imageUrl,
    title: hitRecipe.label || 'Nutritious Recipe',
    tagline,
    description,
    timeMinutes: Math.max(10, Math.round(hitRecipe.totalTime || 15)),
    kcal,
    proteinGrams,
    carbsGrams,
    fatGrams,
    fiberGrams,
    sugarGrams,
    sodiumMg,
    image: imageUrl,
    imageAsset: imageUrl,
    images: [imageUrl],
    servings,
    recommended: false,
    diets: diets.map((d) => d.toLowerCase()),
    mealType: hitRecipe.mealType || [],
    dishTypes: hitRecipe.dishType || [],
    usedIngredientCount: usedIngredients.length,
    missedIngredientCount: missedIngredients.length,
    usedIngredients,
    missedIngredients,
    ingredients: extendedIngredients,
    instructions,
    pantryMatchSummary: usedIngredients.length > 0
      ? `Uses ${usedIngredients.length} pantry ingredients`
      : 'Nutrient-rich balanced pairing',
  };

  normalized.whatsInside = buildWhatsInsideTags(normalized);

  return normalized;
};

/**
 * Query Edamam Recipe Search API v2
 */
const searchEdamamRecipes = async ({
  sourceProduct = null,
  ingredients = [],
  pantryItems = [],
  mealType = '',
  maxTime = null,
  craving = '',
  userProfile = null,
  personalization = null,
  number = 6,
}) => {
  const appId = (process.env.EDAMAM_APP_ID || '').trim();
  const appKey = (process.env.EDAMAM_APP_KEY || '').trim();

  const allPantry = [
    ...ingredients,
    ...pantryItems.map((p) => (typeof p === 'string' ? p : p.name || p.label || '')),
  ].map((s) => s.trim()).filter((s) => s.length > 0);

  const cleanPantry = cleanPantryIngredients(allPantry, sourceProduct);

  const prioritized = buildPrioritizedQueries({
    sourceProduct,
    pantryIngredients: allPantry,
    mealType,
    craving,
  });

  const dietType = personalization?.dietType || userProfile?.dietType || '';
  const allergies = personalization?.allergies || userProfile?.allergies || [];
  const healthFilters = [
    ...mapDietToEdamamHealth(dietType),
    ...mapAllergiesToEdamamHealth(allergies),
  ];

  console.log('--- [EDAMAM SERVICE] Starting Multi-Tier Query Search ---');
  console.log('[EDAMAM DEBUG] Queries to attempt:', prioritized.queries);
  console.log('[EDAMAM DEBUG] Health filters:', healthFilters);

  if (!appId || !appKey || appId === 'your_edamam_app_id_here' || appKey === 'your_edamam_app_key_here') {
    console.warn('[EDAMAM SERVICE] EDAMAM_APP_ID or EDAMAM_APP_KEY is not configured in backend .env');
    return {
      recipes: [],
      rawCount: 0,
      validCount: 0,
      bestScore: 0,
      bestRecipe: null,
      status: 'EDAMAM_HTTP_ERROR',
      error: 'EDAMAM_API_KEYS_NOT_CONFIGURED',
      attemptedQueries: prioritized.queries,
    };
  }

  const combinedHits = [];
  const seenUris = new Set();
  let lastError = null;

  for (const query of prioritized.queries) {
    try {
      let url = `https://api.edamam.com/api/recipes/v2?type=public&app_id=${encodeURIComponent(appId)}&app_key=${encodeURIComponent(appKey)}&q=${encodeURIComponent(query)}`;

      for (const h of healthFilters) {
        url += `&health=${encodeURIComponent(h)}`;
      }

      if (maxTime && typeof maxTime === 'number') {
        url += `&time=1-${maxTime}`;
      }

      console.log(`[EDAMAM DEBUG] Calling Edamam v2 for q="${query}"...`);
      const res = await httpGet(url);

      if (res && Array.isArray(res.hits)) {
        console.log(`[EDAMAM DEBUG] Edamam returned ${res.hits.length} hits for q="${query}"`);
        for (const hit of res.hits) {
          const r = hit?.recipe;
          if (r && r.uri && !seenUris.has(r.uri)) {
            seenUris.add(r.uri);
            combinedHits.push(r);
          }
        }
      }

      // If we already have enough unique hits (e.g. >= 10), stop further requests
      if (combinedHits.length >= 12) {
        break;
      }
    } catch (err) {
      console.warn(`[EDAMAM SERVICE] Query "${query}" failed:`, err.message);
      lastError = err;
    }
  }

  console.log('[EDAMAM DEBUG] Total unique Edamam raw hits gathered:', combinedHits.length);

  if (combinedHits.length === 0) {
    return {
      recipes: [],
      rawCount: 0,
      validCount: 0,
      bestScore: 0,
      bestRecipe: null,
      status: lastError ? 'EDAMAM_HTTP_ERROR' : 'EDAMAM_ZERO_RESULTS',
      error: lastError ? lastError.message : 'No recipes returned from Edamam',
      attemptedQueries: prioritized.queries,
    };
  }

  // Normalize all recipes into common model
  const normalizedRecipes = combinedHits
    .map((r) => normalizeEdamamRecipe(r, cleanPantry))
    .filter((r) => r !== null);

  console.log('[EDAMAM DEBUG] Valid normalized recipes (with images):', normalizedRecipes.length);

  // Score, rank, and validate with DietarySafetyValidator
  const scoredResult = rankAndScoreRecipes({
    recipes: normalizedRecipes,
    sourceProduct,
    pantryIngredients: allPantry,
    mealType,
    userProfile,
    personalization,
    minScoreThreshold: 25,
  });

  const validCount = scoredResult.validRecipes.length;
  const bestScore = scoredResult.bestScore;
  const bestRecipe = scoredResult.bestRecipe;

  let status = 'EDAMAM_SUCCESS';
  if (validCount === 0) {
    status = normalizedRecipes.length > 0 ? 'EDAMAM_DIET_FAILURE' : 'EDAMAM_ZERO_RESULTS';
  } else if (bestScore < 30) {
    status = 'EDAMAM_LOW_RELEVANCE';
  }

  const finalRecipes = scoredResult.validRecipes.slice(0, number).map((r, index) => {
    if (index === 0) return { ...r, recommended: true };
    return r;
  });

  return {
    recipes: finalRecipes,
    rawCount: combinedHits.length,
    validCount,
    bestScore,
    bestRecipe,
    status,
    error: lastError ? lastError.message : null,
    attemptedQueries: prioritized.queries,
  };
};

/**
 * Fetch recipe details by Edamam URI
 */
const getEdamamRecipeDetailsByUri = async (uri, userProfile, personalization) => {
  const appId = (process.env.EDAMAM_APP_ID || '').trim();
  const appKey = (process.env.EDAMAM_APP_KEY || '').trim();

  if (!uri || !appId || !appKey) return null;

  try {
    // Extract recipe ID from URI if needed or search by URI
    const recipeId = uri.includes('#recipe_') ? uri.split('#recipe_')[1] : encodeURIComponent(uri);
    const url = `https://api.edamam.com/api/recipes/v2/${recipeId}?type=public&app_id=${encodeURIComponent(appId)}&app_key=${encodeURIComponent(appKey)}`;

    const res = await httpGet(url);
    if (res && res.recipe) {
      return normalizeEdamamRecipe(res.recipe, []);
    }
  } catch (e) {
    console.warn('[EDAMAM SERVICE] Failed to fetch recipe details for URI:', uri, e.message);
  }

  return null;
};

module.exports = {
  searchEdamamRecipes,
  normalizeEdamamRecipe,
  getEdamamRecipeDetailsByUri,
  mapDietToEdamamHealth,
  mapAllergiesToEdamamHealth,
};
