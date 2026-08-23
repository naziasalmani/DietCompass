const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');

dotenv.config();

process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test_super_secret_jwt_key_diet_compass_2026';
process.env.JWT_ACCESS_EXPIRES_IN = '15m';

const authRoutes = require('./src/routes/authRoutes');
const profileRoutes = require('./src/routes/profileRoutes');
const personalizationRoutes = require('./src/routes/personalizationRoutes');
const recipeRoutes = require('./src/routes/recipeRoutes');
const aiRoutes = require('./src/routes/aiRoutes');
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
  app.use('/api/personalization', personalizationRoutes);
  app.use('/api/recipes', recipeRoutes);
  app.use('/api/ai', aiRoutes);
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

async function runMultiUserTest() {
  console.log('\n======================================================');
  console.log('🧪 MULTI-USER PROFILE SYNCHRONIZATION TEST SUITE');
  console.log('======================================================\n');

  await setup();

  try {
    const timestamp = Date.now();
    const userAEmail = `usera_${timestamp}@test.com`;
    const userBEmail = `userb_${timestamp}@test.com`;

    // -------------------------------------------------------------------------
    // STEP 1: Register User A (Vegetarian, Weight Loss, Allergy: None)
    // -------------------------------------------------------------------------
    console.log('--- STEP 1: Register and Setup User A ---');
    const resRegA = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        fullName: 'User A',
        username: `usera_${timestamp}`,
        email: userAEmail,
        password: 'Password123!',
      }),
    });
    const dataRegA = await resRegA.json();
    assert(resRegA.status === 201, 'User A registered successfully');
    const tokenA = dataRegA.data.tokens.accessToken;
    const userAId = dataRegA.data.user.id || dataRegA.data.user._id;

    // Save User A Personalization
    const resPersA = await fetch(`${baseUrl}/personalization`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        dietType: 'Vegetarian',
        goals: ['Weight Loss'],
        allergies: [],
        isCompleted: true,
      }),
    });
    const dataPersA = await resPersA.json();
    assert(resPersA.status === 200, 'User A personalization saved as Vegetarian / Weight Loss');
    assert(dataPersA.data.personalization.dietType === 'Vegetarian', 'User A diet is Vegetarian');

    // -------------------------------------------------------------------------
    // STEP 2: User A Recipe Generation & Verification
    // -------------------------------------------------------------------------
    console.log('\n--- STEP 2: User A Recipe Generation ---');
    const resRecA = await fetch(`${baseUrl}/recipes/generate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        mode: 'pantry',
        ingredients: ['oats', 'banana', 'milk'],
      }),
    });
    const dataRecA = await resRecA.json();
    assert(resRecA.status === 200, 'User A recipe generation succeeds');
    assert(Array.isArray(dataRecA.data.recipes), 'User A receives recipes array');

    // -------------------------------------------------------------------------
    // STEP 3: Register User B (Non-Vegetarian, Maintain Weight, Allergy: Peanut)
    // -------------------------------------------------------------------------
    console.log('\n--- STEP 3: Register and Setup User B ---');
    const resRegB = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        fullName: 'User B',
        username: `userb_${timestamp}`,
        email: userBEmail,
        password: 'Password123!',
      }),
    });
    const dataRegB = await resRegB.json();
    assert(resRegB.status === 201, 'User B registered successfully');
    const tokenB = dataRegB.data.tokens.accessToken;
    const userBId = dataRegB.data.user.id || dataRegB.data.user._id;

    assert(Boolean(userAId) && Boolean(userBId) && String(userAId) !== String(userBId), 'User A and User B have distinct JWT user IDs');

    // Save User B Personalization
    const resPersB = await fetch(`${baseUrl}/personalization`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenB}`,
      },
      body: JSON.stringify({
        dietType: 'Non-Vegetarian',
        goals: ['Maintain Weight'],
        allergies: ['Peanut'],
        isCompleted: true,
      }),
    });
    const dataPersB = await resPersB.json();
    assert(resPersB.status === 200, 'User B personalization saved as Non-Vegetarian / Maintain Weight / Peanut allergy');
    assert(dataPersB.data.personalization.dietType === 'Non-Vegetarian', 'User B diet is Non-Vegetarian');
    assert(dataPersB.data.personalization.allergies.includes('Peanut'), 'User B has Peanut allergy');

    // -------------------------------------------------------------------------
    // STEP 4: Verify User B Profile Isolation from User A
    // -------------------------------------------------------------------------
    console.log('\n--- STEP 4: Verify User B Data Independence ---');
    const resMeB = await fetch(`${baseUrl}/profile`, {
      headers: { Authorization: `Bearer ${tokenB}` },
    });
    const dataMeB = await resMeB.json();
    assert(dataMeB.data.user.dietType === 'Non-Vegetarian', 'User B profile returns Non-Vegetarian');
    assert(dataMeB.data.user.fullName === 'User B', 'User B profile returns User B');

    // -------------------------------------------------------------------------
    // STEP 5: User B Product Analysis / Compatibility with Peanut & Non-Vegetarian
    // -------------------------------------------------------------------------
    console.log('\n--- STEP 5: User B Compatibility & Safety Check ---');
    const resAiB = await fetch(`${baseUrl}/ai/analyze-product`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenB}`,
      },
      body: JSON.stringify({
        name: 'Peanut Butter Granola Bar',
        brand: 'Nature Crunch',
        ingredients: 'Whole grain oats, peanuts, peanut oil, sugar, honey, salt',
        claims: ['High Protein'],
      }),
    });
    const dataAiB = await resAiB.json();
    assert(resAiB.status === 200, 'Product analysis returns 200 for User B');
    assert(dataAiB.data.compatibility.isSuitable === false, 'Product containing peanuts is flagged as NOT suitable for User B');
    assert(dataAiB.data.compatibility.allergyAlerts.some(a => a.toLowerCase().includes('peanut')), 'Peanut allergy alert present in User B analysis');

    // -------------------------------------------------------------------------
    // STEP 6: User B Recipe Generation with Chicken (Should SUCCEED because Non-Vegetarian)
    // -------------------------------------------------------------------------
    console.log('\n--- STEP 6: User B Recipe Generation (Non-Vegetarian) ---');
    const resRecB = await fetch(`${baseUrl}/recipes/generate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenB}`,
      },
      body: JSON.stringify({
        mode: 'pantry',
        ingredients: ['chicken', 'rice', 'garlic'],
      }),
    });
    const dataRecB = await resRecB.json();
    assert(resRecB.status === 200, 'User B recipe generation for chicken succeeds without vegetarian rejection');
    assert(Array.isArray(dataRecB.data.recipes), 'User B receives recipes for Non-Vegetarian search');

    // -------------------------------------------------------------------------
    // STEP 7: User B Updates Diet to Vegetarian
    // -------------------------------------------------------------------------
    console.log('\n--- STEP 7: User B Changes Diet: Non-Vegetarian -> Vegetarian ---');
    const resUpdateB = await fetch(`${baseUrl}/personalization`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenB}`,
      },
      body: JSON.stringify({
        dietType: 'Vegetarian',
      }),
    });
    const dataUpdateB = await resUpdateB.json();
    assert(resUpdateB.status === 200, 'User B diet updated to Vegetarian');
    assert(dataUpdateB.data.personalization.dietType === 'Vegetarian', 'User B diet confirmed Vegetarian');

    // -------------------------------------------------------------------------
    // STEP 8: User B Retries Recipe (Should Comply with Vegetarian Diet)
    // -------------------------------------------------------------------------
    console.log('\n--- STEP 8: User B Recipe Generation Post-Diet Update ---');
    const resRecB2 = await fetch(`${baseUrl}/recipes/generate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenB}`,
      },
      body: JSON.stringify({
        mode: 'pantry',
        ingredients: ['rice', 'garlic', 'tomato'],
      }),
    });
    const dataRecB2 = await resRecB2.json();
    assert(resRecB2.status === 200, 'User B vegetarian recipe generation succeeds');
    assert(dataRecB2.data.recipes.every(r => !r.title.toLowerCase().includes('beef') && !r.title.toLowerCase().includes('pork')), 'All returned recipes comply with updated Vegetarian diet');

    console.log('\n======================================================');
    console.log('🎉 ALL MULTI-USER SYNCHRONIZATION TESTS PASSED');
    console.log('======================================================\n');
  } catch (err) {
    console.error('Test execution failed:', err);
    process.exit(1);
  } finally {
    await teardown();
  }
}

runMultiUserTest();
