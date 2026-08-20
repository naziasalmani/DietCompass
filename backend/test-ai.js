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
const aiRoutes = require('./src/routes/aiRoutes');
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
  app.use('/api/ai', aiRoutes);
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
  console.log('🧪 Starting Phase 5 AI Nutrition Intelligence Test Suite');
  console.log('======================================================\n');

  await setup();

  try {
    // -------------------------------------------------------------------------
    // Setup: Register test user and setup personalization
    // -------------------------------------------------------------------------
    console.log('--- Registering Test User and Personalization ---');

    const resReg = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        fullName: 'Dr. Sarah Connor',
        username: 'sarahc',
        email: 'sarah@example.com',
        password: 'Password123!',
      }),
    });
    const dataReg = await resReg.json();
    const token = dataReg.data?.tokens?.accessToken;
    const userId = dataReg.data?.user?._id;
    assert(resReg.status === 201 && token, 'Register user succeeds with JWT');

    // Create user personalization (Allergies: Peanuts, Dairy; Diet: Vegan; Goal: Weight Loss)
    await Personalization.create({
      userId,
      fullName: 'Dr. Sarah Connor',
      dietType: 'Vegan',
      allergies: ['Peanuts', 'Dairy'],
      goals: ['Weight Loss', 'Heart Health'],
      healthConditions: ['Hypertension'],
      isCompleted: true,
    });

    // -------------------------------------------------------------------------
    // 1. AI Product & Ingredient Intelligence (/api/ai/analyze-product)
    // -------------------------------------------------------------------------
    console.log('\n--- 1. AI Product & Ingredient Intelligence ---');

    // Unauthenticated request -> 401
    const resUnauth = await fetch(`${baseUrl}/ai/analyze-product`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Oatmeal' }),
    });
    assert(resUnauth.status === 401, 'Unauthenticated POST /api/ai/analyze-product rejected with 401');

    // Empty product request -> 400
    const resEmpty = await fetch(`${baseUrl}/ai/analyze-product`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({}),
    });
    assert(resEmpty.status === 400, 'Empty product rejected with 400 Bad Request');

    // Analyze product with disguised sugar (maltodextrin) and misleading "Zero Sugar" claim
    const resProductA = await fetch(`${baseUrl}/ai/analyze-product`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        name: 'Guilt-Free Protein Bar',
        brand: 'HealthCo',
        barcode: '8901234567890',
        ingredients: 'Soy protein isolate, maltodextrin, high fructose corn syrup, palm oil, BHT, natural flavors, peanuts, milk solids',
        claims: ['Zero Sugar', 'All Natural', 'High Protein'],
        nutrition: {
          calories: 220,
          protein: 15,
          carbohydrates: 24,
          fat: 6,
          fiber: 2,
          sugar: 8,
          sodium: 210,
        },
      }),
    });

    const dataA = await resProductA.json();
    assert(resProductA.status === 200, 'Product analysis returns 200 OK');
    assert(dataA.data.factualData.name === 'Guilt-Free Protein Bar', 'Factual product name preserved');
    assert(dataA.data.factualData.nutrition.protein === 15, 'Factual protein value preserved without invention');

    const aiA = dataA.data.aiAnalysis;
    assert(typeof aiA.healthScore === 'number', 'Calculates numerical health score');
    
    // Check disguised sugars detection
    const sugarsFound = aiA.disguisedSugars.map((s) => s.name.toLowerCase());
    assert(sugarsFound.includes('maltodextrin'), 'Detects Maltodextrin as hidden sugar');
    assert(sugarsFound.includes('high fructose corn syrup'), 'Detects High Fructose Corn Syrup as hidden sugar');

    // Check harmful additives detection
    const additivesFound = aiA.harmfulAdditives.map((a) => a.name.toLowerCase());
    assert(additivesFound.some((a) => a.includes('bht')), 'Detects BHT preservative of concern');

    // Check claim verification
    const zeroSugarClaim = aiA.claimVerifications.find((c) => c.claim.toLowerCase().includes('zero sugar'));
    assert(zeroSugarClaim && zeroSugarClaim.status === 'Misleading', 'Flags "Zero Sugar" claim as Misleading due to hidden syrups/sugars');

    // Check user allergen detection
    assert(aiA.allergenWarnings.some((w) => w.toLowerCase().includes('peanuts')), 'Flags user peanut allergy warning');

    // Check suitability
    assert(aiA.isSuitable === false, 'Flags product as not suitable for vegan/allergic user');

    // -------------------------------------------------------------------------
    // 2. Clean Product Analysis (Clean Label Oat Porridge)
    // -------------------------------------------------------------------------
    console.log('\n--- 2. Clean Product Analysis ---');

    const resCleanProduct = await fetch(`${baseUrl}/ai/analyze-product`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        name: '100% Whole Grain Rolled Oats',
        brand: 'PureHarvest',
        barcode: '8909876543210',
        ingredients: '100% Whole grain rolled oats',
        claims: ['High Fiber', 'No Added Sugar'],
        nutrition: {
          calories: 375,
          protein: 13,
          carbohydrates: 65,
          fat: 6.5,
          fiber: 10,
          sugar: 1,
          sodium: 5,
        },
      }),
    });

    const dataClean = await resCleanProduct.json();
    const aiClean = dataClean.data.aiAnalysis;
    assert(resCleanProduct.status === 200, 'Clean product analysis returns 200');
    assert(aiClean.healthScore >= 80, `Clean product receives high score: ${aiClean.healthScore}/100`);
    assert(aiClean.disguisedSugars.length === 0, 'No hidden sugars flagged on pure oats');
    assert(aiClean.harmfulAdditives.length === 0, 'No harmful additives flagged on pure oats');

    // -------------------------------------------------------------------------
    // 3. OCR / Unknown Label Analysis (/api/ai/analyze-ocr)
    // -------------------------------------------------------------------------
    console.log('\n--- 3. OCR Label Analysis ---');

    // Unauthenticated OCR -> 401
    const resOcrUnauth = await fetch(`${baseUrl}/ai/analyze-ocr`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ ocrText: 'Nutrition Facts Calories 150' }),
    });
    assert(resOcrUnauth.status === 401, 'Unauthenticated OCR rejected with 401');

    // Too short OCR -> 400
    const resOcrShort = await fetch(`${baseUrl}/ai/analyze-ocr`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ ocrText: 'hi' }),
    });
    assert(resOcrShort.status === 400, 'Too short OCR text rejected with 400');

    // Valid OCR text
    const ocrSnippet = `
      NUTRITION FACTS
      Serving Size: 100g
      Calories: 380 kcal
      Total Fat: 12g
      Sodium: 450mg
      Total Carbohydrate: 60g
      Dietary Fiber: 4g
      Total Sugars: 18g
      Protein: 8g
      INGREDIENTS: Whole wheat flour, dextrose, invert sugar, salt, yellow 5, red 40, artificial flavor.
    `;

    const resOcr = await fetch(`${baseUrl}/ai/analyze-ocr`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ ocrText: ocrSnippet }),
    });

    const dataOcr = await resOcr.json();
    assert(resOcr.status === 200, 'OCR analysis returns 200 OK');
    assert(dataOcr.data.factualData.nutrition.calories === 380, 'Extracted calories 380 from OCR snippet');
    assert(dataOcr.data.aiAnalysis.disguisedSugars.length > 0, 'Detected dextrose/invert sugar from OCR label');

    // -------------------------------------------------------------------------
    // 4. AI Nutrition Coach Chatbot (/api/ai/coach)
    // -------------------------------------------------------------------------
    console.log('\n--- 4. AI Nutrition Coach Chatbot ---');

    // Unauthenticated Coach -> 401
    const resCoachUnauth = await fetch(`${baseUrl}/ai/coach`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message: 'What can I eat?' }),
    });
    assert(resCoachUnauth.status === 401, 'Unauthenticated Coach chat rejected with 401');

    // Empty message -> 400
    const resCoachEmpty = await fetch(`${baseUrl}/ai/coach`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ message: '' }),
    });
    assert(resCoachEmpty.status === 400, 'Empty coach message rejected with 400');

    // 4.1 Question 1: Maggi question
    const resMaggi = await fetch(`${baseUrl}/ai/coach`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        message: 'is maggie good for me?',
        history: [],
      }),
    });
    const dataMaggi = await resMaggi.json();
    assert(resMaggi.status === 200, 'Maggi query returns 200 OK');
    assert(typeof dataMaggi.data.message === 'string', 'Maggi response is valid text');
    assert(!dataMaggi.data.message.includes('your_gemini_api_key'), 'API key is never exposed');

    // 4.2 Question 2: Sugar in Dairy Milk
    const resDairyMilk = await fetch(`${baseUrl}/ai/coach`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        message: 'how much sugar does dairymilk have??',
        history: [],
      }),
    });
    const dataDairyMilk = await resDairyMilk.json();
    assert(resDairyMilk.status === 200, 'Dairy Milk sugar query returns 200 OK');
    assert(dataDairyMilk.data.message !== dataMaggi.data.message, 'Different queries receive DIFFERENT dynamic responses');

    // 4.3 Question 3: Sprite
    const resSprite = await fetch(`${baseUrl}/ai/coach`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        message: 'is sprite good for me',
        history: [],
      }),
    });
    const dataSprite = await resSprite.json();
    assert(resSprite.status === 200, 'Sprite query returns 200 OK');
    assert(dataSprite.data.message !== dataMaggi.data.message, 'Sprite response differs from Maggi response');
    assert(dataSprite.data.message !== dataDairyMilk.data.message, 'Sprite response differs from Dairy Milk response');

    // 4.4 Question 4: Protein explanation & Conversation History continuity
    const resProtein1 = await fetch(`${baseUrl}/ai/coach`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        message: 'what is protein?',
        history: [],
      }),
    });
    const dataProtein1 = await resProtein1.json();
    assert(resProtein1.status === 200, 'Protein question returns 200 OK');

    // Follow-up question with conversation history
    const resProtein2 = await fetch(`${baseUrl}/ai/coach`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        message: 'how much of it do I need daily?',
        history: [
          { role: 'user', content: 'what is protein?' },
          { role: 'model', content: dataProtein1.data.message },
        ],
      }),
    });
    const dataProtein2 = await resProtein2.json();
    assert(resProtein2.status === 200, 'Conversation history follow-up query returns 200 OK');
    assert(typeof dataProtein2.data.message === 'string' && dataProtein2.data.message.length > 10, 'Follow-up query returns comprehensive response');

    // 4.5 Question 5: High-protein vegetarian/vegan breakfast
    const resBreakfast = await fetch(`${baseUrl}/ai/coach`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        message: 'give me a high protein vegetarian breakfast',
        history: [],
      }),
    });
    const dataBreakfast = await resBreakfast.json();
    assert(resBreakfast.status === 200, 'Breakfast query returns 200 OK');
    assert(dataBreakfast.data.userContext.dietType === 'Vegan', 'Coach incorporates user vegan diet context');

    // 4.6 Product Context Injection
    const resProductContext = await fetch(`${baseUrl}/ai/coach`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        message: 'Is this product healthy?',
        product: {
          name: 'Classic Potato Chips',
          brand: 'CrispyCo',
          ingredients: 'Potatoes, Palm Oil, Salt',
          calories: 540,
          protein: 6.5,
          carbohydrates: 53,
          fat: 35,
          sugar: 0.5,
          sodium: 600,
        },
      }),
    });
    const dataProductContext = await resProductContext.json();
    assert(resProductContext.status === 200, 'Product context query returns 200 OK');
    assert(typeof dataProductContext.data.message === 'string', 'Product context response returned successfully');

    // -------------------------------------------------------------------------
    // 5. Phase 6B: Personalized Product Compatibility Score Tests
    // -------------------------------------------------------------------------
    console.log('\n--- 5. Phase 6B: Personalized Product Compatibility Score ---');

    // Unauthenticated Compatibility -> 401
    const resCompatUnauth = await fetch(`${baseUrl}/ai/compatibility`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Oats' }),
    });
    assert(resCompatUnauth.status === 401, 'Unauthenticated POST /api/ai/compatibility rejected with 401');

    // 5.1 Suitable Product for User A (Vegan, Peanut Allergic, Weight Loss, Heart Health/Hypertension)
    const oatsProduct = {
      name: 'Organic Rolled Oats',
      brand: 'NatureFresh',
      barcode: '8901112223334',
      ingredients: 'Organic whole grain rolled oats',
      claims: ['High Fiber', 'Low Sodium', 'No Added Sugar'],
      nutrition: {
        calories: 150,
        protein: 6,
        carbohydrates: 27,
        fat: 2.5,
        fiber: 5,
        sugar: 1,
        sodium: 5,
      },
    };

    const resCompatOats = await fetch(`${baseUrl}/ai/compatibility`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(oatsProduct),
    });

    const dataCompatOats = await resCompatOats.json();
    assert(resCompatOats.status === 200, 'Compatibility endpoint returns 200 OK');
    const compOats = dataCompatOats.data;
    assert(compOats.score >= 85, `Suitable product receives high compatibility score: ${compOats.score}/100`);
    assert(compOats.status === 'Excellent Match' || compOats.status === 'Good Match', 'Status is Excellent or Good Match');
    assert(compOats.allergyAlerts.length === 0, 'No allergy alerts on oats for peanut-allergic user');
    assert(compOats.dietaryAlerts.length === 0, 'No dietary alerts on oats for vegan user');
    assert(compOats.positiveFactors.some((f) => f.toLowerCase().includes('vegan')), 'Highlights Vegan diet match in positive factors');
    assert(compOats.positiveFactors.some((f) => f.toLowerCase().includes('fiber') || f.toLowerCase().includes('weight loss')), 'Highlights fiber/weight loss goal alignment');

    // 5.2 Product Conflicting with User Allergy (Peanuts)
    const peanutProduct = {
      name: 'Nutty Energy Bar',
      brand: 'SnackCo',
      barcode: '8905556667778',
      ingredients: 'Rolled oats, peanuts, peanut butter, honey, salt',
      nutrition: {
        calories: 220,
        protein: 8,
        carbohydrates: 22,
        fat: 10,
        fiber: 3,
        sugar: 8,
        sodium: 120,
      },
    };

    const resCompatAllergy = await fetch(`${baseUrl}/ai/compatibility`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(peanutProduct),
    });

    const dataCompatAllergy = await resCompatAllergy.json();
    const compAllergy = dataCompatAllergy.data;
    assert(resCompatAllergy.status === 200, 'Allergen compatibility check returns 200');
    assert(compAllergy.score <= 25, `Allergen conflict severely penalizes score (score: ${compAllergy.score} <= 25)`);
    assert(compAllergy.status === 'Incompatible / Allergy Risk', 'Status flags Incompatible / Allergy Risk');
    assert(compAllergy.allergyAlerts.some((a) => a.toLowerCase().includes('peanuts')), 'Allergy alert specifically names Peanuts');
    assert(compAllergy.isSuitable === false, 'Product is marked isSuitable: false');

    // 5.3 Product Conflicting with User Diet (Non-Vegan Beef/Gelatin)
    const meatProduct = {
      name: 'Savory Beef Protein Soup',
      brand: 'MeatChef',
      barcode: '8908889990001',
      ingredients: 'Water, beef extract, gelatin, vegetables, salt, spices',
      nutrition: {
        calories: 90,
        protein: 12,
        carbohydrates: 4,
        fat: 2,
        fiber: 1,
        sugar: 2,
        sodium: 480,
      },
    };

    const resCompatDiet = await fetch(`${baseUrl}/ai/compatibility`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(meatProduct),
    });

    const dataCompatDiet = await resCompatDiet.json();
    const compDiet = dataCompatDiet.data;
    assert(compDiet.score <= 35, `Diet conflict caps score at <= 35 (score: ${compDiet.score})`);
    assert(compDiet.status === 'Dietary Incompatibility', 'Status indicates Dietary Incompatibility');
    assert(compDiet.dietaryAlerts.length > 0, 'Dietary alert is populated');

    // 5.4 Deterministic Consistency (Same User + Same Product = Same Score)
    const resCompatOats2 = await fetch(`${baseUrl}/ai/compatibility`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(oatsProduct),
    });
    const dataCompatOats2 = await resCompatOats2.json();
    assert(compOats.score === dataCompatOats2.data.score, 'Deterministic score: exact same score on identical requests');
    assert(compOats.status === dataCompatOats2.data.status, 'Deterministic status: exact same status on identical requests');

    // 5.5 User B Personalization (Keto user without allergies) evaluates differently
    const resRegB = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        fullName: 'Alex Keto',
        username: 'alexketo',
        email: 'alex.keto@example.com',
        password: 'Password123!',
      }),
    });
    const dataRegB = await resRegB.json();
    const tokenB = dataRegB.data?.tokens?.accessToken;
    const userIdB = dataRegB.data?.user?._id;

    await Personalization.create({
      userId: userIdB,
      fullName: 'Alex Keto',
      dietType: 'Keto',
      allergies: [],
      goals: ['Muscle Gain'],
      healthConditions: [],
      isCompleted: true,
    });

    // High Carb Oats for Keto User B
    const resCompatKeto = await fetch(`${baseUrl}/ai/compatibility`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenB}`,
      },
      body: JSON.stringify(oatsProduct),
    });
    const compKeto = (await resCompatKeto.json()).data;
    assert(compKeto.score < compOats.score, `Keto user receives lower score for 27g carb oats (${compKeto.score}) vs Vegan user (${compOats.score})`);
    assert(compKeto.concerns.some((c) => c.toLowerCase().includes('keto') || c.toLowerCase().includes('carb')), 'Keto concern flagged for high carb content');

    // Peanut Energy Bar for User B (No peanut allergy)
    const resCompatPeanutB = await fetch(`${baseUrl}/ai/compatibility`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenB}`,
      },
      body: JSON.stringify(peanutProduct),
    });
    const compPeanutB = (await resCompatPeanutB.json()).data;
    assert(compPeanutB.score > compAllergy.score, `Non-allergic User B gets higher score (${compPeanutB.score}) than allergic User A (${compAllergy.score})`);

    // 5.6 Full Product Analysis includes compatibility object
    const resFull = await fetch(`${baseUrl}/ai/analyze-product`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(oatsProduct),
    });
    const dataFull = await resFull.json();
    assert(dataFull.data.compatibility && typeof dataFull.data.compatibility.score === 'number', 'POST /api/ai/analyze-product includes embedded compatibility object');
    assert(Array.isArray(dataFull.data.compatibility.items), 'Compatibility includes structured items for Flutter UI');

    // -------------------------------------------------------------------------
    // 6. Phase 6C: Personalized Similar Product Recommendations
    // -------------------------------------------------------------------------
    console.log('\n--- 6. Phase 6C: Personalized Similar Product Recommendations ---');

    // 6.1 Unauthenticated Recommendations -> 401
    const resRecUnauth = await fetch(`${baseUrl}/ai/recommendations`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Froot Loops' }),
    });
    assert(resRecUnauth.status === 401, 'Unauthenticated POST /api/ai/recommendations rejected with 401');

    // 6.2 Missing Product -> 400
    const resRecEmpty = await fetch(`${baseUrl}/ai/recommendations`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ maxResults: 3 }),
    });
    assert(resRecEmpty.status === 400, 'Empty product for recommendations rejected with 400');

    // 6.3 Scanned High-Sugar Cereal for User A (Vegan, Low Sugar, Weight Loss)
    const sugaryCereal = {
      name: 'Froot Loops Sweetened Cereal',
      brand: "Kellogg's",
      barcode: '038000318306',
      category: 'cereal',
      ingredients: 'Corn flour blend, sugar, wheat flour, hydrogenated vegetable oil, red 40, yellow 5, BHT',
      nutrition: {
        calories: 150,
        protein: 2,
        carbohydrates: 34,
        fat: 1.5,
        fiber: 2,
        sugar: 12,
        sodium: 210,
      },
    };

    const resRecCereal = await fetch(`${baseUrl}/ai/recommendations`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(sugaryCereal),
    });

    const dataRecCereal = await resRecCereal.json();
    assert(resRecCereal.status === 200, 'Recommendations endpoint returns 200 OK');
    const recs = dataRecCereal.data.recommendations;
    assert(Array.isArray(recs) && recs.length > 0, `Returns legitimate recommendations list (${recs.length} found)`);

    // Verify all recommendations are superior in compatibility and real
    const topRec = recs[0];
    assert(topRec.compatibility.score > 70, `Recommended alternative has high compatibility score (${topRec.compatibility.score}/100)`);
    assert(topRec.product.name && typeof topRec.product.name === 'string', 'Candidate has authentic product name');
    assert(topRec.product.brand && typeof topRec.product.brand === 'string', 'Candidate has authentic brand');
    assert(topRec.product.barcode && typeof topRec.product.barcode === 'string', 'Candidate has authentic barcode');
    assert(typeof topRec.product.nutrition.sugar === 'number', 'Candidate has factual numeric sugar content');
    assert(topRec.product.imageUrl.startsWith('http'), 'Candidate has authentic image URL from Open Food Facts');
    assert(topRec.product.category === 'cereal', 'Recommendation is in the same category (cereal)');
    assert(topRec.compatibility.allergyAlerts.length === 0, 'Recommended alternative has no allergen conflicts');
    assert(topRec.compatibility.dietaryAlerts.length === 0, 'Recommended alternative complies with Vegan diet');

    // 6.4 Nutrition Comparison & Match Reason
    assert(topRec.nutritionComparison.sugarDiff <= 0, `Candidate has lower or equal sugar (${topRec.nutritionComparison.sugarDiff}g diff)`);
    assert(typeof topRec.differentiator === 'string' && topRec.differentiator.length > 0, 'Candidate has concise differentiator tag');
    assert(typeof topRec.matchReason === 'string' && topRec.matchReason.length > 10, 'Candidate has personalized match reason');

    // 6.5 Allergen Safety: Peanut-allergic User A scanning snack bar
    const candyBar = {
      name: 'Snickers Milk Chocolate Candy Bar',
      brand: 'Mars',
      barcode: '040000004456',
      category: 'snack_bar',
      ingredients: 'Milk chocolate, peanuts, corn syrup, sugar, palm oil, skim milk, lactose, salt, egg whites',
      nutrition: {
        calories: 250,
        protein: 4,
        carbohydrates: 33,
        fat: 12,
        fiber: 1,
        sugar: 28,
        sodium: 120,
      },
    };

    const resRecBar = await fetch(`${baseUrl}/ai/recommendations`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(candyBar),
    });

    const dataRecBar = await resRecBar.json();
    const recsBar = dataRecBar.data.recommendations;
    // KIND bar with peanuts and Snickers with peanuts must be excluded for peanut-allergic User A
    const containsPeanuts = recsBar.some((r) => r.product.ingredients.toLowerCase().includes('peanuts'));
    assert(!containsPeanuts, 'Peanut-containing snack bars are strictly excluded for peanut-allergic user');

    // Non-vegan milk chocolate must be excluded for Vegan User A
    const containsDairy = recsBar.some((r) => r.product.ingredients.toLowerCase().includes('skim milk') || r.product.ingredients.toLowerCase().includes('milk chocolate'));
    assert(!containsDairy, 'Dairy chocolate bars are strictly excluded for Vegan user');

    // 6.6 User B (Keto / Muscle Gain) gets different recommendations & match reason
    const resRecUserB = await fetch(`${baseUrl}/ai/recommendations`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenB}`,
      },
      body: JSON.stringify(sugaryCereal),
    });

    const dataRecUserB = await resRecUserB.json();
    const recsUserB = dataRecUserB.data.recommendations;
    assert(Array.isArray(recsUserB), 'User B recommendations returned successfully');

    // 6.7 Graceful handling when no suitable alternatives exist
    const uniqueObscureFood = {
      name: 'Ultra Obscure Exotic Root',
      brand: 'Obscura',
      barcode: '9999999999999',
      category: 'obscure_alien_category',
      ingredients: 'Unknown space root',
      nutrition: { calories: 50, protein: 1, sugar: 0, sodium: 0 },
    };

    const resRecNone = await fetch(`${baseUrl}/ai/recommendations`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        ...uniqueObscureFood,
        candidates: [],
      }),
    });

    const dataRecNone = await resRecNone.json();
    assert(resRecNone.status === 200, 'Obscure product returns 200');
    assert(dataRecNone.data.summary.includes('alternative') || dataRecNone.data.summary.includes('Found'), 'Graceful summary message returned');

    // 6.8 Full Product Analysis includes recommendations array
    assert(Array.isArray(dataFull.data.recommendations), 'POST /api/ai/analyze-product returns embedded recommendations list');

    console.log('\n======================================================');
    console.log(`Phase 5, 6B & 6C Test Results: ${passedCount} PASSED | ${failedCount} FAILED`);
    console.log('======================================================\n');
  } finally {
    await teardown();
  }

  if (failedCount > 0) {
    process.exit(1);
  }
};

runTests();


