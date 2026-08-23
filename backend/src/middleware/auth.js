const { verifyAccessToken } = require('../utils/tokenUtils');
const User = require('../models/User');

/**
 * Authentication Middleware: Verifies JWT Access Token from Authorization header
 */
const protect = async (req, res, next) => {
  let token;

  const authHeader = req.headers.authorization;

  if (authHeader && authHeader.startsWith('Bearer ')) {
    token = authHeader.split(' ')[1];
  }

  if (!token) {
    return res.status(401).json({
      success: false,
      status: 401,
      message: 'Authentication required. No authorization token provided.',
    });
  }

  try {
    // 1. Verify token signature & expiration
    const decoded = verifyAccessToken(token);

    // 2. Fetch authenticated user from database
    const user = await User.findById(decoded.id);

    if (!user) {
      return res.status(401).json({
        success: false,
        status: 401,
        message: 'The user belonging to this token no longer exists.',
      });
    }

    const today = new Date();
    const todayUtc = new Date(Date.UTC(
      today.getUTCFullYear(),
      today.getUTCMonth(),
      today.getUTCDate(),
    ));
    const previousActiveUtc = user.lastActiveDate
      ? new Date(Date.UTC(
          user.lastActiveDate.getUTCFullYear(),
          user.lastActiveDate.getUTCMonth(),
          user.lastActiveDate.getUTCDate(),
        ))
      : null;
    const dayDifference = previousActiveUtc
      ? Math.round((todayUtc - previousActiveUtc) / 86400000)
      : null;

    if (dayDifference !== 0) {
      user.streakDays = dayDifference === 1 ? Math.max(user.streakDays || 0, 1) + 1 : 1;
      user.lastActiveDate = todayUtc;
      await user.save();
    }

    // 3. Attach user & token data to request object
    req.user = user;
    req.tokenPayload = decoded;

    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        status: 401,
        code: 'TOKEN_EXPIRED',
        message: 'Access token has expired. Please refresh your session.',
      });
    }

    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        status: 401,
        code: 'TOKEN_INVALID',
        message: 'Invalid authentication token signature.',
      });
    }

    return res.status(401).json({
      success: false,
      status: 401,
      message: 'Authentication failed. Please log in again.',
    });
  }
};

module.exports = { protect };
