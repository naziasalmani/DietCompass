/**
 * DietCompass — Curated Hardcoded Recipes Catalog & Matching Engine
 *
 * Preserves 6 curated high-quality recipes:
 * 1. Banana Oats Power Bowl
 * 2. Chocolate Banana Overnight Oats
 * 3. Apple Cinnamon Oatmeal Bowl
 * 4. Savory Spinach & Mushroom Oats
 * 5. High-Protein Green Egg Scramble
 * 6. Pasta Primavera with Fresh Vegetables
 *
 * These recipes act as:
 * - Legitimate search candidates in Explicit Search / Craving Mode when relevant
 * - Graceful fallback candidates when real-time API generation yields 0 valid results
 */

const { validateRecipeSafety } = require('../utils/dietarySafetyValidator');

const HARDCODED_RECIPES = [
  {
    id: 'hardcoded_banana_oats',
    title: 'Banana Oats Power Bowl',
    tagline: 'Healthy • Quick 15 min • Energy Rich',
    description: 'A nutritious bowl packed with fiber, protein and natural energy to kickstart your day!',
    timeMinutes: 15,
    kcal: 320,
    proteinGrams: 12,
    carbsGrams: 52,
    fatGrams: 6,
    fiberGrams: 7,
    sugarGrams: 14,
    sodiumMg: 45,
    image: 'https://images.unsplash.com/photo-1584776296944-ab6fb57b0bdd?w=600&auto=format&fit=crop',
    imageAsset: 'assets/images/recipe_banana_oats_power_bowl.jpeg',
    recipeSource: 'curated',
    recommended: true,
    dietType: 'Vegetarian',
    diets: ['Vegetarian'],
    vegetarian: true,
    vegan: false,
    allergens: ['Dairy', 'Gluten'],
    ingredients: [
      { name: 'Rolled Oats', amount: '1/2 cup' },
      { name: 'Ripe Banana', amount: '1 sliced' },
      { name: 'Milk', amount: '1 cup' },
      { name: 'Honey', amount: '1 tsp' },
      { name: 'Chia Seeds', amount: '1 tbsp' },
      { name: 'Chopped Almonds', amount: '1 tbsp' },
    ],
    instructions: [
      'In a saucepan, bring milk to a gentle simmer over medium heat.',
      'Add rolled oats and cook for 5 minutes, stirring continuously until creamy.',
      'Pour oatmeal into a serving bowl and arrange fresh banana slices on top.',
      'Drizzle with honey and garnish with chia seeds and chopped almonds.',
      'Serve warm for sustained morning energy!',
    ],
    whatsInside: [
      { icon: 'eco_rounded', title: 'High in Fiber', subtitle: 'Good for digestion', color: '#1E8A4C' },
      { icon: 'bolt_rounded', title: 'Natural Energy', subtitle: 'Sustained vitality', color: '#E0862E' },
      { icon: 'favorite_rounded', title: 'Heart Healthy', subtitle: 'Whole grain oats', color: '#E0525C' },
      { icon: 'shopping_bag_rounded', title: 'Weight Friendly', subtitle: 'Nutrient dense', color: '#6C4EF5' },
    ],
    tags: ['Healthy', 'Quick', 'Delicious', 'Vegetarian', 'High Fiber'],
    keywords: ['banana', 'oat', 'oats', 'oatmeal', 'bowl', 'power bowl', 'breakfast', 'chia', 'honey', 'fruit'],
  },
  {
    id: 'hardcoded_chocolate_banana_oats',
    title: 'Chocolate Banana Overnight Oats',
    tagline: 'Make-ahead • Creamy • Antioxidant Rich',
    description: 'Creamy oats infused with rich cocoa, sweet banana and crunchy nuts. Perfect for a healthy make-ahead breakfast.',
    timeMinutes: 10,
    kcal: 320,
    proteinGrams: 11,
    carbsGrams: 50,
    fatGrams: 7,
    fiberGrams: 8,
    sugarGrams: 12,
    sodiumMg: 50,
    image: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=600&auto=format&fit=crop',
    imageAsset: 'assets/images/recipe_chocolate_banana_oats.jpeg',
    recipeSource: 'curated',
    recommended: false,
    dietType: 'Vegetarian',
    diets: ['Vegetarian'],
    vegetarian: true,
    vegan: false,
    allergens: ['Dairy', 'Gluten', 'Tree Nuts'],
    ingredients: [
      { name: 'Rolled Oats', amount: '1/2 cup' },
      { name: 'Cocoa Powder', amount: '1 tbsp' },
      { name: 'Mashed Banana', amount: '1 medium' },
      { name: 'Milk', amount: '3/4 cup' },
      { name: 'Chia Seeds', amount: '1 tsp' },
      { name: 'Dark Chocolate Chips', amount: '1 tsp' },
      { name: 'Walnuts', amount: '1 tbsp chopped' },
    ],
    instructions: [
      'In a mason jar or glass bowl, combine rolled oats, cocoa powder, and chia seeds.',
      'Add milk and mashed banana, stirring vigorously until cocoa is fully incorporated.',
      'Cover with a lid and refrigerate overnight (or for at least 4 hours).',
      'Before serving, top with dark chocolate chips and chopped walnuts.',
      'Enjoy chilled for a creamy, decadent breakfast dessert!',
    ],
    whatsInside: [
      { icon: 'eco_rounded', title: 'High Fiber', subtitle: 'Keeps you full', color: '#1E8A4C' },
      { icon: 'nightlight_round', title: 'Make-Ahead', subtitle: 'Ready overnight', color: '#6C4EF5' },
      { icon: 'favorite_rounded', title: 'Antioxidants', subtitle: 'From pure cocoa', color: '#E0525C' },
      { icon: 'shopping_bag_rounded', title: 'Portion Smart', subtitle: 'Balanced calories', color: '#E0862E' },
    ],
    tags: ['Make-ahead', 'Creamy', 'Kid-friendly', 'Vegetarian', 'Chocolate', 'Dessert'],
    keywords: ['chocolate', 'cocoa', 'banana', 'oat', 'oats', 'overnight oats', 'oatmeal', 'sweet', 'dessert', 'dark chocolate'],
  },
  {
    id: 'hardcoded_apple_cinnamon_oatmeal',
    title: 'Apple Cinnamon Oatmeal Bowl',
    tagline: 'Warm • Comforting • Heart Healthy',
    description: 'Warm, comforting whole grain oats simmered with crisp apples, aromatic cinnamon and toasted walnuts.',
    timeMinutes: 12,
    kcal: 310,
    proteinGrams: 9,
    carbsGrams: 48,
    fatGrams: 6,
    fiberGrams: 6,
    sugarGrams: 15,
    sodiumMg: 40,
    image: 'https://images.unsplash.com/photo-1584776296944-ab6fb57b0bdd?w=600&auto=format&fit=crop',
    imageAsset: 'assets/images/recipe_apple_cinnamon_oatmeal.jpeg',
    recipeSource: 'curated',
    recommended: false,
    dietType: 'Vegetarian',
    diets: ['Vegetarian'],
    vegetarian: true,
    vegan: false,
    allergens: ['Dairy', 'Gluten', 'Tree Nuts'],
    ingredients: [
      { name: 'Rolled Oats', amount: '1/2 cup' },
      { name: 'Fresh Apple', amount: '1/2 diced' },
      { name: 'Milk', amount: '1 cup' },
      { name: 'Cinnamon Powder', amount: '1/2 tsp' },
      { name: 'Honey', amount: '1 tsp' },
      { name: 'Chopped Walnuts', amount: '1 tbsp' },
    ],
    instructions: [
      'In a small pot, simmer milk and diced apples for 3 minutes until apples soften slightly.',
      'Stir in rolled oats and ground cinnamon.',
      'Cook over low heat for 5-6 minutes, stirring occasionally until thick.',
      'Transfer to a bowl, drizzle with honey, and top with toasted walnuts.',
      'Serve warm on cozy mornings!',
    ],
    whatsInside: [
      { icon: 'favorite_rounded', title: 'Good for Heart', subtitle: 'Whole grain oats', color: '#E0525C' },
      { icon: 'eco_rounded', title: 'Fiber Rich', subtitle: 'Apple + oats', color: '#1E8A4C' },
      { icon: 'bolt_rounded', title: 'Steady Energy', subtitle: 'Low glycemic index', color: '#E0862E' },
      { icon: 'shopping_bag_rounded', title: 'No Added Sugar', subtitle: 'Naturally sweetened', color: '#6C4EF5' },
    ],
    tags: ['Warm', 'Comforting', 'Wholesome', 'Vegetarian', 'Apple', 'Cinnamon'],
    keywords: ['apple', 'cinnamon', 'oat', 'oats', 'oatmeal', 'warm', 'breakfast', 'cinnamon bowl', 'walnuts'],
  },
  {
    id: 'hardcoded_savory_spinach_mushroom_oats',
    title: 'Savory Spinach & Mushroom Oats',
    tagline: 'Savory • High Fiber • Quick 15 min',
    description: 'A wholesome savory oats bowl sautéed with fresh baby spinach, earthy mushrooms, garlic, and cracked black pepper.',
    timeMinutes: 15,
    kcal: 280,
    proteinGrams: 14,
    carbsGrams: 38,
    fatGrams: 7,
    fiberGrams: 8,
    sugarGrams: 3,
    sodiumMg: 120,
    image: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&auto=format&fit=crop',
    imageAsset: 'assets/images/recipe_savory_veggie_oats.jpeg',
    recipeSource: 'curated',
    recommended: false,
    dietType: 'Vegetarian',
    diets: ['Vegetarian', 'Vegan'],
    vegetarian: true,
    vegan: true,
    allergens: ['Gluten'],
    ingredients: [
      { name: 'Rolled Oats', amount: '1/2 cup' },
      { name: 'Fresh Baby Spinach', amount: '1 cup' },
      { name: 'Sliced Mushrooms', amount: '1/2 cup' },
      { name: 'Olive Oil', amount: '1 tsp' },
      { name: 'Garlic', amount: '1 clove minced' },
      { name: 'Vegetable Broth or Water', amount: '1 cup' },
      { name: 'Salt & Black Pepper', amount: 'To taste' },
    ],
    instructions: [
      'Heat olive oil in a skillet over medium heat and sauté minced garlic for 30 seconds.',
      'Add sliced mushrooms and cook until browned (3-4 minutes).',
      'Add baby spinach and toss until wilted.',
      'In a separate pot, cook oats in vegetable broth or water for 5 minutes with salt and pepper.',
      'Spoon savory oats into a bowl and top with the warm sautéed spinach and mushrooms.',
    ],
    whatsInside: [
      { icon: 'fitness_center_rounded', title: 'High Protein', subtitle: 'Plant protein 14g', color: '#E0862E' },
      { icon: 'eco_rounded', title: 'Veggie Packed', subtitle: 'Spinach & mushroom', color: '#1E8A4C' },
      { icon: 'favorite_rounded', title: 'Low Fat', subtitle: 'Heart friendly', color: '#E0525C' },
      { icon: 'shopping_bag_rounded', title: 'Weight Friendly', subtitle: 'Low calorie', color: '#6C4EF5' },
    ],
    tags: ['Savory', 'High Fiber', 'Warm', 'Vegetarian', 'Vegan', 'Spinach', 'Mushroom'],
    keywords: ['spinach', 'mushroom', 'mushrooms', 'oat', 'oats', 'savory', 'vegetable', 'greens', 'garlic'],
  },
  {
    id: 'hardcoded_high_protein_green_egg_scramble',
    title: 'High-Protein Green Egg Scramble',
    tagline: 'High-Protein • Quick 10 min • Keto Friendly',
    description: 'Fluffy whole eggs scrambled with fresh baby spinach, diced bell peppers, and olive oil for a lean, high-protein powerhouse breakfast.',
    timeMinutes: 10,
    kcal: 260,
    proteinGrams: 20,
    carbsGrams: 4,
    fatGrams: 16,
    fiberGrams: 2,
    sugarGrams: 1,
    sodiumMg: 180,
    image: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=600&auto=format&fit=crop',
    imageAsset: 'assets/images/recipe_veggie_omelette.jpeg',
    recipeSource: 'curated',
    recommended: false,
    dietType: 'Eggetarian',
    diets: ['Eggetarian', 'Non-Vegetarian', 'Keto'],
    vegetarian: false,
    vegan: false,
    allergens: ['Eggs'],
    ingredients: [
      { name: 'Whole Eggs', amount: '2 large' },
      { name: 'Egg Whites', amount: '2 large' },
      { name: 'Baby Spinach', amount: '1 cup packed' },
      { name: 'Diced Bell Pepper', amount: '1/4 cup' },
      { name: 'Olive Oil', amount: '1 tsp' },
      { name: 'Salt & Black Pepper', amount: 'To taste' },
    ],
    instructions: [
      'Whisk eggs and egg whites in a bowl with a pinch of salt and black pepper.',
      'Heat olive oil in a non-stick skillet over medium-low heat.',
      'Add diced bell pepper and spinach; cook for 1-2 minutes until spinach wilts.',
      'Pour in whisked eggs and gently scramble with a spatula until soft and fluffy (2-3 minutes).',
      'Transfer to a plate and serve immediately with fresh herbs or sliced avocado.',
    ],
    whatsInside: [
      { icon: 'fitness_center_rounded', title: 'High Protein', subtitle: '20g muscle fuel', color: '#1E8A4C' },
      { icon: 'bolt_rounded', title: 'Low Carb', subtitle: 'Keto friendly 4g carbs', color: '#E0862E' },
      { icon: 'eco_rounded', title: 'Green Superfood', subtitle: 'Rich in iron & folate', color: '#1E8A4C' },
      { icon: 'favorite_rounded', title: 'Quick Fuel', subtitle: 'Ready in 10 mins', color: '#E0525C' },
    ],
    tags: ['High-Protein', 'Quick 10 min', 'Keto-friendly', 'Eggetarian', 'Eggs', 'Spinach'],
    keywords: ['egg', 'eggs', 'scramble', 'scrambled eggs', 'spinach', 'protein', 'keto', 'omelette', 'breakfast'],
  },
  {
    id: 'hardcoded_pasta_primavera',
    title: 'Pasta Primavera with Fresh Vegetables',
    tagline: 'Italian • Fresh Veggies • High Fiber',
    description: 'Tender pasta tossed with colorful sautéed bell peppers, zucchini, sweet cherry tomatoes, extra virgin olive oil, and grated parmesan cheese.',
    timeMinutes: 18,
    kcal: 380,
    proteinGrams: 13,
    carbsGrams: 58,
    fatGrams: 10,
    fiberGrams: 6,
    sugarGrams: 5,
    sodiumMg: 140,
    image: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600&auto=format&fit=crop',
    imageAsset: 'assets/images/recipe_protein_pancakes.jpeg',
    recipeSource: 'curated',
    recommended: false,
    dietType: 'Vegetarian',
    diets: ['Vegetarian'],
    vegetarian: true,
    vegan: false,
    allergens: ['Dairy', 'Gluten'],
    ingredients: [
      { name: 'Pasta (Penne or Fusilli)', amount: '1 cup dry' },
      { name: 'Zucchini', amount: '1/2 sliced' },
      { name: 'Bell Peppers', amount: '1/2 cup sliced' },
      { name: 'Cherry Tomatoes', amount: '1/2 cup halved' },
      { name: 'Olive Oil', amount: '1 tbsp' },
      { name: 'Garlic', amount: '2 cloves minced' },
      { name: 'Parmesan Cheese', amount: '1 tbsp grated' },
      { name: 'Italian Herbs & Pepper', amount: 'To taste' },
    ],
    instructions: [
      'Boil pasta in salted water according to package instructions until al dente; drain and save 2 tbsp cooking water.',
      'Heat olive oil in a large skillet over medium heat and sauté garlic for 30 seconds.',
      'Add sliced bell peppers, zucchini, and cherry tomatoes; sauté for 4-5 minutes until tender-crisp.',
      'Toss drained pasta and reserved pasta water with the vegetables in the pan.',
      'Season with Italian herbs, sprinkle with parmesan cheese, and serve immediately.',
    ],
    whatsInside: [
      { icon: 'eco_rounded', title: 'Fiber Rich', subtitle: 'Fresh seasonal veggies', color: '#1E8A4C' },
      { icon: 'favorite_rounded', title: 'Heart Healthy', subtitle: 'Extra virgin olive oil', color: '#E0525C' },
      { icon: 'bolt_rounded', title: 'Energizing', subtitle: 'Complex carbohydrates', color: '#E0862E' },
      { icon: 'shopping_bag_rounded', title: 'Classic Taste', subtitle: 'Authentic Italian flair', color: '#6C4EF5' },
    ],
    tags: ['Italian', 'Colorful', 'Vegetarian', 'Fiber Rich', 'Pasta', 'Dinner'],
    keywords: ['pasta', 'primavera', 'noodles', 'spaghetti', 'penne', 'italian', 'vegetables', 'tomato', 'zucchini', 'dinner'],
  },
];

/**
 * Checks if a recipe matches search terms or query tokens with word boundary precision
 */
const doesRecipeMatchQuery = (recipe, query) => {
  if (!query || typeof query !== 'string' || query.trim().length === 0) {
    return false;
  }
  const cleanQuery = query.toLowerCase().trim();
  const queryTokens = cleanQuery.split(/[\s,+/_-]+/).filter((t) => t.length >= 3);

  const title = (recipe.title || '').toLowerCase();
  const description = (recipe.description || '').toLowerCase();
  const tags = (recipe.tags || []).map((t) => t.toLowerCase());
  const keywords = (recipe.keywords || []).map((k) => k.toLowerCase());
  const ings = (recipe.ingredients || []).map((i) => (typeof i === 'string' ? i : i.name || '').toLowerCase());

  const fullText = `${title} ${description} ${tags.join(' ')} ${keywords.join(' ')} ${ings.join(' ')}`;

  // 1. Exact keyword match
  if (keywords.includes(cleanQuery)) {
    return true;
  }

  // 2. Word boundary match on full text
  try {
    const escapedQuery = cleanQuery.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const regex = new RegExp(`\\b${escapedQuery}(s|es)?\\b`, 'i');
    if (regex.test(fullText)) {
      return true;
    }
  } catch (_) {
    if (fullText.includes(cleanQuery)) return true;
  }

  // 3. Token-by-token word boundary match
  for (const token of queryTokens) {
    if (keywords.includes(token)) return true;
    try {
      const escaped = token.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      const tokenRegex = new RegExp(`\\b${escaped}(s|es)?\\b`, 'i');
      if (tokenRegex.test(fullText)) {
        return true;
      }
    } catch (_) {
      if (fullText.includes(token)) return true;
    }
  }

  return false;
};

/**
 * Checks if a recipe uses at least 1 pantry ingredient
 */
const doesRecipeMatchPantry = (recipe, pantryIngredients = []) => {
  if (!Array.isArray(pantryIngredients) || pantryIngredients.length === 0) {
    return false;
  }

  const title = (recipe.title || '').toLowerCase();
  const keywords = (recipe.keywords || []).map((k) => k.toLowerCase());
  const ings = (recipe.ingredients || []).map((i) => (typeof i === 'string' ? i : i.name || '').toLowerCase());
  const corpus = `${title} ${keywords.join(' ')} ${ings.join(' ')}`;

  for (const p of pantryIngredients) {
    const clean = (typeof p === 'string' ? p : p.name || p.label || '').toLowerCase().trim();
    if (clean.length >= 3) {
      if (keywords.includes(clean)) return true;
      try {
        const escaped = clean.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        if (new RegExp(`\\b${escaped}(s|es)?\\b`, 'i').test(corpus)) {
          return true;
        }
      } catch (_) {
        if (corpus.includes(clean)) return true;
      }
    }
  }

  return false;
};

/**
 * Finds matching hardcoded candidates for an explicit search query / craving
 */
const findMatchingHardcodedRecipes = (query, { userProfile = null, personalization = null, maxTime = null } = {}) => {
  if (!query || typeof query !== 'string') return [];

  return HARDCODED_RECIPES.filter((recipe) => {
    // 1. Must match query
    if (!doesRecipeMatchQuery(recipe, query)) {
      return false;
    }

    // 2. Must pass dietary safety validator
    const safety = validateRecipeSafety(recipe, userProfile, personalization);
    if (!safety.isCompatible) {
      return false;
    }

    // 3. Time check if specified
    if (maxTime && recipe.timeMinutes > maxTime) {
      return false;
    }

    return true;
  }).map((r) => ({
    ...r,
    recipeSource: 'curated',
  }));
};

/**
 * Finds hardcoded recipes that match at least 1 pantry ingredient
 */
const findPantryMatchingHardcodedRecipes = (pantryIngredients = [], { userProfile = null, personalization = null, maxTime = null } = {}) => {
  if (!Array.isArray(pantryIngredients) || pantryIngredients.length === 0) return [];

  return HARDCODED_RECIPES.filter((recipe) => {
    if (!doesRecipeMatchPantry(recipe, pantryIngredients)) {
      return false;
    }

    const safety = validateRecipeSafety(recipe, userProfile, personalization);
    if (!safety.isCompatible) {
      return false;
    }

    if (maxTime && recipe.timeMinutes > maxTime) {
      return false;
    }

    return true;
  }).map((r) => ({
    ...r,
    recipeSource: 'curated',
  }));
};

/**
 * Returns safe fallback recipes when generation produces 0 results
 */
const getFallbackHardcodedRecipes = ({ userProfile = null, personalization = null, maxTime = null, limit = 4 } = {}) => {
  const safe = HARDCODED_RECIPES.filter((recipe) => {
    const safety = validateRecipeSafety(recipe, userProfile, personalization);
    if (!safety.isCompatible) {
      return false;
    }

    if (maxTime && recipe.timeMinutes > maxTime + 10) {
      return false;
    }

    return true;
  }).map((r) => ({
    ...r,
    recipeSource: 'fallback',
  }));

  return safe.slice(0, limit);
};

/**
 * Resolves a hardcoded recipe by ID or title
 */
const getHardcodedRecipeById = (idOrTitle) => {
  if (!idOrTitle) return null;
  const target = String(idOrTitle).toLowerCase().trim();

  return HARDCODED_RECIPES.find((r) => {
    return (
      r.id.toLowerCase() === target ||
      r.title.toLowerCase() === target ||
      r.title.toLowerCase().replace(/[^a-z0-9]/g, '') === target.replace(/[^a-z0-9]/g, '')
    );
  }) || null;
};

module.exports = {
  HARDCODED_RECIPES,
  findMatchingHardcodedRecipes,
  findPantryMatchingHardcodedRecipes,
  getFallbackHardcodedRecipes,
  getHardcodedRecipeById,
  doesRecipeMatchQuery,
  doesRecipeMatchPantry,
};
