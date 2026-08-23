const { normalizeSourceProduct, cleanPantryIngredients } = require('../utils/productNormalizer');
const { validateRecipeSafety } = require('../utils/dietarySafetyValidator');
const geminiConfig = require('../config/gemini');

/**
 * Call Gemini REST API with prompt and system instructions
 */
const callGeminiAPI = async (prompt, systemInstruction = '', jsonMode = true) => {
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
      temperature: 0.3,
      maxOutputTokens: 2048,
      ...(jsonMode && { responseMimeType: 'application/json' }),
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
      console.warn(`[Gemini Recipe Warning] HTTP ${response.status}: ${errBody}`);
      return null;
    }

    const data = await response.json();
    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
    return text || null;
  } catch (error) {
    console.warn(`[Gemini Recipe Error] ${error.message}`);
    return null;
  }
};

/**
 * Generate a recipe using Gemini AI when both Spoonacular and Edamam return no viable recipes
 */
const generateAiFallbackRecipe = async ({
  mode = 'pantry',
  sourceProduct = null,
  ingredients = [],
  pantryItems = [],
  mealType = '',
  craving = '',
  userProfile = null,
  personalization = null,
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
  const dietType = personalization?.dietType || userProfile?.dietType || 'Vegetarian';
  const allergies = personalization?.allergies || userProfile?.allergies || [];
  const dislikedFoods = personalization?.dislikedFoods || [];
  const goals = personalization?.goals || [];

  const promptConcept = isProductMode
    ? `Generate recipes centered around ${normalized.originalName || normalized.primaryCategory || craving}. The user's pantry ingredients are irrelevant in this mode. Do not treat pantry ingredients as required inputs.`
    : `Generate recipes using one or more of the following available ingredients: ${cleanPantry.join(', ')}. You do not need to use all ingredients. Prefer recipes that use multiple available ingredients when appropriate.`;

  const prompt = `You are a world-class culinary nutritionist AI for the DietCompass health app.
${promptConcept}

Mode: ${isProductMode ? 'Product-centric' : 'Pantry-centric'}
${isProductMode ? `Source Product: ${normalized.originalName || 'None'}\nPrimary Food Focus: ${normalized.primaryCategory || craving || 'Product'}` : `Pantry Ingredients: ${cleanPantry.join(', ')}`}
Dietary Preference: ${dietType} (HARD CONSTRAINT: NEVER include meat, poultry, or seafood for Vegetarian/Vegan)
Allergies: ${allergies.join(', ') || 'None'}
Disliked Foods: ${dislikedFoods.join(', ') || 'None'}
Meal Type: ${mealType || 'Breakfast / Any'}
Health Goals: ${goals.join(', ') || 'Balanced Nutrition'}


Return ONLY a valid JSON object matching this schema:
{
  "title": "Recipe Title (must highlight the food item and pantry pairing)",
  "tagline": "3 short tag keywords (e.g. Vegetarian • High Fiber • Quick)",
  "description": "2-3 sentences describing the flavors and nutritional benefits",
  "timeMinutes": 15,
  "kcal": 340,
  "proteinGrams": 12,
  "carbsGrams": 50,
  "fatGrams": 9,
  "fiberGrams": 7,
  "sugarGrams": 12,
  "sodiumMg": 80,
  "ingredients": [
    { "name": "Rolled Oats", "amount": "1/2 cup" },
    { "name": "Sliced Banana", "amount": "1 whole" }
  ],
  "instructions": [
    "Step 1...",
    "Step 2...",
    "Step 3..."
  ],
  "whatsInside": [
    { "icon": "eco_rounded", "title": "High in Fiber", "subtitle": "7g fiber for gut health", "color": "#1E8A4C" },
    { "icon": "fitness_center_rounded", "title": "Plant Protein", "subtitle": "12g protein", "color": "#E0862E" }
  ]
}`;

  console.log('[AI RECIPE FALLBACK] Requesting Gemini AI Recipe generation...');
  const jsonText = await callGeminiAPI(prompt, 'You are an expert culinary nutrition AI assistant. Output ONLY clean JSON.', true);

  if (jsonText) {
    try {
      const parsed = JSON.parse(jsonText);
      const safeId = `ai_recipe_${Date.now()}`;
      const imageUrl = 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&auto=format&fit=crop';

      const candidate = {
        id: safeId,
        sourceRecipeId: safeId,
        recipeSource: 'ai',
        sourceRecipeUrl: '',
        sourceImageUrl: imageUrl,
        title: parsed.title || 'Personalized AI Chef Creation',
        tagline: parsed.tagline || `${dietType} • Fresh • Balanced`,
        description: parsed.description || 'A nutritious and chef-crafted recipe personalized for your diet and pantry.',
        timeMinutes: parsed.timeMinutes || 15,
        kcal: parsed.kcal || 320,
        proteinGrams: parsed.proteinGrams || 11,
        carbsGrams: parsed.carbsGrams || 48,
        fatGrams: parsed.fatGrams || 8,
        fiberGrams: parsed.fiberGrams || 6,
        sugarGrams: parsed.sugarGrams || 8,
        sodiumMg: parsed.sodiumMg || 100,
        image: imageUrl,
        imageAsset: imageUrl,
        images: [imageUrl],
        servings: 1,
        recommended: true,
        diets: [dietType.toLowerCase()],
        usedIngredientCount: cleanPantry.length,
        missedIngredientCount: 0,
        usedIngredients: cleanPantry,
        missedIngredients: [],
        ingredients: Array.isArray(parsed.ingredients) ? parsed.ingredients : [],
        instructions: Array.isArray(parsed.instructions) ? parsed.instructions : ['Prepare ingredients.', 'Cook according to taste.', 'Serve warm and enjoy!'],
        whatsInside: Array.isArray(parsed.whatsInside) ? parsed.whatsInside : [
          { icon: 'eco_rounded', title: 'Nutrient Rich', subtitle: 'Whole food nutrition', color: '#1E8A4C' }
        ],
        pantryMatchSummary: `AI crafted with ${cleanPantry.length} pantry items`,
      };

      // Validate AI recipe safety
      const safety = validateRecipeSafety(candidate, userProfile, personalization);
      if (safety.isCompatible) {
        console.log('[AI RECIPE FALLBACK] Gemini AI Recipe successfully generated and validated:', candidate.title);
        return [candidate];
      } else {
        console.warn('[AI RECIPE FALLBACK] Gemini AI Recipe violated safety constraint:', safety.rejectionReason);
      }
    } catch (e) {
      console.warn('[AI RECIPE FALLBACK] Failed to parse Gemini response:', e.message);
    }
  }

  return [];
};

module.exports = {
  generateAiFallbackRecipe,
};
