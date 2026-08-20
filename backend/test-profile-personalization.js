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
const profileRoutes = require('./src/routes/profileRoutes');
const personalizationRoutes = require('./src/routes/personalizationRoutes');
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
  app.use('/api/personalization', personalizationRoutes);
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
  console.log('🧪 Starting Phase 4 Profile & Personalization Test Suite');
  console.log('======================================================\n');

  await setup();

  try {
    // -------------------------------------------------------------------------
    // Setup: Register two test users
    // -------------------------------------------------------------------------
    console.log('--- Registering Test Users (User A and User B) ---');

    // Register User A
    const resRegA = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        fullName: 'Alice Walker',
        username: 'alicewalker',
        email: 'alice@example.com',
        password: 'Password123!',
      }),
    });
    const dataRegA = await resRegA.json();
    const tokenA = dataRegA.data?.tokens?.accessToken;
    assert(resRegA.status === 201 && tokenA, 'Register User A succeeds with access token');

    // Register User B
    const resRegB = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        fullName: 'Bob Smith',
        username: 'bobsmith',
        email: 'bob@example.com',
        password: 'Password123!',
      }),
    });
    const dataRegB = await resRegB.json();
    const tokenB = dataRegB.data?.tokens?.accessToken;
    assert(resRegB.status === 201 && tokenB, 'Register User B succeeds with access token');

    // -------------------------------------------------------------------------
    // 1. Profile Retrieval (GET /api/profile)
    // -------------------------------------------------------------------------
    console.log('\n--- 1. Profile Retrieval ---');

    // Unauthenticated GET /api/profile
    const resUnauthProfile = await fetch(`${baseUrl}/profile`, {
      method: 'GET',
    });
    assert(resUnauthProfile.status === 401, 'Unauthenticated GET /api/profile rejected with 401');

    // Authenticated GET /api/profile for User A (no personalization yet)
    const resGetProfileA = await fetch(`${baseUrl}/profile`, {
      method: 'GET',
      headers: { Authorization: `Bearer ${tokenA}` },
    });
    const dataProfileA = await resGetProfileA.json();
    assert(resGetProfileA.status === 200, 'Authenticated GET /api/profile returns 200');
    assert(dataProfileA.data.user.email === 'alice@example.com', 'Returns correct user email');
    assert(dataProfileA.data.user.fullName === 'Alice Walker', 'Returns correct user full name');
    assert(dataProfileA.data.isPersonalizationComplete === false, 'isPersonalizationComplete is false initially');

    // -------------------------------------------------------------------------
    // 2. Profile Update (PUT /api/profile)
    // -------------------------------------------------------------------------
    console.log('\n--- 2. Profile Update ---');

    // Unauthenticated PUT /api/profile
    const resUnauthPut = await fetch(`${baseUrl}/profile`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ fullName: 'Hacker Name' }),
    });
    assert(resUnauthPut.status === 401, 'Unauthenticated PUT /api/profile rejected with 401');

    // Invalid update (empty/short name)
    const resInvalidPut = await fetch(`${baseUrl}/profile`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({ fullName: 'A' }),
    });
    assert(resInvalidPut.status === 400, 'PUT /api/profile with invalid name rejected with 400');

    // Valid update for User A
    const resUpdateProfileA = await fetch(`${baseUrl}/profile`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        fullName: 'Alice M. Walker',
        phone: '9876543210',
        countryCode: '+1',
        country: 'United States',
        city: 'New York',
        address: '123 5th Ave',
        occupation: 'Nutritionist',
        dietType: 'Vegan',
        height: '170',
        weight: '62',
      }),
    });
    const dataUpdateA = await resUpdateProfileA.json();
    assert(resUpdateProfileA.status === 200, 'Valid PUT /api/profile returns 200');
    assert(dataUpdateA.data.user.fullName === 'Alice M. Walker', 'User A full name updated in MongoDB');
    assert(dataUpdateA.data.user.city === 'New York', 'User A city updated in MongoDB');
    assert(dataUpdateA.data.user.dietType === 'Vegan', 'User A dietType updated in MongoDB');

    // -------------------------------------------------------------------------
    // 3. Personalization Retrieval & Creation (GET / PUT /api/personalization)
    // -------------------------------------------------------------------------
    console.log('\n--- 3. Personalization Retrieval & Saving ---');

    // Unauthenticated GET /api/personalization
    const resUnauthPers = await fetch(`${baseUrl}/personalization`, {
      method: 'GET',
    });
    assert(resUnauthPers.status === 401, 'Unauthenticated GET /api/personalization rejected with 401');

    // Authenticated GET before onboarding
    const resGetPersInitial = await fetch(`${baseUrl}/personalization`, {
      method: 'GET',
      headers: { Authorization: `Bearer ${tokenA}` },
    });
    const dataPersInitial = await resGetPersInitial.json();
    assert(resGetPersInitial.status === 200, 'GET /api/personalization returns 200');
    assert(dataPersInitial.data.personalization === null, 'Personalization is null before onboarding');

    // Save complete 7-step personalization for User A
    const resSavePersA = await fetch(`${baseUrl}/personalization`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        fullName: 'Alice M. Walker',
        age: '28',
        gender: 'Female',
        height: '170',
        weight: '62',
        goals: ['Weight Loss', 'Improve Energy'],
        activityLevel: 'Active',
        sleepHours: '7-8 hours',
        waterIntake: '8-10 glasses',
        healthConditions: ['Lactose Intolerance'],
        pregnantOrBreastfeeding: false,
        dietType: 'Vegan',
        allergies: ['Peanuts', 'Dairy'],
        dislikedFoods: ['Mushrooms'],
        nutritionFocus: ['High Protein', 'Low Sugar'],
        productAlerts: {
          'Alert me if a product contains my allergens': true,
          'Warn me about high sugar products': true,
        },
        aiFeatures: {
          'Personalized recipes': true,
          'Smart shopping suggestions': true,
        },
        isCompleted: true,
      }),
    });
    const dataSavePersA = await resSavePersA.json();
    assert(resSavePersA.status === 200, 'Save personalization returns 200');
    assert(dataSavePersA.data.isCompleted === true, 'isCompleted is true after saving');
    assert(dataSavePersA.data.personalization.dietType === 'Vegan', 'dietType saved in personalization');
    assert(dataSavePersA.data.personalization.allergies.includes('Peanuts'), 'allergies saved in personalization');

    // Verify GET /api/profile now shows isPersonalizationComplete: true
    const resCheckProfileA = await fetch(`${baseUrl}/profile`, {
      method: 'GET',
      headers: { Authorization: `Bearer ${tokenA}` },
    });
    const dataCheckProfileA = await resCheckProfileA.json();
    assert(dataCheckProfileA.data.isPersonalizationComplete === true, 'Profile now returns isPersonalizationComplete: true');

    // -------------------------------------------------------------------------
    // 4. Personalization Partial Update (PATCH /api/personalization)
    // -------------------------------------------------------------------------
    console.log('\n--- 4. Partial Personalization Update (PATCH) ---');

    const resPatchPersA = await fetch(`${baseUrl}/personalization`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        goals: ['Weight Loss', 'Muscle Gain'],
        allergies: ['Peanuts', 'Dairy', 'Shellfish'],
      }),
    });
    const dataPatchPersA = await resPatchPersA.json();
    assert(resPatchPersA.status === 200, 'PATCH /api/personalization returns 200');
    assert(dataPatchPersA.data.personalization.allergies.includes('Shellfish'), 'Shellfish added to allergies in DB');
    assert(dataPatchPersA.data.personalization.goals.includes('Muscle Gain'), 'Muscle Gain added to goals in DB');

    // -------------------------------------------------------------------------
    // 5. Cross-User Data Isolation (Security)
    // -------------------------------------------------------------------------
    console.log('\n--- 5. Cross-User Data Isolation & Security ---');

    // User B fetches their own profile
    const resGetProfileB = await fetch(`${baseUrl}/profile`, {
      method: 'GET',
      headers: { Authorization: `Bearer ${tokenB}` },
    });
    const dataProfileB = await resGetProfileB.json();
    assert(dataProfileB.data.user.email === 'bob@example.com', 'User B receives only their own profile');
    assert(dataProfileB.data.user.fullName === 'Bob Smith', 'User B cannot see User A name');
    assert(dataProfileB.data.isPersonalizationComplete === false, 'User B personalization is still false');

    // User B fetches their own personalization
    const resGetPersB = await fetch(`${baseUrl}/personalization`, {
      method: 'GET',
      headers: { Authorization: `Bearer ${tokenB}` },
    });
    const dataPersB = await resGetPersB.json();
    assert(dataPersB.data.personalization === null, 'User B cannot see User A personalization data');

    // -------------------------------------------------------------------------
    // 6. Cross-Device / Re-login Data Persistence
    // -------------------------------------------------------------------------
    console.log('\n--- 6. Cross-Device / Re-login Data Persistence ---');

    // Simulate Device B logging in as User A
    const resLoginA2 = await fetch(`${baseUrl}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'alice@example.com',
        password: 'Password123!',
        deviceInfo: 'Device B (iPad)',
      }),
    });
    const dataLoginA2 = await resLoginA2.json();
    const tokenA2 = dataLoginA2.data?.tokens?.accessToken;
    assert(resLoginA2.status === 200 && tokenA2, 'User A logs in from Device B and gets fresh access token');

    // Fetch profile with Device B token
    const resProfileDeviceB = await fetch(`${baseUrl}/profile`, {
      method: 'GET',
      headers: { Authorization: `Bearer ${tokenA2}` },
    });
    const dataProfileDeviceB = await resProfileDeviceB.json();
    assert(dataProfileDeviceB.data.user.fullName === 'Alice M. Walker', 'Device B fetches synchronized full name');
    assert(dataProfileDeviceB.data.user.city === 'New York', 'Device B fetches synchronized city');
    assert(dataProfileDeviceB.data.isPersonalizationComplete === true, 'Device B knows personalization is complete');

    // Fetch personalization with Device B token
    const resPersDeviceB = await fetch(`${baseUrl}/personalization`, {
      method: 'GET',
      headers: { Authorization: `Bearer ${tokenA2}` },
    });
    const dataPersDeviceB = await resPersDeviceB.json();
    assert(dataPersDeviceB.data.personalization.dietType === 'Vegan', 'Device B fetches synchronized dietType');
    assert(dataPersDeviceB.data.personalization.allergies.includes('Shellfish'), 'Device B fetches synchronized allergies');
    assert(dataPersDeviceB.data.personalization.goals.includes('Muscle Gain'), 'Device B fetches synchronized goals');

    console.log('\n======================================================');
    console.log(`Test Results: ${passedCount} PASSED | ${failedCount} FAILED`);
    console.log('======================================================\n');
  } finally {
    await teardown();
  }

  if (failedCount > 0) {
    process.exit(1);
  }
};

runTests();
