const express = require('express');
const router = express.Router();
const { generateRecipes, getRecipeDetails } = require('../controllers/recipeController');
const { protect } = require('../middleware/auth');

// All recipe generation endpoints require authenticated JWT
router.post('/generate', protect, generateRecipes);
router.get('/:id', protect, getRecipeDetails);

module.exports = router;
