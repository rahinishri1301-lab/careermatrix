const User = require('../models/User');
const asyncHandler = require('../utils/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');
const generateToken = require('../utils/generateToken');
const { sendResponse } = require('../utils/apiResponse');
const { sendEmail } = require('../services/emailService');
const { hashToken } = require('../services/tokenService');

/**
 * @desc    Register a new user (student, alumni, or admin)
 * @route   POST /api/auth/register
 * @access  Public
 */
const register = asyncHandler(async (req, res, next) => {
  const { name, email, password, role } = req.body;

  const existingUser = await User.findOne({ email: email.toLowerCase() });
  if (existingUser) {
    return next(new ErrorResponse('An account with this email already exists', 400));
  }

  const user = await User.create({
    name,
    email,
    password,
    role: role || 'student',
  });

  const token = generateToken(user._id, user.role);

  return sendResponse(res, 201, true, 'User registered successfully', {
    user,
    token,
  });
});

/**
 * @desc    Login user and return JWT (role-based)
 * @route   POST /api/auth/login
 * @access  Public
 */
const login = asyncHandler(async (req, res, next) => {
  const { email, password, role } = req.body;

  // Explicitly select password since schema excludes it by default
  const user = await User.findOne({ email: email.toLowerCase() }).select('+password');

  if (!user) {
    return next(new ErrorResponse('Invalid email or password', 401));
  }

  if (!user.isActive) {
    return next(new ErrorResponse('This account has been deactivated. Contact admin.', 403));
  }

  const isMatch = await user.matchPassword(password);
  if (!isMatch) {
    return next(new ErrorResponse('Invalid email or password', 401));
  }

  // Optional role-based login check: if the client specifies which portal
  // they are logging in from (student/alumni/admin), enforce it matches.
  if (role && role !== user.role) {
    return next(
      new ErrorResponse(`No ${role} account found with these credentials`, 401)
    );
  }

  user.lastLogin = Date.now();
  await user.save({ validateBeforeSave: false });

  const token = generateToken(user._id, user.role);

  return sendResponse(res, 200, true, 'Login successful', {
    user,
    token,
  });
});

/**
 * @desc    Get currently logged-in user
 * @route   GET /api/auth/me
 * @access  Private
 */
const getMe = asyncHandler(async (req, res) => {
  return sendResponse(res, 200, true, 'Current user fetched', { user: req.user });
});

/**
 * @desc    Send password reset token to user's email
 * @route   POST /api/auth/forgot-password
 * @access  Public
 */
const forgotPassword = asyncHandler(async (req, res, next) => {
  const { email } = req.body;

  const user = await User.findOne({ email: email.toLowerCase() });

  // Respond with a generic message regardless of whether the user exists,
  // to avoid leaking which emails are registered.
  const genericMessage = 'If an account exists for this email, a password reset link has been sent.';

  if (!user) {
    return sendResponse(res, 200, true, genericMessage);
  }

  const resetToken = user.getResetPasswordToken();
  await user.save({ validateBeforeSave: false });

  const resetUrl = `${process.env.CLIENT_URL}/reset-password/${resetToken}`;

  const message = `You requested a password reset for your Career Matrix account.\n\nPlease use the link below (valid for ${process.env.RESET_PASSWORD_EXPIRE || 10} minutes):\n\n${resetUrl}\n\nIf you did not request this, please ignore this email.`;

  try {
    await sendEmail({
      to: user.email,
      subject: 'Career Matrix - Password Reset Request',
      text: message,
      html: `<p>You requested a password reset for your Career Matrix account.</p>
             <p>Click the link below (valid for ${process.env.RESET_PASSWORD_EXPIRE || 10} minutes):</p>
             <p><a href="${resetUrl}">${resetUrl}</a></p>
             <p>If you did not request this, please ignore this email.</p>`,
    });

    return sendResponse(res, 200, true, genericMessage);
  } catch (err) {
    // Roll back the token if the email fails to send
    user.resetPasswordToken = undefined;
    user.resetPasswordExpire = undefined;
    await user.save({ validateBeforeSave: false });

    return next(new ErrorResponse('Email could not be sent. Please try again later.', 500));
  }
});

/**
 * @desc    Reset password using the token emailed to the user
 * @route   PUT /api/auth/reset-password/:resettoken
 * @access  Public
 */
const resetPassword = asyncHandler(async (req, res, next) => {
  const hashedToken = hashToken(req.params.resettoken);

  const user = await User.findOne({
    resetPasswordToken: hashedToken,
    resetPasswordExpire: { $gt: Date.now() },
  });

  if (!user) {
    return next(new ErrorResponse('Invalid or expired reset token', 400));
  }

  user.password = req.body.password;
  user.resetPasswordToken = undefined;
  user.resetPasswordExpire = undefined;
  await user.save();

  const token = generateToken(user._id, user.role);

  return sendResponse(res, 200, true, 'Password reset successful', { token });
});

module.exports = {
  register,
  login,
  getMe,
  forgotPassword,
  resetPassword,
};
