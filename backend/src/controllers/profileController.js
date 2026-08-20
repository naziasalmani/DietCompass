const User = require('../models/User');
const Personalization = require('../models/Personalization');

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

module.exports = {
  getProfile,
  updateProfile,
};
