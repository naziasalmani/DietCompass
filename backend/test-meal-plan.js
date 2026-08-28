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
const recipeRoutes = require('./src/routes/recipeRoutes');
const mealPlanRoutes = require('./src/routes/mealPlanRoutes');
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
  app.use('/api/meal-plans', mealPlanRoutes);
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
  console.log('🧪 AI MEAL PLANNER BACKEND SUITE');
  console.log('======================================================\n');

  await setup();

  try {
    const timestamp = Date.now();
    const userEmail = `planner_user_${timestamp}@example.com`;
    const password = 'Password123!';

    // --- 1. Auth Guard ---
    console.log('--- 1. Authentication Guards ---');
    const unauthRes = await fetch(`${baseUrl}/meal-plans/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ durationDays: 7 }),
    });
    assert(unauthRes.status === 401, 'Unauthenticated POST /meal-plans/generate rejected with 401');

    // --- 2. Register & Auth ---
    console.log('\n--- 2. Register & Setup User ---');
    const regRes = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        fullName: 'Chef Gourmet',
        username: `chefg_${timestamp}`,
        email: userEmail,
        password,
      }),
    });
    const regData = await regRes.json();
    assert(regRes.status === 201, 'User registered successfully');
    const token = regData.data.tokens.accessToken;

    // Set personalization preferences
    await fetch(`${baseUrl}/personalization`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        goals: ['Weight Loss'],
        dietType: 'Vegetarian',
        allergies: ['Peanut'],
      }),
    });

    // --- 3. 1-Day Meal Plan Generation ---
    console.log('\n--- 3. 1-Day Plan Generation ---');
    const res1Day = await fetch(`${baseUrl}/meal-plans/generate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        durationDays: 1,
        goal: 'Weight Loss',
        calories: 1800,
        diet: 'Vegetarian',
      }),
    });
    const data1Day = await res1Day.json();
    assert(res1Day.status === 200, 'POST /meal-plans/generate (1 Day) returned 200');
    assert(data1Day.success === true, 'Response reports success: true');
    assert(data1Day.data.durationDays === 1, 'durationDays is exactly 1');
    assert(data1Day.data.days.length === 1, 'Generates exactly 1 day');
    assert(data1Day.data.days[0].meals.length >= 3, 'Day 1 contains requested meals');
    assert(typeof data1Day.data.summary === 'string' && data1Day.data.summary.includes('1-day'), 'Summary reflects 1-day duration');

    // --- 4. 3-Day Meal Plan Generation ---
    console.log('\n--- 4. 3-Day Plan Generation ---');
    const res3Day = await fetch(`${baseUrl}/meal-plans/generate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        durationDays: 3,
        goal: 'Muscle Gain',
        calories: 2200,
        diet: 'Vegetarian',
      }),
    });
    const data3Day = await res3Day.json();
    assert(res3Day.status === 200, 'POST /meal-plans/generate (3 Days) returned 200');
    assert(data3Day.data.durationDays === 3, 'durationDays is exactly 3');
    assert(data3Day.data.days.length === 3, 'Generates exactly 3 days');
    assert(data3Day.data.goal === 'Muscle Gain', 'Goal matches Muscle Gain');

    // --- 5. 7-Day Meal Plan Generation & Variety ---
    console.log('\n--- 5. 7-Day Plan Generation & Meal Variety ---');
    const res7Day = await fetch(`${baseUrl}/meal-plans/generate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        durationDays: 7,
        goal: 'Weight Loss',
        calories: 1800,
        diet: 'Vegetarian',
        usePantry: true,
        pantryIngredients: ['rice', 'noodle', 'chilli'],
      }),
    });
    const data7Day = await res7Day.json();
    assert(res7Day.status === 200, 'POST /meal-plans/generate (7 Days) returned 200');
    assert(data7Day.data.durationDays === 7, 'durationDays is exactly 7');
    assert(data7Day.data.days.length === 7, 'Generates exactly 7 days');

    const mealTitles = new Set();
    data7Day.data.days.forEach((d) => {
      d.meals.forEach((m) => {
        mealTitles.add(m.title);
        // Verify image integrity (not blank)
        assert(typeof m.image === 'string' && m.image.length > 0, `Meal "${m.title}" has valid image URL`);
        // Verify no meat/fish in Vegetarian
        const lower = m.title.toLowerCase();
        assert(!lower.includes('chicken') && !lower.includes('beef') && !lower.includes('pork') && !lower.includes('fish'), `Vegetarian meal "${m.title}" contains no meat`);
      });
    });
    assert(mealTitles.size >= 4, `7-day plan contains variety (${mealTitles.size} unique meals across 7 days)`);

    // --- 6. 30-Day Plan Generation ---
    console.log('\n--- 6. 30-Day Plan Generation ---');
    const res30Day = await fetch(`${baseUrl}/meal-plans/generate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        durationDays: 30,
        goal: 'Maintenance',
        calories: 2000,
        diet: 'Vegetarian',
      }),
    });
    const data30Day = await res30Day.json();
    assert(res30Day.status === 200, 'POST /meal-plans/generate (30 Days) returned 200');
    assert(data30Day.data.durationDays === 30, 'durationDays is exactly 30');
    assert(data30Day.data.days.length === 30, 'Generates exactly 30 days');

    // --- 7. Strict Allergy Rejection ---
    console.log('\n--- 7. Strict Allergy Rejection ---');
    const resAllergy = await fetch(`${baseUrl}/meal-plans/generate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        durationDays: 3,
        diet: 'Vegetarian',
        allergies: ['Peanut', 'Dairy'],
      }),
    });
    const dataAllergy = await resAllergy.json();
    assert(resAllergy.status === 200, 'Allergy-restricted plan generated successfully');
    dataAllergy.data.days.forEach((d) => {
      d.meals.forEach((m) => {
        const fullText = `${m.title} ${m.ingredients.join(' ')}`.toLowerCase();
        assert(!fullText.includes('peanut'), `Allergic meal excludes peanuts: "${m.title}"`);
      });
    });

    // --- 8. Non-Vegetarian Plan ---
    console.log('\n--- 8. Non-Vegetarian Plan ---');
    const resNonVeg = await fetch(`${baseUrl}/meal-plans/generate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        durationDays: 3,
        diet: 'Non-Vegetarian',
        calories: 2000,
      }),
    });
    const dataNonVeg = await resNonVeg.json();
    assert(resNonVeg.status === 200, 'Non-Vegetarian plan generated');
    assert(dataNonVeg.data.diet === 'Non-Vegetarian', 'Diet recorded as Non-Vegetarian');

    console.log('\n======================================================');
    console.log('🎉 ALL MEAL PLANNER BACKEND TESTS PASSED');
    console.log('======================================================\n');
  } catch (error) {
    console.error('Test execution error:', error);
    process.exit(1);
  } finally {
    await teardown();
  }
}

runTests();
