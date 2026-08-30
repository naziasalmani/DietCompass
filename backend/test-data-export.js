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
const ScanHistory = require('./src/models/ScanHistory');
const RecipeHistory = require('./src/models/RecipeHistory');
const authRoutes = require('./src/routes/authRoutes');
const profileRoutes = require('./src/routes/profileRoutes');
const { exportUserData } = require('./src/controllers/profileController');
const { protect } = require('./src/middleware/auth');
const errorHandler = require('./src/middleware/errorHandler');

let mongoServer;
let app;
let server;
let baseUrl;

const setup = async () => {
  mongoServer = await MongoMemoryServer.create();
  const uri = mongoServer.getUri();
  await mongoose.connect(uri);

  app = express();
  app.use(cors());
  app.use(express.json());
  app.use('/api/auth', authRoutes);
  app.use('/api/profile', profileRoutes);
  app.get('/api/data-export', protect, exportUserData);
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

let passedCount = 0;
let failedCount = 0;

const assert = (condition, testName, extra = '') => {
  if (condition) {
    console.log(`  ✅ PASS: ${testName}`);
    passedCount++;
  } else {
    console.error(`  ❌ FAIL: ${testName} ${extra}`);
    failedCount++;
  }
};

const runTests = async () => {
  console.log('\n======================================================');
  console.log(' DietCompass — Data Export Endpoint & Security Tests');
  console.log('======================================================\n');

  try {
    await setup();

    // 1. Register User A
    const regResA = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        fullName: 'Nazia User A',
        username: 'nazia_a',
        email: 'nazia_a@example.com',
        password: 'Password123!',
      }),
    });
    const regDataA = await regResA.json();
    const tokenA = regDataA.data.tokens.accessToken;
    const userIdA = regDataA.data.user.id || regDataA.data.user._id;

    // 2. Register User B
    const regResB = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        fullName: 'Alex User B',
        username: 'alex_b',
        email: 'alex_b@example.com',
        password: 'Password123!',
      }),
    });
    const regDataB = await regResB.json();
    const tokenB = regDataB.data.tokens.accessToken;
    const userIdB = regDataB.data.user.id || regDataB.data.user._id;

    // Seed Personalization for User A
    await Personalization.create({
      userId: userIdA,
      fullName: 'Nazia User A',
      goals: ['Weight Loss', 'Better Digestion'],
      dietType: 'Vegetarian',
      allergies: ['Peanuts', 'Shellfish'],
      height: '165',
      weight: '58',
      isCompleted: true,
      completedAt: new Date(),
    });

    // Seed Scan History for User A
    await ScanHistory.create({
      userId: userIdA,
      barcode: '8901234567890',
      productName: 'Organic Almond Milk',
      brand: 'Silk',
      score: 92,
      allergens: ['Tree nuts'],
      nutrients: { calories: 60, protein: 2, carbohydrates: 3, fat: 3 },
    });

    // Seed Scan History for User B
    await ScanHistory.create({
      userId: userIdB,
      barcode: '8909876543210',
      productName: 'Whole Wheat Bread',
      brand: 'Modern',
      score: 84,
      allergens: ['Gluten'],
      nutrients: { calories: 120, protein: 4, carbohydrates: 22, fat: 1 },
    });

    // Seed Recipe History for User A (1 bookmarked, 1 regular)
    await RecipeHistory.create({
      userId: userIdA,
      recipeId: 'rec_a1',
      title: 'Spinach Chickpea Curry',
      ingredients: ['Spinach', 'Chickpeas', 'Tomatoes'],
      instructions: ['Sauté spices', 'Add chickpeas', 'Simmer'],
      isBookmarked: true,
      isViewed: true,
    });
    await RecipeHistory.create({
      userId: userIdA,
      recipeId: 'rec_a2',
      title: 'Berry Smoothie Bowl',
      ingredients: ['Berries', 'Banana', 'Oats'],
      instructions: ['Blend ingredients', 'Serve cold'],
      isBookmarked: false,
      isViewed: true,
    });

    // Seed Recipe History for User B
    await RecipeHistory.create({
      userId: userIdB,
      recipeId: 'rec_b1',
      title: 'Grilled Salmon with Asparagus',
      ingredients: ['Salmon', 'Asparagus'],
      instructions: ['Grill salmon'],
      isBookmarked: true,
      isViewed: true,
    });

    // TEST 1: Unauthenticated request should fail with 401
    const unauthRes = await fetch(`${baseUrl}/profile/export`);
    assert(unauthRes.status === 401, '1. Unauthenticated GET /profile/export returns 401');

    // TEST 2: Authenticated request for User A via /profile/export
    const authResA = await fetch(`${baseUrl}/profile/export`, {
      headers: { Authorization: `Bearer ${tokenA}` },
    });
    assert(authResA.status === 200, '2. Authenticated GET /profile/export returns 200');
    const dataA = (await authResA.json()).data;

    assert(dataA.user.email === 'nazia_a@example.com', '3. Exported user belongs strictly to User A');
    assert(dataA.user.password === undefined, '4. Password hash is never exposed in exported data');
    assert(dataA.user.tokens === undefined, '5. Tokens are never exposed in exported data');
    assert(dataA.personalization.dietType === 'Vegetarian', '6. User A personalization correctly included');
    assert(dataA.scanHistory.length === 1 && dataA.scanHistory[0].productName === 'Organic Almond Milk', '7. User A scan history isolated from User B');
    assert(dataA.recipeHistory.length === 2, '8. User A recipe history includes all 2 recipes');
    assert(dataA.savedRecipes.length === 1 && dataA.savedRecipes[0].recipeId === 'rec_a1', '9. User A saved recipes filtered to bookmarked items');

    // TEST 3: Authenticated request for User B via /data-export
    const authResB = await fetch(`${baseUrl}/data-export`, {
      headers: { Authorization: `Bearer ${tokenB}` },
    });
    assert(authResB.status === 200, '10. GET /data-export returns 200');
    const dataB = (await authResB.json()).data;
    assert(dataB.user.email === 'alex_b@example.com', '11. User B receives ONLY User B data');
    assert(dataB.scanHistory.length === 1 && dataB.scanHistory[0].productName === 'Whole Wheat Bread', '12. User B scan history isolated from User A');
    assert(dataB.savedRecipes.length === 1 && dataB.savedRecipes[0].recipeId === 'rec_b1', '13. User B saved recipes isolated from User A');

  } catch (err) {
    console.error('Test error:', err);
    failedCount++;
  } finally {
    await teardown();
  }

  console.log('\n======================================================');
  console.log(` Results: ${passedCount} passed, ${failedCount} failed`);
  console.log('======================================================\n');
  process.exit(failedCount > 0 ? 1 : 0);
};

runTests();
