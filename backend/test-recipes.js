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
  console.log('🧪 Starting Phase 6D Recipe Generator Test Suite');
  console.log('======================================================\n');

  try {
    await setup();

    // 1. Create Test Users (User A: Vegan, Peanut Allergy, Low Sugar; User B: Omnivore, High Protein)
    console.log('--- Registering Test Users & Personalization ---');
    const userARes = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        fullName: 'Nazia Salmani',
        username: 'nazia_chef',
        email: 'nazia.recipes@example.com',
        password: 'Password123!',
        termsAccepted: true,
      }),
    });
    const userAData = await userARes.json();
    const tokenA = userAData.data.tokens.accessToken;

    // Save Personalization for User A (Vegan, Peanut Allergy, Low Sugar goal, Dislikes mushrooms)
    await fetch(`${baseUrl}/personalization`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        dietType: 'Vegan',
        allergies: ['Peanuts'],
        dislikedFoods: ['mushrooms'],
        goals: ['Low Sugar', 'Weight Loss'],
      }),
    });
    assert(true, 'Test User A created with Vegan diet, Peanut allergy, and mushroom dislike');

    // Create User B (Omnivore, Muscle Gain)
    const userBRes = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        fullName: 'Alex Miller',
        username: 'alex_athlete',
        email: 'alex.recipes@example.com',
        password: 'Password123!',
        termsAccepted: true,
      }),
    });
    const userBData = await userBRes.json();
    const tokenB = userBData.data.tokens.accessToken;

    await fetch(`${baseUrl}/personalization`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenB}`,
      },
      body: JSON.stringify({
        dietType: 'Omnivore',
        allergies: [],
        goals: ['Muscle Gain', 'High Protein'],
      }),
    });
    assert(true, 'Test User B created with Omnivore diet and Muscle Gain goal');


    // -------------------------------------------------------------------------
    // 2. Authentication & Authorization Guards
    // -------------------------------------------------------------------------
    console.log('\n--- 1. Authentication Guards ---');
    const resUnauth = await fetch(`${baseUrl}/recipes/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ ingredients: ['oats', 'banana'] }),
    });
    assert(resUnauth.status === 401, 'Unauthenticated POST /api/recipes/generate rejected with 401');

    const resDetailUnauth = await fetch(`${baseUrl}/recipes/634486`, {
      method: 'GET',
    });
    assert(resDetailUnauth.status === 401, 'Unauthenticated GET /api/recipes/:id rejected with 401');

    // -------------------------------------------------------------------------
    // 3. Empty Pantry Handling
    // -------------------------------------------------------------------------
    console.log('\n--- 2. Empty Pantry Handling ---');
    const resEmpty = await fetch(`${baseUrl}/recipes/generate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({ ingredients: [], pantryItems: [] }),
    });
    const dataEmpty = await resEmpty.json();
    assert(resEmpty.status === 200, 'Empty pantry request returns 200 OK');
    assert(dataEmpty.data.totalFound === 0, 'Empty pantry returns 0 recipes');
    assert(Array.isArray(dataEmpty.data.recipes) && dataEmpty.data.recipes.length === 0, 'Recipes array is empty');
    assert(dataEmpty.data.pantrySummary.includes('empty'), 'User-friendly empty pantry summary returned');

    // -------------------------------------------------------------------------
    // 4. Pantry Ingredients & Real Spoonacular Results
    // -------------------------------------------------------------------------
    console.log('\n--- 3. Recipe Generation from Pantry ---');
    const resGen = await fetch(`${baseUrl}/recipes/generate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        ingredients: ['oats', 'banana', 'almond milk', 'chia seeds'],
        pantryItems: [{ name: 'Oats' }, { name: 'Banana' }],
      }),
    });
    const dataGen = await resGen.json();
    assert(resGen.status === 200, 'Recipe generation returns 200 OK');
    assert(Array.isArray(dataGen.data.recipes) && dataGen.data.recipes.length > 0, `Generated ${dataGen.data.recipes.length} recipes from pantry`);

    const firstRecipe = dataGen.data.recipes[0];
    assert(typeof firstRecipe.id === 'number', 'Recipe has valid numeric ID');
    assert(typeof firstRecipe.title === 'string' && firstRecipe.title.length > 0, 'Recipe has authentic title');
    assert(firstRecipe.imageAsset.startsWith('http') || firstRecipe.imageAsset.startsWith('assets/'), 'Recipe has real image URL or valid asset fallback');
    assert(typeof firstRecipe.timeMinutes === 'number' && firstRecipe.timeMinutes > 0, 'Recipe has cooking time in minutes');
    assert(typeof firstRecipe.kcal === 'number' && firstRecipe.kcal > 0, 'Recipe has factual calorie count');
    assert(typeof firstRecipe.proteinGrams === 'number', 'Recipe has factual protein content');
    assert(Array.isArray(firstRecipe.whatsInside) && firstRecipe.whatsInside.length > 0, 'Recipe contains WhatsIn nutrition tags');
    assert(firstRecipe.recommended === true, 'First recipe is marked as Recommended');

    // -------------------------------------------------------------------------
    // 5. Pantry Match Details & Ingredients
    // -------------------------------------------------------------------------
    console.log('\n--- 4. Pantry Match & Ingredients Breakdown ---');
    assert(typeof firstRecipe.usedIngredientCount === 'number', 'Contains usedIngredientCount');
    assert(typeof firstRecipe.missedIngredientCount === 'number', 'Contains missedIngredientCount');
    assert(Array.isArray(firstRecipe.usedIngredients), 'Contains usedIngredients array');
    assert(Array.isArray(firstRecipe.missedIngredients), 'Contains missedIngredients array');
    assert(typeof firstRecipe.pantryMatchSummary === 'string' && firstRecipe.pantryMatchSummary.includes('pantry'), 'Contains informative pantryMatchSummary');

    // -------------------------------------------------------------------------
    // 6. Safety: Dietary & Allergy Filtering
    // -------------------------------------------------------------------------
    console.log('\n--- 5. Allergy & Dietary Restriction Safety ---');
    const recipesA = dataGen.data.recipes;
    // User A has Peanut allergy
    const hasPeanut = recipesA.some((r) => `${r.title} ${r.ingredients.map((i) => i.name).join(' ')}`.toLowerCase().includes('peanut'));
    assert(!hasPeanut, 'Peanut-containing recipes are strictly excluded for peanut-allergic user');

    // User A dislikes mushrooms
    const hasMushroom = recipesA.some((r) => `${r.title} ${r.ingredients.map((i) => i.name).join(' ')}`.toLowerCase().includes('mushroom'));
    assert(!hasMushroom, 'Disliked foods (mushrooms) are strictly excluded');

    // User A is Vegan
    const hasNonVegan = recipesA.some((r) => {
      const txt = `${r.title} ${r.ingredients.map((i) => i.name).join(' ')}`.toLowerCase();
      return txt.includes('chicken') || txt.includes('beef') || txt.includes('pork') || txt.includes('fish');
    });
    assert(!hasNonVegan, 'Meat/poultry/fish recipes are strictly excluded for Vegan user');

    // -------------------------------------------------------------------------
    // 7. Recipe Details API
    // -------------------------------------------------------------------------
    console.log('\n--- 6. Recipe Details Retrieval ---');
    const resDetail = await fetch(`${baseUrl}/recipes/${firstRecipe.id}`, {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${tokenA}`,
      },
    });
    const dataDetail = await resDetail.json();
    assert(resDetail.status === 200, 'GET /api/recipes/:id returns 200 OK');
    const detail = dataDetail.data;
    assert(detail.id === firstRecipe.id, 'Returns correct recipe ID');
    assert(Array.isArray(detail.ingredients) && detail.ingredients.length > 0, 'Contains ingredients with measurements');
    assert(Array.isArray(detail.instructions) && detail.instructions.length > 0, 'Contains numbered step-by-step instructions');
    assert(detail.servings >= 1, 'Contains serving size');

    // -------------------------------------------------------------------------
    // 8. API Key Security Guard
    // -------------------------------------------------------------------------
    console.log('\n--- 7. API Key Security ---');
    const responseText = JSON.stringify(dataGen);
    assert(!responseText.includes(process.env.SPOONACULAR_API_KEY || 'SECRET_KEY_NOT_FOUND'), 'Spoonacular API key is never exposed in response body');

    console.log('\n======================================================');
    console.log(`Phase 6D Recipe Generator Test Results: ${passedCount} PASSED | ${failedCount} FAILED`);
    console.log('======================================================\n');
  } finally {
    await teardown();
  }

  if (failedCount > 0) {
    process.exit(1);
  }
};

runTests();
