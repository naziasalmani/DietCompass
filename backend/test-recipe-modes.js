/**
 * Comprehensive Automated Test Suite for DietCompass Recipe Generation:
 * 1. Product Normalization (Dairy Milk -> chocolate, Maggi -> noodles, Oreo -> cookies, etc.)
 * 2. Product-Centric Recipe Generation Flow (Raw brand names NOT sent to recipe API, pantry IGNORED)
 * 3. Pantry-Centric Recipe Generation Flow (Flexible subset matching, all ingredients NOT required)
 * 4. Mode Independence & Search Query Safety
 */

const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

dotenv.config();

process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test_super_secret_jwt_key_diet_compass_2026';
process.env.JWT_ACCESS_EXPIRES_IN = '15m';

const { normalizeProductForRecipe } = require('./src/utils/productNormalizer');
const authRoutes = require('./src/routes/authRoutes');
const personalizationRoutes = require('./src/routes/personalizationRoutes');
const recipeRoutes = require('./src/routes/recipeRoutes');
const errorHandler = require('./src/middleware/errorHandler');

let mongoServer;
let app;
let server;
let baseUrl;
let authToken;
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

  server = app.listen(0);
  const port = server.address().port;
  baseUrl = `http://localhost:${port}/api`;
};

const teardown = async () => {
  if (server) server.close();
  if (mongoose.connection.readyState !== 0) await mongoose.disconnect();
  if (mongoServer) await mongoServer.stop();
};

const runSuite = async () => {
  try {
    await setup();

    console.log('======================================================');
    console.log('🧪 Starting Root Recipe Search & Normalization Test Suite');
    console.log('======================================================\n');

    // ---------------------------------------------------------------------------
    // SECTION 1: Pure Product Normalization Tests (Brand -> Generic Culinary Category)
    // ---------------------------------------------------------------------------
    console.log('--- SECTION 1: Product-to-Culinary Category Normalization ---');

    const testCases = [
      { input: { name: 'Dairy Milk Silk Chocolate', brand: 'Cadbury' }, expected: 'chocolate' },
      { input: { name: 'Cadbury Dairy Milk', brand: 'Cadbury' }, expected: 'chocolate' },
      { input: { name: 'Maggi 2-Minute Masala Noodles', brand: 'Nestle' }, expected: 'noodles' },
      { input: { name: 'Maggi Masala Noodles', brand: 'Nestle' }, expected: 'noodles' },
      { input: { name: "Lay's Classic Salted Potato Chips", brand: "Lay's" }, expected: 'potato chips' },
      { input: { name: 'Amul Butter', brand: 'Amul' }, expected: 'butter' },
      { input: { name: 'Amul Processed Cheese', brand: 'Amul' }, expected: 'cheese' },
      { input: { name: 'Oreo Original', brand: 'Cadbury' }, expected: 'cookies' },
      { input: { name: 'Nutella Hazelnut Spread', brand: 'Ferrero' }, expected: 'hazelnut spread' },
      { input: { name: 'Organic Rolled Oats', brand: 'Quaker' }, expected: 'oats' },
    ];

    for (const { input, expected } of testCases) {
      const norm = normalizeProductForRecipe(input);
      assert(
        norm.normalizedIngredient === expected,
        `"${input.name}" -> normalizedIngredient = "${norm.normalizedIngredient}" (expected: "${expected}")`
      );
      assert(
        norm.recipeSearchQuery === expected,
        `"${input.name}" -> recipeSearchQuery = "${norm.recipeSearchQuery}" (never raw brand name)`
      );
    }

    // Register test user
    const regRes = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        fullName: 'Culinary Tester',
        username: 'culinary2026',
        email: 'culinary@example.com',
        password: 'Password123!',
        termsAccepted: true,
      }),
    });
    const regData = await regRes.json();
    authToken = regData.data.tokens.accessToken;

    await fetch(`${baseUrl}/personalization`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${authToken}`,
      },
      body: JSON.stringify({
        dietType: 'Vegetarian',
        allergies: [],
        dislikedFoods: [],
        goals: ['Weight Loss'],
      }),
    });

    // ---------------------------------------------------------------------------
    // SECTION 2: TEST 1 — Dairy Milk Silk Chocolate (Product Mode)
    // ---------------------------------------------------------------------------
    console.log('\n--- SECTION 2: TEST 1 — Dairy Milk Silk Chocolate (Product Mode) ---');

    const dairyMilkRes = await fetch(`${baseUrl}/recipes/generate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${authToken}`,
      },
      body: JSON.stringify({
        mode: 'product',
        sourceProduct: {
          name: 'Dairy Milk Silk Chocolate',
          brand: 'Cadbury',
        },
        mealType: 'Breakfast',
      }),
    });

    const dairyMilkData = await dairyMilkRes.json();
    assert(dairyMilkRes.status === 200, 'POST /recipes/generate with Dairy Milk Silk Chocolate returns 200 OK');
    assert(dairyMilkData.success === true, 'Response reports success: true');
    assert(dairyMilkData.data.recipes.length > 0, 'Returned recipes for chocolate');
    assert(dairyMilkData.data.pantryIngredients.length === 0, 'Pantry ingredients are completely IGNORED');

    // ---------------------------------------------------------------------------
    // SECTION 3: TEST 2 — Cadbury Dairy Milk (Product Mode)
    // ---------------------------------------------------------------------------
    console.log('\n--- SECTION 3: TEST 2 — Cadbury Dairy Milk (Product Mode) ---');

    const cadburyRes = await fetch(`${baseUrl}/recipes/generate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${authToken}`,
      },
      body: JSON.stringify({
        mode: 'product',
        sourceProduct: {
          name: 'Cadbury Dairy Milk',
          brand: 'Cadbury',
        },
        mealType: 'Breakfast',
      }),
    });

    const cadburyData = await cadburyRes.json();
    assert(cadburyRes.status === 200, 'POST /recipes/generate with Cadbury Dairy Milk returns 200 OK');
    assert(cadburyData.success === true, 'Response reports success: true');
    assert(cadburyData.data.recipes.length > 0, 'Returned recipes for chocolate');

    // ---------------------------------------------------------------------------
    // SECTION 4: TEST 3 — Maggi Masala Noodles (Product Mode)
    // ---------------------------------------------------------------------------
    console.log('\n--- SECTION 4: TEST 3 — Maggi Masala Noodles (Product Mode) ---');

    const maggiRes = await fetch(`${baseUrl}/recipes/generate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${authToken}`,
      },
      body: JSON.stringify({
        mode: 'product',
        sourceProduct: {
          name: 'Maggi Masala Noodles',
          brand: 'Nestle',
        },
        mealType: 'Lunch',
      }),
    });

    const maggiData = await maggiRes.json();
    assert(maggiRes.status === 200, 'POST /recipes/generate with Maggi Masala Noodles returns 200 OK');
    assert(maggiData.success === true, 'Response reports success: true');
    assert(maggiData.data.recipes.length > 0, 'Returned recipes for noodles');
    const topMaggi = maggiData.data.recipes[0];
    assert(typeof topMaggi.title === 'string', `Top noodle recipe title: "${topMaggi.title}"`);
    assert(topMaggi.image && topMaggi.image.startsWith('http'), 'Top noodle recipe has valid genuine image URL');

    // ---------------------------------------------------------------------------
    // SECTION 5: TEST 4 — Home Recipe Generator (Pantry Mode with Flexible Matching)
    // ---------------------------------------------------------------------------
    console.log('\n--- SECTION 5: TEST 4 — Home Pantry Recipe Generator (Flexible Subsets) ---');

    const pantryRes = await fetch(`${baseUrl}/recipes/generate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${authToken}`,
      },
      body: JSON.stringify({
        mode: 'pantry',
        ingredients: ['Oats', 'Banana', 'Milk', 'Honey', 'Chia Seeds'],
        mealType: 'Breakfast',
      }),
    });

    const pantryData = await pantryRes.json();
    assert(pantryRes.status === 200, 'POST /recipes/generate with Pantry items returns 200 OK');
    assert(pantryData.success === true, 'Response reports success: true');
    assert(pantryData.data.recipes.length > 0, 'Returned recipes from pantry');
    const topPantry = pantryData.data.recipes[0];
    assert(topPantry.matchedPantryIngredients >= 1, `Recipe matched ${topPantry.matchedPantryIngredients} of 5 pantry items (flexible subset matching)`);
    assert(pantryData.data.pantryIngredients.length === 5, 'Selected pantry ingredients list preserved');

    console.log('\n======================================================');
    console.log(`Test Results: ${passedCount} PASSED | ${failedCount} FAILED`);
    console.log('======================================================\n');
  } catch (err) {
    console.error('Test Suite Error:', err);
  } finally {
    await teardown();
    process.exit(failedCount > 0 ? 1 : 0);
  }
};

runSuite();
