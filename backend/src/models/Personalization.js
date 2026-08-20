const mongoose = require('mongoose');

const personalizationSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
      index: true,
    },
    fullName: {
      type: String,
      trim: true,
      default: '',
    },
    age: {
      type: String,
      trim: true,
      default: '',
    },
    gender: {
      type: String,
      default: '',
    },
    height: {
      type: String,
      trim: true,
      default: '',
    },
    weight: {
      type: String,
      trim: true,
      default: '',
    },
    goals: {
      type: [String],
      default: [],
    },
    activityLevel: {
      type: String,
      default: '',
    },
    sleepHours: {
      type: String,
      default: '',
    },
    waterIntake: {
      type: String,
      default: '',
    },
    healthConditions: {
      type: [String],
      default: [],
    },
    pregnantOrBreastfeeding: {
      type: Boolean,
      default: false,
    },
    dietType: {
      type: String,
      default: '',
    },
    allergies: {
      type: [String],
      default: [],
    },
    dislikedFoods: {
      type: [String],
      default: [],
    },
    nutritionFocus: {
      type: [String],
      default: [],
    },
    productAlerts: {
      type: Map,
      of: Boolean,
      default: () => ({
        'Alert me if a product contains my allergens': true,
        'Warn me about high sugar products': true,
        'Warn me about high sodium': true,
        'Warn me about ultra-processed foods': true,
        'Suggest healthier alternatives automatically': true,
      }),
    },
    aiFeatures: {
      type: Map,
      of: Boolean,
      default: () => ({
        'Personalized recipes': true,
        'Smart shopping suggestions': true,
        'Pantry expiry reminders': true,
        'Weekly nutrition insights': true,
      }),
    },
    isCompleted: {
      type: Boolean,
      default: false,
    },
    completedAt: {
      type: Date,
    },
  },
  {
    timestamps: true,
  }
);

personalizationSchema.set('toJSON', {
  transform: function (doc, ret) {
    delete ret.__v;
    return ret;
  },
});

const Personalization = mongoose.model('Personalization', personalizationSchema);

module.exports = Personalization;
