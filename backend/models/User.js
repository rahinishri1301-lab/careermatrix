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
      minlength: [6, 'Password must be at least 6 characters'],
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
    resetPasswordToken: {
      type: String,
      select: false,
    },
    resetPasswordExpire: {
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

// Instance method: generate and hash password reset token
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

// Never expose sensitive fields even if accidentally selected
UserSchema.methods.toJSON = function () {
  const user = this.toObject();
  delete user.password;
  delete user.resetPasswordToken;
  delete user.resetPasswordExpire;
  delete user.__v;
  return user;
};

module.exports = mongoose.model('User', UserSchema);
