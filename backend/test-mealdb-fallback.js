const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

dotenv.config();

process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test_super_secret_jwt_key_diet_compass_2026';
process.env.JWT_ACCESS_EXPIRES_IN = '15m';

const User = require('./src/models/User');
const Personalization = require('./src/models/Personalization');
const authRoutes = require('./src/routes/authRoutes');
const personalizationRoutes = require('./src/routes/personalizationRoutes');
const recipeRoutes = require('./src/routes/recipeRoutes');
const errorHandler = require('./src/middleware/errorHandler');

const { normalizeSourceProduct, cleanPantryIngredients, buildPrioritizedQueries } = require('./src/utils/productNormalizer');
const { validateRecipeSafety } = require('./src/utils/dietarySafetyValidator');
const { scoreRecipe } = require('./src/utils/recipeScorer');
const mealDbService = require('./src/services/mealDbService');
const recipePipelineService = require('./src/services/recipePipelineService');

let mongoServer;
let app;
let server;
let baseUrl;
let passedCount = 0;
let failedCount = 0;

const assert = (condition, message) => {
  if (condition) {
    console.log(`  ✅ PASS: ${message}`);
    passedCount++;
  } else {
    console.error(`  ❌ FAIL: ${message}`);
    failedCount++;
  }
};

const setup = async () => {
  mongoServer = await MongoMemoryServer.create();
  const uri = mongoServer.getUri();
  await mongoose.connect(uri);

  app = express();
  app.use(cors());
  app.use(express.json());
  app.use('/api/auth', authRoutes);
  app.use('/api/personalization', personalizationRoutes);
  app.use('/api/recipes', recipeRoutes);
  app.use(errorHandler);

  return new Promise((resolve) => {
    server = app.listen(0, () => {
      const port = server.address().port;
      baseUrl = `http://localhost:${port}/api`;
      resolve();
    });
  });
};

const teardown = async () => {
  if (server) await new Promise((r) => server.close(r));
  if (mongoose.connection.readyState !== 0) await mongoose.disconnect();
  if (mongoServer) await mongoServer.stop();
};

const runTests = async () => {
  console.log('\n======================================================');
  console.log('🧪 Starting TheMealDB Recipe Fallback Pipeline Test Suite');
  console.log('======================================================\n');

  try {
    await setup();

    // -------------------------------------------------------------------------
    // TEST 1: TheMealDB Result Parsing & Single Recipe Object Preservation
    // -------------------------------------------------------------------------
    console.log('--- 1. TheMealDB Result Parsing & Exact Image Preservation ---');

    const sampleMealDbRaw = {
      idMeal: '52776',
      strMeal: 'Chocolate Gateau',
      strCategory: 'Dessert',
      strArea: 'French',
      strInstructions: 'Preheat the oven to 180C/350F/Gas 4. Melt chocolate and butter gently in a bowl over a pan of hot water.',
      strMealThumb: 'https://www.themealdb.com/images/media/meals/tqtywx1468317395.jpg',
      strTags: 'Cake,Chocolate,Dessert',
      strIngredient1: 'Plain Chocolate',
      strIngredient2: 'Butter',
      strIngredient3: 'Milk',
      strIngredient4: 'Eggs',
      strMeasure1: '175g',
      strMeasure2: '100g',
      strMeasure3: '3 tbsp',
      strMeasure4: '3',
      strSource: 'http://www.bbcgoodfood.com/recipes/chocolate-gateau',
    };

    const normalized = mealDbService.normalizeMealDbRecipe(sampleMealDbRaw, ['Milk', 'Butter']);
    assert(normalized !== null, 'TheMealDB raw object normalized successfully');
    assert(normalized.id === '52776', 'Preserves TheMealDB meal ID');
    assert(normalized.sourceRecipeId === '52776', 'Preserves sourceRecipeId');
    assert(normalized.recipeSource === 'themealdb', 'Marks recipeSource as "themealdb"');
    assert(normalized.image === sampleMealDbRaw.strMealThumb, 'Preserves exact TheMealDB meal image URL (strMealThumb)');
    assert(normalized.title === 'Chocolate Gateau', 'Preserves exact meal title');
    assert(normalized.ingredients.length === 4, 'Extracted all 4 ingredients with measurements');
    assert(normalized.ingredients[0].name === 'Plain Chocolate', 'Parsed ingredient name accurately');
    assert(normalized.ingredients[0].amount === '175g', 'Parsed ingredient measurement accurately');
    assert(Array.isArray(normalized.whatsInside) && normalized.whatsInside.length > 0, 'Builds nutrition tags');

    // -------------------------------------------------------------------------
    // TEST 2: TheMealDB Dietary Filtering (Hard Vegetarian Constraint)
    // -------------------------------------------------------------------------
    console.log('\n--- 2. TheMealDB Vegetarian Safety Filtering ---');

    const vegProfile = { dietType: 'Vegetarian' };

    // Valid vegetarian chocolate dessert
    const safetyGateau = validateRecipeSafety(normalized, vegProfile, {});
    assert(safetyGateau.isCompatible, 'Chocolate Gateau is compatible with Vegetarian diet');

    // Meat meal from TheMealDB (e.g. Beef and Mustard Pie)
    const rawBeefMeal = {
      idMeal: '52874',
      strMeal: 'Beef and Mustard Pie',
      strCategory: 'Beef',
      strMealThumb: 'https://www.themealdb.com/images/media/meals/sytuqu1511553755.jpg',
      strIngredient1: 'Beef',
      strIngredient2: 'Plain Flour',
      strIngredient3: 'Beef Stock',
      strMeasure1: '1kg',
      strMeasure2: '2 tbsp',
      strMeasure3: '400ml',
      strInstructions: 'Preheat oven. Brown the beef in a pan with beef stock.',
    };

    const normalizedBeef = mealDbService.normalizeMealDbRecipe(rawBeefMeal, []);
    const safetyBeef = validateRecipeSafety(normalizedBeef, vegProfile, {});
    assert(!safetyBeef.isCompatible, 'Vegetarian profile strictly REJECTS Beef meal from TheMealDB');
    assert(safetyBeef.rejectionReason.includes('beef'), 'Rejection identifies beef violation');

    // Fish meal from TheMealDB
    const rawFishMeal = {
      idMeal: '52882',
      strMeal: 'Three Fish Pie',
      strCategory: 'Seafood',
      strMealThumb: 'https://www.themealdb.com/images/media/meals/sxxpst1468569726.jpg',
      strIngredient1: 'Salmon',
      strIngredient2: 'Cod',
      strMeasure1: '250g',
      strMeasure2: '250g',
      strInstructions: 'Poach fish in milk.',
    };
    const normalizedFish = mealDbService.normalizeMealDbRecipe(rawFishMeal, []);
    const safetyFish = validateRecipeSafety(normalizedFish, vegProfile, {});
    assert(!safetyFish.isCompatible, 'Vegetarian profile strictly REJECTS Seafood meal from TheMealDB');

    // -------------------------------------------------------------------------
    // TEST 3: Source Product Relevance Scoring
    // -------------------------------------------------------------------------
    console.log('\n--- 3. Source Product Relevance Scoring ---');

    const scoreResultGood = scoreRecipe({
      recipe: normalized,
      sourceProduct: 'Cadbury Dairy Milk',
      pantryIngredients: ['Oats', 'Banana', 'Milk'],
      mealType: 'Breakfast',
      userProfile: vegProfile,
    });

    assert(scoreResultGood.isValid, 'Chocolate recipe is scored as valid');
    assert(scoreResultGood.score >= 80, `Chocolate recipe scores high (${scoreResultGood.score} points)`);
    assert(scoreResultGood.breakdown.sourceProductMatch === 40, 'Received +40 source product match bonus');
    assert(scoreResultGood.breakdown.primaryCategoryMatch === 30, 'Received +30 culinary category match bonus');

    // Unrelated recipe (e.g. Tomato Soup for Chocolate search)
    const tomatoSoup = {
      id: '52952',
      title: 'Tomato Soup',
      image: 'https://www.themealdb.com/images/media/meals/1529444830.jpg',
      ingredients: [{ name: 'Tomatoes' }, { name: 'Onions' }, { name: 'Garlic' }],
      instructions: ['Simmer tomatoes and blend'],
    };
    const scoreSoup = scoreRecipe({
      recipe: tomatoSoup,
      sourceProduct: 'Cadbury Dairy Milk',
      pantryIngredients: ['Oats', 'Banana'],
      userProfile: vegProfile,
    });
    assert(scoreSoup.score < 30, `Tomato Soup receives penalty and low score (${scoreSoup.score}) for Chocolate search`);

    // -------------------------------------------------------------------------
    // TEST 4: Live TheMealDB Free V1 API Service Execution
    // -------------------------------------------------------------------------
    console.log('\n--- 4. Live TheMealDB Service Query Execution ---');

    const mealDbServiceResult = await mealDbService.searchMealDbRecipes({
      sourceProduct: 'Cadbury Dairy Milk',
      ingredients: ['Milk', 'Banana', 'Oats'],
      mealType: 'Breakfast',
      userProfile: vegProfile,
    });

    assert(mealDbServiceResult.rawCount > 0, `TheMealDB free V1 returned ${mealDbServiceResult.rawCount} raw meals for chocolate`);
    assert(mealDbServiceResult.validCount > 0, `TheMealDB produced ${mealDbServiceResult.validCount} valid vegetarian chocolate recipes`);

    const topMealDb = mealDbServiceResult.recipes[0];
    assert(Boolean(topMealDb.id), 'Selected TheMealDB recipe has valid ID');
    assert(topMealDb.image.startsWith('http'), 'Selected TheMealDB recipe has valid image URL');
    assert(
      topMealDb.title.toLowerCase().includes('chocolate') ||
      topMealDb.ingredients.some((i) => i.name.toLowerCase().includes('chocolate') || i.name.toLowerCase().includes('cocoa')),
      'Selected TheMealDB recipe genuinely contains chocolate'
    );

    // -------------------------------------------------------------------------
    // TEST 5: End-to-End Fallback Pipeline via HTTP API
    // -------------------------------------------------------------------------
    console.log('\n--- 5. End-to-End Fallback Pipeline via HTTP API ---');

    // Register User with Vegetarian diet and Weight Loss goal
    const userRes = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        fullName: 'Nazia Salmani',
        username: 'nazia_mealdb_test',
        email: 'nazia.mealdb@example.com',
        password: 'Password123!',
        termsAccepted: true,
      }),
    });
    const userData = await userRes.json();
    const token = userData.data.tokens.accessToken;

    await fetch(`${baseUrl}/personalization`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        dietType: 'Vegetarian',
        allergies: [],
        goals: ['Weight Loss'],
      }),
    });

    // 5A. Spoonacular Normal Success Path
    console.log('\n  [5A] Testing Normal Spoonacular Success Path:');
    const normalRes = await fetch(`${baseUrl}/recipes/generate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        sourceProduct: {
          name: 'Cadbury Dairy Milk',
          brand: 'Cadbury',
        },
        ingredients: ['Oats', 'Banana', 'Milk', 'Chia Seeds'],
        mealType: 'Breakfast',
      }),
    });

    assert(normalRes.status === 200, 'POST /api/recipes/generate returns 200 OK');
    const normalData = await normalRes.json();
    assert(normalData.success === true, 'Response reports success: true');
    assert(Array.isArray(normalData.data.recipes) && normalData.data.recipes.length > 0, 'Generated recipes from primary provider');

    // 5B. Spoonacular Unusable -> Fallback to TheMealDB
    console.log('\n  [5B] Testing Simulated Spoonacular Failure -> TheMealDB Fallback:');
    const origApiKey = process.env.SPOONACULAR_API_KEY;
    try {
      process.env.SPOONACULAR_API_KEY = 'invalid_key_to_force_mealdb_fallback';

      const fallbackRes = await fetch(`${baseUrl}/recipes/generate`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          sourceProduct: {
            name: 'Cadbury Dairy Milk',
            brand: 'Cadbury',
          },
          ingredients: ['Milk', 'Banana', 'Oats'],
          mealType: 'Breakfast',
        }),
      });

      assert(fallbackRes.status === 200, 'Fallback request returns 200 OK');
      const fallbackData = await fallbackRes.json();
      assert(fallbackData.success === true, 'Fallback response reports success: true');
      assert(Array.isArray(fallbackData.data.recipes), 'Fallback contains recipes');
      assert(fallbackData.data.recipes.length > 0, `Fallback produced ${fallbackData.data.recipes.length} recipes via TheMealDB/AI`);

      const topFallback = fallbackData.data.recipes[0];
      assert(topFallback.recipeSource === 'themealdb' || topFallback.recipeSource === 'ai', 'Fallback selected TheMealDB or AI source');
      assert(Boolean(topFallback.image) && topFallback.image.startsWith('http'), 'Fallback recipe contains genuine image URL');

      // Verify no demo recipes used
      const isDemo = topFallback.id === 'recipe_dairymilk_oats_1' || topFallback.id === 'recipe_banana_oats_default_1';
      assert(!isDemo, 'Confirmed: No hardcoded demo recipe was used as fallback');
    } finally {
      process.env.SPOONACULAR_API_KEY = origApiKey;
    }

    console.log('\n======================================================');
    console.log(`TheMealDB Fallback Test Results: ${passedCount} PASSED | ${failedCount} FAILED`);
    console.log('======================================================\n');
  } finally {
    await teardown();
  }

  if (failedCount > 0) {
    process.exit(1);
  }
};

runTests();
