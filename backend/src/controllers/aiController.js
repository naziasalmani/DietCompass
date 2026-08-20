const User = require('../models/User');
const Personalization = require('../models/Personalization');
const geminiService = require('../services/geminiService');
const recommendationService = require('../services/recommendationService');

/**
 * @desc    Analyze product ingredients, hidden sugars & claims with Gemini AI
 * @route   POST /api/ai/analyze-product
 * @access  Private (Protected by JWT)
 */
const analyzeProduct = async (req, res, next) => {
  try {
    const { name, brand, barcode, ingredients, nutrition, claims, sugar, sodium, protein, fiber, calories, carbohydrates, fat } = req.body;

    if (!name && !ingredients && !barcode) {
      return res.status(400).json({
        success: false,
        message: 'Product must include at least a name, barcode, or ingredient list.',
      });
    }

    const product = {
      name: name || 'Scanned Food Item',
      brand: brand || '',
      barcode: barcode || '',
      ingredients: ingredients || '',
      claims: Array.isArray(claims) ? claims : [],
      nutrition: nutrition || {
        calories: calories ?? null,
        protein: protein ?? null,
        carbohydrates: carbohydrates ?? null,
        fat: fat ?? null,
        fiber: fiber ?? null,
        sugar: sugar ?? null,
        sodium: sodium ?? null,
      },
    };

    // Fetch user context for personalized intelligence
    const [userProfile, personalization] = await Promise.all([
      User.findById(req.user._id).select('-password'),
      Personalization.findOne({ userId: req.user._id }),
    ]);

    const [result, recommendationsResult] = await Promise.all([
      geminiService.analyzeProductNutrition({
        product,
        userProfile,
        personalization,
      }),
      recommendationService.getPersonalizedRecommendations({
        scannedProduct: product,
        candidates: Array.isArray(req.body.candidates) ? req.body.candidates : [],
        userProfile,
        personalization,
        maxResults: 3,
      }),
    ]);

    result.recommendations = recommendationsResult.recommendations || [];
    result.recommendationsSummary = recommendationsResult.summary || '';

    res.status(200).json({
      success: true,
      data: result,
    });
  } catch (error) {
    next(error);
  }
};


/**
 * @desc    Analyze raw OCR / label scan text with Gemini AI
 * @route   POST /api/ai/analyze-ocr
 * @access  Private (Protected by JWT)
 */
const analyzeOcr = async (req, res, next) => {
  try {
    const { ocrText } = req.body;

    if (!ocrText || typeof ocrText !== 'string' || ocrText.trim().length < 3) {
      return res.status(400).json({
        success: false,
        message: 'Please provide valid OCR label text for analysis (at least 3 characters).',
      });
    }

    const [userProfile, personalization] = await Promise.all([
      User.findById(req.user._id).select('-password'),
      Personalization.findOne({ userId: req.user._id }),
    ]);

    const result = await geminiService.analyzeOcrLabel({
      ocrText: ocrText.trim(),
      userProfile,
      personalization,
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
 * @desc    Lookup or enrich food product using Gemini AI
 * @route   POST /api/ai/lookup-product
 * @access  Private (Protected by JWT)
 */
const lookupProduct = async (req, res, next) => {
  try {
    const { barcode, name, ingredients, nutrition, ocrText } = req.body;

    const [userProfile, personalization] = await Promise.all([
      User.findById(req.user._id).select('-password'),
      Personalization.findOne({ userId: req.user._id }),
    ]);

    const result = await geminiService.lookupProductWithGemini({
      barcode,
      name,
      ingredients,
      nutrition,
      ocrText,
      userProfile,
      personalization,
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
 * @desc    Chat with personalized AI Nutrition Coach
 * @route   POST /api/ai/coach
 * @access  Private (Protected by JWT)
 */
const chatCoach = async (req, res, next) => {
  try {
    const { message, history, product } = req.body;

    if (!message || typeof message !== 'string' || message.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a message for the AI Nutrition Coach.',
      });
    }

    const [userProfile, personalization] = await Promise.all([
      User.findById(req.user._id).select('-password'),
      Personalization.findOne({ userId: req.user._id }),
    ]);

    const result = await geminiService.chatWithNutritionCoach({
      userMessage: message.trim(),
      conversationHistory: Array.isArray(history) ? history : [],
      userProfile,
      personalization,
      product,
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
 * @desc    Calculate deterministic personalized product compatibility score
 * @route   POST /api/ai/compatibility
 * @access  Private (Protected by JWT)
 */
const getCompatibility = async (req, res, next) => {
  try {
    const { name, brand, barcode, ingredients, nutrition, claims, sugar, sodium, protein, fiber, calories, carbohydrates, fat, aiAnalysis } = req.body;

    const product = {
      name: name || 'Scanned Food Item',
      brand: brand || '',
      barcode: barcode || '',
      ingredients: ingredients || '',
      claims: Array.isArray(claims) ? claims : [],
      nutrition: nutrition || {
        calories: calories ?? null,
        protein: protein ?? null,
        carbohydrates: carbohydrates ?? null,
        fat: fat ?? null,
        fiber: fiber ?? null,
        sugar: sugar ?? null,
        sodium: sodium ?? null,
      },
    };

    const [userProfile, personalization] = await Promise.all([
      User.findById(req.user._id).select('-password'),
      Personalization.findOne({ userId: req.user._id }),
    ]);

    const compatibility = geminiService.calculatePersonalizedCompatibility({
      product,
      userProfile,
      personalization,
      aiAnalysis: aiAnalysis || {},
    });

    res.status(200).json({
      success: true,
      data: compatibility,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get personalized similar product recommendations
 * @route   POST /api/ai/recommendations
 * @access  Private (Protected by JWT)
 */
const getRecommendations = async (req, res, next) => {
  try {
    const {
      name,
      brand,
      barcode,
      ingredients,
      nutrition,
      sugar,
      sodium,
      protein,
      fiber,
      calories,
      carbohydrates,
      fat,
      candidates,
      maxResults,
    } = req.body;

    if (!name && !ingredients && !barcode) {
      return res.status(400).json({
        success: false,
        message: 'Please provide at least a product name, barcode, or ingredient list to get recommendations.',
      });
    }

    const scannedProduct = {
      name: name || 'Scanned Food Item',
      brand: brand || '',
      barcode: barcode || '',
      ingredients: ingredients || '',
      nutrition: nutrition || {
        calories: calories ?? null,
        protein: protein ?? null,
        carbohydrates: carbohydrates ?? null,
        fat: fat ?? null,
        fiber: fiber ?? null,
        sugar: sugar ?? null,
        sodium: sodium ?? null,
      },
    };

    const [userProfile, personalization] = await Promise.all([
      User.findById(req.user._id).select('-password'),
      Personalization.findOne({ userId: req.user._id }),
    ]);

    const result = await recommendationService.getPersonalizedRecommendations({
      scannedProduct,
      candidates: Array.isArray(candidates) ? candidates : [],
      userProfile,
      personalization,
      maxResults: typeof maxResults === 'number' ? maxResults : 3,
    });

    res.status(200).json({
      success: true,
      data: result,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  analyzeProduct,
  analyzeOcr,
  chatCoach,
  lookupProduct,
  getCompatibility,
  getRecommendations,
};


