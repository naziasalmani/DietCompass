const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');

const userSchema = new mongoose.Schema(
  {
    fullName: {
      type: String,
      required: [true, 'Full name is required'],
      trim: true,
      minlength: [2, 'Full name must be at least 2 characters'],
      maxlength: [100, 'Full name cannot exceed 100 characters'],
    },
    username: {
      type: String,
      required: [true, 'Username is required'],
      unique: true,
      trim: true,
      lowercase: true,
      minlength: [3, 'Username must be at least 3 characters'],
      maxlength: [30, 'Username cannot exceed 30 characters'],
      match: [/^[a-zA-Z0-9_]+$/, 'Username can only contain alphanumeric characters and underscores'],
      index: true,
    },
    email: {
      type: String,
      required: [true, 'Email address is required'],
      unique: true,
      trim: true,
      lowercase: true,
      match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,})+$/, 'Please provide a valid email address'],
      index: true,
    },
    phone: {
      type: String,
      trim: true,
      default: '',
    },
    countryCode: {
      type: String,
      trim: true,
      default: '+91',
    },
    password: {
      type: String,
      required: function () {
        return this.authProvider !== 'google';
      },
      minlength: [8, 'Password must be at least 8 characters long'],
      select: false, // Never return password hash in regular queries
    },
    authProvider: {
      type: String,
      enum: ['password', 'google'],
      default: 'password',
    },
    googleId: {
      type: String,
      unique: true,
      sparse: true,
      select: false,
    },
    accountType: {
      type: String,
      enum: {
        values: ['individual', 'family'],
        message: '{VALUE} is not a valid account type. Must be either "individual" or "family"',
      },
      default: 'individual',
    },
    avatarUrl: {
      type: String,
      default: '',
    },
    badgeLabel: {
      type: String,
      default: 'Healthy Explorer',
    },
    dateOfBirth: {
      type: String,
      default: '',
    },
    gender: {
      type: String,
      default: '',
    },
    country: {
      type: String,
      default: 'India',
    },
    city: {
      type: String,
      default: '',
    },
    address: {
      type: String,
      default: '',
    },
    occupation: {
      type: String,
      default: '',
    },
    dietType: {
      type: String,
      default: 'Vegetarian',
    },
    height: {
      type: String,
      default: '',
    },
    weight: {
      type: String,
      default: '',
    },
    healthScore: {
      type: Number,
      default: 85,
    },
    streakDays: {
      type: Number,
      default: 1,
    },
    isEmailVerified: {
      type: Boolean,
      default: false,
    },
    resetPasswordToken: {
      type: String,
      select: false,
    },
    resetPasswordExpires: {
      type: Date,
      select: false,
    },
  },
  {
    timestamps: true,
  }
);

/**
 * Pre-save middleware: Automatically hash password if modified
 */
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) {
    return next();
  }

  try {
    const salt = await bcrypt.genSalt(12);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

/**
 * Instance method: Compare entered password with bcrypt hash in DB
 */
userSchema.methods.comparePassword = async function (enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

/**
 * Instance method: Generate cryptographically secure password reset token (SHA-256 hashed in DB)
 */
userSchema.methods.generatePasswordResetToken = function () {
  // Generate 32 bytes (64-character hex string) random token
  const resetToken = crypto.randomBytes(32).toString('hex');

  // Hash token with SHA-256 and store in database
  this.resetPasswordToken = crypto
    .createHash('sha256')
    .update(resetToken)
    .digest('hex');

  // Set expiration (default: 60 minutes)
  const expirationMinutes = parseInt(process.env.RESET_PASSWORD_EXPIRES_MINUTES, 10) || 60;
  this.resetPasswordExpires = Date.now() + expirationMinutes * 60 * 1000;

  // Return raw unhashed token to be sent to user's email
  return resetToken;
};

/**
 * Clean serialization: Remove sensitive fields when converting to JSON
 */
userSchema.set('toJSON', {
  transform: function (doc, ret) {
    delete ret.password;
    delete ret.resetPasswordToken;
    delete ret.resetPasswordExpires;
    delete ret.__v;
    return ret;
  },
});

const User = mongoose.model('User', userSchema);

module.exports = User;
