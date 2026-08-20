const express = require('express');
const router = express.Router();
const { analyzeProduct, analyzeOcr, chatCoach, lookupProduct, getCompatibility, getRecommendations } = require('../controllers/aiController');
const { protect } = require('../middleware/auth');

// All AI Intelligence endpoints require authenticated JWT
router.post('/analyze-product', protect, analyzeProduct);
router.post('/analyze-ocr', protect, analyzeOcr);
router.post('/lookup-product', protect, lookupProduct);
router.post('/coach', protect, chatCoach);
router.post('/compatibility', protect, getCompatibility);
router.post('/recommendations', protect, getRecommendations);

module.exports = router;


