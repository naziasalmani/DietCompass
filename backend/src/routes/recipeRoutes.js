const express = require('express');
const router = express.Router();
const { generateRecipes, getRecipeDetails } = require('../controllers/recipeController');
const {
  saveRecipeHistory,
  getRecipeHistory,
  toggleBookmark,
  deleteRecipeHistory,
  clearRecipeHistory,
} = require('../controllers/recipeHistoryController');
const { protect } = require('../middleware/auth');

// All recipe generation and history endpoints require authenticated JWT
router.post('/generate', protect, generateRecipes);

// Recipe Generation History Routes (must come before /:id)
router.post('/history', protect, saveRecipeHistory);
router.get('/history', protect, getRecipeHistory);
router.patch('/history/:id/bookmark', protect, toggleBookmark);
router.delete('/history/:id', protect, deleteRecipeHistory);
router.delete('/history', protect, clearRecipeHistory);

// Specific recipe detail
router.get('/:id', protect, getRecipeDetails);

module.exports = router;
