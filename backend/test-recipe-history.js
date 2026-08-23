const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

dotenv.config();

process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test_super_secret_jwt_key_diet_compass_2026';
process.env.JWT_ACCESS_EXPIRES_IN = '15m';

const authRoutes = require('./src/routes/authRoutes');
const profileRoutes = require('./src/routes/profileRoutes');
const recipeRoutes = require('./src/routes/recipeRoutes');
const errorHandler = require('./src/middleware/errorHandler');

let mongoServer;
let app;
let server;
let baseUrl;

const assert = (condition, message) => {
  if (!condition) {
    console.error(`  ❌ FAIL: ${message}`);
    process.exit(1);
  }
  console.log(`  ✅ PASS: ${message}`);
};

const setup = async () => {
  mongoServer = await MongoMemoryServer.create();
  const uri = mongoServer.getUri();
  await mongoose.connect(uri);

  app = express();
  app.use(cors());
  app.use(express.json());
  app.use('/api/auth', authRoutes);
  app.use('/api/profile', profileRoutes);
  app.use('/api/recipes', recipeRoutes);
  app.use(errorHandler);

  return new Promise((resolve) => {
    server = app.listen(0, () => {
      const port = server.address().port;
      baseUrl = `http://127.0.0.1:${port}/api`;
      resolve();
    });
  });
};

const teardown = async () => {
  if (server) server.close();
  if (mongoose.connection.readyState !== 0) await mongoose.disconnect();
  if (mongoServer) await mongoServer.stop();
};

async function runTests() {
  console.log('\n======================================================');
  console.log('🧪 RECIPE HISTORY PERSISTENCE & USER ISOLATION TESTS');
  console.log('======================================================\n');

  await setup();

  try {
    const timestamp = Date.now();
    const userAEmail = `user_a_${timestamp}@example.com`;
    const userBEmail = `user_b_${timestamp}@example.com`;
    const password = 'Password123!';

    // --- 1. Authentication Guards ---
    console.log('--- 1. Authentication Guards ---');
    const resUnauthGet = await fetch(`${baseUrl}/recipes/history`);
    assert(resUnauthGet.status === 401, 'Unauthenticated GET /api/recipes/history rejected with 401');

    const resUnauthPost = await fetch(`${baseUrl}/recipes/history`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: 'Test Recipe' }),
    });
    assert(resUnauthPost.status === 401, 'Unauthenticated POST /api/recipes/history rejected with 401');

    // --- 2. Register Users ---
    console.log('\n--- 2. Register Users ---');
    const resRegA = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        fullName: 'User A',
        username: `usera_${timestamp}`,
        email: userAEmail,
        password,
      }),
    });
    const regDataA = await resRegA.json();
    assert(resRegA.status === 201, 'User A registered successfully');
    const tokenA = regDataA.data.tokens.accessToken;

    const resRegB = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        fullName: 'User B',
        username: `userb_${timestamp}`,
        email: userBEmail,
        password,
      }),
    });
    const regDataB = await resRegB.json();
    assert(resRegB.status === 201, 'User B registered successfully');
    const tokenB = regDataB.data.tokens.accessToken;

    // --- 3. User A Initial State ---
    console.log('\n--- 3. User A Initial State (Empty) ---');
    const resInitA = await fetch(`${baseUrl}/recipes/history`, {
      headers: { Authorization: `Bearer ${tokenA}` },
    });
    const initDataA = await resInitA.json();
    assert(resInitA.status === 200, 'User A initial history returns 200');
    assert(initDataA.data.recipes.length === 0, 'User A has 0 recipes initially (no demo data)');
    assert(initDataA.data.totalCount === 0, 'User A totalCount is 0');

    // --- 4. User A Saves Product-Mode Recipes ---
    console.log('\n--- 4. User A Saves Product-Mode Recipe (Cadbury Dairy Milk) ---');
    const chocolateRecipe = {
      recipeId: 'sp_634011',
      title: 'Banana Bread with Chocolate Swirl',
      description: 'Moist banana bread with decadent chocolate swirls.',
      imageUrl: 'https://img.spoonacular.com/recipes/634011-312x231.jpg',
      ingredients: [
        { name: 'chocolate', amount: '100g' },
        { name: 'banana', amount: '2 ripe' },
        { name: 'flour', amount: '2 cups' },
      ],
      instructions: [
        'Mash bananas in a bowl.',
        'Melt chocolate and swirl into batter.',
        'Bake at 350F for 45 minutes.',
      ],
      nutrition: {
        calories: 320,
        protein: 6,
        carbs: 48,
        fat: 12,
        fiber: 3,
      },
      timeMinutes: 45,
      recipeSource: 'spoonacular',
    };

    const resSaveProd = await fetch(`${baseUrl}/recipes/history`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        recipes: [chocolateRecipe],
        generationMode: 'product',
        sourceProduct: 'Cadbury Dairy Milk Silk',
        normalizedIngredient: 'chocolate',
      }),
    });
    const saveProdData = await resSaveProd.json();
    assert(resSaveProd.status === 200, 'User A saved Product Mode recipe');
    assert(saveProdData.data.recipes.length === 1, 'Saved 1 recipe');
    const savedRec0 = saveProdData.data.recipes[0];
    assert(savedRec0.title === 'Banana Bread with Chocolate Swirl', 'Title matches');
    assert(savedRec0.generationMode === 'product', 'Generation mode is product');
    assert(savedRec0.sourceProduct === 'Cadbury Dairy Milk Silk', 'Source product is Cadbury Dairy Milk Silk');
    assert(savedRec0.normalizedIngredient === 'chocolate', 'Normalized ingredient is chocolate');
    assert(savedRec0.imageUrl === 'https://img.spoonacular.com/recipes/634011-312x231.jpg', 'Exact Spoonacular image URL preserved');

    // --- 5. User A Saves Pantry-Mode Recipe (TheMealDB) ---
    console.log('\n--- 5. User A Saves Pantry-Mode Recipe (TheMealDB) ---');
    const mealDbRecipe = {
      recipeId: 'tm_52772',
      title: 'Teriyaki Chicken Casserole',
      description: 'Japanese style chicken and rice casserole.',
      imageUrl: 'https://www.themealdb.com/images/media/meals/wvpsxx1468256321.jpg',
      ingredients: [
        { name: 'chicken', amount: '500g' },
        { name: 'rice', amount: '1 cup' },
      ],
      instructions: ['Cook chicken and rice with teriyaki sauce.'],
      nutrition: { calories: 450, protein: 32, carbs: 55, fat: 10, fiber: 2 },
      timeMinutes: 30,
      recipeSource: 'themealdb',
    };

    const resSavePantry = await fetch(`${baseUrl}/recipes/history`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        recipes: [mealDbRecipe],
        generationMode: 'pantry',
        pantryIngredients: ['chicken', 'rice', 'soy sauce'],
      }),
    });
    assert(resSavePantry.status === 200, 'User A saved Pantry Mode recipe (TheMealDB)');

    // --- 6. Verify User A Ordering (Newest First) ---
    console.log('\n--- 6. Verify User A History Ordering (Newest First) ---');
    const resHistA = await fetch(`${baseUrl}/recipes/history`, {
      headers: { Authorization: `Bearer ${tokenA}` },
    });
    const histDataA = await resHistA.json();
    assert(histDataA.data.recipes.length === 2, 'User A has exactly 2 recipes in history');
    assert(histDataA.data.recipes[0].title === 'Teriyaki Chicken Casserole', 'Newest recipe is first (Teriyaki Chicken)');
    assert(histDataA.data.recipes[1].title === 'Banana Bread with Chocolate Swirl', 'Older recipe is second (Banana Bread)');

    // --- 7. Re-generating Same Recipe Bumps Timestamp (No Duplicates) ---
    console.log('\n--- 7. Re-generating Same Recipe Bumps Timestamp ---');
    await fetch(`${baseUrl}/recipes/history`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        recipes: [chocolateRecipe],
        generationMode: 'product',
        sourceProduct: 'Cadbury Dairy Milk Silk',
        normalizedIngredient: 'chocolate',
      }),
    });

    const resBumped = await fetch(`${baseUrl}/recipes/history`, {
      headers: { Authorization: `Bearer ${tokenA}` },
    });
    const bumpedData = await resBumped.json();
    assert(bumpedData.data.recipes.length === 2, 'Total count remains 2 (no duplicate row created)');
    assert(bumpedData.data.recipes[0].title === 'Banana Bread with Chocolate Swirl', 'Banana Bread bumped to top');

    // --- 8. Bookmark Toggling ---
    console.log('\n--- 8. Bookmark Toggling ---');
    const bananaId = bumpedData.data.recipes[0]._id;
    const resBookmark = await fetch(`${baseUrl}/recipes/history/${bananaId}/bookmark`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({ isBookmarked: true }),
    });
    const bookmarkData = await resBookmark.json();
    assert(resBookmark.status === 200, 'Bookmark PATCH returned 200');
    assert(bookmarkData.data.recipe.isBookmarked === true, 'isBookmarked updated to true');

    const resSavedTab = await fetch(`${baseUrl}/recipes/history?tab=saved`, {
      headers: { Authorization: `Bearer ${tokenA}` },
    });
    const savedTabData = await resSavedTab.json();
    assert(savedTabData.data.recipes.length === 1, 'Saved tab returns only bookmarked recipe');
    assert(savedTabData.data.recipes[0].title === 'Banana Bread with Chocolate Swirl', 'Correct saved recipe returned');

    // --- 9. User B Scans Different Recipes & Verify Cross-User Isolation ---
    console.log('\n--- 9. Strict Multi-User Data Isolation ---');
    const userBRecipe = {
      recipeId: 'sp_998877',
      title: 'Spicy Tofu Stir Fry',
      description: 'Crispy tofu in spicy chili garlic sauce.',
      imageUrl: 'https://img.spoonacular.com/recipes/998877-312x231.jpg',
      ingredients: [{ name: 'tofu', amount: '200g' }],
      instructions: ['Fry tofu until golden.'],
      nutrition: { calories: 290, protein: 18, carbs: 15, fat: 14, fiber: 4 },
      timeMinutes: 20,
      recipeSource: 'spoonacular',
    };

    await fetch(`${baseUrl}/recipes/history`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenB}`,
      },
      body: JSON.stringify({
        recipes: [userBRecipe],
        generationMode: 'pantry',
        pantryIngredients: ['tofu', 'garlic'],
      }),
    });

    const resHistB = await fetch(`${baseUrl}/recipes/history`, {
      headers: { Authorization: `Bearer ${tokenB}` },
    });
    const histDataB = await resHistB.json();
    assert(histDataB.data.recipes.length === 1, 'User B has exactly 1 recipe');
    assert(histDataB.data.recipes[0].title === 'Spicy Tofu Stir Fry', 'User B recipe is Spicy Tofu');
    const bHasA = histDataB.data.recipes.some(r => r.title.includes('Banana') || r.title.includes('Teriyaki'));
    assert(!bHasA, 'User B history does NOT contain any of User A recipes');

    const resHistAFinal = await fetch(`${baseUrl}/recipes/history`, {
      headers: { Authorization: `Bearer ${tokenA}` },
    });
    const histDataAFinal = await resHistAFinal.json();
    const aHasB = histDataAFinal.data.recipes.some(r => r.title.includes('Tofu'));
    assert(!aHasB, 'User A history does NOT contain any of User B recipes');

    console.log('\n======================================================');
    console.log('🎉 ALL RECIPE HISTORY BACKEND TESTS PASSED');
    console.log('======================================================\n');
  } catch (err) {
    console.error('\n❌ TEST FAILED:', err.message);
    process.exit(1);
  } finally {
    await teardown();
  }
}

runTests();
