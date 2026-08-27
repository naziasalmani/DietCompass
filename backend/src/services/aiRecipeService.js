const { normalizeSourceProduct, cleanPantryIngredients, getMatchingPantryIngredients } = require('../utils/productNormalizer');
const { validateRecipeSafety } = require('../utils/dietarySafetyValidator');
const geminiConfig = require('../config/gemini');

/**
 * Get category-appropriate appetizing food image
 */
const getCategoryImageUrl = (category = '', productName = '') => {
  const text = `${category} ${productName}`.toLowerCase();
  if (text.includes('noodle') || text.includes('maggi') || text.includes('ramen') || text.includes('pasta') || text.includes('chow mein') || text.includes('spaghetti')) {
    return 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600&auto=format&fit=crop';
  }
  if (text.includes('rice') || text.includes('fried rice') || text.includes('biryani') || text.includes('pulao')) {
    return 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=600&auto=format&fit=crop';
  }
  if (text.includes('chocolate') || text.includes('cadbury') || text.includes('cocoa') || text.includes('dairy milk') || text.includes('dessert')) {
    return 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=600&auto=format&fit=crop';
  }
  if (text.includes('oat') || text.includes('cereal') || text.includes('granola') || text.includes('muesli') || text.includes('porridge')) {
    return 'https://images.unsplash.com/photo-1584776296944-ab6fb57b0bdd?w=600&auto=format&fit=crop';
  }
  if (text.includes('chip') || text.includes('crisp') || text.includes('snack') || text.includes('wafer') || text.includes('dorito')) {
    return 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=600&auto=format&fit=crop';
  }
  if (text.includes('yogurt') || text.includes('curd') || text.includes('dahi') || text.includes('milk') || text.includes('smoothie')) {
    return 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=600&auto=format&fit=crop';
  }
  return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&auto=format&fit=crop';
};

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
 * Generate recipes using Gemini AI when both Spoonacular and TheMealDB return no viable recipes
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
  const goals = (personalization?.goals && personalization.goals.length > 0) ? personalization.goals : ['Weight Loss', 'Balanced Nutrition'];
  const productName = normalized.originalName || (typeof sourceProduct === 'string' ? sourceProduct : sourceProduct?.name || 'Maggi Masala Noodles');
  const category = normalized.primaryCategory || 'noodles';

  const promptConcept = isProductMode
    ? `Generate a quick, delicious, and healthier recipe centered specifically around the product "${productName}" (category: ${category}). The user's pantry ingredients must be COMPLETELY IGNORED in this mode. Make ${productName} the hero ingredient and enhance it with wholesome vegetables or seasonings suitable for ${mealType || 'Breakfast'} and ${goals.join(', ')}.`
    : `Generate a list of 2 to 4 diverse recipes using one or more of the following available ingredients: ${cleanPantry.join(', ')}. Each recipe MUST feature at least one of these pantry ingredients prominently. Provide diversity across the pantry items.`;

  const prompt = `You are a world-class culinary nutritionist AI for the DietCompass health app.
${promptConcept}

Mode: ${isProductMode ? 'Product-centric' : 'Pantry-centric'}
${isProductMode ? `Exact Source Product: ${productName}\nPrimary Food Focus: ${category}\nPantry: IGNORED` : `Pantry Ingredients: ${cleanPantry.join(', ')}`}
Dietary Preference: ${dietType} (HARD CONSTRAINT: NEVER include meat, poultry, or seafood for Vegetarian/Vegan)
Allergies: ${allergies.join(', ') || 'None'}
Disliked Foods: ${dislikedFoods.join(', ') || 'None'}
Meal Type: ${mealType || 'Breakfast / Quick Meal'}
Health Goals: ${goals.join(', ')}
Cooking Time: Under 20 minutes

Return ONLY a valid JSON array of recipe objects (or single object if product-centric) matching this schema:
[
  {
    "title": "Recipe Title (must highlight ${isProductMode ? productName : 'the key pantry ingredient'})",
    "tagline": "3 short tag keywords (e.g. Vegetarian • Quick 15 min • High Fiber)",
    "description": "2-3 sentences describing the flavors and nutritional benefits",
    "timeMinutes": 15,
    "kcal": 310,
    "proteinGrams": 9,
    "carbsGrams": 46,
    "fatGrams": 7,
    "fiberGrams": 5,
    "sugarGrams": 3,
    "sodiumMg": 95,
    "ingredients": [
      { "name": "${isProductMode ? productName : cleanPantry[0] || 'Main Ingredient'}", "amount": "1 portion" },
      { "name": "Mixed Fresh Vegetables", "amount": "1/2 cup" },
      { "name": "Seasonings & Herbs", "amount": "To taste" }
    ],
    "instructions": [
      "Step 1: Prepare and chop fresh vegetables.",
      "Step 2: Cook the main ingredient with aromatics for 5-7 minutes.",
      "Step 3: Garnish with fresh herbs and serve hot."
    ],
    "whatsInside": [
      { "icon": "eco_rounded", "title": "Nutrient Rich", "subtitle": "Whole food nutrition", "color": "#1E8A4C" },
      { "icon": "shopping_bag_rounded", "title": "Portion Balanced", "subtitle": "Light & satisfying", "color": "#6C4EF5" }
    ]
  }
]`;

  console.log('[AI RECIPE FALLBACK] Requesting Gemini AI Recipe generation...');
  const jsonText = await callGeminiAPI(prompt, 'You are an expert culinary nutrition AI assistant. Output ONLY clean JSON.', true);

  if (jsonText) {
    try {
      let parsed = JSON.parse(jsonText);
      if (!Array.isArray(parsed)) {
        parsed = parsed.recipes || [parsed];
      }

      const validAiRecipes = [];
      for (let idx = 0; idx < parsed.length; idx++) {
        const item = parsed[idx];
        const safeId = `ai_recipe_${Date.now()}_${idx}`;
        const itemImage = getCategoryImageUrl(category, item.title || productName);

        const candidate = {
          id: safeId,
          sourceRecipeId: safeId,
          recipeSource: 'ai',
          sourceRecipeUrl: '',
          sourceImageUrl: itemImage,
          title: item.title || (isProductMode ? `Light Vegetable ${productName}` : 'Personalized AI Chef Creation'),
          tagline: item.tagline || `${dietType} • Quick 15 min • Balanced`,
          description: item.description || `A nutritious and chef-crafted recipe personalized around ${isProductMode ? productName : 'your ingredients'}.`,
          timeMinutes: item.timeMinutes || 15,
          kcal: item.kcal || 310,
          proteinGrams: item.proteinGrams || 9,
          carbsGrams: item.carbsGrams || 46,
          fatGrams: item.fatGrams || 7,
          fiberGrams: item.fiberGrams || 5,
          sugarGrams: item.sugarGrams || 3,
          sodiumMg: item.sodiumMg || 95,
          image: itemImage,
          imageAsset: itemImage,
          images: [itemImage],
          servings: 1,
          recommended: idx === 0,
          diets: [dietType.toLowerCase()],
          usedIngredientCount: isProductMode ? 1 : cleanPantry.length,
          missedIngredientCount: 0,
          usedIngredients: isProductMode ? [productName] : cleanPantry,
          missedIngredients: [],
          ingredients: Array.isArray(item.ingredients) ? item.ingredients : [
            { name: isProductMode ? productName : cleanPantry[0] || 'Main Ingredient', amount: '1 portion' },
            { name: 'Mixed Vegetables', amount: '1/2 cup' },
          ],
          instructions: Array.isArray(item.instructions) ? item.instructions : [
            'Prepare fresh vegetables and heat water.',
            `Cook ingredients and simmer gently until tender.`,
            'Garnish with fresh herbs and serve hot.',
          ],
          whatsInside: Array.isArray(item.whatsInside) ? item.whatsInside : [
            { icon: 'eco_rounded', title: 'Nutrient Rich', subtitle: 'Whole food nutrition', color: '#1E8A4C' },
            { icon: 'shopping_bag_rounded', title: 'Portion Balanced', subtitle: 'Quick & wholesome', color: '#6C4EF5' }
          ],
          pantryMatchSummary: isProductMode
            ? `Crafted with ${productName}`
            : `AI crafted with ${cleanPantry.length} pantry items`,
        };

        const safety = validateRecipeSafety(candidate, userProfile, personalization);
        if (safety.isCompatible) {
          if (!isProductMode && cleanPantry.length > 0) {
            const matches = getMatchingPantryIngredients(candidate, cleanPantry);
            if (matches.length > 0) {
              candidate.usedIngredientCount = matches.length;
              candidate.pantryMatchSummary = `Uses ${matches.length} of ${cleanPantry.length} pantry ingredients (${matches.join(', ')})`;
              validAiRecipes.push(candidate);
            }
          } else {
            validAiRecipes.push(candidate);
          }
        }
      }

      if (validAiRecipes.length > 0) {
        console.log(`[AI RECIPE FALLBACK] Generated ${validAiRecipes.length} valid AI recipes.`);
        return validAiRecipes;
      }
    } catch (e) {
      console.warn('[AI RECIPE FALLBACK] Failed to parse Gemini response:', e.message);
    }
  }

  // Deterministic fallback specifically tailored to the active mode & pantry
  if (!isProductMode && cleanPantry.length > 0) {
    const generatedPantryRecipes = [];

    // Build specific recipes for the user's actual pantry ingredients (e.g. rice, noodles, chilli)
    const hasRice = cleanPantry.some((p) => p.includes('rice'));
    const hasNoodle = cleanPantry.some((p) => p.includes('noodle') || p.includes('pasta'));
    const hasChilli = cleanPantry.some((p) => p.includes('chilli') || p.includes('chili') || p.includes('pepper'));

    if (hasRice) {
      const safeId = `ai_pantry_rice_${Date.now()}`;
      const img = 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=600&auto=format&fit=crop';
      generatedPantryRecipes.push({
        id: safeId,
        sourceRecipeId: safeId,
        recipeSource: 'ai',
        sourceImageUrl: img,
        image: img,
        imageAsset: img,
        images: [img],
        title: hasChilli ? 'Spicy Veggie Chilli Fried Rice' : 'Homestyle Vegetable Fried Rice',
        tagline: `${dietType} • Quick 15 min • High Fiber`,
        description: 'Flavorful steamed rice tossed with colorful stir-fried vegetables, aromatic garlic, and savory seasonings.',
        timeMinutes: 15,
        kcal: 330,
        proteinGrams: 9,
        carbsGrams: 54,
        fatGrams: 7,
        fiberGrams: 5,
        sugarGrams: 3,
        sodiumMg: 110,
        servings: 1,
        recommended: true,
        diets: [dietType.toLowerCase()],
        usedIngredientCount: hasChilli ? 2 : 1,
        usedIngredients: hasChilli ? ['rice', 'chilli'] : ['rice'],
        ingredients: [
          { name: 'Steamed Rice', amount: '1 cup cooked', original: '1 cup cooked rice' },
          { name: 'Diced Carrots & Bell Peppers', amount: '1/2 cup', original: '1/2 cup mixed diced vegetables' },
          ...(hasChilli ? [{ name: 'Fresh Green Chilli', amount: '1 sliced', original: '1 green chilli finely sliced' }] : []),
          { name: 'Soy Sauce & Olive Oil', amount: '1 tbsp', original: '1 tbsp light seasoning' },
        ],
        instructions: [
          'Heat olive oil in a skillet or wok over medium-high heat and sauté garlic.',
          'Add vegetables and cook for 2 minutes until tender-crisp.',
          'Toss in cooked rice and seasonings, stirring vigorously for 3 minutes.',
          'Serve warm garnished with spring onions.',
        ],
        whatsInside: [
          { icon: 'eco_rounded', title: 'Fiber Rich', subtitle: 'Veggies + rice', color: '#1E8A4C' },
          { icon: 'shopping_bag_rounded', title: 'Portion Controlled', subtitle: '330 kcal balanced portion', color: '#6C4EF5' },
        ],
        pantryMatchSummary: hasChilli ? 'Uses 2 pantry ingredients (rice, chilli)' : 'Uses 1 pantry ingredient (rice)',
      });
    }

    if (hasNoodle) {
      const safeId = `ai_pantry_noodle_${Date.now()}`;
      const img = 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600&auto=format&fit=crop';
      generatedPantryRecipes.push({
        id: safeId,
        sourceRecipeId: safeId,
        recipeSource: 'ai',
        sourceImageUrl: img,
        image: img,
        imageAsset: img,
        images: [img],
        title: hasChilli ? 'Chilli Garlic Sesame Noodles' : 'Quick Vegetable Stir-Fry Noodles',
        tagline: `${dietType} • Quick 12 min • Savory`,
        description: 'Tender noodles wok-tossed with fresh garlic, crisp vegetables, and zesty aromatic spices.',
        timeMinutes: 12,
        kcal: 310,
        proteinGrams: 8,
        carbsGrams: 48,
        fatGrams: 8,
        fiberGrams: 4,
        sugarGrams: 2,
        sodiumMg: 120,
        servings: 1,
        recommended: generatedPantryRecipes.length === 0,
        diets: [dietType.toLowerCase()],
        usedIngredientCount: hasChilli ? 2 : 1,
        usedIngredients: hasChilli ? ['noodle', 'chilli'] : ['noodle'],
        ingredients: [
          { name: 'Noodles', amount: '1 portion', original: '1 portion cooked noodles' },
          { name: 'Minced Garlic & Ginger', amount: '1 tsp', original: '1 tsp fresh minced aromatics' },
          ...(hasChilli ? [{ name: 'Red Chilli Flakes / Chilli', amount: '1/2 tsp', original: '1/2 tsp chilli' }] : []),
          { name: 'Sautéed Greens & Veggies', amount: '1/2 cup', original: '1/2 cup sliced vegetables' },
        ],
        instructions: [
          'Boil noodles in lightly salted water until tender; drain thoroughly.',
          'Heat oil in a pan and sauté garlic and chilli until aromatic.',
          'Add vegetables and toss with noodles and light sauce for 2 minutes.',
          'Serve steaming hot for a satisfying meal.',
        ],
        whatsInside: [
          { icon: 'bolt_rounded', title: 'Energizing', subtitle: 'Quick carbohydrates', color: '#E0862E' },
          { icon: 'eco_rounded', title: 'Fresh Greens', subtitle: 'Wholesome nutrition', color: '#1E8A4C' },
        ],
        pantryMatchSummary: hasChilli ? 'Uses 2 pantry ingredients (noodle, chilli)' : 'Uses 1 pantry ingredient (noodle)',
      });
    }

    if (generatedPantryRecipes.length > 0) {
      console.log(`[AI RECIPE FALLBACK] Deterministic Pantry Recipes generated: ${generatedPantryRecipes.map((r) => r.title).join(', ')}`);
      return generatedPantryRecipes;
    }

    // Generic individual item recipe for other pantry items
    const primaryPantry = cleanPantry[0];
    const safeId = `ai_pantry_gen_${Date.now()}`;
    const img = getCategoryImageUrl(primaryPantry, primaryPantry);
    const genRecipe = {
      id: safeId,
      sourceRecipeId: safeId,
      recipeSource: 'ai',
      sourceImageUrl: img,
      image: img,
      imageAsset: img,
      images: [img],
      title: `Savory ${primaryPantry.charAt(0).toUpperCase() + primaryPantry.slice(1)} Bowl`,
      tagline: `${dietType} • Quick 15 min • Balanced`,
      description: `A wholesome, delicious meal crafted around fresh ${primaryPantry} with nutritious vegetables and seasonings.`,
      timeMinutes: 15,
      kcal: 310,
      proteinGrams: 10,
      carbsGrams: 45,
      fatGrams: 7,
      fiberGrams: 6,
      sugarGrams: 3,
      sodiumMg: 100,
      servings: 1,
      recommended: true,
      diets: [dietType.toLowerCase()],
      usedIngredientCount: 1,
      usedIngredients: [primaryPantry],
      ingredients: [
        { name: primaryPantry, amount: '1 portion', original: `1 portion ${primaryPantry}` },
        { name: 'Mixed Sautéed Vegetables', amount: '1/2 cup', original: '1/2 cup seasonal vegetables' },
        { name: 'Olive Oil & Herbs', amount: '1 tbsp', original: '1 tbsp olive oil and seasonings' },
      ],
      instructions: [
        'Prepare all ingredients and heat pan over medium heat.',
        `Cook ${primaryPantry} with aromatics and vegetables until tender.`,
        'Garnish and serve warm.',
      ],
      whatsInside: [
        { icon: 'eco_rounded', title: 'Nutrient Rich', subtitle: 'Whole food ingredients', color: '#1E8A4C' },
      ],
      pantryMatchSummary: `Uses 1 pantry ingredient (${primaryPantry})`,
    };
    return [genRecipe];
  }

  // Product Mode fallback
  const safeId = `ai_product_${Date.now()}`;
  const img = getCategoryImageUrl(category, productName);
  return [
    {
      id: safeId,
      sourceRecipeId: safeId,
      recipeSource: 'ai',
      sourceImageUrl: img,
      image: img,
      imageAsset: img,
      images: [img],
      title: category === 'noodles' ? `Light Vegetable ${productName}` : `Wholesome ${productName} Creation`,
      tagline: `${dietType} • Quick 15 min • Balanced`,
      description: `A delicious and balanced recipe centered around ${productName}.`,
      timeMinutes: 15,
      kcal: 310,
      proteinGrams: 9,
      carbsGrams: 46,
      fatGrams: 7,
      fiberGrams: 5,
      sugarGrams: 3,
      sodiumMg: 95,
      servings: 1,
      recommended: true,
      diets: [dietType.toLowerCase()],
      usedIngredientCount: 1,
      usedIngredients: [productName],
      ingredients: [
        { name: productName, amount: '1 pack / serving', original: `1 pack ${productName}` },
        { name: 'Diced Carrots & Peas', amount: '1/2 cup', original: '1/2 cup diced carrots and green peas' },
        { name: 'Fresh Coriander', amount: '1 tbsp', original: '1 tbsp chopped coriander' },
      ],
      instructions: [
        'Bring water to a boil and add fresh vegetables.',
        `Add ${productName} and simmer gently until cooked.`,
        'Serve hot with fresh herbs.',
      ],
      whatsInside: [
        { icon: 'eco_rounded', title: 'High Fiber', subtitle: 'Enhanced with fresh veggies', color: '#1E8A4C' },
      ],
      pantryMatchSummary: `Crafted with ${productName}`,
    }
  ];
};

module.exports = {
  generateAiFallbackRecipe,
};
