const express = require('express');
const router = express.Router();
const {
  getPersonalization,
  savePersonalization,
  patchPersonalization,
} = require('../controllers/personalizationController');
const { protect } = require('../middleware/auth');

// All personalization endpoints are protected by JWT authentication
router.get('/', protect, getPersonalization);
router.put('/', protect, savePersonalization);
router.post('/', protect, savePersonalization);
router.patch('/', protect, patchPersonalization);

module.exports = router;
