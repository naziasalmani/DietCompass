const crypto = require('crypto');
const { OAuth2Client } = require('google-auth-library');
const User = require('../models/User');
const RefreshToken = require('../models/RefreshToken');
const {
  generateAccessToken,
  generateRefreshToken,
  hashToken,
  getRefreshTokenExpiryDate,
} = require('../utils/tokenUtils');
const { sendPasswordResetEmail } = require('../services/emailService');

const googleClient = new OAuth2Client();

const createUniqueUsername = async (email) => {
  const base = email
    .split('@')[0]
    .toLowerCase()
    .replace(/[^a-z0-9_]/g, '_')
    .slice(0, 24) || 'google_user';
  let username = base;
  let suffix = 1;
  while (await User.exists({ username })) {
    username = `${base}_${suffix++}`.slice(0, 30);
  }
  return username;
};

/**
 * Helper to create and persist a new refresh session
 */
const createRefreshSession = async (userId, rawRefreshToken, req) => {
  const tokenHash = hashToken(rawRefreshToken);
  const expiresAt = getRefreshTokenExpiryDate();
  const deviceInfo = req.headers['user-agent'] || req.body.deviceInfo || 'Unknown Device';
  const ipAddress = req.ip || req.connection.remoteAddress || '';

  const session = await RefreshToken.create({
    userId,
    tokenHash,
    deviceInfo,
    ipAddress,
    expiresAt,
  });

  return session;
};

/**
 * @desc    Register a new user
 * @route   POST /api/auth/register
 * @access  Public
 */
const register = async (req, res, next) => {
  try {
    const { fullName, username, email, phone, countryCode, password, accountType } = req.body;

    // 1. Validate required fields
    if (!fullName || !fullName.trim()) {
      return res.status(400).json({ success: false, message: 'Full name is required.' });
    }
    if (!username || !username.trim()) {
      return res.status(400).json({ success: false, message: 'Username is required.' });
    }
    if (!email || !email.trim()) {
      return res.status(400).json({ success: false, message: 'Email address is required.' });
    }
    if (!password) {
      return res.status(400).json({ success: false, message: 'Password is required.' });
    }
    if (password.length < 8) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 8 characters long.',
      });
    }

    const normalizedEmail = email.toLowerCase().trim();
    const normalizedUsername = username.toLowerCase().trim();

    // 2. Check for duplicate email
    const existingEmail = await User.findOne({ email: normalizedEmail });
    if (existingEmail) {
      return res.status(409).json({
        success: false,
        message: 'An account with this email address already exists. Please log in instead.',
      });
    }

    // 3. Check for duplicate username
    const existingUsername = await User.findOne({ username: normalizedUsername });
    if (existingUsername) {
      return res.status(409).json({
        success: false,
        message: 'This username is already taken. Please choose a different username.',
      });
    }

    // 4. Create user in database
    const user = await User.create({
      fullName: fullName.trim(),
      username: normalizedUsername,
      email: normalizedEmail,
      phone: phone ? phone.trim() : '',
      countryCode: countryCode ? countryCode.trim() : '+91',
      password,
      accountType: accountType || 'individual',
    });

    // 5. Generate Access & Refresh tokens
    const accessToken = generateAccessToken(user);
    const rawRefreshToken = generateRefreshToken();

    // 6. Save Refresh Session in DB
    await createRefreshSession(user._id, rawRefreshToken, req);

    res.status(201).json({
      success: true,
      message: 'Account created successfully.',
      data: {
        user: user.toJSON(),
        tokens: {
          accessToken,
          refreshToken: rawRefreshToken,
          tokenType: 'Bearer',
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Authenticate user & get tokens
 * @route   POST /api/auth/login
 * @access  Public
 */
const login = async (req, res, next) => {
  try {
    const { email, username, identifier: requestIdentifier, password } = req.body;
    const identifier = requestIdentifier || email || username;

    if (!identifier || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide both email/username and password.',
      });
    }

    const cleanIdentifier = identifier.toLowerCase().trim();
    const phoneIdentifier = cleanIdentifier.replace(/[\s-]/g, '');

    // 1. Find user by email or username, explicitly selecting password hash
    const user = await User.findOne({
      $or: [
        { email: cleanIdentifier },
        { username: cleanIdentifier },
        { phone: cleanIdentifier },
        { phone: phoneIdentifier },
      ],
    }).select('+password');

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials. Please check your email and password.',
      });
    }

    // 2. Verify password with bcrypt
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials. Please check your email and password.',
      });
    }

    // 3. Generate Access & Refresh tokens
    const accessToken = generateAccessToken(user);
    const rawRefreshToken = generateRefreshToken();

    // 4. Save Refresh Session in DB
    await createRefreshSession(user._id, rawRefreshToken, req);

    res.status(200).json({
      success: true,
      message: 'Logged in successfully.',
      data: {
        user: user.toJSON(),
        tokens: {
          accessToken,
          refreshToken: rawRefreshToken,
          tokenType: 'Bearer',
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Authenticate with a verified Google ID token
 * @route   POST /api/auth/google
 * @access  Public
 */
const googleLogin = async (req, res, next) => {
  try {
    const { idToken } = req.body;
    if (!idToken || !process.env.GOOGLE_WEB_CLIENT_ID) {
      return res.status(400).json({
        success: false,
        message: 'Google Sign-In is not configured correctly.',
      });
    }

    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_WEB_CLIENT_ID,
    });
    const payload = ticket.getPayload();
    if (!payload?.sub || !payload.email || payload.email_verified !== true) {
      return res.status(401).json({
        success: false,
        message: 'Google account could not be verified.',
      });
    }

    const email = payload.email.toLowerCase().trim();
    let user = await User.findOne({
      $or: [{ googleId: payload.sub }, { email }],
    }).select('+googleId');

    if (!user) {
      user = await User.create({
        fullName: payload.name || email.split('@')[0],
        username: await createUniqueUsername(email),
        email,
        password: crypto.randomBytes(32).toString('hex'),
        authProvider: 'google',
        googleId: payload.sub,
        avatarUrl: payload.picture || '',
        isEmailVerified: true,
      });
    } else if (!user.googleId) {
      user.googleId = payload.sub;
      user.authProvider = 'google';
      user.isEmailVerified = true;
      if (payload.picture && !user.avatarUrl) user.avatarUrl = payload.picture;
      await user.save();
    }

    const accessToken = generateAccessToken(user);
    const rawRefreshToken = generateRefreshToken();
    await createRefreshSession(user._id, rawRefreshToken, req);

    return res.status(200).json({
      success: true,
      message: 'Logged in with Google successfully.',
      data: {
        user: user.toJSON(),
        tokens: {
          accessToken,
          refreshToken: rawRefreshToken,
          tokenType: 'Bearer',
        },
      },
    });
  } catch (error) {
    if (error.message?.includes('Wrong number of segments') || error.message?.includes('Invalid token')) {
      return res.status(401).json({
        success: false,
        message: 'Google account could not be verified.',
      });
    }
    next(error);
  }
};

/**
 * @desc    Get currently logged in user profile
 * @route   GET /api/auth/me
 * @access  Private (Protected by JWT)
 */
const getMe = async (req, res, next) => {
  try {
    res.status(200).json({
      success: true,
      data: {
        user: req.user.toJSON(),
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Refresh expired Access Token using active Refresh Token
 * @route   POST /api/auth/refresh
 * @access  Public (Requires Refresh Token)
 */
const refreshToken = async (req, res, next) => {
  try {
    const { refreshToken: rawRefreshToken } = req.body;

    if (!rawRefreshToken) {
      return res.status(400).json({
        success: false,
        message: 'Refresh token is required.',
      });
    }

    const hashedToken = hashToken(rawRefreshToken);

    // 1. Find session in DB
    const session = await RefreshToken.findOne({ tokenHash: hashedToken });

    if (!session) {
      return res.status(401).json({
        success: false,
        code: 'REFRESH_TOKEN_NOT_FOUND',
        message: 'Invalid refresh token. Session does not exist.',
      });
    }

    // 2. Check if token was revoked
    if (session.isRevoked) {
      return res.status(401).json({
        success: false,
        code: 'SESSION_REVOKED',
        message: 'This session has been logged out or revoked. Please log in again.',
      });
    }

    // 3. Check if token has expired
    if (session.expiresAt.getTime() < Date.now()) {
      return res.status(401).json({
        success: false,
        code: 'REFRESH_TOKEN_EXPIRED',
        message: 'Refresh session has expired. Please log in again.',
      });
    }

    // 4. Fetch User
    const user = await User.findById(session.userId);
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'User associated with this session no longer exists.',
      });
    }

    // 5. Rotate Refresh Token (Issue new raw token, invalidate old one)
    const newRawRefreshToken = generateRefreshToken();
    const newHashedToken = hashToken(newRawRefreshToken);

    session.isRevoked = true;
    session.revokedAt = new Date();
    session.replacedByTokenHash = newHashedToken;
    await session.save();

    // 6. Save new active session
    await createRefreshSession(user._id, newRawRefreshToken, req);

    // 7. Issue new Access Token
    const newAccessToken = generateAccessToken(user);

    res.status(200).json({
      success: true,
      message: 'Token refreshed successfully.',
      data: {
        tokens: {
          accessToken: newAccessToken,
          refreshToken: newRawRefreshToken,
          tokenType: 'Bearer',
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Log out current session
 * @route   POST /api/auth/logout
 * @access  Private / Public with Refresh Token
 */
const logout = async (req, res, next) => {
  try {
    const { refreshToken: rawRefreshToken } = req.body;

    if (rawRefreshToken) {
      const hashedToken = hashToken(rawRefreshToken);
      await RefreshToken.findOneAndUpdate(
        { tokenHash: hashedToken },
        { isRevoked: true, revokedAt: new Date() }
      );
    } else if (req.user) {
      // Revoke the most recent active session for the authenticated user
      const latestSession = await RefreshToken.findOne({
        userId: req.user._id,
        isRevoked: false,
      }).sort({ createdAt: -1 });

      if (latestSession) {
        latestSession.isRevoked = true;
        latestSession.revokedAt = new Date();
        await latestSession.save();
      }
    }

    res.status(200).json({
      success: true,
      message: 'Logged out successfully. Device session invalidated.',
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Log out from all devices
 * @route   POST /api/auth/logout-all
 * @access  Private (Protected by JWT)
 */
const logoutAll = async (req, res, next) => {
  try {
    await RefreshToken.updateMany(
      { userId: req.user._id, isRevoked: false },
      { isRevoked: true, revokedAt: new Date() }
    );

    res.status(200).json({
      success: true,
      message: 'Logged out from all devices successfully.',
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Request password reset email with secure token
 * @route   POST /api/auth/forgot-password
 * @access  Public
 */
const forgotPassword = async (req, res, next) => {
  try {
    const { email } = req.body;

    if (!email || !email.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Email address is required.',
      });
    }

    const normalizedEmail = email.toLowerCase().trim();
    const user = await User.findOne({ email: normalizedEmail });

    // For security, if user doesn't exist, respond with safe generic message
    if (!user) {
      return res.status(200).json({
        success: true,
        message: 'If an account exists with this email address, a password reset link has been sent.',
      });
    }

    // Generate token and save hash + expiry to user document
    const rawResetToken = user.generatePasswordResetToken();
    await user.save({ validateBeforeSave: false });

    // Construct Reset URL
    const clientBaseUrl = process.env.CLIENT_URL || process.env.API_BASE_URL || 'http://localhost:5000';
    const resetUrl = `${clientBaseUrl}/reset-password/${rawResetToken}`;
    const expirationMinutes = parseInt(process.env.RESET_PASSWORD_EXPIRES_MINUTES, 10) || 60;

    // Send real branded email
    try {
      await sendPasswordResetEmail({
        to: user.email,
        name: user.fullName,
        resetUrl,
        expiresInMinutes: expirationMinutes,
      });

      res.status(200).json({
        success: true,
        message: 'Password reset link has been sent to your email address.',
      });
    } catch (emailError) {
      // If email sending fails, clear the reset token so it can be retried
      user.resetPasswordToken = undefined;
      user.resetPasswordExpires = undefined;
      await user.save({ validateBeforeSave: false });

      return res.status(500).json({
        success: false,
        message: 'Failed to send password reset email. Please try again later.',
      });
    }
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Reset password using valid reset token
 * @route   POST /api/auth/reset-password/:token
 * @access  Public
 */
const resetPassword = async (req, res, next) => {
  try {
    const { token } = req.params;
    const { password } = req.body;

    if (!token) {
      return res.status(400).json({
        success: false,
        message: 'Reset token is required.',
      });
    }

    if (!password) {
      return res.status(400).json({
        success: false,
        message: 'New password is required.',
      });
    }

    if (password.length < 8) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 8 characters long.',
      });
    }

    // 1. Hash incoming token to match database SHA-256 hash
    const hashedToken = crypto
      .createHash('sha256')
      .update(token)
      .digest('hex');

    // 2. Find user with matching token and valid (unexpired) timestamp
    const user = await User.findOne({
      resetPasswordToken: hashedToken,
      resetPasswordExpires: { $gt: Date.now() },
    });

    if (!user) {
      return res.status(400).json({
        success: false,
        message: 'Password reset token is invalid, already used, or has expired.',
      });
    }

    // 3. Set new password & clear reset token fields
    user.password = password;
    user.resetPasswordToken = undefined;
    user.resetPasswordExpires = undefined;
    await user.save(); // Pre-save hook hashes new password with bcrypt

    // 4. Invalidate all existing refresh sessions across devices (security best practice)
    await RefreshToken.updateMany(
      { userId: user._id, isRevoked: false },
      { isRevoked: true, revokedAt: new Date() }
    );

    res.status(200).json({
      success: true,
      message: 'Password has been reset successfully. You can now log in with your new password.',
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  register,
  login,
  googleLogin,
  getMe,
  refreshToken,
  logout,
  logoutAll,
  forgotPassword,
  resetPassword,
};
