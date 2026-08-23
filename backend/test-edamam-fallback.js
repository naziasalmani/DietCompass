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
const { scoreRecipe, rankAndScoreRecipes } = require('./src/utils/recipeScorer');
const edamamService = require('./src/services/edamamService');
const spoonacularService = require('./src/services/spoonacularService');
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
  console.log('🧪 Starting Edamam Recipe Search API & Fallback Test Suite');
  console.log('======================================================\n');

  try {
    await setup();

    // -------------------------------------------------------------------------
    // TEST 1: Product to Culinary Category Normalization
    // -------------------------------------------------------------------------
    console.log('--- 1. Product to Culinary Category Normalization ---');

    const norm1 = normalizeSourceProduct('Cadbury Dairy Milk');
    assert(norm1.primaryCategory === 'chocolate', 'Cadbury Dairy Milk normalizes to "chocolate"');
    assert(norm1.keywords.includes('chocolate'), 'Keywords include "chocolate"');

    const norm2 = normalizeSourceProduct({ name: 'Maggi Masala Noodles', brand: 'Nestle' });
    assert(norm2.primaryCategory === 'noodles', 'Maggi Masala Noodles normalizes to "noodles"');

    const norm3 = normalizeSourceProduct('Lay\'s Classic');
    assert(norm3.primaryCategory === 'potato chips', 'Lay\'s Classic normalizes to "potato chips"');

    const norm4 = normalizeSourceProduct('Coca Cola');
    assert(norm4.primaryCategory === 'cola', 'Coca Cola normalizes to "cola"');

    // Test prioritized query builder
    const prioritized = buildPrioritizedQueries({
      sourceProduct: 'Cadbury Dairy Milk',
      pantryIngredients: ['Oats', 'Banana', 'Milk', 'Honey', 'Chia Seeds'],
      mealType: 'Breakfast',
    });

    assert(prioritized.queries[0] === 'chocolate oats banana', `Prioritized Attempt 1 matches product + top pantry: "${prioritized.queries[0]}"`);
    assert(prioritized.queries.includes('chocolate oats'), 'Prioritized queries include "chocolate oats"');
    assert(prioritized.queries.includes('chocolate banana'), 'Prioritized queries include "chocolate banana"');
    assert(prioritized.queries.includes('chocolate breakfast'), 'Prioritized queries include "chocolate breakfast"');

    // -------------------------------------------------------------------------
    // TEST 2: Dietary Safety Validator Hard Constraints
    // -------------------------------------------------------------------------
    console.log('\n--- 2. Backend Dietary Safety Validation ---');

    const vegProfile = { dietType: 'Vegetarian' };
    const peanutProfile = { dietType: 'Vegetarian', allergies: ['Peanuts'] };

    // A. Vegetarian safety checks
    const meatRecipe = {
      id: 'rec_beef_1',
      title: 'Slow Cooked Beef Brisket',
      image: 'https://images.example.com/beef.jpg',
      ingredients: [{ name: 'Beef Brisket' }, { name: 'Beef Broth' }],
      instructions: ['Cook beef until tender'],
    };
    const safetyMeat = validateRecipeSafety(meatRecipe, vegProfile, {});
    assert(!safetyMeat.isCompatible, 'Vegetarian rejects Beef Brisket recipe');
    assert(safetyMeat.rejectionReason.includes('beef'), 'Rejection reason identifies meat violation');

    const chickenRecipe = {
      id: 'rec_chicken_1',
      title: 'Grilled Chicken Salad',
      image: 'https://images.example.com/chicken.jpg',
      ingredients: [{ name: 'Chicken breast' }, { name: 'Lettuce' }],
      instructions: ['Grill chicken and serve with lettuce'],
    };
    const safetyChicken = validateRecipeSafety(chickenRecipe, vegProfile, {});
    assert(!safetyChicken.isCompatible, 'Vegetarian rejects Chicken recipe');

    const fishRecipe = {
      id: 'rec_salmon_1',
      title: 'Pan Seared Salmon',
      image: 'https://images.example.com/salmon.jpg',
      ingredients: [{ name: 'Salmon fillet' }, { name: 'Lemon' }],
      instructions: ['Sear salmon in olive oil'],
    };
    const safetyFish = validateRecipeSafety(fishRecipe, vegProfile, {});
    assert(!safetyFish.isCompatible, 'Vegetarian rejects Salmon recipe');

    // B. Safe plant exceptions
    const oatmealRecipe = {
      id: 'rec_choc_oats_1',
      title: 'Chocolate Banana Oatmeal Bowl',
      image: 'https://images.example.com/choc_oats.jpg',
      ingredients: [
        { name: 'Rolled Oats', amount: '1/2 cup' },
        { name: 'Banana', amount: '1 sliced' },
        { name: 'Dark chocolate', amount: '20g' },
        { name: 'Almond milk', amount: '1 cup' },
        { name: 'Chia seeds', amount: '1 tbsp' },
      ],
      instructions: ['Cook oats in almond milk and top with chocolate and banana'],
    };
    const safetyOatmeal = validateRecipeSafety(oatmealRecipe, vegProfile, {});
    assert(safetyOatmeal.isCompatible, 'Vegetarian safely allows Chocolate Banana Oatmeal with Almond Milk');

    // C. Allergy rejection
    const peanutRecipe = {
      id: 'rec_peanut_1',
      title: 'Chocolate Peanut Butter Oats',
      image: 'https://images.example.com/peanut_oats.jpg',
      ingredients: [{ name: 'Oats' }, { name: 'Peanut Butter' }, { name: 'Chocolate' }],
      instructions: ['Stir peanut butter into oats'],
    };
    const safetyPeanut = validateRecipeSafety(peanutRecipe, peanutProfile, peanutProfile);
    assert(!safetyPeanut.isCompatible, 'Peanut allergy strictly rejects Peanut Butter recipe');

    // D. Missing image rejection
    const noImgRecipe = {
      id: 'rec_no_img',
      title: 'Chocolate Oats',
      image: '',
      ingredients: [{ name: 'Oats' }, { name: 'Chocolate' }],
      instructions: ['Cook and serve'],
    };
    const safetyNoImg = validateRecipeSafety(noImgRecipe, vegProfile, {});
    assert(!safetyNoImg.isCompatible, 'Recipe with missing/empty image is strictly rejected');

    // -------------------------------------------------------------------------
    // TEST 3: Relevance Scoring System
    // -------------------------------------------------------------------------
    console.log('\n--- 3. Relevance Scoring System ---');

    const scoreResultGood = scoreRecipe({
      recipe: oatmealRecipe,
      sourceProduct: 'Cadbury Dairy Milk',
      pantryIngredients: ['Oats', 'Banana', 'Milk', 'Honey', 'Chia Seeds'],
      mealType: 'Breakfast',
      userProfile: vegProfile,
      personalization: { goals: ['Weight Loss'] },
    });

    assert(scoreResultGood.isValid, 'Chocolate Banana Oatmeal is valid');
    assert(scoreResultGood.score >= 80, `Chocolate Banana Oatmeal scores high (${scoreResultGood.score} points)`);
    assert(scoreResultGood.breakdown.sourceProductMatch === 40, 'Received +40 for source product match');
    assert(scoreResultGood.breakdown.primaryCategoryMatch === 30, 'Received +30 for culinary category match');
    assert(scoreResultGood.breakdown.pantryMatches.length >= 2, 'Received pantry matching bonuses');

    // Unrelated recipe (e.g. Egg Scramble for a Chocolate search)
    const eggScrambleRecipe = {
      id: 'rec_egg_1',
      title: 'Classic Egg Scramble',
      image: 'https://images.example.com/scramble.jpg',
      ingredients: [{ name: 'Eggs' }, { name: 'Butter' }, { name: 'Salt' }],
      instructions: ['Scramble eggs in butter'],
    };
    const scoreResultEgg = scoreRecipe({
      recipe: eggScrambleRecipe,
      sourceProduct: 'Cadbury Dairy Milk',
      pantryIngredients: ['Oats', 'Banana', 'Milk', 'Honey', 'Chia Seeds'],
      mealType: 'Breakfast',
      userProfile: vegProfile,
    });
    assert(scoreResultEgg.score < 30, `Egg Scramble receives penalty and low score (${scoreResultEgg.score}) for Chocolate search`);

    // -------------------------------------------------------------------------
    // TEST 4: Edamam Single Recipe Object Preservation & Normalization
    // -------------------------------------------------------------------------
    console.log('\n--- 4. Edamam Single Recipe Object Preservation ---');

    const sampleEdamamHit = {
      uri: 'http://www.edamam.com/ontologies/edamam.owl#recipe_b79327d44b34c5e7ba57377f366f01da',
      label: 'Chocolate Banana Oatmeal',
      image: 'https://edamam-product-images.s3.amazonaws.com/web-img/choc_oats.jpg',
      images: {
        REGULAR: {
          url: 'https://edamam-product-images.s3.amazonaws.com/web-img/choc_oats.jpg',
          width: 300,
          height: 300,
        },
      },
      url: 'http://www.seriouseats.com/recipes/chocolate-banana-oatmeal',
      yield: 2,
      dietLabels: ['Vegetarian'],
      healthLabels: ['Vegetarian', 'Peanut-Free', 'High-Fiber'],
      ingredientLines: [
        '1 cup rolled oats',
        '2 cups milk',
        '1 ripe banana, sliced',
        '2 oz dark chocolate, chopped',
      ],
      ingredients: [
        { text: '1 cup rolled oats', quantity: 1, measure: 'cup', food: 'rolled oats' },
        { text: '2 cups milk', quantity: 2, measure: 'cup', food: 'milk' },
        { text: '1 ripe banana, sliced', quantity: 1, measure: 'whole', food: 'banana' },
        { text: '2 oz dark chocolate, chopped', quantity: 2, measure: 'oz', food: 'dark chocolate' },
      ],
      calories: 640,
      totalTime: 15,
      totalNutrients: {
        ENERC_KCAL: { label: 'Energy', quantity: 640, unit: 'kcal' },
        PROCNT: { label: 'Protein', quantity: 22, unit: 'g' },
        CHOCDF: { label: 'Carbs', quantity: 96, unit: 'g' },
        FAT: { label: 'Fat', quantity: 18, unit: 'g' },
        FIBTG: { label: 'Fiber', quantity: 12, unit: 'g' },
        SUGAR: { label: 'Sugars', quantity: 28, unit: 'g' },
        NA: { label: 'Sodium', quantity: 160, unit: 'mg' },
      },
    };

    const normalizedEdamam = edamamService.normalizeEdamamRecipe(sampleEdamamHit, ['Oats', 'Banana', 'Milk']);
    assert(normalizedEdamam !== null, 'Edamam hit successfully normalized');
    assert(normalizedEdamam.id === sampleEdamamHit.uri, 'Preserves stable URI as recipe ID');
    assert(normalizedEdamam.sourceRecipeId === sampleEdamamHit.uri, 'Preserves sourceRecipeId');
    assert(normalizedEdamam.recipeSource === 'edamam', 'Marks recipeSource as "edamam"');
    assert(normalizedEdamam.image === sampleEdamamHit.image, 'Preserves exact image from same Edamam recipe object');
    assert(normalizedEdamam.title === 'Chocolate Banana Oatmeal', 'Preserves recipe title');
    assert(normalizedEdamam.kcal === 320, 'Calculates per-serving calories (640 / 2 = 320 kcal)');
    assert(normalizedEdamam.proteinGrams === 11, 'Calculates per-serving protein (22 / 2 = 11g)');
    assert(Array.isArray(normalizedEdamam.whatsInside) && normalizedEdamam.whatsInside.length > 0, 'Builds nutrition tags');

    // -------------------------------------------------------------------------
    // TEST 5: Fallback Pipeline End-to-End API Test
    // -------------------------------------------------------------------------
    console.log('\n--- 5. End-to-End Fallback Pipeline via HTTP Endpoint ---');

    // Register User with Vegetarian diet and Weight Loss goal
    const userRes = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        fullName: 'Nazia Salmani',
        username: 'nazia_fallback_test',
        email: 'nazia.fallback@example.com',
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

    // Request recipe generation with Cadbury Dairy Milk + Pantry
    const generateRes = await fetch(`${baseUrl}/recipes/generate`, {
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
        ingredients: ['Oats', 'Banana', 'Milk', 'Honey', 'Chia Seeds'],
        mealType: 'Breakfast',
      }),
    });

    assert(generateRes.status === 200, 'POST /api/recipes/generate returns 200 OK');
    const genData = await generateRes.json();
    assert(genData.success === true, 'API response reports success: true');
    assert(Array.isArray(genData.data.recipes), 'Response contains recipes array');
    assert(genData.data.recipes.length > 0, `Generated ${genData.data.recipes.length} recipes in fallback chain`);

    const topRecipe = genData.data.recipes[0];
    console.log('\n  [PIPELINE OUTPUT SUMMARY]');
    console.log('  Selected Source:', genData.data.recipeSource || topRecipe.recipeSource);
    console.log('  Top Recipe ID:', topRecipe.id);
    console.log('  Top Recipe Title:', topRecipe.title);
    console.log('  Top Recipe Image:', topRecipe.image);

    assert(Boolean(topRecipe.id), 'Top recipe has valid ID');
    assert(Boolean(topRecipe.image) && (topRecipe.image.startsWith('http://') || topRecipe.image.startsWith('https://')), 'Top recipe has valid real image URL');
    assert(
      topRecipe.title.toLowerCase().includes('chocolate') ||
      topRecipe.title.toLowerCase().includes('oat') ||
      topRecipe.title.toLowerCase().includes('banana'),
      'Top recipe is relevant to Chocolate/Oats/Banana request'
    );

    // Verify 100% vegetarian constraint
    const safetyCheck = validateRecipeSafety(topRecipe, vegProfile, {});
    assert(safetyCheck.isCompatible, 'Final selected recipe is 100% compliant with Vegetarian diet');

    // Confirm NO hardcoded demo recipe was automatically injected
    const isHardcodedDemo = topRecipe.id === 'recipe_dairymilk_oats_1' || topRecipe.id === 'recipe_banana_oats_default_1';
    assert(!isHardcodedDemo, 'Confirmed: No hardcoded demo recipe was injected into the production pipeline');

    // -------------------------------------------------------------------------
    // TEST 6: Simulated Spoonacular Failure Triggers Edamam Fallback
    // -------------------------------------------------------------------------
    console.log('\n--- 6. Simulated Spoonacular Unusable -> Edamam Fallback Execution ---');

    const origApiKey = process.env.SPOONACULAR_API_KEY;
    try {
      // Temporarily set invalid Spoonacular key to simulate API failure/quota limit
      process.env.SPOONACULAR_API_KEY = 'invalid_key_for_fallback_simulation';

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
          ingredients: ['Oats', 'Banana', 'Milk', 'Chia Seeds'],
          mealType: 'Breakfast',
        }),
      });

      assert(fallbackRes.status === 200, 'Fallback request returns 200 OK');
      const fallbackData = await fallbackRes.json();
      assert(fallbackData.success === true, 'Fallback response reports success: true');
      assert(Array.isArray(fallbackData.data.recipes), 'Fallback response contains recipes');
      assert(fallbackData.data.recipes.length > 0, `Fallback produced ${fallbackData.data.recipes.length} recipes via Edamam/AI`);

      const fallbackTop = fallbackData.data.recipes[0];
      console.log('\n  [EDAMAM FALLBACK OUTPUT SUMMARY]');
      console.log('  Selected Source:', fallbackData.data.recipeSource || fallbackTop.recipeSource);
      console.log('  Top Recipe ID:', fallbackTop.id);
      console.log('  Top Recipe Title:', fallbackTop.title);
      console.log('  Top Recipe Image:', fallbackTop.image);

      assert(Boolean(fallbackTop.id), 'Fallback recipe has valid ID');
      assert(Boolean(fallbackTop.image) && fallbackTop.image.startsWith('http'), 'Fallback recipe has valid image URL');
      assert(fallbackTop.recipeSource === 'edamam' || fallbackTop.recipeSource === 'ai', 'Fallback selected EDAMAM or AI source');

      const fallbackSafety = validateRecipeSafety(fallbackTop, vegProfile, {});
      assert(fallbackSafety.isCompatible, 'Fallback recipe is 100% compliant with Vegetarian diet');
    } finally {
      process.env.SPOONACULAR_API_KEY = origApiKey;
    }

    console.log('\n======================================================');
    console.log(`Edamam Fallback Test Results: ${passedCount} PASSED | ${failedCount} FAILED`);
    console.log('======================================================\n');

  } finally {
    await teardown();
  }

  if (failedCount > 0) {
    process.exit(1);
  }
};

runTests();
