/**
 * DietCompass — Unified Recipe Relevance Scorer
 * Implements strict scoring rules according to user specifications across Spoonacular, Edamam, and AI
 */

const { validateRecipeSafety } = require('./dietarySafetyValidator');
const { normalizeSourceProduct, cleanPantryIngredients } = require('./productNormalizer');

/**
 * Calculates relevance score for any normalized recipe
 *
 * Scoring rules:
 * - SOURCE PRODUCT MATCH: +40
 * - PRIMARY CULINARY CATEGORY MATCH: +30
 * - PANTRY INGREDIENT MATCH: +10 per matching pantry ingredient
 * - MEAL TYPE MATCH: +10
 * - DIET MATCH: +20
 * - USER GOAL MATCH: +10
 *
 * Penalties:
 * - Unrelated recipe: -50
 * - Diet violation: REJECT (null / score -9999)
 * - Missing image: REJECT
 * - Missing recipe identity: REJECT
 */
const scoreRecipe = ({
  recipe,
  mode = 'pantry',
  sourceProduct = null,
  pantryIngredients = [],
  mealType = '',
  userProfile = null,
  personalization = null,
}) => {
  // 1. Safety & Identity Hard Validation
  const safety = validateRecipeSafety(recipe, userProfile, personalization);
  if (!safety.isCompatible) {
    return {
      score: -9999,
      isValid: false,
      rejectionReason: safety.rejectionReason,
      breakdown: { safetyViolated: true },
    };
  }

  let score = 0;
  const breakdown = {
    sourceProductMatch: 0,
    primaryCategoryMatch: 0,
    pantryMatches: [],
    matchedPantryIngredients: 0,
    mealTypeMatch: 0,
    dietMatch: 0,
    goalMatch: 0,
    unrelatedPenalty: 0,
  };

  const title = (recipe.title || '').toLowerCase();
  const summary = (recipe.summary || recipe.description || '').toLowerCase();
  const ings = (recipe.ingredients || recipe.extendedIngredients || recipe.ingredientLines || [])
    .map((i) => (typeof i === 'string' ? i : `${i.name || i.original || i.text || ''}`))
    .join(' ')
    .toLowerCase();
  const corpus = `${title} ${summary} ${ings}`;

  const isProductMode = mode === 'product' || Boolean(sourceProduct);
  const normalized = isProductMode ? normalizeSourceProduct(sourceProduct) : { originalName: '', primaryCategory: '', keywords: [], aliases: [] };
  const cleanPantry = isProductMode ? [] : cleanPantryIngredients(pantryIngredients, null);
  const userGoals = (personalization?.goals || []).map((g) => g.toLowerCase());
  const userDiet = (personalization?.dietType || userProfile?.dietType || 'Vegetarian').toLowerCase();

  let matchedProduct = false;
  let matchedCategory = false;

  if (isProductMode) {
    // -------------------------------------------------------------------------
    // PRODUCT MODE SCORING
    // -------------------------------------------------------------------------
    // 1. Source Product Match (+40)
    const orig = (normalized.originalName || '').toLowerCase();
    if (orig && (corpus.includes(orig) || (normalized.keywords || []).some((kw) => kw.length > 2 && corpus.includes(kw)))) {
      score += 40;
      matchedProduct = true;
      breakdown.sourceProductMatch = 40;
    }

    // 2. Primary Culinary Category Match (+30)
    const cat = (normalized.primaryCategory || '').toLowerCase();
    if (cat && (corpus.includes(cat) || (normalized.aliases || []).some((a) => corpus.includes(a)))) {
      score += 30;
      matchedCategory = true;
      breakdown.primaryCategoryMatch = 30;
    }

    // Unrelated recipe penalty (-50) if neither product nor primary category matched
    if (!matchedProduct && !matchedCategory) {
      score -= 50;
      breakdown.unrelatedPenalty = -50;
    }
  } else {
    // -------------------------------------------------------------------------
    // PANTRY MODE SCORING: Subset matching (+15 per used pantry ingredient)
    // -------------------------------------------------------------------------
    for (const pantryItem of cleanPantry) {
      const p = pantryItem.toLowerCase().trim();
      if (p.length > 2 && corpus.includes(p)) {
        score += 15;
        breakdown.pantryMatches.push(pantryItem);
      }
    }
    breakdown.matchedPantryIngredients = breakdown.pantryMatches.length;

    // A recipe with zero meaningful pantry matches is penalized in pantry mode
    if (cleanPantry.length > 0 && breakdown.pantryMatches.length === 0) {
      score -= 40;
      breakdown.unrelatedPenalty = -40;
    }
  }

  // 4. Meal Type Match (+10)
  if (mealType) {
    const m = mealType.toLowerCase().trim();
    const recipeMeals = (recipe.mealType || recipe.dishTypes || []).map((d) => d.toLowerCase());
    if (title.includes(m) || summary.includes(m) || recipeMeals.some((d) => d.includes(m))) {
      score += 10;
      breakdown.mealTypeMatch = 10;
    }
  }

  // 5. Diet Match (+20)
  const diets = (recipe.diets || recipe.dietLabels || []).map((d) => d.toLowerCase());
  if (diets.some((d) => d.includes(userDiet)) || (userDiet.includes('veg') && recipe.vegetarian)) {
    score += 20;
    breakdown.dietMatch = 20;
  } else {
    // If it passed hard dietary validation, grant base diet match
    score += 10;
    breakdown.dietMatch = 10;
  }

  // 6. User Goal Match (+10)
  const calories = recipe.kcal || recipe.calories || 300;
  const protein = recipe.proteinGrams || recipe.protein || 10;
  const sugar = recipe.sugarGrams || recipe.sugar || 6;

  for (const goal of userGoals) {
    if (goal.includes('weight') && calories <= 380) {
      score += 10;
      breakdown.goalMatch += 10;
      break;
    } else if (goal.includes('protein') && protein >= 12) {
      score += 10;
      breakdown.goalMatch += 10;
      break;
    } else if (goal.includes('sugar') && sugar <= 6) {
      score += 10;
      breakdown.goalMatch += 10;
      break;
    }
  }

  return {
    score,
    isValid: score > 0,
    rejectionReason: null,
    breakdown,
  };
};

/**
 * Filter, score, and rank an array of recipes
 */
const rankAndScoreRecipes = ({
  recipes = [],
  mode = 'pantry',
  sourceProduct = null,
  pantryIngredients = [],
  mealType = '',
  userProfile = null,
  personalization = null,
  minScoreThreshold = 20,
}) => {
  if (!Array.isArray(recipes) || recipes.length === 0) {
    return {
      validRecipes: [],
      rejectedRecipes: [],
      bestScore: 0,
      bestRecipe: null,
    };
  }

  const isProductMode = mode === 'product' || Boolean(sourceProduct);
  const scored = [];
  const rejected = [];

  for (const recipe of recipes) {
    const evaluation = scoreRecipe({
      recipe,
      mode: isProductMode ? 'product' : 'pantry',
      sourceProduct: isProductMode ? sourceProduct : null,
      pantryIngredients: isProductMode ? [] : pantryIngredients,
      mealType,
      userProfile,
      personalization,
    });

    if (evaluation.isValid && evaluation.score >= minScoreThreshold) {
      const enrichedRecipe = {
        ...recipe,
        score: evaluation.score,
        scoreBreakdown: evaluation.breakdown,
        matchedPantryIngredients: evaluation.breakdown.matchedPantryIngredients || evaluation.breakdown.pantryMatches.length,
        pantryMatchSummary: !isProductMode && pantryIngredients.length > 0
          ? `Uses ${evaluation.breakdown.pantryMatches.length} of ${pantryIngredients.length} pantry ingredients`
          : recipe.pantryMatchSummary || '',
      };
      scored.push(enrichedRecipe);
    } else {
      rejected.push({
        recipe,
        score: evaluation.score,
        reason: evaluation.rejectionReason || (evaluation.score < minScoreThreshold ? 'Score below relevance threshold' : 'Invalid recipe'),
        breakdown: evaluation.breakdown,
      });
    }
  }

  // Sort descending by score
  scored.sort((a, b) => (b.score || 0) - (a.score || 0));

  return {
    validRecipes: scored,
    rejectedRecipes: rejected,
    bestScore: scored.length > 0 ? scored[0].score : 0,
    bestRecipe: scored.length > 0 ? scored[0] : null,
  };
};

module.exports = {
  scoreRecipe,
  rankAndScoreRecipes,
};
