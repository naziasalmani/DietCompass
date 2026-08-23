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
const scanHistoryRoutes = require('./src/routes/scanHistoryRoutes');
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
  app.use('/api/scan-history', scanHistoryRoutes);
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

async function runScanHistoryTests() {
  console.log('\n======================================================');
  console.log('🧪 SCAN HISTORY PERSISTENCE & MULTI-USER TEST SUITE');
  console.log('======================================================\n');

  await setup();

  try {
    const timestamp = Date.now();

    // -------------------------------------------------------------------------
    // 1. Authentication Guards
    // -------------------------------------------------------------------------
    console.log('--- 1. Authentication Guards ---');
    const resUnauthGet = await fetch(`${baseUrl}/scan-history`);
    assert(resUnauthGet.status === 401, 'Unauthenticated GET /api/scan-history rejected with 401');

    const resUnauthPost = await fetch(`${baseUrl}/scan-history`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ productName: 'Oreo' }),
    });
    assert(resUnauthPost.status === 401, 'Unauthenticated POST /api/scan-history rejected with 401');

    // -------------------------------------------------------------------------
    // 2. Register Test User A & User B
    // -------------------------------------------------------------------------
    console.log('\n--- 2. Register Users ---');
    const resRegA = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        fullName: 'User A',
        username: `scana_${timestamp}`,
        email: `scana_${timestamp}@test.com`,
        password: 'Password123!',
      }),
    });
    const dataRegA = await resRegA.json();
    const tokenA = dataRegA.data.tokens.accessToken;
    assert(resRegA.status === 201, 'User A registered successfully');

    const resRegB = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        fullName: 'User B',
        username: `scanb_${timestamp}`,
        email: `scanb_${timestamp}@test.com`,
        password: 'Password123!',
      }),
    });
    const dataRegB = await resRegB.json();
    const tokenB = dataRegB.data.tokens.accessToken;
    assert(resRegB.status === 201, 'User B registered successfully');

    // -------------------------------------------------------------------------
    // 3. User A: Initial Empty Scan History
    // -------------------------------------------------------------------------
    console.log('\n--- 3. User A Initial State ---');
    const resEmptyA = await fetch(`${baseUrl}/scan-history`, {
      headers: { Authorization: `Bearer ${tokenA}` },
    });
    const dataEmptyA = await resEmptyA.json();
    assert(resEmptyA.status === 200, 'User A initial scan history returns 200');
    assert(Array.isArray(dataEmptyA.data.scans) && dataEmptyA.data.scans.length === 0, 'User A has 0 scans initially (no fake demo data)');
    assert(dataEmptyA.data.totalCount === 0, 'User A totalCount is 0');

    // -------------------------------------------------------------------------
    // 4. User A Scans Products (Dairy Milk, then Maggi)
    // -------------------------------------------------------------------------
    console.log('\n--- 4. User A Scans Products ---');
    const resScanA1 = await fetch(`${baseUrl}/scan-history`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        productName: 'Cadbury Dairy Milk Silk',
        brand: 'Cadbury',
        barcode: '8901233024013',
        imageUrl: 'https://images.openfoodfacts.org/dairy_milk.jpg',
        score: 65,
        ingredients: 'Sugar, Milk Solids, Cocoa Butter, Cocoa Solids, Emulsifiers',
        nutrients: { calories: 534, protein: 7.8, sugar: 56.4 },
      }),
    });
    const dataScanA1 = await resScanA1.json();
    assert(resScanA1.status === 200, 'User A saved scan 1 (Dairy Milk)');
    assert(dataScanA1.data.scan.productName === 'Cadbury Dairy Milk Silk', 'Scan 1 has correct product name');

    // Add small delay to ensure distinct timestamp
    await new Promise((r) => setTimeout(r, 50));

    const resScanA2 = await fetch(`${baseUrl}/scan-history`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        productName: 'Maggi 2-Minute Masala Noodles',
        brand: 'Nestle',
        barcode: '8901058852449',
        imageUrl: 'https://images.openfoodfacts.org/maggi.jpg',
        score: 72,
        ingredients: 'Refined wheat flour, Palm oil, Salt, Wheat gluten, Mineral',
        nutrients: { calories: 389, protein: 8.2, sodium: 860 },
      }),
    });
    const dataScanA2 = await resScanA2.json();
    assert(resScanA2.status === 200, 'User A saved scan 2 (Maggi)');

    // -------------------------------------------------------------------------
    // 5. User A Fetches History: Verify Newest-First Ordering
    // -------------------------------------------------------------------------
    console.log('\n--- 5. User A Ordering (Newest First) ---');
    const resListA = await fetch(`${baseUrl}/scan-history`, {
      headers: { Authorization: `Bearer ${tokenA}` },
    });
    const dataListA = await resListA.json();
    assert(dataListA.data.scans.length === 2, 'User A has exactly 2 scans');
    assert(dataListA.data.scans[0].productName === 'Maggi 2-Minute Masala Noodles', 'First scan is the newest (Maggi)');
    assert(dataListA.data.scans[1].productName === 'Cadbury Dairy Milk Silk', 'Second scan is older (Dairy Milk)');

    // -------------------------------------------------------------------------
    // 6. User A Re-scans Dairy Milk (Should Bump to Top without Duplicating)
    // -------------------------------------------------------------------------
    console.log('\n--- 6. User A Re-scans Existing Product ---');
    await new Promise((r) => setTimeout(r, 50));
    const resRescanA = await fetch(`${baseUrl}/scan-history`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        productName: 'Cadbury Dairy Milk Silk',
        brand: 'Cadbury',
        barcode: '8901233024013',
        imageUrl: 'https://images.openfoodfacts.org/dairy_milk.jpg',
        score: 65,
      }),
    });
    assert(resRescanA.status === 200, 'User A re-scanned Dairy Milk');

    const resListA2 = await fetch(`${baseUrl}/scan-history`, {
      headers: { Authorization: `Bearer ${tokenA}` },
    });
    const dataListA2 = await resListA2.json();
    assert(dataListA2.data.scans.length === 2, 'Total scans remains 2 (no duplicate row created)');
    assert(dataListA2.data.scans[0].productName === 'Cadbury Dairy Milk Silk', 'Dairy Milk bumped to top as most recent');
    assert(dataListA2.data.scans[1].productName === 'Maggi 2-Minute Masala Noodles', 'Maggi is now second');

    // -------------------------------------------------------------------------
    // 7. User B Scans Different Products (Oreo, Pepsi)
    // -------------------------------------------------------------------------
    console.log('\n--- 7. User B Scans Different Products ---');
    const resScanB1 = await fetch(`${baseUrl}/scan-history`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenB}`,
      },
      body: JSON.stringify({
        productName: 'Oreo Vanilla Creme Cookies',
        brand: 'Cadbury Oreo',
        barcode: '7622201777708',
        imageUrl: 'https://images.openfoodfacts.org/oreo.jpg',
        score: 58,
      }),
    });
    assert(resScanB1.status === 200, 'User B saved Oreo scan');

    await new Promise((r) => setTimeout(r, 50));
    const resScanB2 = await fetch(`${baseUrl}/scan-history`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenB}`,
      },
      body: JSON.stringify({
        productName: 'Pepsi Zero Sugar',
        brand: 'PepsiCo',
        barcode: '012000000133',
        imageUrl: 'https://images.openfoodfacts.org/pepsi.jpg',
        score: 62,
      }),
    });
    assert(resScanB2.status === 200, 'User B saved Pepsi scan');

    // -------------------------------------------------------------------------
    // 8. Verify Strict User Isolation (User B NEVER sees User A data)
    // -------------------------------------------------------------------------
    console.log('\n--- 8. Verify Strict Multi-User Data Isolation ---');
    const resListB = await fetch(`${baseUrl}/scan-history`, {
      headers: { Authorization: `Bearer ${tokenB}` },
    });
    const dataListB = await resListB.json();
    assert(dataListB.data.scans.length === 2, 'User B has exactly 2 scans');
    assert(dataListB.data.scans[0].productName === 'Pepsi Zero Sugar', 'User B newest scan is Pepsi');
    assert(dataListB.data.scans[1].productName === 'Oreo Vanilla Creme Cookies', 'User B second scan is Oreo');
    assert(
      !dataListB.data.scans.some((s) => s.productName.includes('Maggi') || s.productName.includes('Dairy Milk')),
      'User B does NOT contain any of User A scans (Maggi / Dairy Milk)'
    );

    // Verify User A history remains intact
    const resCheckA = await fetch(`${baseUrl}/scan-history`, {
      headers: { Authorization: `Bearer ${tokenA}` },
    });
    const dataCheckA = await resCheckA.json();
    assert(
      !dataCheckA.data.scans.some((s) => s.productName.includes('Pepsi') || s.productName.includes('Oreo')),
      'User A does NOT contain any of User B scans (Pepsi / Oreo)'
    );

    console.log('\n======================================================');
    console.log('🎉 ALL SCAN HISTORY BACKEND TESTS PASSED');
    console.log('======================================================\n');
  } catch (error) {
    console.error('Scan history test failed:', error);
    process.exit(1);
  } finally {
    await teardown();
  }
}

runScanHistoryTests();
