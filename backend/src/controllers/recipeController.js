const User = require('../models/User');
const Personalization = require('../models/Personalization');
const spoonacularService = require('../services/spoonacularService');

/**
 * @desc    Generate personalized recipes based on pantry ingredients
 * @route   POST /api/recipes/generate
 * @access  Private (Protected by JWT)
 */
const generateRecipes = async (req, res, next) => {
  try {
    const { ingredients, pantryItems, mealType, maxTime, craving, number } = req.body;

    const [userProfile, personalization] = await Promise.all([
      User.findById(req.user._id).select('-password'),
      Personalization.findOne({ userId: req.user._id }),
    ]);

    const result = await spoonacularService.generatePantryRecipes({
      ingredients: Array.isArray(ingredients) ? ingredients : [],
      pantryItems: Array.isArray(pantryItems) ? pantryItems : [],
      mealType: mealType || '',
      maxTime: typeof maxTime === 'number' ? maxTime : null,
      craving: craving || '',
      userProfile,
      personalization,
      number: typeof number === 'number' ? number : 6,
    });

    res.status(200).json({
      success: true,
      data: result,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get detailed recipe information by ID
 * @route   GET /api/recipes/:id
 * @access  Private (Protected by JWT)
 */
const getRecipeDetails = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (!id) {
      return res.status(400).json({
        success: false,
        message: 'Recipe ID is required.',
      });
    }

    const [userProfile, personalization] = await Promise.all([
      User.findById(req.user._id).select('-password'),
      Personalization.findOne({ userId: req.user._id }),
    ]);

    const recipe = await spoonacularService.getRecipeDetails(id, userProfile, personalization);

    res.status(200).json({
      success: true,
      data: recipe,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  generateRecipes,
  getRecipeDetails,
};
