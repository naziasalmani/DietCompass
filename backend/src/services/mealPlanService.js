const { validateRecipeSafety } = require('../utils/dietarySafetyValidator');
const { cleanPantryIngredients, getMatchingPantryIngredients } = require('../utils/productNormalizer');
const {
  HARDCODED_RECIPES,
  findMatchingHardcodedRecipes,
  findPantryMatchingHardcodedRecipes,
  getHardcodedRecipeById,
} = require('../data/hardcodedRecipes');
const mealDbService = require('./mealDbService');
const spoonacularService = require('./spoonacularService');
const aiRecipeService = require('./aiRecipeService');
const geminiConfig = require('../config/gemini');

/**
 * Helper to call Gemini REST API for Meal Plan Orchestration
 */
const callGeminiMealPlan = async (prompt, systemInstruction = '') => {
  if (!geminiConfig.apiKey) {
    return null;
  }

  const endpoint = `${geminiConfig.baseUrl}/${geminiConfig.model}:generateContent?key=${geminiConfig.apiKey}`;

  const requestBody = {
    contents: [
      {
        role: 'user',
        parts: [{ text: prompt }],
      },
    ],
    generationConfig: {
      temperature: 0.2,
      maxOutputTokens: 8192,
      responseMimeType: 'application/json',
    },
  };

  if (systemInstruction) {
    requestBody.systemInstruction = {
      parts: [{ text: systemInstruction }],
    };
  }

  try {
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(requestBody),
    });

    if (!response.ok) {
      const errBody = await response.text();
      console.warn(`[Gemini MealPlan Warning] HTTP ${response.status}: ${errBody}`);
      return null;
    }

    const data = await response.json();
    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
    return text || null;
  } catch (error) {
    console.warn(`[Gemini MealPlan Error] ${error.message}`);
    return null;
  }
};

/**
 * Normalizes meal types into standard list: ['Breakfast', 'Lunch', 'Dinner', 'Snacks']
 */
const parseMealTypes = (mealTypesInput) => {
  if (Array.isArray(mealTypesInput)) {
    return mealTypesInput.map((s) => s.trim()).filter(Boolean);
  }
  if (typeof mealTypesInput === 'string' && mealTypesInput.trim().length > 0) {
    return mealTypesInput
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean);
  }
  return ['Breakfast', 'Lunch', 'Snack', 'Dinner'];
};

/**
 * Standardize meal type name
 */
const standardizeMealType = (type) => {
  const lower = (type || '').toLowerCase().trim();
  if (lower.includes('breakfast')) return 'Breakfast';
  if (lower.includes('lunch')) return 'Lunch';
  if (lower.includes('snack')) return 'Snack';
  if (lower.includes('dinner')) return 'Dinner';
  return 'Meal';
};

/**
 * Gather candidate recipes across external APIs, curated recipes, and AI fallback
 */
const gatherRecipeCandidates = async ({
  diet,
  allergies = [],
  mealTypes = [],
  usePantry = false,
  pantryIngredients = [],
  userProfile = null,
  personalization = null,
}) => {
  const cleanPantry = usePantry ? cleanPantryIngredients(pantryIngredients) : [];
  const candidatePool = [];
  const seenIds = new Set();
  const seenTitles = new Set();

  const addCandidate = (recipe, mealTypeHint = '') => {
    if (!recipe || !recipe.title) return;
    const titleKey = recipe.title.toLowerCase().trim();
    const idKey = (recipe.id || recipe.recipeId || titleKey).toString();

    if (seenIds.has(idKey) || seenTitles.has(titleKey)) return;

    // Strict Dietary & Allergy Safety Validation
    const safety = validateRecipeSafety(
      recipe,
      { ...userProfile, dietType: diet },
      { ...personalization, dietType: diet, allergies }
    );

    if (!safety.isCompatible) {
      return;
    }

    // Pantry Relevance Check if in Pantry mode
    if (usePantry && cleanPantry.length > 0) {
      const matched = getMatchingPantryIngredients(recipe, cleanPantry);
      // If recipe has 0 pantry matches in pantry mode, skip unless pool is small
      if (matched.length === 0 && candidatePool.length > 30) {
        return;
      }
      recipe.matchedPantryIngredients = matched.length;
      recipe.pantryMatches = matched;
    }

    const assignedMealType = mealTypeHint || recipe.mealType || 'Meal';
    const kcal = recipe.kcal || recipe.calories || (recipe.nutrition?.calories) || 350;
    const proteinG = recipe.proteinGrams || recipe.protein || (recipe.nutrition?.protein) || 12;
    const carbsG = recipe.carbsGrams || recipe.carbs || (recipe.nutrition?.carbs) || 45;
    const fatG = recipe.fatGrams || recipe.fat || (recipe.nutrition?.fat) || 10;
    const fiberG = recipe.fiberGrams || recipe.fiber || (recipe.nutrition?.fiber) || 5;

    const candidate = {
      id: idKey,
      recipeId: idKey,
      title: recipe.title,
      description: recipe.description || recipe.summary || '',
      type: assignedMealType,
      calories: Math.round(Number(kcal) || 350),
      proteinGrams: Math.round(Number(proteinG) || 12),
      carbsGrams: Math.round(Number(carbsG) || 45),
      fatGrams: Math.round(Number(fatG) || 10),
      fiberGrams: Math.round(Number(fiberG) || 5),
      image: recipe.imageUrl || recipe.image || recipe.imageAsset || 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&auto=format&fit=crop',
      ingredients: (recipe.ingredients || []).map((i) => (typeof i === 'string' ? i : i.name || i.original || '')).filter(Boolean),
      instructions: recipe.instructions || [],
      tags: recipe.tags || [],
      isVegetarian: recipe.isVegetarian !== false,
      pantryMatches: recipe.pantryMatches || [],
      matchedPantryIngredients: recipe.matchedPantryIngredients || 0,
      recipeSource: recipe.recipeSource || recipe.source || 'api',
    };

    candidatePool.push(candidate);
    seenIds.add(idKey);
    seenTitles.add(titleKey);
  };

  // 1. Curated Fallback Recipes (Diet-Safe)
  const curated = HARDCODED_RECIPES;
  for (const cr of curated) {
    addCandidate(cr, cr.mealType);
  }

  // 2. Fetch from TheMealDB across search keys
  const searchQueries = usePantry && cleanPantry.length > 0
    ? cleanPantry.slice(0, 4)
    : ['healthy', 'salad', 'soup', 'rice', 'chicken', 'egg', 'vegetable'];

  for (const q of searchQueries) {
    try {
      const mealDbResult = await mealDbService.searchRecipesByIngredients({
        ingredients: [q],
        diet,
        allergies,
        number: 8,
      });

      if (mealDbResult && Array.isArray(mealDbResult.recipes)) {
        for (const r of mealDbResult.recipes) {
          addCandidate(r);
        }
      }
    } catch (_) {}
  }

  // 3. Fetch from Spoonacular if configured
  if (spoonacularService && process.env.SPOONACULAR_API_KEY) {
    try {
      const spResult = await spoonacularService.searchRecipes({
        query: usePantry && cleanPantry.length > 0 ? cleanPantry.join(' ') : 'healthy',
        diet,
        allergies,
        number: 10,
      });
      if (spResult && Array.isArray(spResult.recipes)) {
        for (const r of spResult.recipes) {
          addCandidate(r);
        }
      }
    } catch (_) {}
  }

  return candidatePool;
};

/**
 * Deterministic meal-plan organizer (used directly or as fallback when Gemini is offline)
 */
const buildDeterministicPlan = ({
  durationDays,
  targetCalories,
  goal,
  diet,
  mealTypes,
  candidatePool,
  usePantry,
  cleanPantry,
}) => {
  const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const days = [];

  const breakfastPool = candidatePool.filter((c) => c.type === 'Breakfast' || c.tags.some((t) => t.toLowerCase().includes('breakfast')) || c.title.toLowerCase().includes('oat') || c.title.toLowerCase().includes('pancake') || c.title.toLowerCase().includes('egg') || c.title.toLowerCase().includes('smoothie'));
  const lunchPool = candidatePool.filter((c) => c.type === 'Lunch' || c.tags.some((t) => t.toLowerCase().includes('lunch')) || c.title.toLowerCase().includes('salad') || c.title.toLowerCase().includes('rice') || c.title.toLowerCase().includes('pasta') || c.title.toLowerCase().includes('wrap'));
  const snackPool = candidatePool.filter((c) => c.type === 'Snack' || c.tags.some((t) => t.toLowerCase().includes('snack')) || c.title.toLowerCase().includes('smoothie') || c.title.toLowerCase().includes('apple') || c.title.toLowerCase().includes('nuts') || c.calories <= 220);
  const dinnerPool = candidatePool.filter((c) => c.type === 'Dinner' || c.tags.some((t) => t.toLowerCase().includes('dinner')) || c.title.toLowerCase().includes('curry') || c.title.toLowerCase().includes('stir fry') || c.title.toLowerCase().includes('casserole') || c.title.toLowerCase().includes('soup'));

  const getPool = (type) => {
    switch (type) {
      case 'Breakfast': return breakfastPool.length > 0 ? breakfastPool : candidatePool;
      case 'Lunch': return lunchPool.length > 0 ? lunchPool : candidatePool;
      case 'Snack': return snackPool.length > 0 ? snackPool : candidatePool;
      case 'Dinner': return dinnerPool.length > 0 ? dinnerPool : candidatePool;
      default: return candidatePool;
    }
  };

  const today = new Date();

  for (let d = 0; d < durationDays; d++) {
    const dayDate = new Date(today);
    dayDate.setDate(today.getDate() + d);

    const dayLabel = dayNames[dayDate.getDay() === 0 ? 6 : dayDate.getDay() - 1] || `Day ${d + 1}`;
    const dayNumber = `Day ${d + 1}`;
    const dayMeals = [];

    let dayCal = 0;
    let dayProt = 0;
    let dayFib = 0;

    for (const mt of mealTypes) {
      const pool = getPool(mt);
      // Offset selection to prevent identical repeats across days
      const idx = (d + dayMeals.length) % pool.length;
      const candidate = pool[idx] || candidatePool[d % candidatePool.length];

      const meal = {
        type: mt,
        recipeId: candidate.recipeId,
        title: candidate.title,
        description: candidate.description,
        calories: candidate.calories,
        proteinGrams: candidate.proteinGrams,
        carbsGrams: candidate.carbsGrams,
        fatGrams: candidate.fatGrams,
        fiberGrams: candidate.fiberGrams,
        image: candidate.image,
        ingredients: candidate.ingredients,
        instructions: candidate.instructions,
        isVegetarian: candidate.isVegetarian,
      };

      dayMeals.push(meal);
      dayCal += meal.calories;
      dayProt += meal.proteinGrams;
      dayFib += meal.fiberGrams;
    }

    days.push({
      day: d + 1,
      dayLabel,
      dayNumber,
      date: dayDate.toISOString().split('T')[0],
      meals: dayMeals,
      dailyCalories: dayCal,
      dailyProtein: dayProt,
      dailyFiber: dayFib,
      waterGlasses: goal.toLowerCase().includes('muscle') ? 9 : 8,
    });
  }

  return days;
};

/**
 * Generate a Dynamic Personalized AI Summary text
 */
const generateDynamicSummary = ({ goal, diet, calories, durationDays, usePantry, cleanPantry }) => {
  const pantryPart = usePantry && cleanPantry.length > 0
    ? ` while prioritizing fresh ingredients from your pantry (${cleanPantry.slice(0, 3).join(', ')})`
    : '';

  return `Your personalized ${durationDays}-day meal plan is tailored for ${goal} with a ${diet} dietary approach, targeting ~${calories} kcal/day with balanced protein and fiber${pantryPart}.`;
};

/**
 * Main Meal Plan Generation Orchestration Engine
 */
const generateMealPlan = async ({
  durationDays = 7,
  goal = 'Weight Loss',
  calories = 1800,
  mealTypes = ['Breakfast', 'Lunch', 'Snack', 'Dinner'],
  diet = 'Vegetarian',
  allergies = [],
  budget = 'Moderate',
  usePantry = true,
  pantryIngredients = [],
  userProfile = null,
  personalization = null,
}) => {
  const validDuration = [1, 3, 7, 30].includes(Number(durationDays)) ? Number(durationDays) : 7;
  const numCalories = parseInt(calories.toString().replace(/[^0-9]/g, ''), 10) || 1800;
  const parsedMealTypes = parseMealTypes(mealTypes).map(standardizeMealType);
  const cleanPantry = usePantry ? cleanPantryIngredients(pantryIngredients) : [];

  console.log('\n==============================================');
  console.log('[MEAL PLAN DEBUG]');
  console.log(`durationDays = ${validDuration}`);
  console.log(`goal = ${goal}`);
  console.log(`diet = ${diet}`);
  console.log(`calories = ${numCalories}`);
  console.log(`mealTypes = [${parsedMealTypes.join(', ')}]`);
  console.log(`usePantry = ${usePantry}`);
  console.log(`pantryIngredients = [${cleanPantry.join(', ')}]`);
  console.log('==============================================\n');

  // 1. Gather & safety-validate recipe candidate pool
  const candidatePool = await gatherRecipeCandidates({
    diet,
    allergies,
    mealTypes: parsedMealTypes,
    usePantry,
    pantryIngredients: cleanPantry,
    userProfile,
    personalization,
  });

  console.log('\n==============================================');
  console.log('[MEAL PLAN CANDIDATES]');
  console.log(`candidateCount = ${candidatePool.length}`);
  console.log('==============================================\n');

  if (candidatePool.length === 0) {
    throw new Error('No safe recipe candidates available matching the selected diet and allergy constraints.');
  }

  // 2. Build candidate map for strict image and metadata integrity
  const candidateMap = new Map();
  for (const c of candidatePool) {
    candidateMap.set(c.title.toLowerCase().trim(), c);
    candidateMap.set(c.recipeId.toLowerCase().trim(), c);
  }

  let finalDays = [];
  let geminiUsed = false;

  // 3. AI Orchestration with Gemini
  if (geminiConfig.apiKey) {
    console.log('\n==============================================');
    console.log('[MEAL PLAN GEMINI]');
    console.log('generationStarted = true');

    try {
      // For 30-day plans, generate in chunks of 7 days to ensure high reliability & token safety
      const chunkSize = validDuration === 30 ? 7 : validDuration;
      const totalChunks = Math.ceil(validDuration / chunkSize);
      const generatedDays = [];

      for (let chunkIdx = 0; chunkIdx < totalChunks; chunkIdx++) {
        const startDay = chunkIdx * chunkSize + 1;
        const countDays = Math.min(chunkSize, validDuration - startDay + 1);

        const prompt = `You are the DietCompass Meal Planning AI.
Generate a structured ${countDays}-day meal plan (Day ${startDay} to Day ${startDay + countDays - 1}).

USER CONSTRAINTS:
- Goal: ${goal}
- Target Daily Calories: ${numCalories} kcal
- Diet: ${diet} (NEVER include meat/fish if Vegetarian or Eggetarian)
- Allergies / Intolerances to strictly EXCLUDE: ${allergies.join(', ') || 'None'}
- Required Meal Types per day: ${parsedMealTypes.join(', ')}
- Budget: ${budget}
- Pantry Ingredients Prioritized: ${usePantry && cleanPantry.length > 0 ? cleanPantry.join(', ') : 'None'}

AVAILABLE VALIDATED RECIPE POOL (Select directly from these verified recipes where suitable):
${candidatePool.slice(0, 40).map((c) => `- "${c.title}" (${c.type}, ${c.calories} kcal, ${c.proteinGrams}g protein, Ingredients: ${c.ingredients.slice(0, 5).join(', ')})`).join('\n')}

INSTRUCTIONS:
1. Generate exactly ${countDays} days starting from day number ${startDay}.
2. Ensure each day has all requested meal types: ${parsedMealTypes.join(', ')}.
3. Ensure variety across days (do not repeat the same meal consecutively).
4. Strictly respect the ${diet} diet and all allergen exclusions.

Return ONLY valid JSON matching this schema:
{
  "days": [
    {
      "day": ${startDay},
      "dayLabel": "Mon",
      "dayNumber": "Day ${startDay}",
      "meals": [
        {
          "type": "Breakfast",
          "title": "Exact Recipe Title",
          "calories": 350,
          "proteinGrams": 12,
          "carbsGrams": 45,
          "fatGrams": 8,
          "fiberGrams": 5
        }
      ]
    }
  ]
}`;

        const aiResponseText = await callGeminiMealPlan(prompt, 'You are DietCompass AI Meal Planner. Return structured JSON only.');

        if (aiResponseText) {
          try {
            const parsed = JSON.parse(aiResponseText.replace(/```json/gi, '').replace(/```/g, '').trim());
            if (Array.isArray(parsed.days)) {
              for (const d of parsed.days) {
                generatedDays.push(d);
              }
            }
          } catch (e) {
            console.warn(`[Gemini Chunk Parse Error] ${e.message}`);
          }
        }
      }

      if (generatedDays.length === validDuration) {
        finalDays = generatedDays;
        geminiUsed = true;
      }
      console.log(`generationCompleted = ${geminiUsed}`);
      console.log('==============================================\n');
    } catch (e) {
      console.warn(`[Gemini Orchestration Failed] ${e.message}`);
    }
  }

  // Fallback to deterministic plan if Gemini did not produce the complete duration
  if (finalDays.length !== validDuration) {
    finalDays = buildDeterministicPlan({
      durationDays: validDuration,
      targetCalories: numCalories,
      goal,
      diet,
      mealTypes: parsedMealTypes,
      candidatePool,
      usePantry,
      cleanPantry,
    });
  }

  // 4. Final Validation & Strict Image Binding
  const acceptedMeals = [];
  const rejectedMeals = [];
  const rejectionReasons = [];
  const validatedDays = [];

  const today = new Date();
  const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  for (let i = 0; i < finalDays.length; i++) {
    const rawDay = finalDays[i];
    const dayDate = new Date(today);
    dayDate.setDate(today.getDate() + i);

    const dayLabel = rawDay.dayLabel || dayNames[dayDate.getDay() === 0 ? 6 : dayDate.getDay() - 1] || `Day ${i + 1}`;
    const dayNumber = `Day ${i + 1}`;

    const validMeals = [];
    let dayCalories = 0;
    let dayProtein = 0;
    let dayFiber = 0;

    const rawMeals = Array.isArray(rawDay.meals) ? rawDay.meals : [];

    for (const rm of rawMeals) {
      const candidate = candidateMap.get((rm.title || '').toLowerCase().trim()) || candidatePool[validMeals.length % candidatePool.length];
      
      const safety = validateRecipeSafety(
        candidate,
        { ...userProfile, dietType: diet },
        { ...personalization, dietType: diet, allergies }
      );

      if (!safety.isCompatible) {
        rejectedMeals.push(rm.title);
        rejectionReasons.push(safety.rejectionReason || 'Dietary safety violation');
        continue;
      }

      const verifiedMeal = {
        type: standardizeMealType(rm.type || candidate.type),
        recipeId: candidate.recipeId,
        title: candidate.title,
        description: candidate.description,
        calories: Number(rm.calories || candidate.calories) || 350,
        proteinGrams: Number(rm.proteinGrams || candidate.proteinGrams) || 12,
        carbsGrams: Number(rm.carbsGrams || candidate.carbsGrams) || 45,
        fatGrams: Number(rm.fatGrams || candidate.fatGrams) || 10,
        fiberGrams: Number(rm.fiberGrams || candidate.fiberGrams) || 5,
        image: candidate.image,
        ingredients: candidate.ingredients,
        instructions: candidate.instructions,
        isVegetarian: candidate.isVegetarian,
      };

      validMeals.push(verifiedMeal);
      acceptedMeals.push(verifiedMeal.title);
      dayCalories += verifiedMeal.calories;
      dayProtein += verifiedMeal.proteinGrams;
      dayFiber += verifiedMeal.fiberGrams;
    }

    validatedDays.push({
      day: i + 1,
      dayLabel,
      dayNumber,
      date: dayDate.toISOString().split('T')[0],
      meals: validMeals,
      dailyCalories: dayCalories,
      dailyProtein: dayProtein,
      dailyFiber: dayFiber,
      waterGlasses: goal.toLowerCase().includes('muscle') ? 9 : 8,
    });
  }

  console.log('\n==============================================');
  console.log('[MEAL PLAN VALIDATION]');
  console.log(`acceptedMeals = ${acceptedMeals.length}`);
  console.log(`rejectedMeals = ${rejectedMeals.length}`);
  console.log(`rejectionReasons = [${rejectionReasons.join(', ')}]`);
  console.log('==============================================\n');

  console.log('\n==============================================');
  console.log('[MEAL PLAN FINAL]');
  console.log(`days = ${validatedDays.length}`);
  console.log(`totalMeals = ${acceptedMeals.length}`);
  console.log('==============================================\n');

  const totalCaloriesAll = validatedDays.reduce((acc, d) => acc + d.dailyCalories, 0);
  const totalProteinAll = validatedDays.reduce((acc, d) => acc + d.dailyProtein, 0);
  const totalFiberAll = validatedDays.reduce((acc, d) => acc + d.dailyFiber, 0);

  const avgCalories = Math.round(totalCaloriesAll / validatedDays.length);
  const avgProtein = Math.round(totalProteinAll / validatedDays.length);
  const avgFiber = Math.round(totalFiberAll / validatedDays.length);

  const summary = generateDynamicSummary({
    goal,
    diet,
    calories: numCalories,
    durationDays: validDuration,
    usePantry,
    cleanPantry,
  });

  return {
    durationDays: validDuration,
    goal,
    diet,
    targetCalories: numCalories,
    summary,
    geminiPowered: geminiUsed,
    days: validatedDays,
    totals: {
      averageCalories: avgCalories,
      averageProtein: avgProtein,
      averageFiber: avgFiber,
    },
  };
};

module.exports = {
  generateMealPlan,
  gatherRecipeCandidates,
  parseMealTypes,
  standardizeMealType,
};
