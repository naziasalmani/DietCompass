const User = require('../models/User');
const Personalization = require('../models/Personalization');
const recipePipelineService = require('../services/recipePipelineService');

/**
 * @desc    Generate personalized recipes based on pantry ingredients & source product
 * @route   POST /api/recipes/generate
 * @access  Private (Protected by JWT)
 */
const generateRecipes = async (req, res, next) => {
  try {
    const { mode, ingredients, pantryItems, mealType, maxTime, craving, sourceProduct, primaryIngredient, number } = req.body;

    const [userProfile, personalization] = await Promise.all([
      User.findById(req.user._id).select('-password'),
      Personalization.findOne({ userId: req.user._id }),
    ]);

    const result = await recipePipelineService.generatePersonalizedRecipes({
      mode: mode || (sourceProduct ? 'product' : 'pantry'),
      ingredients: Array.isArray(ingredients) ? ingredients : [],
      pantryItems: Array.isArray(pantryItems) ? pantryItems : [],
      mealType: mealType || '',
      maxTime: typeof maxTime === 'number' ? maxTime : null,
      craving: craving || primaryIngredient || '',
      sourceProduct: sourceProduct || null,
      userProfile,
      personalization,
      number: typeof number === 'number' ? number : 6,
    });


    console.log('\n[BACKEND RECIPE RESPONSE]');
    console.log('status = 200');
    console.log(`responseKeys = [${Object.keys(result || {}).join(', ')}]`);
    console.log(`recipeCount = ${(result?.recipes || []).length}`);
    console.log(`source = ${result?.recipeSource || 'none'}`);
    console.log(`finalResponseShape = { success: true, data: { recipes: [${(result?.recipes || []).length}], totalFound: ${result?.totalFound ?? 0}, recipeSource: "${result?.recipeSource}" } }`);

    res.status(200).json({
      success: true,
      data: result,
    });

  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get detailed recipe information by ID or URI
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

    const recipe = await recipePipelineService.getRecipeDetails(id, userProfile, personalization);

    if (!recipe) {
      return res.status(404).json({
        success: false,
        message: 'Recipe not found.',
      });
    }

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

