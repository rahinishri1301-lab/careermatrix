const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');

const UserSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
      minlength: [2, 'Name must be at least 2 characters'],
      maxlength: [100, 'Name cannot exceed 100 characters'],
    },
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      lowercase: true,
      trim: true,
      match: [
        /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
        'Please provide a valid email address',
      ],
    },
    password: {
      type: String,
      required: [true, 'Password is required'],
      minlength: [8, 'Password must be at least 8 characters'],
      select: false, // never return password by default
    },
    role: {
      type: String,
      enum: {
        values: ['student', 'alumni', 'mentor', 'company', 'admin'],
        message: 'Role must be one of: student, alumni, mentor, company, admin',
      },
      default: 'student',
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    lastLogin: {
      type: Date,
    },
    // Legacy token-based reset fields (kept for backward compatibility)
    resetPasswordToken: {
      type: String,
      select: false,
    },
    resetPasswordExpire: {
      type: Date,
      select: false,
    },
    // OTP-based reset fields
    resetPasswordOTP: {
      type: String, // bcrypt-hashed OTP
      select: false,
    },
    resetPasswordOTPExpires: {
      type: Date,
      select: false,
    },
    resetPasswordVerified: {
      type: Boolean,
      default: false,
      select: false,
    },
    resetPasswordOTPSentAt: {
      type: Date,
      select: false,
    },
  },
  {
    timestamps: true,
  }
);

// Index for faster role-based queries
UserSchema.index({ role: 1 });

// Hash password before saving, only if it was modified
UserSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();

  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Instance method: compare entered password with hashed password
UserSchema.methods.matchPassword = async function (enteredPassword) {
  return bcrypt.compare(enteredPassword, this.password);
};

// Instance method: generate and hash password reset token (legacy)
UserSchema.methods.getResetPasswordToken = function () {
  // Plain token sent to the user via email
  const resetToken = crypto.randomBytes(32).toString('hex');

  // Hashed version stored in DB
  this.resetPasswordToken = crypto
    .createHash('sha256')
    .update(resetToken)
    .digest('hex');

  const expireMinutes = Number(process.env.RESET_PASSWORD_EXPIRE) || 10;
  this.resetPasswordExpire = Date.now() + expireMinutes * 60 * 1000;

  return resetToken;
};

// Instance method: generate a secure 6-digit OTP for password reset.
// Returns the plain OTP (to be emailed). The bcrypt-hashed version is
// stored in the DB so the plain OTP is never persisted.
UserSchema.methods.generateResetOTP = async function () {
  // Generate a cryptographically secure 6-digit OTP
  const otp = crypto.randomInt(100000, 999999).toString();

  // Hash it before storing (same security principle as passwords)
  const salt = await bcrypt.genSalt(10);
  this.resetPasswordOTP = await bcrypt.hash(otp, salt);

  const expireMinutes = Number(process.env.RESET_PASSWORD_EXPIRE) || 10;
  this.resetPasswordOTPExpires = new Date(Date.now() + expireMinutes * 60 * 1000);
  this.resetPasswordVerified = false;
  this.resetPasswordOTPSentAt = new Date();

  return otp;
};

// Instance method: verify a plain OTP against the stored hash
UserSchema.methods.matchResetOTP = async function (enteredOTP) {
  if (!this.resetPasswordOTP) return false;
  return bcrypt.compare(enteredOTP, this.resetPasswordOTP);
};

// Instance method: clear all OTP/reset fields
UserSchema.methods.clearResetFields = function () {
  this.resetPasswordOTP = undefined;
  this.resetPasswordOTPExpires = undefined;
  this.resetPasswordVerified = false;
  this.resetPasswordOTPSentAt = undefined;
  this.resetPasswordToken = undefined;
  this.resetPasswordExpire = undefined;
};

// Never expose sensitive fields even if accidentally selected
UserSchema.methods.toJSON = function () {
  const user = this.toObject();
  delete user.password;
  delete user.resetPasswordToken;
  delete user.resetPasswordExpire;
  delete user.resetPasswordOTP;
  delete user.resetPasswordOTPExpires;
  delete user.resetPasswordVerified;
  delete user.resetPasswordOTPSentAt;
  delete user.__v;
  return user;
};

module.exports = mongoose.model('User', UserSchema);

