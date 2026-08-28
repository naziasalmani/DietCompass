const express = require('express');
const router = express.Router();
const { generateMealPlan } = require('../controllers/mealPlanController');
const { protect } = require('../middleware/auth');

// POST /api/meal-plans/generate — Authenticated meal plan generation
router.post('/generate', protect, generateMealPlan);

module.exports = router;
