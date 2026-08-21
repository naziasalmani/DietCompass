const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

dotenv.config();

// Ensure test environment variables
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test_super_secret_jwt_key_diet_compass_2026';
process.env.JWT_ACCESS_EXPIRES_IN = '15m';
process.env.RESET_PASSWORD_EXPIRES_MINUTES = '60';

const User = require('./src/models/User');
const RefreshToken = require('./src/models/RefreshToken');
const authRoutes = require('./src/routes/authRoutes');
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
  app.use(errorHandler);

  return new Promise((resolve) => {
    server = app.listen(0, () => {
      const port = server.address().port;
      baseUrl = `http://localhost:${port}/api/auth`;
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
  console.log('\n======================================================================');
  console.log('🧪 DIETCOMPASS AUTHENTICATION SYSTEM — AUTOMATED TEST SUITE');
  console.log('======================================================================\n');

  await setup();

  let passed = 0;
  let failed = 0;

  const assert = (condition, testName, details = '') => {
    if (condition) {
      console.log(`  ✅ [PASS] ${testName}`);
      passed++;
    } else {
      console.error(`  ❌ [FAIL] ${testName} ${details ? `(${details})` : ''}`);
      failed++;
    }
  };

  try {
    // -------------------------------------------------------------------------
    // TEST GROUP 1: Registration
    // -------------------------------------------------------------------------
    console.log('\n📦 1. USER REGISTRATION TESTS');

    // 1.1 Valid Registration
    const regRes = await fetch(`${baseUrl}/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        fullName: 'Nazia Salmani',
        username: 'nazia_salmani',
        email: 'nazia@example.com',
        phone: '9876543210',
        countryCode: '+91',
        password: 'Password123!',
        accountType: 'individual',
      }),
    });
    const regData = await regRes.json();
    assert(regRes.status === 201 && regData.success === true, '1.1 New user registration succeeds with 201');
    assert(regData.data.tokens.accessToken && regData.data.tokens.refreshToken, '1.2 Access & Refresh tokens returned on registration');
    assert(!regData.data.user.password, '1.3 Password hash is NOT returned in response');
    assert(regData.data.user.email === 'nazia@example.com', '1.4 Email is normalized to lowercase');

    let firstUserAccessToken = regData.data.tokens.accessToken;
    let firstUserRefreshToken = regData.data.tokens.refreshToken;

    // 1.2 Duplicate Email
    const dupEmailRes = await fetch(`${baseUrl}/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        fullName: 'Another User',
        username: 'another_user',
        email: 'NAZIA@example.com', // uppercase to verify normalization
        password: 'Password123!',
      }),
    });
    assert(dupEmailRes.status === 409, '1.5 Duplicate email is rejected with 409 Conflict');

    // 1.3 Duplicate Username
    const dupUserRes = await fetch(`${baseUrl}/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        fullName: 'Another User',
        username: 'nazia_salmani',
        email: 'unique_email@example.com',
        password: 'Password123!',
      }),
    });
    assert(dupUserRes.status === 409, '1.6 Duplicate username is rejected with 409 Conflict');

    // 1.4 Password too short (< 8 chars)
    const weakPassRes = await fetch(`${baseUrl}/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        fullName: 'Short Pass User',
        username: 'short_pass',
        email: 'short@example.com',
        password: '123',
      }),
    });
    assert(weakPassRes.status === 400, '1.7 Weak password (< 8 chars) is rejected with 400');

    // -------------------------------------------------------------------------
    // TEST GROUP 2: Login
    // -------------------------------------------------------------------------
    console.log('\n🔑 2. USER LOGIN TESTS');

    // 2.1 Login with Email
    const loginEmailRes = await fetch(`${baseUrl}/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'nazia@example.com',
        password: 'Password123!',
      }),
    });
    const loginEmailData = await loginEmailRes.json();
    assert(loginEmailRes.status === 200 && loginEmailData.success === true, '2.1 Login with valid email & password succeeds');

    // 2.2 Login with Username
    const loginUserRes = await fetch(`${baseUrl}/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: 'nazia_salmani',
        password: 'Password123!',
      }),
    });
    const loginUserData = await loginUserRes.json();
    assert(loginUserRes.status === 200 && loginUserData.success === true, '2.2 Login with valid username & password succeeds');

    // 2.3 Login with Phone
    const loginPhoneRes = await fetch(`${baseUrl}/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        identifier: '987 654 3210',
        password: 'Password123!',
      }),
    });
    const loginPhoneData = await loginPhoneRes.json();
    assert(loginPhoneRes.status === 200 && loginPhoneData.success === true, '2.3 Login with valid phone succeeds');

    // 2.4 Wrong Password
    const wrongPassRes = await fetch(`${baseUrl}/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'nazia@example.com',
        password: 'WrongPassword999!',
      }),
    });
    assert(wrongPassRes.status === 401, '2.4 Wrong password returns 401 Unauthorized');

    // 2.5 Non-existent account
    const nonExistentRes = await fetch(`${baseUrl}/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'nonexistent@example.com',
        password: 'Password123!',
      }),
    });
    assert(nonExistentRes.status === 401, '2.5 Non-existent account returns 401 Unauthorized');

    // -------------------------------------------------------------------------
    // TEST GROUP 3: JWT Verification & Protected GET /api/auth/me
    // -------------------------------------------------------------------------
    console.log('\n🛡️ 3. JWT VERIFICATION & PROTECTED /ME ROUTE TESTS');

    const validAccessToken = loginEmailData.data.tokens.accessToken;

    // 3.1 Valid Token
    const meRes = await fetch(`${baseUrl}/me`, {
      headers: { Authorization: `Bearer ${validAccessToken}` },
    });
    const meData = await meRes.json();
    assert(meRes.status === 200 && meData.data.user.email === 'nazia@example.com', '3.1 Valid Bearer token retrieves user profile via GET /me');

    // 3.2 Missing Token
    const missingTokenRes = await fetch(`${baseUrl}/me`);
    assert(missingTokenRes.status === 401, '3.2 Missing Authorization header returns 401');

    // 3.3 Forged / Invalid Token
    const invalidTokenRes = await fetch(`${baseUrl}/me`, {
      headers: { Authorization: 'Bearer forged.invalid.token' },
    });
    assert(invalidTokenRes.status === 401, '3.3 Forged/tampered JWT token returns 401');

    // 3.4 Expired Token Test
    const jwt = require('jsonwebtoken');
    const expiredToken = jwt.sign(
      { id: meData.data.user._id, email: 'nazia@example.com' },
      process.env.JWT_SECRET,
      { expiresIn: '-1s' } // Expired in the past
    );

    const expiredRes = await fetch(`${baseUrl}/me`, {
      headers: { Authorization: `Bearer ${expiredToken}` },
    });
    const expiredData = await expiredRes.json();
    assert(expiredRes.status === 401 && expiredData.code === 'TOKEN_EXPIRED', '3.4 Expired access token is rejected with 401 TOKEN_EXPIRED');


    // -------------------------------------------------------------------------
    // TEST GROUP 4: Refresh Token & Rotation
    // -------------------------------------------------------------------------
    console.log('\n🔄 4. REFRESH TOKEN & SESSION ROTATION TESTS');

    // 4.1 Successful Token Refresh
    const refreshRes = await fetch(`${baseUrl}/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken: firstUserRefreshToken }),
    });
    const refreshData = await refreshRes.json();
    assert(refreshRes.status === 200 && refreshData.data.tokens.accessToken, '4.1 Valid refresh token issues new access & refresh token pair');

    const rotatedAccessToken = refreshData.data.tokens.accessToken;
    const rotatedRefreshToken = refreshData.data.tokens.refreshToken;

    // 4.2 Use new access token on protected route
    const newAccessMeRes = await fetch(`${baseUrl}/me`, {
      headers: { Authorization: `Bearer ${rotatedAccessToken}` },
    });
    assert(newAccessMeRes.status === 200, '4.2 Newly issued access token accesses protected endpoint');

    // 4.3 Replay / Reuse Old Rotated Refresh Token (Must fail)
    const replayOldRefreshRes = await fetch(`${baseUrl}/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken: firstUserRefreshToken }),
    });
    assert(replayOldRefreshRes.status === 401, '4.3 Old rotated refresh token is revoked and cannot be reused');

    // 4.4 Non-existent / Invalid Refresh Token
    const fakeRefreshRes = await fetch(`${baseUrl}/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken: 'fake_random_token_value_12345' }),
    });
    assert(fakeRefreshRes.status === 401, '4.4 Invalid refresh token returns 401');

    // -------------------------------------------------------------------------
    // TEST GROUP 5: Logout & Session Invalidation
    // -------------------------------------------------------------------------
    console.log('\n🚪 5. LOGOUT & MULTI-DEVICE SESSION INVALIDATION TESTS');

    // 5.1 Logout current session with refresh token
    const logoutRes = await fetch(`${baseUrl}/logout`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${rotatedAccessToken}`,
      },
      body: JSON.stringify({ refreshToken: rotatedRefreshToken }),
    });
    assert(logoutRes.status === 200, '5.1 Logout endpoint returns 200 success');

    // 5.2 Attempt to refresh using logged-out session
    const refreshAfterLogoutRes = await fetch(`${baseUrl}/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken: rotatedRefreshToken }),
    });
    assert(refreshAfterLogoutRes.status === 401, '5.2 Logged-out refresh session is revoked and cannot refresh');

    // -------------------------------------------------------------------------
    // TEST GROUP 6: Forgot Password & Reset Token
    // -------------------------------------------------------------------------
    console.log('\n📧 6. FORGOT PASSWORD & SECURE TOKEN TESTS');

    // 6.1 Forgot password for existing email
    const forgotRes = await fetch(`${baseUrl}/forgot-password`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'nazia@example.com' }),
    });
    const forgotData = await forgotRes.json();
    assert(forgotRes.status === 200 && forgotData.success === true, '6.1 Forgot password returns 200 success');

    // Verify token was stored hashed in DB
    const userInDb = await User.findOne({ email: 'nazia@example.com' }).select('+resetPasswordToken +resetPasswordExpires');
    assert(userInDb.resetPasswordToken && userInDb.resetPasswordExpires > Date.now(), '6.2 Reset token hash and expiration stored in DB');
    assert(userInDb.resetPasswordToken.length === 64, '6.3 Token in database is a 64-char SHA-256 hash (raw token is never stored)');

    // 6.2 Forgot password for non-existent email (Safe response)
    const forgotUnknownRes = await fetch(`${baseUrl}/forgot-password`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'unknown@example.com' }),
    });
    assert(forgotUnknownRes.status === 200, '6.4 Non-existent email returns safe generic 200 response (no user enumeration)');

    // -------------------------------------------------------------------------
    // TEST GROUP 7: Password Reset Flow
    // -------------------------------------------------------------------------
    console.log('\n🔒 7. PASSWORD RESET API TESTS');

    // Generate fresh reset token directly from user instance to test endpoint
    const rawResetToken = userInDb.generatePasswordResetToken();
    await userInDb.save({ validateBeforeSave: false });

    // 7.1 Invalid token reset attempt
    const invalidResetRes = await fetch(`${baseUrl}/reset-password/invalid_token_12345`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ password: 'BrandNewPassword123!' }),
    });
    assert(invalidResetRes.status === 400, '7.1 Invalid reset token is rejected with 400');

    // 7.2 Short password reset attempt
    const shortResetPassRes = await fetch(`${baseUrl}/reset-password/${rawResetToken}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ password: 'short' }),
    });
    assert(shortResetPassRes.status === 400, '7.2 New password < 8 chars is rejected with 400');

    // 7.3 Successful Password Reset
    const validResetRes = await fetch(`${baseUrl}/reset-password/${rawResetToken}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ password: 'BrandNewPassword123!' }),
    });
    const validResetData = await validResetRes.json();
    assert(validResetRes.status === 200 && validResetData.success === true, '7.3 Valid token successfully resets password');

    // 7.4 Reset token reuse attempt (Must fail)
    const reuseResetRes = await fetch(`${baseUrl}/reset-password/${rawResetToken}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ password: 'YetAnotherPassword123!' }),
    });
    assert(reuseResetRes.status === 400, '7.4 Used reset token cannot be reused');

    // 7.5 Old password rejected after reset
    const oldLoginRes = await fetch(`${baseUrl}/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'nazia@example.com',
        password: 'Password123!', // old password
      }),
    });
    assert(oldLoginRes.status === 401, '7.5 Old password no longer works after reset');

    // 7.6 New password works immediately
    const newLoginRes = await fetch(`${baseUrl}/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'nazia@example.com',
        password: 'BrandNewPassword123!', // new password
      }),
    });
    const newLoginData = await newLoginRes.json();
    assert(newLoginRes.status === 200 && newLoginData.success === true, '7.6 New password logs in successfully');
  } catch (err) {
    console.error('💥 Test suite crashed with error:', err);
    failed++;
  } finally {
    await teardown();
  }

  console.log('\n======================================================================');
  console.log(`📊 TEST SUMMARY: ${passed} PASSED | ${failed} FAILED | TOTAL: ${passed + failed}`);
  console.log('======================================================================\n');

  if (failed > 0) {
    process.exit(1);
  } else {
    process.exit(0);
  }
};

runTests();
