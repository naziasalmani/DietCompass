const https = require('https');
const { normalizeSourceProduct, cleanPantryIngredients, buildPrioritizedQueries } = require('../utils/productNormalizer');
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
 * Map user dietary preferences to Spoonacular diet string
 */
const mapDietTypeToSpoonacular = (dietType) => {
  if (!dietType || typeof dietType !== 'string') return '';
  const d = dietType.toLowerCase().trim();

  if (d.includes('vegan')) return 'vegan';
  if (d.includes('vegetarian')) return 'vegetarian';
  if (d.includes('gluten') && d.includes('free')) return 'gluten free';
  if (d.includes('keto')) return 'ketogenic';
  if (d.includes('pescatarian') || d.includes('pescetarian')) return 'pescetarian';
  if (d.includes('paleo')) return 'paleo';
  if (d.includes('fodmap')) return 'low-fodmap';
  if (d.includes('whole30')) return 'whole30';

  return '';
};

/**
 * Map user allergies to Spoonacular intolerances string
 */
const mapAllergiesToIntolerances = (allergies = []) => {
  if (!Array.isArray(allergies)) return '';

  const mapped = [];
  for (const allergy of allergies) {
    const a = allergy.toLowerCase();
    if (a.includes('peanut')) mapped.push('peanut');
    else if (a.includes('tree nut') || a.includes('almond') || a.includes('walnut') || a.includes('cashew')) mapped.push('tree nut');
    else if (a.includes('milk') || a.includes('dairy') || a.includes('lactose')) mapped.push('dairy');
    else if (a.includes('egg')) mapped.push('egg');
    else if (a.includes('gluten')) mapped.push('gluten');
    else if (a.includes('wheat')) mapped.push('wheat');
    else if (a.includes('shellfish') || a.includes('crustacean')) mapped.push('shellfish');
    else if (a.includes('seafood') || a.includes('fish')) mapped.push('seafood');
    else if (a.includes('soy')) mapped.push('soy');
    else if (a.includes('sesame')) mapped.push('sesame');
  }

  return [...new Set(mapped)].join(',');
};

/**
 * Build "WhatsIn" nutrient and benefit tags for the Flutter UI
 */
const buildWhatsInsideTags = (recipe) => {
  const tags = [];
  const protein = recipe.proteinGrams || recipe.protein || 0;
  const fiber = recipe.fiberGrams || recipe.fiber || 0;
  const calories = recipe.kcal || recipe.calories || 0;
  const sugar = recipe.sugarGrams || recipe.sugar || 0;
  const fat = recipe.fatGrams || recipe.fat || 0;

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
 * Normalize Spoonacular recipe into common internal Recipe model
 */
const normalizeSpoonacularRecipe = (raw, userPantry = []) => {
  if (!raw) return null;

  const imageUrl = raw.image || raw.imageAsset || '';
  if (!imageUrl || typeof imageUrl !== 'string' || (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://') && !imageUrl.startsWith('assets/'))) {
    return null; // Reject missing image
  }

  const nutrients = raw.nutrition?.nutrients || [];
  const getNutrient = (name, fallback = 0) => {
    const item = nutrients.find((n) => n.name && n.name.toLowerCase().includes(name.toLowerCase()));
    return item && typeof item.amount === 'number' ? Math.round(item.amount) : (raw[name] || fallback);
  };

  const kcal = getNutrient('calories', raw.calories || 300);
  const proteinGrams = getNutrient('protein', raw.protein || 10);
  const carbsGrams = getNutrient('carbohydrates', raw.carbohydrates || 45);
  const fatGrams = getNutrient('fat', raw.fat || 8);
  const fiberGrams = getNutrient('fiber', raw.fiber || 5);
  const sugarGrams = getNutrient('sugar', raw.sugar || 6);
  const sodiumMg = getNutrient('sodium', raw.sodium || 120);

  const usedIngredients = (raw.usedIngredients || []).map((i) => (typeof i === 'string' ? i : i.name || i.original || ''));
  const missedIngredients = (raw.missedIngredients || []).map((i) => (typeof i === 'string' ? i : i.name || i.original || ''));
  const extendedIngredients = (raw.extendedIngredients || []).map((i) => ({
    name: i.name || i.originalName || '',
    amount: `${i.amount || ''} ${i.unit || ''}`.trim() || 'As desired',
    original: i.original || `${i.amount || ''} ${i.unit || ''} ${i.name || ''}`.trim(),
  }));

  const instructions = Array.isArray(raw.instructions)
    ? raw.instructions
    : Array.isArray(raw.analyzedInstructions?.[0]?.steps)
    ? raw.analyzedInstructions[0].steps.map((s) => s.step)
    : typeof raw.instructions === 'string' && raw.instructions.length > 0
    ? raw.instructions.split(/\r?\n|\. /).map((s) => s.trim()).filter((s) => s.length > 3)
    : ['Prepare ingredients as desired.', 'Cook according to personal preference.', 'Serve fresh and enjoy!'];

  const diets = (raw.diets || []).map((d) => d.toLowerCase());
  const tagline = diets.length > 0
    ? diets.slice(0, 3).map((d) => d.charAt(0).toUpperCase() + d.slice(1)).join(' • ')
    : 'Healthy • Fresh • Nutritious';

  const description = (raw.summary || '').replace(/<[^>]*>?/gm, '').trim() || 'A nutritious and delicious recipe personalized for your diet and pantry.';

  const normalized = {
    id: raw.id,
    sourceRecipeId: raw.id,
    recipeSource: 'spoonacular',
    sourceRecipeUrl: raw.sourceUrl || '',
    sourceImageUrl: imageUrl,
    title: raw.title || 'Personalized Recipe',
    tagline,
    description,
    timeMinutes: raw.readyInMinutes || 15,
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
    servings: raw.servings || 1,
    recommended: false,
    diets,
    dishTypes: raw.dishTypes || [],
    usedIngredientCount: usedIngredients.length,
    missedIngredientCount: missedIngredients.length,
    usedIngredients,
    missedIngredients,
    ingredients: extendedIngredients.length > 0 ? extendedIngredients : usedIngredients.map((u) => ({ name: u, amount: 'As desired', original: u })),
    instructions: instructions.length > 0 ? instructions : ['Prepare fresh ingredients.', 'Cook according to instructions.', 'Serve warm and enjoy!'],
    pantryMatchSummary: `Uses ${usedIngredients.length} pantry ingredients${missedIngredients.length > 0 ? ` • ${missedIngredients.length} more needed` : ' • Fully stocked!'}`,
  };

  normalized.whatsInside = buildWhatsInsideTags(normalized);

  return normalized;
};

/**
 * Generate recipes using real Spoonacular API
 */
const generatePantryRecipes = async ({
  mode = 'pantry',
  ingredients = [],
  pantryItems = [],
  mealType = '',
  maxTime = null,
  craving = '',
  sourceProduct = null,
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
  const primaryCategory = normalized.primaryCategory || craving || 'food';

  const prioritized = isProductMode
    ? { primaryCategory, queries: [primaryCategory + (mealType ? ` ${mealType}` : ''), primaryCategory] }
    : buildPrioritizedQueries({
        sourceProduct: null,
        pantryIngredients: allPantry,
        mealType,
        craving,
      });

  const apiKey = (process.env.SPOONACULAR_API_KEY || '').trim();
  const diet = mapDietTypeToSpoonacular(personalization?.dietType || userProfile?.dietType);
  const intolerances = mapAllergiesToIntolerances(personalization?.allergies || userProfile?.allergies);
  const excludeIngredients = (personalization?.dislikedFoods || []).join(',');

  console.log('\n[RECIPE API REQUEST]');
  console.log('provider = Spoonacular');
  console.log(`query = ${primaryCategory}`);
  console.log(`diet = ${diet || 'None'}`);
  console.log(`mealType = ${mealType || 'None'}`);
  console.log(`number = ${number}`);
  console.log(`other filters = ${[intolerances ? `intolerances: ${intolerances}` : null, maxTime ? `maxReadyTime: ${maxTime}` : null].filter(Boolean).join(', ') || 'None'}`);


  if (!apiKey || apiKey === 'your_spoonacular_api_key_here') {
    console.warn('[SPOONACULAR SERVICE] SPOONACULAR_API_KEY not configured.');
    return {
      recipes: [],
      rawCount: 0,
      validCount: 0,
      bestScore: 0,
      bestRecipe: null,
      status: 'SPOONACULAR_HTTP_ERROR',
      error: 'SPOONACULAR_API_KEY_NOT_CONFIGURED',
      attemptedQueries: prioritized.queries,
    };
  }

  const combinedResults = [];
  const seenIds = new Set();
  let apiError = null;

  const buildSearchUrl = (query, includeIngs, options = {}) => {
    const { applyDiet = true, applyType = true, applyTime = true, applyAllergies = true } = options;
    let url = `https://api.spoonacular.com/recipes/complexSearch?addRecipeInformation=true&addRecipeNutrition=true&fillIngredients=true&number=12&ranking=1&apiKey=${apiKey}`;
    if (query) url += `&query=${encodeURIComponent(query)}`;
    if (includeIngs && includeIngs.length > 0) {
      url += `&includeIngredients=${encodeURIComponent(includeIngs.join(','))}`;
    }
    if (applyDiet && diet) url += `&diet=${encodeURIComponent(diet)}`;
    if (applyAllergies && intolerances) url += `&intolerances=${encodeURIComponent(intolerances)}`;
    if (excludeIngredients) url += `&excludeIngredients=${encodeURIComponent(excludeIngredients)}`;
    if (applyType && mealType) url += `&type=${encodeURIComponent(mealType.toLowerCase())}`;
    if (applyTime && maxTime && typeof maxTime === 'number') url += `&maxReadyTime=${maxTime}`;
    return url;
  };

  const addUniqueResults = (results) => {
    if (Array.isArray(results)) {
      for (const r of results) {
        if (r && r.id && !seenIds.has(r.id)) {
          seenIds.add(r.id);
          combinedResults.push(r);
        }
      }
    }
  };

  try {
    if (isProductMode) {
      // PRODUCT MODE HIERARCHY:
      // LEVEL 1: Primary category + all preferences (mealType, diet, time)
      const q1 = prioritized.queries[0] || primaryCategory;
      const url1 = buildSearchUrl(q1, [], { applyDiet: true, applyType: true, applyTime: true });
      const res1 = await httpGet(url1);
      if (res1?.results) addUniqueResults(res1.results);

      // LEVEL 2: Primary category + diet (relax mealType & maxTime)
      if (combinedResults.length < 4 && primaryCategory) {
        const url2 = buildSearchUrl(primaryCategory, [], { applyDiet: true, applyType: false, applyTime: false });
        const res2 = await httpGet(url2);
        if (res2?.results) addUniqueResults(res2.results);
      }

      // LEVEL 3: Primary category broad search (relax URL diet parameter, validate with internal safety)
      if (combinedResults.length < 4 && primaryCategory) {
        const url3 = buildSearchUrl(primaryCategory, [], { applyDiet: false, applyType: false, applyTime: false });
        const res3 = await httpGet(url3);
        if (res3?.results) addUniqueResults(res3.results);
      }
    } else {
      // PANTRY MODE STRATEGY: Iterate across all pantry ingredients and sensible combinations
      if (cleanPantry.length > 0) {
        for (const query of prioritized.queries.slice(0, 6)) {
          if (combinedResults.length >= 16) break;
          console.log(`\n[PANTRY SEARCH STRATEGY]\nquery = "${query}"`);
          const url = buildSearchUrl(query, [], { applyDiet: true, applyType: false });
          const res = await httpGet(url);
          if (res?.results) addUniqueResults(res.results);
        }
      } else if (craving) {
        const urlCraving = buildSearchUrl(craving, []);
        const resCraving = await httpGet(urlCraving);
        if (resCraving?.results) addUniqueResults(resCraving.results);
      }
    }
  } catch (err) {
    console.warn('[SPOONACULAR SERVICE] Spoonacular API call failed:', err.message);
    apiError = err;
  }

  console.log('\n[RECIPE RAW RESPONSE]');
  console.log(`statusCode = ${apiError ? (apiError.statusCode || 500) : 200}`);
  console.log(`rawRecipeCount = ${combinedResults.length}`);

  if (combinedResults.length === 0) {
    console.log('\n[RECIPE PARSING]\nparsedRecipeCount = 0');
    console.log('\n[RECIPE FILTERING]\nfinalRecipeCount = 0');
    return {
      recipes: [],
      rawCount: 0,
      validCount: 0,
      bestScore: 0,
      bestRecipe: null,
      status: apiError ? 'SPOONACULAR_HTTP_ERROR' : 'SPOONACULAR_ZERO_RESULTS',
      error: apiError ? apiError.message : 'No recipes returned from Spoonacular',
      attemptedQueries: prioritized.queries,
    };
  }

  // Normalize all Spoonacular recipes
  const normalizedRecipes = combinedResults
    .map((r) => normalizeSpoonacularRecipe(r, cleanPantry))
    .filter((r) => r !== null);

  console.log('\n[RECIPE PARSING]');
  console.log(`parsedRecipeCount = ${normalizedRecipes.length}`);

  // Score, rank and validate with DietarySafetyValidator
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

  let status = 'SPOONACULAR_SUCCESS';
  if (validCount === 0) {
    status = normalizedRecipes.length > 0 ? 'SPOONACULAR_DIET_FAILURE' : 'SPOONACULAR_ZERO_RESULTS';
  } else if (bestScore < (isProductMode ? 30 : 20)) {
    status = 'SPOONACULAR_LOW_RELEVANCE';
  }


  const finalRecipes = scoredResult.validRecipes.slice(0, number).map((r, index) => {
    if (index === 0) return { ...r, recommended: true };
    return r;
  });

  return {
    recipes: finalRecipes,
    rawCount: combinedResults.length,
    validCount,
    bestScore,
    bestRecipe,
    status,
    error: apiError ? apiError.message : null,
    attemptedQueries: prioritized.queries,
  };
};

/**
 * Get detailed recipe information for a single recipe by ID
 */
const getRecipeDetails = async (recipeId, userProfile, personalization) => {
  const apiKey = (process.env.SPOONACULAR_API_KEY || '').trim();

  if (apiKey && apiKey !== 'your_spoonacular_api_key_here') {
    try {
      const url = `https://api.spoonacular.com/recipes/${recipeId}/information?includeNutrition=true&apiKey=${apiKey}`;
      const r = await httpGet(url);
      if (r && r.id) {
        return normalizeSpoonacularRecipe(r, []);
      }
    } catch (e) {
      console.warn('[SpoonacularService] Live recipe details call failed:', e.message);
    }
  }

  return null;
};

module.exports = {
  generatePantryRecipes,
  getRecipeDetails,
  normalizeSpoonacularRecipe,
  mapDietTypeToSpoonacular,
  mapAllergiesToIntolerances,
};
