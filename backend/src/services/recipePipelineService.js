const spoonacularService = require('./spoonacularService');
const mealDbService = require('./mealDbService');
const aiRecipeService = require('./aiRecipeService');
const { normalizeProductForRecipe, cleanPantryIngredients, getMatchingPantryIngredients } = require('../utils/productNormalizer');
const {
  findMatchingHardcodedRecipes,
  findPantryMatchingHardcodedRecipes,
  getFallbackHardcodedRecipes,
  getHardcodedRecipeById,
} = require('../data/hardcodedRecipes');

/**
 * Checks if a recipe set qualifies as "good results"
 */
const isGoodRecipeResult = (result, hasSourceProduct = false, cleanPantry = []) => {
  if (!result || !Array.isArray(result.recipes) || result.recipes.length === 0) {
    return false;
  }

  if (result.validCount === 0) {
    return false;
  }

  // If pantry mode with pantry ingredients, ensure every recipe has >= 1 pantry match
  if (!hasSourceProduct && cleanPantry && cleanPantry.length > 0) {
    const validPantryRecipes = result.recipes.filter(
      (r) => getMatchingPantryIngredients(r, cleanPantry).length >= 1
    );
    if (validPantryRecipes.length === 0) {
      return false;
    }
  }

  const topRecipe = result.recipes[0];
  if (!topRecipe || !topRecipe.image || !topRecipe.id) {
    return false;
  }

  if (hasSourceProduct) {
    return result.bestScore >= 30;
  }

  return result.bestScore >= 15;
};

/**
 * Main Fallback Pipeline: Spoonacular -> TheMealDB -> Gemini AI -> Curated Fallback
 */
const generatePersonalizedRecipes = async ({
  mode = '',
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
  const isProductMode = mode === 'product' || (mode === '' && Boolean(sourceProduct));
  const effectiveMode = isProductMode ? 'product' : 'pantry';
  const hasExplicitCraving = Boolean(craving && craving.trim().length > 0 && !isProductMode);

  const normalized = isProductMode ? normalizeProductForRecipe(sourceProduct) : { originalProduct: '', normalizedIngredient: '', recipeSearchQuery: '' };
  const allPantry = isProductMode
    ? []
    : [
        ...ingredients,
        ...pantryItems.map((p) => (typeof p === 'string' ? p : p.name || p.label || '')),
      ].map((s) => s.trim()).filter((s) => s.length > 0);

  const cleanPantry = isProductMode ? [] : cleanPantryIngredients(allPantry, null);
  const userDiet = personalization?.dietType || userProfile?.dietType || 'Vegetarian';
  const userGoal = (personalization?.goals && personalization.goals.length > 0) ? personalization.goals.join(', ') : 'Weight Loss';
  const userNutrition = personalization?.nutritionPreference || 'Balanced';
  const userTime = maxTime ? `Under ${maxTime} minutes` : 'Under 20 minutes';
  const effectiveMealType = mealType || 'Breakfast';
  const hasSourceProduct = isProductMode && Boolean(normalized.originalProduct);
  const effectiveSourceProduct = isProductMode ? sourceProduct : null;
  const primaryIngredient = normalized.normalizedIngredient || (isProductMode ? '' : craving) || 'food';
  const searchQuery = primaryIngredient;

  // Empty Pantry / Input Guard for Pantry Mode
  if (!isProductMode && allPantry.length === 0 && !craving) {
    return {
      recipes: [],
      totalFound: 0,
      recipeSource: 'none',
      pantrySummary: 'Your pantry is currently empty.',
      message: 'Add ingredients to your pantry to generate personalized recipes.',
    };
  }

  console.log('\n==============================================');
  console.log('[BACKEND RECIPE DEBUG]');
  console.log(`mode = ${effectiveMode}`);
  console.log(`pantryIngredients = [${allPantry.join(', ')}]`);
  console.log(`normalizedPantryIngredients = [${cleanPantry.join(', ')}]`);
  console.log(`userPreferences = { diet: "${userDiet}", mealType: "${effectiveMealType}", goal: "${userGoal}", nutrition: "${userNutrition}", time: "${userTime}" }`);
  console.log('==============================================\n');

  // Retrieve matching hardcoded candidates ONLY for explicit search/craving query
  const matchingHardcoded = hasExplicitCraving
    ? findMatchingHardcodedRecipes(craving, { userProfile, personalization, maxTime })
    : [];

  // Helper to merge matching hardcoded candidates in explicit search mode without overriding API recipes
  const enrichSearchResults = (apiRecipes) => {
    if (!hasExplicitCraving || matchingHardcoded.length === 0) {
      return apiRecipes;
    }
    const combined = [...apiRecipes];
    const existingTitles = new Set(apiRecipes.map((r) => (r.title || '').toLowerCase().trim()));
    for (const hc of matchingHardcoded) {
      const hcTitle = hc.title.toLowerCase().trim();
      if (!existingTitles.has(hcTitle) && combined.length < number) {
        combined.push(hc);
        existingTitles.add(hcTitle);
      }
    }
    return combined;
  };

  // Helper to log candidate analysis
  const logCandidates = (sourceName, recipes) => {
    console.log(`\n[${sourceName} CANDIDATE ANALYSIS] (Found ${recipes.length} candidates):`);
    for (const r of recipes) {
      const pMatches = getMatchingPantryIngredients(r, cleanPantry);
      console.log(`[CANDIDATE]`);
      console.log(`title = ${r.title}`);
      console.log(`ingredients = ${(r.ingredients || []).map((i) => i.name || i.original || '').join(', ')}`);
      console.log(`pantryMatches = [${pMatches.join(', ')}]`);
      console.log(`pantryMatchCount = ${pMatches.length}`);

      const isAccepted = isProductMode || hasExplicitCraving || cleanPantry.length === 0 || pMatches.length >= 1;
      console.log(`[FILTER]`);
      console.log(`title = ${r.title}`);
      console.log(`accepted/rejected = ${isAccepted ? 'ACCEPTED' : 'REJECTED'}`);
      console.log(`reason = ${isAccepted ? 'OK (matches pantry)' : 'REJECTED (0 pantry matches in pantry mode)'}\n`);
    }
  };

  // ---------------------------------------------------------------------------
  // STEP 1: Attempt Spoonacular
  // ---------------------------------------------------------------------------
  console.log('[SPOONACULAR QUERY]');
  console.log(`query = ${isProductMode ? searchQuery : (craving || cleanPantry.join(' '))}`);
  console.log(`includeIngredients = ${isProductMode ? 'None' : cleanPantry.join(',')}`);
  console.log(`diet = ${userDiet}`);
  console.log(`mealType = ${effectiveMealType}`);
  console.log(`maxReadyTime = ${maxTime || 20}\n`);

  let spoonacularResult = await spoonacularService.generatePantryRecipes({
    mode: effectiveMode,
    ingredients: isProductMode ? [] : ingredients,
    pantryItems: isProductMode ? [] : pantryItems,
    mealType: effectiveMealType,
    maxTime,
    craving: isProductMode ? searchQuery : craving,
    sourceProduct: effectiveSourceProduct,
    userProfile,
    personalization,
    number,
  });

  if (spoonacularResult?.recipes?.length > 0) {
    logCandidates('SPOONACULAR', spoonacularResult.recipes);
  }

  const spoonacularGood = isGoodRecipeResult(spoonacularResult, hasSourceProduct, cleanPantry);

  if (spoonacularGood) {
    let validRecipes = spoonacularResult.recipes;
    if (!isProductMode && cleanPantry.length > 0) {
      validRecipes = validRecipes.filter((r) => getMatchingPantryIngredients(r, cleanPantry).length >= 1);
    }

    if (validRecipes.length > 0) {
      const finalRecipes = enrichSearchResults(validRecipes);
      console.log('\n[FINAL PANTRY RESULTS]');
      console.log(`count = ${finalRecipes.length}`);
      console.log(`source = pantry_api (spoonacular)`);
      finalRecipes.forEach((r, idx) => {
        const pMatches = getMatchingPantryIngredients(r, cleanPantry);
        console.log(`  Recipe ${idx + 1}: "${r.title}" | Matched: [${pMatches.join(', ')}]`);
      });
      console.log('==============================================\n');

      return {
        recipes: finalRecipes,
        totalFound: finalRecipes.length,
        recipeSource: 'spoonacular',
        pantrySummary: isProductMode
          ? `Generated ${finalRecipes.length} recipes for ${normalized.originalProduct || 'your product'}.`
          : hasExplicitCraving
          ? `Found ${finalRecipes.length} recipes matching "${craving}".`
          : `Generated ${finalRecipes.length} recipes from your pantry.`,
        pantryIngredients: allPantry,
      };
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 2: Fallback to TheMealDB (Free V1 API)
  // ---------------------------------------------------------------------------
  console.log('[MEALDB QUERY]');
  console.log(`query = ${isProductMode ? searchQuery : (cleanPantry.join(', ') || 'healthy')}\n`);

  let mealDbResult = await mealDbService.searchMealDbRecipes({
    mode: effectiveMode,
    sourceProduct: effectiveSourceProduct,
    ingredients: isProductMode ? [] : ingredients,
    pantryItems: isProductMode ? [] : pantryItems,
    mealType: effectiveMealType,
    craving: isProductMode ? searchQuery : craving,
    userProfile,
    personalization,
    number,
  });

  if (mealDbResult?.recipes?.length > 0) {
    logCandidates('THEMEALDB', mealDbResult.recipes);
  }

  const mealDbGood = isGoodRecipeResult(mealDbResult, hasSourceProduct, cleanPantry);

  if (mealDbGood) {
    let validRecipes = mealDbResult.recipes;
    if (!isProductMode && cleanPantry.length > 0) {
      validRecipes = validRecipes.filter((r) => getMatchingPantryIngredients(r, cleanPantry).length >= 1);
    }

    if (validRecipes.length > 0) {
      const finalRecipes = enrichSearchResults(validRecipes);
      console.log('\n[FINAL PANTRY RESULTS]');
      console.log(`count = ${finalRecipes.length}`);
      console.log(`source = pantry_api (themealdb)`);
      finalRecipes.forEach((r, idx) => {
        const pMatches = getMatchingPantryIngredients(r, cleanPantry);
        console.log(`  Recipe ${idx + 1}: "${r.title}" | Matched: [${pMatches.join(', ')}]`);
      });
      console.log('==============================================\n');

      return {
        recipes: finalRecipes,
        totalFound: finalRecipes.length,
        recipeSource: 'themealdb',
        pantrySummary: isProductMode
          ? `Generated ${finalRecipes.length} recipes for ${normalized.originalProduct || 'your product'} from TheMealDB.`
          : hasExplicitCraving
          ? `Found ${finalRecipes.length} recipes matching "${craving}" from TheMealDB.`
          : `Generated ${finalRecipes.length} recipes from your pantry from TheMealDB.`,
        pantryIngredients: allPantry,
      };
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 3: Fallback to Gemini AI Recipe Generation
  // ---------------------------------------------------------------------------
  console.log('[AI QUERY]');
  console.log(`prompt ingredients = ${isProductMode ? normalized.originalProduct : cleanPantry.join(', ')}`);
  console.log(`diet = ${userDiet}, mealType = ${effectiveMealType}\n`);

  const aiRecipes = await aiRecipeService.generateAiFallbackRecipe({
    mode: effectiveMode,
    sourceProduct: effectiveSourceProduct,
    ingredients: isProductMode ? [] : ingredients,
    pantryItems: isProductMode ? [] : pantryItems,
    mealType: effectiveMealType,
    craving: isProductMode ? searchQuery : craving,
    userProfile,
    personalization,
  });

  if (aiRecipes.length > 0) {
    let validAiRecipes = aiRecipes;
    if (!isProductMode && cleanPantry.length > 0) {
      validAiRecipes = validAiRecipes.filter((r) => getMatchingPantryIngredients(r, cleanPantry).length >= 1);
    }

    if (validAiRecipes.length > 0) {
      const finalRecipes = enrichSearchResults(validAiRecipes);
      console.log('\n[FINAL PANTRY RESULTS]');
      console.log(`count = ${finalRecipes.length}`);
      console.log(`source = pantry_ai`);
      finalRecipes.forEach((r, idx) => {
        const pMatches = getMatchingPantryIngredients(r, cleanPantry);
        console.log(`  Recipe ${idx + 1}: "${r.title}" | Matched: [${pMatches.join(', ')}]`);
      });
      console.log('==============================================\n');

      return {
        recipes: finalRecipes,
        totalFound: finalRecipes.length,
        recipeSource: 'ai',
        pantrySummary: isProductMode
          ? `Generated recipe for ${normalized.originalProduct || 'your product'} using DietCompass AI Chef.`
          : `Generated ${finalRecipes.length} recipes crafted from your pantry using DietCompass AI Chef.`,
        pantryIngredients: allPantry,
      };
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 4: ZERO-RESULT FALLBACK PIPELINE
  // When live generation/APIs return 0 valid recipes
  // ---------------------------------------------------------------------------
  console.log('[STEP 4: Live Generation produced 0 valid pantry recipes -> HARDCODED / FALLBACK PIPELINE]');

  // CASE 2: Explicit Search Mode zero-result resolution
  if (hasExplicitCraving) {
    if (matchingHardcoded.length > 0) {
      console.log(`matchedHardcodedCount = ${matchingHardcoded.length}`);
      console.log(`source = curated`);
      console.log('==============================================\n');
      return {
        recipes: matchingHardcoded,
        totalFound: matchingHardcoded.length,
        recipeSource: 'curated',
        pantrySummary: `Found curated recipes matching "${craving}".`,
        pantryIngredients: allPantry,
      };
    }

    const genericFallback = getFallbackHardcodedRecipes({ userProfile, personalization, maxTime, limit: number });
    console.log(`genericFallbackCount = ${genericFallback.length}`);
    console.log('source = fallback');
    console.log('==============================================\n');

    return {
      recipes: genericFallback,
      totalFound: genericFallback.length,
      recipeSource: 'hardcoded_fallback',
      pantrySummary: `No direct matches for "${craving}". Here are wholesome recipe recommendations based on your preferences.`,
      pantryIngredients: allPantry,
    };
  }

  // CASE 1: Pantry Mode zero-result resolution
  if (!isProductMode) {
    // Check if any hardcoded recipes match at least 1 pantry ingredient
    const pantryMatchingHardcoded = findPantryMatchingHardcodedRecipes(allPantry, { userProfile, personalization, maxTime });
    if (pantryMatchingHardcoded.length > 0) {
      console.log(`pantryMatchingHardcodedCount = ${pantryMatchingHardcoded.length}`);
      console.log('source = curated');
      console.log('==============================================\n');
      return {
        recipes: pantryMatchingHardcoded,
        totalFound: pantryMatchingHardcoded.length,
        recipeSource: 'curated',
        pantrySummary: `Generated ${pantryMatchingHardcoded.length} recipes from your available pantry ingredients.`,
        pantryIngredients: allPantry,
      };
    }

    // If zero pantry-matching recipes found anywhere, use safe fallback recipes so UI never breaks
    const pantryFallback = getFallbackHardcodedRecipes({ userProfile, personalization, maxTime, limit: number });
    console.log(`[ZERO PANTRY MATCH FALLBACK TRIGGERED] Returning ${pantryFallback.length} fallback suggestions`);
    console.log('recipeSource = hardcoded_fallback');
    console.log('==============================================\n');
    return {
      recipes: pantryFallback,
      totalFound: pantryFallback.length,
      recipeSource: 'hardcoded_fallback',
      pantrySummary: 'We couldn\'t generate recipes matching your exact pantry items, so here are delicious recommendations for your diet.',
      pantryIngredients: allPantry,
    };
  }

  // Product Mode fallback
  const productFallback = getFallbackHardcodedRecipes({ userProfile, personalization, maxTime, limit: number });
  console.log(`productFallbackCount = ${productFallback.length}`);
  console.log('source = hardcoded_fallback');
  console.log('==============================================\n');

  return {
    recipes: productFallback,
    totalFound: productFallback.length,
    recipeSource: 'hardcoded_fallback',
    pantrySummary: 'We couldn\'t find specific recipes for this product, so here are wholesome suggestions tailored for you.',
  };
};

/**
 * Get detailed recipe info by ID
 */
const getRecipeDetails = async (id, userProfile = null, personalization = null) => {
  if (!id) return null;

  // 1. Check curated / hardcoded catalog
  const hardcodedMatch = getHardcodedRecipeById(id);
  if (hardcodedMatch) {
    return hardcodedMatch;
  }

  // 2. Spoonacular ID (numeric string)
  if (!isNaN(id)) {
    return await spoonacularService.getRecipeDetails(id, userProfile, personalization);
  }

  // 3. TheMealDB ID (starts with mealdb_)
  if (typeof id === 'string' && id.startsWith('mealdb_')) {
    const rawMealDbId = id.replace('mealdb_', '');
    return await mealDbService.getMealDbRecipeDetails(rawMealDbId, userProfile, personalization);
  }

  // 4. Default to Spoonacular ID handler
  return await spoonacularService.getRecipeDetails(id, userProfile, personalization);
};

module.exports = {
  generatePersonalizedRecipes,
  getRecipeDetails,
  isGoodRecipeResult,
};
