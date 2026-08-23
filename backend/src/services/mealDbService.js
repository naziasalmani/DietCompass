const https = require('https');
const { buildPrioritizedQueries, cleanPantryIngredients, normalizeSourceProduct } = require('../utils/productNormalizer');
const { validateRecipeSafety } = require('../utils/dietarySafetyValidator');
const { rankAndScoreRecipes } = require('../utils/recipeScorer');

const THEMEALDB_BASE_URL = 'https://www.themealdb.com/api/json/v1/1';

/**
 * Execute HTTP GET request with error handling
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
 * Build "WhatsIn" nutrient and benefit tags for the Flutter UI
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

  if (sugar <= 6) {
    tags.push({
      icon: 'shield_outlined',
      title: 'Balanced Sugar',
      subtitle: `${sugar}g natural sweetness`,
      color: '#6C4EF5',
    });
  } else if (calories <= 360) {
    tags.push({
      icon: 'shopping_bag_rounded',
      title: 'Weight Friendly',
      subtitle: `${calories} kcal balanced portion`,
      color: '#6C4EF5',
    });
  }

  if (fat <= 10) {
    tags.push({
      icon: 'favorite_rounded',
      title: 'Heart Healthy',
      subtitle: 'Wholesome ingredients',
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
 * Normalize TheMealDB meal into common internal Recipe model
 * Preserves exact meal ID, title, image, ingredients, and instructions as ONE Recipe object.
 */
const normalizeMealDbRecipe = (meal, userPantry = []) => {
  if (!meal || !meal.idMeal) return null;

  const imageUrl = (meal.strMealThumb || '').trim();
  if (!imageUrl || (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://'))) {
    return null; // Reject recipe with invalid/missing image
  }

  // Extract ingredients and measurements (strIngredient1..20, strMeasure1..20)
  const extendedIngredients = [];
  for (let i = 1; i <= 20; i++) {
    const ingName = (meal[`strIngredient${i}`] || '').trim();
    const measure = (meal[`strMeasure${i}`] || '').trim();
    if (ingName && ingName.length > 0) {
      extendedIngredients.push({
        name: ingName,
        amount: measure || 'As desired',
        original: measure ? `${measure} ${ingName}` : ingName,
      });
    }
  }

  // Extract instructions
  const rawInstructions = meal.strInstructions || '';
  const instructions = rawInstructions.length > 0
    ? rawInstructions
        .split(/\r?\n|\. /)
        .map((s) => s.trim())
        .filter((s) => s.length > 3)
    : [
        'Prepare all fresh ingredients as specified.',
        'Combine and cook according to recipe method.',
        'Serve fresh and enjoy your meal!',
      ];

  // Match pantry ingredients
  const usedIngredients = [];
  const missedIngredients = [];
  const ingCorpus = extendedIngredients.map((i) => i.name.toLowerCase()).join(' ');

  for (const pantryItem of userPantry) {
    const p = (typeof pantryItem === 'string' ? pantryItem : pantryItem?.name || '').toLowerCase().trim();
    if (p.length > 2) {
      if (ingCorpus.includes(p)) {
        usedIngredients.push(pantryItem);
      } else {
        missedIngredients.push(pantryItem);
      }
    }
  }

  // Determine diets
  const diets = [];
  if (meal.strCategory) diets.push(meal.strCategory.toLowerCase());
  if (meal.strTags) {
    const tags = meal.strTags.split(',').map((t) => t.trim().toLowerCase());
    diets.push(...tags);
  }

  const isDessert = diets.includes('dessert') || (meal.strCategory || '').toLowerCase() === 'dessert';
  const kcal = isDessert ? 340 : 380;
  const proteinGrams = 10;
  const carbsGrams = 48;
  const fatGrams = 9;
  const fiberGrams = 5;
  const sugarGrams = isDessert ? 12 : 5;
  const sodiumMg = 110;

  const tagline = (meal.strCategory ? `${meal.strCategory} • ` : '') +
    (meal.strArea ? `${meal.strArea} • ` : '') +
    'Delicious & Nutritious';

  const description = `A classic ${meal.strArea || ''} ${meal.strCategory || 'dish'} featuring ${extendedIngredients.slice(0, 3).map((i) => i.name).join(', ')}.`;

  const stableId = String(meal.idMeal);

  const normalized = {
    id: stableId,
    sourceRecipeId: stableId,
    recipeSource: 'themealdb',
    sourceRecipeUrl: meal.strSource || meal.strYoutube || '',
    sourceImageUrl: imageUrl,
    title: meal.strMeal || 'TheMealDB Recipe',
    tagline,
    description,
    timeMinutes: 20,
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
    servings: 2,
    recommended: false,
    diets,
    dishTypes: meal.strCategory ? [meal.strCategory] : [],
    usedIngredientCount: usedIngredients.length,
    missedIngredientCount: missedIngredients.length,
    usedIngredients,
    missedIngredients,
    ingredients: extendedIngredients.length > 0 ? extendedIngredients : [{ name: meal.strMeal, amount: '1 portion', original: meal.strMeal }],
    instructions: instructions.length > 0 ? instructions : ['Prepare ingredients.', 'Cook thoroughly.', 'Serve fresh.'],
    pantryMatchSummary: usedIngredients.length > 0
      ? `Uses ${usedIngredients.length} pantry ingredients`
      : 'Nutrient-rich balanced pairing',
  };

  normalized.whatsInside = buildWhatsInsideTags(normalized);

  return normalized;
};

/**
 * Fetch full meal details by TheMealDB ID
 */
const lookupMealDetails = async (mealId) => {
  if (!mealId) return null;
  try {
    const url = `${THEMEALDB_BASE_URL}/lookup.php?i=${encodeURIComponent(mealId)}`;
    const data = await httpGet(url);
    if (data && Array.isArray(data.meals) && data.meals.length > 0) {
      return data.meals[0];
    }
  } catch (e) {
    console.warn(`[THEMEALDB] Lookup error for ID ${mealId}:`, e.message);
  }
  return null;
};

/**
 * Search TheMealDB for recipes using free V1 endpoints
 */
const searchMealDbRecipes = async ({
  mode = 'pantry',
  sourceProduct = null,
  ingredients = [],
  pantryItems = [],
  mealType = '',
  craving = '',
  userProfile = null,
  personalization = null,
  number = 6,
}) => {
  const isProductMode = mode === 'product' || Boolean(sourceProduct);
  const normalized = isProductMode ? normalizeSourceProduct(sourceProduct) : { originalName: '', primaryCategory: '', keywords: [], aliases: [] };
  const allPantry = isProductMode
    ? []
    : [
        ...ingredients,
        ...pantryItems.map((p) => (typeof p === 'string' ? p : p.name || p.label || '')),
      ].map((s) => s.trim()).filter((s) => s.length > 0);

  const cleanPantry = isProductMode ? [] : cleanPantryIngredients(allPantry, null);

  const primarySearchTerm = isProductMode
    ? (normalized.primaryCategory || craving || 'chocolate')
    : (craving || cleanPantry[0] || 'healthy');

  console.log('\n[RECIPE API REQUEST]');
  console.log('provider = TheMealDB');
  console.log(`query = ${primarySearchTerm}`);
  console.log(`diet = ${personalization?.dietType || userProfile?.dietType || 'None'}`);
  console.log(`mealType = ${mealType || 'None'}`);
  console.log(`number = ${number}`);
  console.log('other filters = Free V1 API (No restrictive query params)');

  const rawMealMap = new Map();
  let lastError = null;

  const searchTerms = isProductMode
    ? [primarySearchTerm]
    : (cleanPantry.length > 0 ? cleanPantry.slice(0, 3) : [primarySearchTerm]);

  // 1. Search by name query (/search.php?s=...)
  for (const term of searchTerms) {
    try {
      const searchUrl = `${THEMEALDB_BASE_URL}/search.php?s=${encodeURIComponent(term)}`;
      const res = await httpGet(searchUrl);
      if (res && Array.isArray(res.meals)) {
        for (const m of res.meals) {
          if (m && m.idMeal && !rawMealMap.has(m.idMeal)) {
            rawMealMap.set(m.idMeal, m);
          }
        }
      }
    } catch (e) {
      lastError = e;
      console.warn(`[THEMEALDB] Search query "${term}" failed:`, e.message);
    }
  }

  // 2. Filter by ingredient (/filter.php?i=...)
  for (const term of searchTerms) {
    if (rawMealMap.size >= 8) break;
    try {
      const filterUrl = `${THEMEALDB_BASE_URL}/filter.php?i=${encodeURIComponent(term)}`;
      const filterRes = await httpGet(filterUrl);
      if (filterRes && Array.isArray(filterRes.meals)) {
        const toLookup = filterRes.meals.slice(0, 5);
        for (const summaryMeal of toLookup) {
          if (summaryMeal && summaryMeal.idMeal && !rawMealMap.has(summaryMeal.idMeal)) {
            const fullMeal = await lookupMealDetails(summaryMeal.idMeal);
            if (fullMeal) {
              rawMealMap.set(fullMeal.idMeal, fullMeal);
            }
          }
        }
      }
    } catch (e) {
      lastError = e;
      console.warn(`[THEMEALDB] Ingredient filter "${term}" failed:`, e.message);
    }
  }

  const allRawMeals = Array.from(rawMealMap.values());
  console.log('\n[RECIPE RAW RESPONSE]');
  console.log(`statusCode = ${lastError ? 500 : 200}`);
  console.log(`rawRecipeCount = ${allRawMeals.length}`);

  if (allRawMeals.length === 0) {
    console.log('\n[RECIPE PARSING]\nparsedRecipeCount = 0');
    console.log('\n[RECIPE FILTERING]\nfinalRecipeCount = 0');
    return {
      recipes: [],
      rawCount: 0,
      validCount: 0,
      bestScore: 0,
      bestRecipe: null,
      status: lastError ? 'THEMEALDB_HTTP_ERROR' : 'THEMEALDB_ZERO_RESULTS',
      error: lastError ? lastError.message : 'No recipes returned from TheMealDB',
      query: primarySearchTerm,
    };
  }

  // 3. Normalize all meals into common internal Recipe model
  const normalizedRecipes = allRawMeals
    .map((m) => normalizeMealDbRecipe(m, cleanPantry))
    .filter((r) => r !== null);

  console.log('\n[RECIPE PARSING]');
  console.log(`parsedRecipeCount = ${normalizedRecipes.length}`);

  // 4. Validate each recipe with DietarySafetyValidator and log validation
  const validationLogs = [];
  for (const r of normalizedRecipes) {
    const safety = validateRecipeSafety(r, userProfile, personalization);
    const textCorpus = `${r.title} ${r.ingredients.map((i) => i.name).join(' ')}`.toLowerCase();
    const hasSourceIng = isProductMode && normalized.primaryCategory
      ? textCorpus.includes(normalized.primaryCategory.toLowerCase())
      : true;

    validationLogs.push({
      recipe: r.title,
      accepted: safety.isCompatible && hasSourceIng,
      reason: safety.rejectionReason || 'OK',
    });
  }

  // 5. Score and rank compliant recipes
  const scoredResult = rankAndScoreRecipes({
    recipes: normalizedRecipes,
    mode: isProductMode ? 'product' : 'pantry',
    sourceProduct: isProductMode ? sourceProduct : null,
    pantryIngredients: isProductMode ? [] : cleanPantry,
    mealType,
    userProfile,
    personalization,
    minScoreThreshold: isProductMode ? 20 : 15,
  });

  console.log('\n[RECIPE FILTERING]');
  console.log(`finalRecipeCount = ${scoredResult.validRecipes.length}`);


  const validCount = scoredResult.validRecipes.length;
  const bestScore = scoredResult.bestScore;
  const bestRecipe = scoredResult.bestRecipe;

  let status = 'THEMEALDB_SUCCESS';
  if (validCount === 0) {
    status = normalizedRecipes.length > 0 ? 'THEMEALDB_DIET_FAILURE' : 'THEMEALDB_ZERO_RESULTS';
  } else if (bestScore < (isProductMode ? 25 : 15)) {
    status = 'THEMEALDB_LOW_RELEVANCE';
  }


  const finalRecipes = scoredResult.validRecipes.slice(0, number).map((r, index) => {
    if (index === 0) return { ...r, recommended: true };
    return r;
  });

  return {
    recipes: finalRecipes,
    rawCount: allRawMeals.length,
    validCount,
    bestScore,
    bestRecipe,
    status,
    error: lastError ? lastError.message : null,
    query: primarySearchTerm,
    validationLogs,
  };
};

/**
 * Get full recipe details by TheMealDB ID
 */
const getMealDbRecipeDetails = async (mealId, userProfile, personalization) => {
  const fullMeal = await lookupMealDetails(mealId);
  if (fullMeal) {
    return normalizeMealDbRecipe(fullMeal, []);
  }
  return null;
};

module.exports = {
  searchMealDbRecipes,
  normalizeMealDbRecipe,
  lookupMealDetails,
  getMealDbRecipeDetails,
  THEMEALDB_BASE_URL,
};
