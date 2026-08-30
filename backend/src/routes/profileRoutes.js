const express = require('express');
const router = express.Router();
const { getProfile, updateProfile, exportUserData } = require('../controllers/profileController');
const { protect } = require('../middleware/auth');

// All profile endpoints are protected by JWT authentication
router.get('/', protect, getProfile);
router.put('/', protect, updateProfile);
router.get('/export', protect, exportUserData);

module.exports = router;
