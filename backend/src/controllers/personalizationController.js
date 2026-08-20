const Personalization = require('../models/Personalization');
const User = require('../models/User');

/**
 * @desc    Get current user's personalization data
 * @route   GET /api/personalization
 * @access  Private (Protected by JWT)
 */
const getPersonalization = async (req, res, next) => {
  try {
    const personalization = await Personalization.findOne({ userId: req.user._id });

    res.status(200).json({
      success: true,
      data: {
        personalization: personalization ? personalization.toJSON() : null,
        isCompleted: personalization ? Boolean(personalization.isCompleted) : false,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Create or update full personalization data
 * @route   PUT /api/personalization
 * @access  Private (Protected by JWT)
 */
const savePersonalization = async (req, res, next) => {
  try {
    const {
      fullName,
      age,
      gender,
      height,
      weight,
      goals,
      activityLevel,
      sleepHours,
      waterIntake,
      healthConditions,
      pregnantOrBreastfeeding,
      dietType,
      allergies,
      dislikedFoods,
      nutritionFocus,
      productAlerts,
      aiFeatures,
      isCompleted = true,
    } = req.body;

    const updateDoc = {
      userId: req.user._id,
      ...(fullName !== undefined && { fullName: String(fullName).trim() }),
      ...(age !== undefined && { age: String(age).trim() }),
      ...(gender !== undefined && { gender: String(gender).trim() }),
      ...(height !== undefined && { height: String(height).trim() }),
      ...(weight !== undefined && { weight: String(weight).trim() }),
      ...(goals !== undefined && { goals: Array.isArray(goals) ? goals : [] }),
      ...(activityLevel !== undefined && { activityLevel: String(activityLevel).trim() }),
      ...(sleepHours !== undefined && { sleepHours: String(sleepHours).trim() }),
      ...(waterIntake !== undefined && { waterIntake: String(waterIntake).trim() }),
      ...(healthConditions !== undefined && { healthConditions: Array.isArray(healthConditions) ? healthConditions : [] }),
      ...(pregnantOrBreastfeeding !== undefined && { pregnantOrBreastfeeding: Boolean(pregnantOrBreastfeeding) }),
      ...(dietType !== undefined && { dietType: String(dietType).trim() }),
      ...(allergies !== undefined && { allergies: Array.isArray(allergies) ? allergies : [] }),
      ...(dislikedFoods !== undefined && { dislikedFoods: Array.isArray(dislikedFoods) ? dislikedFoods : [] }),
      ...(nutritionFocus !== undefined && { nutritionFocus: Array.isArray(nutritionFocus) ? nutritionFocus : [] }),
      ...(productAlerts !== undefined && { productAlerts }),
      ...(aiFeatures !== undefined && { aiFeatures }),
      isCompleted: Boolean(isCompleted),
      completedAt: isCompleted ? new Date() : undefined,
    };

    const savedPersonalization = await Personalization.findOneAndUpdate(
      { userId: req.user._id },
      { $set: updateDoc },
      { new: true, upsert: true, runValidators: true, setDefaultsOnInsert: true }
    );

    // Sync relevant user fields in User model
    const userUpdates = {};
    if (fullName && fullName.trim()) userUpdates.fullName = fullName.trim();
    if (gender) userUpdates.gender = gender.trim();
    if (height) userUpdates.height = height.trim();
    if (weight) userUpdates.weight = weight.trim();
    if (dietType) userUpdates.dietType = dietType.trim();

    if (Object.keys(userUpdates).length > 0) {
      await User.findByIdAndUpdate(req.user._id, { $set: userUpdates });
    }

    res.status(200).json({
      success: true,
      message: 'Personalization preferences saved successfully.',
      data: {
        personalization: savedPersonalization.toJSON(),
        isCompleted: savedPersonalization.isCompleted,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Partially update personalization fields
 * @route   PATCH /api/personalization
 * @access  Private (Protected by JWT)
 */
const patchPersonalization = async (req, res, next) => {
  try {
    const allowedFields = [
      'fullName',
      'age',
      'gender',
      'height',
      'weight',
      'goals',
      'activityLevel',
      'sleepHours',
      'waterIntake',
      'healthConditions',
      'pregnantOrBreastfeeding',
      'dietType',
      'allergies',
      'dislikedFoods',
      'nutritionFocus',
      'productAlerts',
      'aiFeatures',
      'isCompleted',
    ];

    const updates = {};
    for (const field of allowedFields) {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field];
      }
    }

    if (updates.isCompleted) {
      updates.completedAt = new Date();
    }

    const savedPersonalization = await Personalization.findOneAndUpdate(
      { userId: req.user._id },
      { $set: updates },
      { new: true, upsert: true, runValidators: true, setDefaultsOnInsert: true }
    );

    res.status(200).json({
      success: true,
      message: 'Personalization updated successfully.',
      data: {
        personalization: savedPersonalization.toJSON(),
        isCompleted: savedPersonalization.isCompleted,
      },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getPersonalization,
  savePersonalization,
  patchPersonalization,
};
