const mealPlanService = require('../services/mealPlanService');
const Personalization = require('../models/Personalization');
const User = require('../models/User');

/**
 * Generate AI-Powered Personalized Meal Plan
 * POST /api/meal-plans/generate
 */
const generateMealPlan = async (req, res, next) => {
  try {
    const userId = req.user?._id || req.user?.id;
    const body = req.body || {};

    let userProfile = null;
    let personalization = null;

    if (userId) {
      const [userDoc, personDoc] = await Promise.all([
        User.findById(userId).lean().catch(() => null),
        Personalization.findOne({ userId }).lean().catch(() => null),
      ]);
      userProfile = userDoc;
      personalization = personDoc;
    }

    const durationDays = body.durationDays ?? body.duration ?? 7;
    const goal = body.goal || (personalization?.goals && personalization.goals.length > 0 ? personalization.goals[0] : 'Weight Loss');
    const calories = body.calories || body.calorieTarget || 1800;
    const mealTypes = body.mealTypes || ['Breakfast', 'Lunch', 'Snack', 'Dinner'];
    const diet = body.diet || body.dietPreference || personalization?.dietType || userProfile?.dietType || 'Vegetarian';
    const allergies = Array.isArray(body.allergies)
      ? body.allergies
      : (body.allergy && body.allergy !== 'None' ? [body.allergy] : personalization?.allergies || []);
    const budget = body.budget || 'Moderate';
    const usePantry = body.usePantry !== false;
    const pantryIngredients = Array.isArray(body.pantryIngredients)
      ? body.pantryIngredients
      : (Array.isArray(body.pantryItems) ? body.pantryItems.map(p => typeof p === 'string' ? p : p.name || p.label || '') : []);

    const plan = await mealPlanService.generateMealPlan({
      durationDays,
      goal,
      calories,
      mealTypes,
      diet,
      allergies,
      budget,
      usePantry,
      pantryIngredients,
      userProfile,
      personalization,
    });

    return res.status(200).json({
      success: true,
      message: `Successfully generated ${plan.durationDays}-day personalized meal plan.`,
      data: plan,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  generateMealPlan,
};
