const spoonacularService = require('./spoonacularService');
const mealDbService = require('./mealDbService');
const aiRecipeService = require('./aiRecipeService');
const { normalizeProductForRecipe, normalizeSourceProduct, cleanPantryIngredients } = require('../utils/productNormalizer');

/**
 * Checks if a recipe set qualifies as "good results"
 */
const isGoodRecipeResult = (result, hasSourceProduct = false) => {
  if (!result || !Array.isArray(result.recipes) || result.recipes.length === 0) {
    return false;
  }

  if (result.validCount === 0) {
    return false;
  }

  const topRecipe = result.recipes[0];
  if (!topRecipe || !topRecipe.image || !topRecipe.id) {
    return false;
  }

  if (hasSourceProduct) {
    return result.bestScore >= 35;
  }

  return result.bestScore >= 20;
};

/**
 * Main Fallback Pipeline: Spoonacular -> TheMealDB -> Gemini AI
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

  const normalized = isProductMode ? normalizeProductForRecipe(sourceProduct) : { originalProduct: '', normalizedIngredient: '', recipeSearchQuery: '' };
  const allPantry = isProductMode
    ? []
    : [
        ...ingredients,
        ...pantryItems.map((p) => (typeof p === 'string' ? p : p.name || p.label || '')),
      ].map((s) => s.trim()).filter((s) => s.length > 0);

  const cleanPantry = isProductMode ? [] : cleanPantryIngredients(allPantry, null);
  const userDiet = personalization?.dietType || userProfile?.dietType || 'Vegetarian';
  const hasSourceProduct = isProductMode && Boolean(normalized.originalProduct);
  const effectiveSourceProduct = isProductMode ? sourceProduct : null;
  const primaryIngredient = normalized.normalizedIngredient || (isProductMode ? '' : craving) || 'food';

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
  console.log('[RECIPE MODE]');
  if (isProductMode) {
    console.log('mode = product\n');
    console.log('[PRODUCT NORMALIZATION]');
    console.log(`originalProduct = ${normalized.originalProduct || sourceProduct?.name || 'None'}`);
    console.log(`normalizedIngredient = ${primaryIngredient}\n`);
    console.log('[RECIPE SEARCH]');
    console.log(`searchQuery = ${primaryIngredient}`);
    console.log('pantryIngredients = IGNORED');
  } else {
    console.log('mode = pantry\n');
    console.log('[PANTRY RECIPE SEARCH]');
    console.log(`pantryIngredients = ${allPantry.join(', ')}`);
  }
  console.log('==============================================');


  // ---------------------------------------------------------------------------
  // STEP 1: Attempt Spoonacular
  // ---------------------------------------------------------------------------
  let spoonacularResult = await spoonacularService.generatePantryRecipes({
    mode: effectiveMode,
    ingredients: isProductMode ? [] : ingredients,
    pantryItems: isProductMode ? [] : pantryItems,
    mealType,
    maxTime,
    craving,
    sourceProduct: effectiveSourceProduct,
    userProfile,
    personalization,
    number,
  });

  const spoonacularGood = isGoodRecipeResult(spoonacularResult, hasSourceProduct);

  let spoonacularStatus = spoonacularResult.status;
  if (!spoonacularGood && spoonacularStatus === 'SPOONACULAR_SUCCESS') {
    spoonacularStatus = 'SPOONACULAR_LOW_RELEVANCE';
  }

  console.log('[SPOONACULAR]');
  console.log(`status = ${spoonacularStatus}`);
  console.log(`results = ${spoonacularResult.validCount}`);

  if (spoonacularGood) {
    const top = spoonacularResult.recipes[0];
    console.log('\n[FINAL RECIPE]');
    console.log(`source = Spoonacular`);
    console.log(`title = ${top.title}`);
    console.log(`image = ${top.image}`);
    console.log(`ingredients = ${(top.ingredients || []).map((i) => i.name).join(', ')}`);
    console.log('==============================================\n');

    return {
      recipes: spoonacularResult.recipes,
      totalFound: spoonacularResult.recipes.length,
      recipeSource: 'spoonacular',
      pantrySummary: isProductMode
        ? `Generated ${spoonacularResult.recipes.length} recipes for ${normalized.originalName || 'your product'}.`
        : `Generated ${spoonacularResult.recipes.length} recipes from your pantry.`,
      pantryIngredients: allPantry,
    };
  }

  // ---------------------------------------------------------------------------
  // STEP 2: Spoonacular Unusable -> Fallback to TheMealDB (Free V1 API)
  // ---------------------------------------------------------------------------
  console.log('\n[THEMEALDB]');
  console.log(`fallbackTriggered = true`);

  let mealDbResult = await mealDbService.searchMealDbRecipes({
    mode: effectiveMode,
    sourceProduct: effectiveSourceProduct,
    ingredients: isProductMode ? [] : ingredients,
    pantryItems: isProductMode ? [] : pantryItems,
    mealType,
    craving,
    userProfile,
    personalization,
    number,
  });

  const mealDbGood = isGoodRecipeResult(mealDbResult, hasSourceProduct);

  let mealDbStatus = mealDbResult.status;
  if (!mealDbGood && mealDbStatus === 'THEMEALDB_SUCCESS') {
    mealDbStatus = 'THEMEALDB_LOW_RELEVANCE';
  }

  console.log(`status = ${mealDbStatus}`);
  console.log(`results = ${mealDbResult.validCount}`);

  if (mealDbGood) {
    const top = mealDbResult.recipes[0];
    console.log('\n[FINAL RECIPE]');
    console.log(`source = TheMealDB`);
    console.log(`title = ${top.title}`);
    console.log(`image = ${top.image}`);
    console.log(`ingredients = ${(top.ingredients || []).map((i) => i.name).join(', ')}`);
    console.log('==============================================\n');

    return {
      recipes: mealDbResult.recipes,
      totalFound: mealDbResult.recipes.length,
      recipeSource: 'themealdb',
      pantrySummary: isProductMode
        ? `Generated ${mealDbResult.recipes.length} recipes for ${normalized.originalName || 'your product'} from TheMealDB.`
        : `Generated ${mealDbResult.recipes.length} recipes from your pantry from TheMealDB.`,
      pantryIngredients: allPantry,
    };
  }

  // ---------------------------------------------------------------------------
  // STEP 3: Fallback to Gemini AI Generation
  // ---------------------------------------------------------------------------
  console.log('\n[GEMINI AI FALLBACK]');
  console.log(`fallbackTriggered = true`);

  const aiRecipes = await aiRecipeService.generateAiFallbackRecipe({
    mode: effectiveMode,
    sourceProduct: effectiveSourceProduct,
    ingredients: isProductMode ? [] : ingredients,
    pantryItems: isProductMode ? [] : pantryItems,
    mealType,
    craving,
    userProfile,
    personalization,
  });

  if (aiRecipes.length > 0) {
    const top = aiRecipes[0];
    console.log('\n[FINAL RECIPE]');
    console.log(`source = AI`);
    console.log(`title = ${top.title}`);
    console.log(`image = ${top.image}`);
    console.log(`ingredients = ${(top.ingredients || []).map((i) => i.name).join(', ')}`);
    console.log('==============================================\n');

    return {
      recipes: aiRecipes,
      totalFound: aiRecipes.length,
      recipeSource: 'ai',
      pantrySummary: `Generated recipe using DietCompass AI Chef.`,
      pantryIngredients: allPantry,
    };
  }

  console.log('\n[FINAL RECIPE]');
  console.log('source = None');
  console.log('title = No suitable recipe found');
  console.log('==============================================\n');

  return {
    recipes: [],
    totalFound: 0,
    recipeSource: 'none',
    pantrySummary: 'No suitable recipes found with your current pantry and preferences.',
    spoonacularStatus,
    mealDbStatus,
  };
};

/**
 * Get detailed recipe info by ID
 */
const getRecipeDetails = async (id, userProfile, personalization) => {
  if (!id) return null;

  const idStr = String(id);

  // If ID starts with "ai_"
  if (idStr.startsWith('ai_')) {
    return null;
  }

  // Try Spoonacular first if API key is present
  const spoonacularRecipe = await spoonacularService.getRecipeDetails(id, userProfile, personalization);
  if (spoonacularRecipe) return spoonacularRecipe;

  // Try TheMealDB lookup
  const mealDbRecipe = await mealDbService.getMealDbRecipeDetails(id, userProfile, personalization);
  if (mealDbRecipe) return mealDbRecipe;

  return null;
};

module.exports = {
  generatePersonalizedRecipes,
  getRecipeDetails,
  isGoodRecipeResult,
};
