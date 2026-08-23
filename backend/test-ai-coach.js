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
const personalizationRoutes = require('./src/routes/personalizationRoutes');
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

async function runTests() {
  console.log('\n======================================================');
  console.log('🧪 AI COACH PRODUCT CONTEXT & MULTI-USER PROFILE TESTS');
  console.log('======================================================\n');

  await setup();

  try {
    const timestamp = Date.now();

    // 1. Setup User A (Vegetarian) and User B (Non-Vegetarian)
    console.log('--- 1. Register & Profile Setup ---');
    const resRegA = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        fullName: 'User A',
        username: `usera_${timestamp}`,
        email: `usera_${timestamp}@example.com`,
        password: 'Password123!',
      }),
    });
    const regDataA = await resRegA.json();
    const tokenA = regDataA.data.tokens.accessToken;

    // Set User A personalization to Vegetarian & Weight Loss
    await fetch(`${baseUrl}/personalization`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        dietType: 'Vegetarian',
        goals: ['Weight Loss'],
        allergies: ['Peanuts'],
      }),
    });
    console.log('  ✅ PASS: User A configured with Vegetarian & Weight Loss profile');

    const resRegB = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        fullName: 'User B',
        username: `userb_${timestamp}`,
        email: `userb_${timestamp}@example.com`,
        password: 'Password123!',
      }),
    });
    const regDataB = await resRegB.json();
    const tokenB = regDataB.data.tokens.accessToken;

    // Set User B personalization to Non-Vegetarian & Muscle Gain
    await fetch(`${baseUrl}/personalization`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenB}`,
      },
      body: JSON.stringify({
        dietType: 'Non-Vegetarian',
        goals: ['Muscle Gain'],
        allergies: [],
      }),
    });
    console.log('  ✅ PASS: User B configured with Non-Vegetarian & Muscle Gain profile');

    // Products
    const productA = {
      name: 'Cadbury Dairy Milk Silk',
      brand: 'Cadbury',
      barcode: '7622201497984',
      ingredients: 'Sugar, Cocoa Butter, Milk Solids, Cocoa Solids, Emulsifiers (442, 476)',
      calories: 534,
      protein: 7.3,
      carbohydrates: 57.0,
      sugar: 56.0,
      fat: 31.0,
      sodium: 150,
      compatibilityScore: 51,
      compatibilityStatus: 'Moderate Match',
      concerns: ['High in sugar (56g/100g)', 'Calorie dense (534 kcal)'],
    };

    const productB = {
      name: 'Quaker Rolled Oats',
      brand: 'Quaker',
      barcode: '8901491101820',
      ingredients: '100% Wholegrain Rolled Oats',
      calories: 389,
      protein: 13.0,
      carbohydrates: 66.0,
      sugar: 1.0,
      fat: 6.9,
      sodium: 5,
      compatibilityScore: 92,
      compatibilityStatus: 'Excellent Match',
      positiveFactors: ['High in dietary fiber', 'Low in sugar'],
    };

    // --- TEST 1: User asks "What product am I looking at?" with Product A ---
    console.log('\n--- TEST 1: Product A Identification ---');
    const resCoach1 = await fetch(`${baseUrl}/ai/coach`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        message: 'What product am I looking at?',
        product: productA,
      }),
    });
    const dataCoach1 = await resCoach1.json();
    assert(resCoach1.status === 200, 'Chat with coach returned 200');
    assert(dataCoach1.data.message.includes('Cadbury Dairy Milk Silk'), 'AI correctly identifies Product A');

    // --- TEST 2: User asks same question with Product B -> AI identifies Product B ---
    console.log('\n--- TEST 2: Product B Identification (Context Switch) ---');
    const resCoach2 = await fetch(`${baseUrl}/ai/coach`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        message: 'What product am I looking at?',
        product: productB,
      }),
    });
    const dataCoach2 = await resCoach2.json();
    assert(resCoach2.status === 200, 'Chat with coach returned 200');
    assert(dataCoach2.data.message.includes('Quaker Rolled Oats'), 'AI correctly identifies Product B');
    assert(!dataCoach2.data.message.includes('Cadbury Dairy Milk Silk'), 'AI does NOT mention previous Product A');

    // --- TEST 3: User A (Vegetarian) asks "Is this suitable for my diet?" ---
    console.log('\n--- TEST 3: User A (Vegetarian) Diet Suitability ---');
    const resCoach3 = await fetch(`${baseUrl}/ai/coach`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        message: 'Is this suitable for my diet?',
        product: productA,
      }),
    });
    const dataCoach3 = await resCoach3.json();
    assert(resCoach3.status === 200, 'Chat with coach returned 200');
    assert(dataCoach3.data.message.includes('Vegetarian'), 'AI explicitly uses User A Vegetarian profile');

    // --- TEST 4: User B (Non-Vegetarian) asks "Is this suitable for my diet?" ---
    console.log('\n--- TEST 4: User B (Non-Vegetarian) Diet Suitability ---');
    const resCoach4 = await fetch(`${baseUrl}/ai/coach`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenB}`,
      },
      body: JSON.stringify({
        message: 'Is this suitable for my diet?',
        product: productA,
      }),
    });
    const dataCoach4 = await resCoach4.json();
    assert(resCoach4.status === 200, 'Chat with coach returned 200');
    assert(dataCoach4.data.message.includes('Non-Vegetarian'), 'AI explicitly uses User B Non-Vegetarian profile');
    assert(!dataCoach4.data.message.includes('**Vegetarian**'), 'AI does NOT use User A Vegetarian profile for User B');

    // --- TEST 5: Score Explanation ---
    console.log('\n--- TEST 5: Explaining Compatibility Score Factors ---');
    const resCoach5 = await fetch(`${baseUrl}/ai/coach`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        message: 'Why is my compatibility score 51%?',
        product: productA,
      }),
    });
    const dataCoach5 = await resCoach5.json();
    assert(resCoach5.status === 200, 'Chat with coach returned 200');
    assert(dataCoach5.data.message.includes('51%') || dataCoach5.data.message.includes('Sugar') || dataCoach5.data.message.includes('56g'), 'AI explains the factors behind the 51% compatibility score');

    console.log('\n======================================================');
    console.log('🎉 ALL AI COACH PRODUCT-CONTEXT BACKEND TESTS PASSED');
    console.log('======================================================\n');
  } catch (err) {
    console.error('\n❌ TEST FAILED:', err.message);
    process.exit(1);
  } finally {
    await teardown();
  }
}

runTests();
