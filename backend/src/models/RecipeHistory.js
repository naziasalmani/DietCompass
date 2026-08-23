const mongoose = require('mongoose');

const recipeHistorySchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User ID is required'],
      index: true,
    },
    recipeId: {
      type: String,
      required: [true, 'Recipe ID is required'],
      trim: true,
    },
    title: {
      type: String,
      required: [true, 'Recipe title is required'],
      trim: true,
    },
    description: {
      type: String,
      default: '',
      trim: true,
    },
    imageUrl: {
      type: String,
      default: '',
      trim: true,
    },
    ingredients: {
      type: [mongoose.Schema.Types.Mixed],
      default: [],
    },
    instructions: {
      type: [String],
      default: [],
    },
    nutrition: {
      calories: { type: Number, default: null },
      protein: { type: Number, default: null },
      carbs: { type: Number, default: null },
      fat: { type: Number, default: null },
      fiber: { type: Number, default: null },
    },
    timeMinutes: {
      type: Number,
      default: 15,
    },
    prepTime: {
      type: String,
      default: '15 mins',
    },
    cookTime: {
      type: String,
      default: '',
    },
    servings: {
      type: Number,
      default: 2,
    },
    difficulty: {
      type: String,
      default: 'Easy',
    },
    tags: {
      type: [String],
      default: [],
    },
    recipeSource: {
      type: String,
      default: 'api',
      trim: true,
    },
    generationMode: {
      type: String,
      enum: ['product', 'pantry'],
      default: 'pantry',
    },
    sourceProduct: {
      type: String,
      default: '',
      trim: true,
    },
    normalizedIngredient: {
      type: String,
      default: '',
      trim: true,
    },
    pantryIngredients: {
      type: [String],
      default: [],
    },
    isBookmarked: {
      type: Boolean,
      default: false,
    },
    isViewed: {
      type: Boolean,
      default: true,
    },
    generatedAt: {
      type: Date,
      default: Date.now,
      index: true,
    },
  },
  {
    timestamps: true,
  }
);

// Compound index for querying user recipe history sorted newest first
recipeHistorySchema.index({ userId: 1, generatedAt: -1 });

module.exports = mongoose.model('RecipeHistory', recipeHistorySchema);
