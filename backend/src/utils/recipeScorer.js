/**
 * DietCompass — Unified Recipe Relevance Scorer
 * Implements strict scoring rules according to user specifications across Spoonacular, TheMealDB, and AI
 */

const { validateRecipeSafety } = require('./dietarySafetyValidator');
const { normalizeSourceProduct, cleanPantryIngredients, getMatchingPantryIngredients } = require('./productNormalizer');

/**
 * Calculates relevance score for any normalized recipe
 *
 * Scoring rules:
 * - SOURCE PRODUCT MATCH: +40
 * - PRIMARY CULINARY CATEGORY MATCH: +30
 * - PANTRY INGREDIENT MATCH: +20 per matching pantry ingredient
 * - MEAL TYPE MATCH: +10
 * - DIET MATCH: +20
 * - USER GOAL MATCH: +10
 *
 * Hard Constraints / Rejections:
 * - Dietary safety violation: REJECT (score -9999)
 * - Missing image / stable ID: REJECT (score -9999)
 * - PANTRY MODE with 0 matched pantry ingredients: REJECT (score -9999)
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
    // PANTRY MODE SCORING & HARD REQUIREMENT
    // -------------------------------------------------------------------------
    if (cleanPantry.length > 0) {
      const matches = getMatchingPantryIngredients(recipe, cleanPantry);
      breakdown.pantryMatches = matches;
      breakdown.matchedPantryIngredients = matches.length;

      // HARD CONSTRAINT: In pantry mode with non-empty pantry, EVERY recipe MUST contain >= 1 pantry ingredient
      if (matches.length === 0) {
        return {
          score: -9999,
          isValid: false,
          rejectionReason: 'Does not contain any pantry ingredient in pantry mode',
          breakdown: { ...breakdown, pantryMatchViolated: true },
        };
      }

      // +20 per used pantry ingredient
      const pantryScore = matches.length * 20;
      score += pantryScore;
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
 * Filter, score, and rank an array of recipes with pantry ingredient diversity
 */
const rankAndScoreRecipes = ({
  recipes = [],
  mode = 'pantry',
  sourceProduct = null,
  pantryIngredients = [],
  mealType = '',
  userProfile = null,
  personalization = null,
  minScoreThreshold = 10,
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
      const matchCount = evaluation.breakdown.matchedPantryIngredients || evaluation.breakdown.pantryMatches.length;
      const matchedNames = evaluation.breakdown.pantryMatches || [];
      const enrichedRecipe = {
        ...recipe,
        score: evaluation.score,
        scoreBreakdown: evaluation.breakdown,
        matchedPantryIngredients: matchCount,
        usedIngredientCount: matchCount,
        pantryMatchSummary: !isProductMode && pantryIngredients.length > 0
          ? `Uses ${matchCount} of ${pantryIngredients.length} pantry ingredients (${matchedNames.join(', ')})`
          : recipe.pantryMatchSummary || '',
      };
      scored.push(enrichedRecipe);
    } else {
      rejected.push({
        recipeTitle: recipe.title,
        score: evaluation.score,
        reason: evaluation.rejectionReason || (evaluation.score < minScoreThreshold ? 'Score below relevance threshold' : 'Invalid recipe'),
        breakdown: evaluation.breakdown,
      });
    }
  }

  // Sort descending by score
  scored.sort((a, b) => (b.score || 0) - (a.score || 0));

  // Ingredient Diversity Selection in Pantry Mode:
  // Ensure that diverse pantry ingredients are represented in the top recipes
  let diverseList = scored;
  if (!isProductMode && pantryIngredients.length > 1 && scored.length > 1) {
    const selected = [];
    const remaining = [...scored];
    const coveredPantry = new Set();

    // First pass: pick best recipe for each unique pantry ingredient
    for (const p of pantryIngredients) {
      const cleanP = (typeof p === 'string' ? p : p.name || p.label || '').toLowerCase().trim();
      const matchIdx = remaining.findIndex((r) =>
        (r.scoreBreakdown?.pantryMatches || []).some((m) => m.toLowerCase().includes(cleanP) || cleanP.includes(m.toLowerCase()))
      );
      if (matchIdx !== -1) {
        const picked = remaining.splice(matchIdx, 1)[0];
        selected.push(picked);
        coveredPantry.add(cleanP);
      }
    }

    // Second pass: fill remainder with highest scoring remaining recipes
    selected.push(...remaining);
    diverseList = selected;
  }

  return {
    validRecipes: diverseList,
    rejectedRecipes: rejected,
    bestScore: diverseList.length > 0 ? diverseList[0].score : 0,
    bestRecipe: diverseList.length > 0 ? diverseList[0] : null,
  };
};

module.exports = {
  scoreRecipe,
  rankAndScoreRecipes,
};
