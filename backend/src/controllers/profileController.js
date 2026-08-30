const User = require('../models/User');
const Personalization = require('../models/Personalization');
const ScanHistory = require('../models/ScanHistory');
const RecipeHistory = require('../models/RecipeHistory');

/**
 * @desc    Get current user profile & personalization status
 * @route   GET /api/profile
 * @access  Private (Protected by JWT)
 */
const getProfile = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User profile not found.',
      });
    }

    const personalization = await Personalization.findOne({ userId: req.user._id });

    res.status(200).json({
      success: true,
      data: {
        user: user.toJSON(),
        isPersonalizationComplete: personalization ? Boolean(personalization.isCompleted) : false,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Update current user profile
 * @route   PUT /api/profile
 * @access  Private (Protected by JWT)
 */
const updateProfile = async (req, res, next) => {
  try {
    const allowedFields = [
      'fullName',
      'phone',
      'countryCode',
      'avatarUrl',
      'badgeLabel',
      'dateOfBirth',
      'gender',
      'country',
      'city',
      'address',
      'occupation',
      'dietType',
      'height',
      'weight',
      'healthScore',
      'streakDays',
    ];

    const updates = {};
    for (const field of allowedFields) {
      if (req.body[field] !== undefined) {
        updates[field] = typeof req.body[field] === 'string' ? req.body[field].trim() : req.body[field];
      }
    }

    // Validate fullName if provided
    if (updates.fullName !== undefined && (!updates.fullName || updates.fullName.length < 2)) {
      return res.status(400).json({
        success: false,
        message: 'Full name must be at least 2 characters.',
      });
    }

    const updatedUser = await User.findByIdAndUpdate(
      req.user._id,
      { $set: updates },
      { new: true, runValidators: true }
    );

    if (!updatedUser) {
      return res.status(404).json({
        success: false,
        message: 'User not found.',
      });
    }

    // Synchronize common fields (gender, height, weight, dietType) with Personalization doc if it exists
    const persUpdates = {};
    if (updates.gender !== undefined) persUpdates.gender = updates.gender;
    if (updates.height !== undefined) persUpdates.height = updates.height;
    if (updates.weight !== undefined) persUpdates.weight = updates.weight;
    if (updates.dietType !== undefined) persUpdates.dietType = updates.dietType;

    if (Object.keys(persUpdates).length > 0) {
      await Personalization.findOneAndUpdate(
        { userId: req.user._id },
        { $set: persUpdates }
      );
    }

    res.status(200).json({
      success: true,
      message: 'Profile updated successfully.',
      data: {
        user: updatedUser.toJSON(),
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Export all user-owned data for the authenticated user
 * @route   GET /api/profile/export (or GET /api/data-export)
 * @access  Private (Protected by JWT)
 */
const exportUserData = async (req, res, next) => {
  try {
    const userId = req.user._id;

    console.log('\n[DATA EXPORT DEBUG]');
    console.log('route hit = true');
    console.log(`authenticated user id = ${userId.toString()}`);
    console.log('database query started = true');

    // 1. Fetch user (safe sanitized representation without password/tokens)
    const user = await User.findById(userId);
    if (!user) {
      console.log('response status = 404');
      return res.status(404).json({
        success: false,
        message: 'User not found.',
      });
    }

    const safeUser = user.toJSON();

    // 2. Fetch personalization profile
    const personalizationDoc = await Personalization.findOne({ userId });
    const personalization = personalizationDoc ? personalizationDoc.toJSON() : null;

    // 3. Fetch scan history
    const scans = await ScanHistory.find({ userId }).sort({ scannedAt: -1 }).lean();
    const scanHistory = scans.map((s) => ({
      id: s._id?.toString(),
      barcode: s.barcode || '',
      productName: s.productName,
      brand: s.brand || '',
      imageUrl: s.imageUrl || '',
      score: s.score,
      ingredients: s.ingredients || '',
      allergens: s.allergens || [],
      nutrients: s.nutrients || {},
      scannedAt: s.scannedAt,
    }));

    // 4. Fetch recipe history and saved recipes
    const recipes = await RecipeHistory.find({ userId }).sort({ generatedAt: -1 }).lean();
    const recipeHistory = recipes.map((r) => ({
      recipeId: r.recipeId,
      title: r.title,
      description: r.description || '',
      imageUrl: r.imageUrl || '',
      ingredients: r.ingredients || [],
      instructions: r.instructions || [],
      nutrition: r.nutrition || {},
      timeMinutes: r.timeMinutes,
      prepTime: r.prepTime || '',
      cookTime: r.cookTime || '',
      servings: r.servings,
      difficulty: r.difficulty || 'Easy',
      tags: r.tags || [],
      recipeSource: r.recipeSource || 'api',
      generationMode: r.generationMode || 'pantry',
      sourceProduct: r.sourceProduct || '',
      normalizedIngredient: r.normalizedIngredient || '',
      pantryIngredients: r.pantryIngredients || [],
      isBookmarked: Boolean(r.isBookmarked),
      isViewed: Boolean(r.isViewed),
      generatedAt: r.generatedAt,
    }));

    const savedRecipes = recipeHistory.filter((r) => r.isBookmarked);

    const exportPayload = {
      exportMetadata: {
        appName: 'DietCompass',
        version: '1.0.0',
        exportedAt: new Date().toISOString(),
        userId: userId.toString(),
      },
      user: safeUser,
      personalization,
      scanHistory,
      savedRecipes,
      recipeHistory,
    };

    console.log(`database query result = success (user: ${Boolean(safeUser)}, personalization: ${Boolean(personalization)}, scans: ${scanHistory.length}, recipes: ${recipeHistory.length})`);
    console.log('response status = 200\n');

    res.status(200).json({
      success: true,
      message: 'User data exported successfully.',
      data: exportPayload,
    });
  } catch (error) {
    console.error('[DATA EXPORT DEBUG] error =', error.message);
    console.log('response status = 500\n');
    next(error);
  }
};

module.exports = {
  getProfile,
  updateProfile,
  exportUserData,
};
