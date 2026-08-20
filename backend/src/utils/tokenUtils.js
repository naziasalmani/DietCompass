const jwt = require('jsonwebtoken');
const crypto = require('crypto');

/**
 * Generate short-lived JWT Access Token
 * @param {Object} user - User document
 * @returns {String} JWT token
 */
const generateAccessToken = (user) => {
  const payload = {
    id: user._id.toString(),
    email: user.email,
    username: user.username,
    accountType: user.accountType,
  };

  const secret = process.env.JWT_SECRET || 'diet_compass_default_jwt_secret_dev';
  const expiresIn = process.env.JWT_ACCESS_EXPIRES_IN || process.env.JWT_EXPIRES_IN || '15m';

  return jwt.sign(payload, secret, { expiresIn });
};

/**
 * Generate cryptographically secure random Refresh Token string
 * @returns {String} Raw refresh token
 */
const generateRefreshToken = () => {
  return crypto.randomBytes(40).toString('hex');
};

/**
 * Hash any token string using SHA-256 for secure database storage
 * @param {String} token - Raw token string
 * @returns {String} Hashed token
 */
const hashToken = (token) => {
  if (!token) return '';
  return crypto.createHash('sha256').update(token).digest('hex');
};

/**
 * Verify JWT Access Token
 * @param {String} token - JWT Access Token
 * @returns {Object} Decoded payload
 */
const verifyAccessToken = (token) => {
  const secret = process.env.JWT_SECRET || 'diet_compass_default_jwt_secret_dev';
  return jwt.verify(token, secret);
};

/**
 * Calculate Refresh Token expiration date
 * @returns {Date} Expiration Date
 */
const getRefreshTokenExpiryDate = () => {
  const days = parseInt(process.env.JWT_REFRESH_EXPIRES_IN_DAYS, 10) || 30;
  return new Date(Date.now() + days * 24 * 60 * 60 * 1000);
};

module.exports = {
  generateAccessToken,
  generateRefreshToken,
  hashToken,
  verifyAccessToken,
  getRefreshTokenExpiryDate,
};
