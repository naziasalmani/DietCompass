const mongoose = require('mongoose');

const scanHistorySchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User ID is required'],
      index: true,
    },
    barcode: {
      type: String,
      trim: true,
      default: '',
    },
    productName: {
      type: String,
      required: [true, 'Product name is required'],
      trim: true,
    },
    brand: {
      type: String,
      trim: true,
      default: '',
    },
    imageUrl: {
      type: String,
      trim: true,
      default: '',
    },
    score: {
      type: Number,
      default: 85,
      min: 0,
      max: 100,
    },
    ingredients: {
      type: String,
      default: '',
    },
    allergens: {
      type: [String],
      default: [],
    },
    nutrients: {
      calories: { type: Number, default: null },
      protein: { type: Number, default: null },
      carbohydrates: { type: Number, default: null },
      fat: { type: Number, default: null },
      fiber: { type: Number, default: null },
      sugar: { type: Number, default: null },
      sodium: { type: Number, default: null },
    },
    scannedAt: {
      type: Date,
      default: Date.now,
      index: true,
    },
  },
  {
    timestamps: true,
  }
);

// Compound index for querying user scan history sorted newest first
scanHistorySchema.index({ userId: 1, scannedAt: -1 });

module.exports = mongoose.model('ScanHistory', scanHistorySchema);
