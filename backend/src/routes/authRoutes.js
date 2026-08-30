const express = require('express');
const router = express.Router();
const {
  register,
  login,
  googleLogin,
  getMe,
  refreshToken,
  logout,
  logoutAll,
  forgotPassword,
  resetPassword,
  changePassword,
  getSessions,
} = require('../controllers/authController');
const { protect } = require('../middleware/auth');

// Public routes
router.post('/register', register);
router.post('/login', login);
router.post('/google', googleLogin);
router.post('/refresh', refreshToken);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password/:token', resetPassword);

// Protected routes (Requires valid JWT Access Token)
router.get('/me', protect, getMe);
router.post('/logout', protect, logout);
router.post('/logout-all', protect, logoutAll);
router.post('/change-password', protect, changePassword);
router.get('/sessions', protect, getSessions);

module.exports = router;
