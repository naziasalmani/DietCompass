const RecipeHistory = require('../models/RecipeHistory');

/**
 * Save single recipe or batch of generated recipes to user's history
 * POST /api/recipes/history
 */
const saveRecipeHistory = async (req, res, next) => {
  try {
    const userId = req.user._id || req.user.id;
    const body = req.body;

    const generationMode = body.generationMode === 'product' ? 'product' : 'pantry';
    const sourceProduct = (body.sourceProduct || '').trim();
    const normalizedIngredient = (body.normalizedIngredient || '').trim();
    const pantryIngredients = Array.isArray(body.pantryIngredients) ? body.pantryIngredients : [];

    // Support both single recipe or array of recipes
    let rawList = [];
    if (Array.isArray(body.recipes)) {
      rawList = body.recipes;
    } else if (body.recipe && typeof body.recipe === 'object') {
      rawList = [body.recipe];
    } else if (body.title) {
      rawList = [body];
    }

    if (rawList.length === 0) {
      return res.status(400).json({
        success: false,
        status: 400,
        message: 'No valid recipe provided to save to history.',
      });
    }

    const savedRecords = [];
    const now = new Date();

    for (const r of rawList) {
      const title = (r.title || '').trim();
      if (!title) continue;

      const recipeId = (r.recipeId || r.id || `rec_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`).toString().trim();
      const description = (r.description || r.summary || '').trim();
      const imageUrl = (r.imageUrl || r.image || r.imageAsset || '').trim();
      const timeMinutes = typeof r.timeMinutes === 'number' ? r.timeMinutes : (typeof r.readyInMinutes === 'number' ? r.readyInMinutes : 15);
      const prepTime = (r.prepTime || `${timeMinutes} mins`).toString().trim();
      const cookTime = (r.cookTime || '').toString().trim();
      const servings = typeof r.servings === 'number' ? r.servings : (typeof r.serves === 'number' ? r.serves : 2);
      const difficulty = (r.difficulty || 'Easy').toString().trim();
      const tags = Array.isArray(r.tags) ? r.tags : (r.tagline ? r.tagline.split('•').map(s => s.trim()) : []);
      const recipeSource = (r.recipeSource || r.source || 'api').toString().trim();
      const isBookmarked = r.isBookmarked === true;

      // Extract ingredients and instructions
      let ingredients = [];
      if (Array.isArray(r.ingredients)) {
        ingredients = r.ingredients.map(i => {
          if (typeof i === 'string') return { name: i, amount: '' };
          if (typeof i === 'object' && i !== null) {
            return {
              name: i.name || i.original || '',
              amount: i.amount || '',
              unit: i.unit || '',
            };
          }
          return { name: String(i), amount: '' };
        });
      }

      let instructions = [];
      if (Array.isArray(r.instructions)) {
        instructions = r.instructions.map(inst => (typeof inst === 'string' ? inst : (inst.step || inst.text || ''))).filter(Boolean);
      } else if (typeof r.instructions === 'string') {
        instructions = r.instructions.split('\n').map(s => s.trim()).filter(Boolean);
      }

      // Extract nutrition
      const nutrition = {
        calories: r.nutrition?.calories ?? (typeof r.kcal === 'number' ? r.kcal : (typeof r.calories === 'number' ? r.calories : null)),
        protein: r.nutrition?.protein ?? (typeof r.proteinGrams === 'number' ? r.proteinGrams : (typeof r.protein === 'number' ? r.protein : null)),
        carbs: r.nutrition?.carbs ?? (typeof r.carbsGrams === 'number' ? r.carbsGrams : (typeof r.carbs === 'number' ? r.carbs : null)),
        fat: r.nutrition?.fat ?? (typeof r.fatGrams === 'number' ? r.fatGrams : (typeof r.fat === 'number' ? r.fat : null)),
        fiber: r.nutrition?.fiber ?? (typeof r.fiberGrams === 'number' ? r.fiberGrams : (typeof r.fiber === 'number' ? r.fiber : null)),
      };

      // Check existing to bump timestamp instead of creating duplicates
      let existing = await RecipeHistory.findOne({
        userId,
        $or: [
          { recipeId },
          { title: { $regex: new RegExp(`^${title.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&')}$`, 'i') } },
        ],
      });

      const isAlreadySaved = Boolean(existing?.isBookmarked);

      let saved;
      if (existing) {
        existing.generatedAt = now;
        if (imageUrl) existing.imageUrl = imageUrl;
        if (description) existing.description = description;
        if (ingredients.length > 0) existing.ingredients = ingredients;
        if (instructions.length > 0) existing.instructions = instructions;
        if (recipeSource) existing.recipeSource = recipeSource;
        existing.generationMode = generationMode;
        if (sourceProduct) existing.sourceProduct = sourceProduct;
        if (normalizedIngredient) existing.normalizedIngredient = normalizedIngredient;
        if (pantryIngredients.length > 0) existing.pantryIngredients = pantryIngredients;
        if (typeof r.isBookmarked === 'boolean') {
          existing.isBookmarked = r.isBookmarked;
        } else if (isBookmarked) {
          existing.isBookmarked = true;
        }
        saved = await existing.save();
      } else {
        saved = await RecipeHistory.create({
          userId,
          recipeId,
          title,
          description,
          imageUrl,
          ingredients,
          instructions,
          nutrition,
          timeMinutes,
          prepTime,
          cookTime,
          servings,
          difficulty,
          tags,
          recipeSource,
          generationMode,
          sourceProduct,
          normalizedIngredient,
          pantryIngredients,
          isBookmarked: isBookmarked || false,
          isViewed: true,
          generatedAt: now,
        });
      }

      console.log('\n==============================================');
      console.log('[RECIPE SAVE TRACE]');
      console.log(`recipeId = ${saved.recipeId}`);
      console.log(`recipeTitle = ${saved.title}`);
      console.log(`userId = ${userId}`);
      console.log(`source = ${saved.recipeSource}`);
      console.log(`isAlreadySaved = ${isAlreadySaved}`);
      console.log('saveRequestStarted = true');
      console.log('saveResponseStatus = 200');
      console.log('saveSuccessful = true');
      console.log('==============================================\n');

      savedRecords.push(saved);
    }

    return res.status(200).json({
      success: true,
      message: `Saved ${savedRecords.length} recipe(s) to history.`,
      data: {
        recipes: savedRecords,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Retrieve recipe history for authenticated user (ordered newest -> oldest)
 * GET /api/recipes/history
 */
const getRecipeHistory = async (req, res, next) => {
  try {
    const userId = req.user._id || req.user.id;
    const limit = req.query.limit ? parseInt(req.query.limit, 10) : null;
    const tab = req.query.tab ? req.query.tab.toLowerCase() : 'all';

    let filter = { userId };
    if (tab === 'saved') {
      filter.isBookmarked = true;
    } else if (tab === 'viewed') {
      filter.isViewed = true;
    }

    let query = RecipeHistory.find(filter).sort({ generatedAt: -1 });
    if (limit && !isNaN(limit) && limit > 0) {
      query = query.limit(limit);
    }

    const [recipes, totalCount] = await Promise.all([
      query.exec(),
      RecipeHistory.countDocuments(filter),
    ]);

    console.log('\n==============================================');
    console.log('[HISTORY LOAD TRACE]');
    console.log(`userId = ${userId}`);
    console.log(`savedRecipeCount = ${recipes.filter(r => r.isBookmarked).length}`);
    console.log(`totalCount = ${recipes.length}`);
    console.log('==============================================\n');

    return res.status(200).json({
      success: true,
      data: {
        recipes,
        totalCount,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Toggle bookmark status for a recipe in history
 * PATCH /api/recipes/history/:id/bookmark
 */
const toggleBookmark = async (req, res, next) => {
  try {
    const userId = req.user._id || req.user.id;
    const { id } = req.params;

    const item = await RecipeHistory.findOne({
      userId,
      $or: [{ _id: id.match(/^[0-9a-fA-F]{24}$/) ? id : null }, { recipeId: id }].filter(Boolean),
    });

    if (!item) {
      return res.status(404).json({
        success: false,
        status: 404,
        message: 'Recipe history item not found.',
      });
    }

    item.isBookmarked = typeof req.body.isBookmarked === 'boolean' ? req.body.isBookmarked : !item.isBookmarked;
    await item.save();

    return res.status(200).json({
      success: true,
      data: {
        recipe: item,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Delete a single recipe from history
 * DELETE /api/recipes/history/:id
 */
const deleteRecipeHistory = async (req, res, next) => {
  try {
    const userId = req.user._id || req.user.id;
    const { id } = req.params;

    const result = await RecipeHistory.findOneAndDelete({
      userId,
      $or: [{ _id: id.match(/^[0-9a-fA-F]{24}$/) ? id : null }, { recipeId: id }].filter(Boolean),
    });

    if (!result) {
      return res.status(404).json({
        success: false,
        status: 404,
        message: 'Recipe history item not found or unauthorized.',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Recipe removed from history.',
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Clear all recipe history for the authenticated user
 * DELETE /api/recipes/history
 */
const clearRecipeHistory = async (req, res, next) => {
  try {
    const userId = req.user._id || req.user.id;
    await RecipeHistory.deleteMany({ userId });

    return res.status(200).json({
      success: true,
      message: 'Recipe history cleared successfully.',
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  saveRecipeHistory,
  getRecipeHistory,
  toggleBookmark,
  deleteRecipeHistory,
  clearRecipeHistory,
};
