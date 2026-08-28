const User = require('../models/User');
const Profile = require('../models/Profile');
const asyncHandler = require('../utils/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');
const generateToken = require('../utils/generateToken');
const { sendResponse } = require('../utils/apiResponse');
const { sendEmail } = require('../services/emailService');

/**
 * @desc    Register a new user (student, alumni, mentor, company, or admin)
 * @route   POST /api/auth/register
 * @access  Public
 */
const register = asyncHandler(async (req, res, next) => {
  const { name, email, password, role, company } = req.body;

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

  if (company && company.trim()) {
    await Profile.create({
      user: user._id,
      company: company.trim(),
    });
  }

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
 * @desc    Send a 6-digit OTP to the user's email for password reset
 * @route   POST /api/auth/forgot-password
 * @access  Public
 */
const forgotPassword = asyncHandler(async (req, res, next) => {
  const { email } = req.body;

  const user = await User.findOne({ email: email.toLowerCase() }).select(
    '+resetPasswordOTPSentAt +resetPasswordOTP +resetPasswordOTPExpires +resetPasswordVerified'
  );

  // Generic message — never reveal whether the email exists
  const genericMessage = 'If an account exists for this email, a password reset OTP has been sent.';

  if (!user) {
    return sendResponse(res, 200, true, genericMessage);
  }

  // Rate limit: 60 seconds between OTP requests
  if (user.resetPasswordOTPSentAt) {
    const secondsSinceLast = (Date.now() - user.resetPasswordOTPSentAt.getTime()) / 1000;
    if (secondsSinceLast < 60) {
      const wait = Math.ceil(60 - secondsSinceLast);
      return next(new ErrorResponse(`Please wait ${wait} seconds before requesting another OTP.`, 429));
    }
  }

  const otp = await user.generateResetOTP();
  await user.save({ validateBeforeSave: false });

  const expiryMinutes = process.env.RESET_PASSWORD_EXPIRE || 10;

  const htmlContent = `
    <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 480px; margin: 0 auto; padding: 32px; background: #f6f9ff; border-radius: 16px;">
      <div style="text-align: center; margin-bottom: 24px;">
        <h1 style="color: #1957E0; margin: 0; font-size: 24px;">Career Matrix</h1>
        <p style="color: #677289; margin: 4px 0 0; font-size: 14px;">Password Reset OTP</p>
      </div>
      <div style="background: #ffffff; border-radius: 12px; padding: 28px; box-shadow: 0 2px 8px rgba(0,0,0,0.06);">
        <p style="color: #0E1B33; font-size: 15px; margin: 0 0 16px;">Hello,</p>
        <p style="color: #5B6B85; font-size: 14px; margin: 0 0 20px;">You requested a password reset for your Career Matrix account. Use the OTP below to verify your identity:</p>
        <div style="text-align: center; margin: 24px 0;">
          <span style="display: inline-block; font-size: 32px; font-weight: 800; letter-spacing: 8px; color: #1957E0; background: #EAF1FF; padding: 16px 32px; border-radius: 12px;">${otp}</span>
        </div>
        <p style="color: #5B6B85; font-size: 13px; margin: 0 0 8px; text-align: center;">This OTP is valid for <strong>${expiryMinutes} minutes</strong>.</p>
        <p style="color: #677289; font-size: 12px; margin: 20px 0 0; text-align: center;">If you did not request this, please ignore this email. Your password will remain unchanged.</p>
      </div>
      <p style="color: #9CA3AF; font-size: 11px; text-align: center; margin: 20px 0 0;">© Career Matrix · AI-Powered Career Ecosystem</p>
    </div>`;

  const textContent = `Career Matrix - Password Reset OTP\n\nYou requested a password reset. Your OTP is: ${otp}\n\nThis OTP is valid for ${expiryMinutes} minutes.\n\nIf you did not request this, please ignore this email.`;

  try {
    await sendEmail({
      to: user.email,
      subject: 'Career Matrix - Password Reset OTP',
      html: htmlContent,
      text: textContent,
    });

    return sendResponse(res, 200, true, genericMessage);
  } catch (err) {
    // Roll back OTP if the email fails to send
    user.clearResetFields();
    await user.save({ validateBeforeSave: false });

    return next(new ErrorResponse('Email could not be sent. Please try again later.', 500));
  }
});

/**
 * @desc    Verify the 6-digit OTP sent to the user's email
 * @route   POST /api/auth/verify-reset-otp
 * @access  Public
 */
const verifyResetOTP = asyncHandler(async (req, res, next) => {
  const { email, otp } = req.body;

  if (!email || !otp) {
    return next(new ErrorResponse('Email and OTP are required.', 400));
  }

  const user = await User.findOne({ email: email.toLowerCase() }).select(
    '+resetPasswordOTP +resetPasswordOTPExpires +resetPasswordVerified'
  );

  if (!user) {
    return next(new ErrorResponse('Invalid email or OTP.', 400));
  }

  // Check if OTP exists
  if (!user.resetPasswordOTP) {
    return next(new ErrorResponse('No OTP was requested for this account. Please request a new one.', 400));
  }

  // Check expiry
  if (!user.resetPasswordOTPExpires || user.resetPasswordOTPExpires < Date.now()) {
    // Clear expired OTP
    user.clearResetFields();
    await user.save({ validateBeforeSave: false });
    return next(new ErrorResponse('OTP has expired. Please request a new one.', 400));
  }

  // Compare OTP (bcrypt)
  const isMatch = await user.matchResetOTP(otp.toString().trim());
  if (!isMatch) {
    return next(new ErrorResponse('Invalid OTP. Please check and try again.', 400));
  }

  // Mark as verified, invalidate the OTP so it can't be reused
  user.resetPasswordVerified = true;
  user.resetPasswordOTP = undefined;
  user.resetPasswordOTPExpires = undefined;
  await user.save({ validateBeforeSave: false });

  return sendResponse(res, 200, true, 'OTP verified successfully. You can now reset your password.');
});

/**
 * @desc    Reset password after OTP verification
 * @route   PUT /api/auth/reset-password
 * @access  Public
 */
const resetPassword = asyncHandler(async (req, res, next) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return next(new ErrorResponse('Email and new password are required.', 400));
  }

  const user = await User.findOne({ email: email.toLowerCase() }).select(
    '+resetPasswordVerified'
  );

  if (!user) {
    return next(new ErrorResponse('User not found.', 404));
  }

  if (!user.resetPasswordVerified) {
    return next(new ErrorResponse('Please verify your OTP before resetting your password.', 400));
  }

  // Set new password (the pre-save hook will hash it)
  user.password = password;
  user.clearResetFields();
  await user.save();

  return sendResponse(res, 200, true, 'Password reset successful. Please login with your new password.');
});

/**
 * @desc    Resend a new OTP (rate-limited to 1 per 60 seconds)
 * @route   POST /api/auth/resend-reset-otp
 * @access  Public
 */
const resendResetOTP = asyncHandler(async (req, res, next) => {
  const { email } = req.body;

  const user = await User.findOne({ email: email.toLowerCase() }).select(
    '+resetPasswordOTPSentAt +resetPasswordOTP +resetPasswordOTPExpires +resetPasswordVerified'
  );

  const genericMessage = 'If an account exists for this email, a new OTP has been sent.';

  if (!user) {
    return sendResponse(res, 200, true, genericMessage);
  }

  // Rate limit: 60 seconds between OTP requests
  if (user.resetPasswordOTPSentAt) {
    const secondsSinceLast = (Date.now() - user.resetPasswordOTPSentAt.getTime()) / 1000;
    if (secondsSinceLast < 60) {
      const wait = Math.ceil(60 - secondsSinceLast);
      return next(new ErrorResponse(`Please wait ${wait} seconds before requesting another OTP.`, 429));
    }
  }

  const otp = await user.generateResetOTP();
  await user.save({ validateBeforeSave: false });

  const expiryMinutes = process.env.RESET_PASSWORD_EXPIRE || 10;

  const htmlContent = `
    <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 480px; margin: 0 auto; padding: 32px; background: #f6f9ff; border-radius: 16px;">
      <div style="text-align: center; margin-bottom: 24px;">
        <h1 style="color: #1957E0; margin: 0; font-size: 24px;">Career Matrix</h1>
        <p style="color: #677289; margin: 4px 0 0; font-size: 14px;">Password Reset OTP (Resend)</p>
      </div>
      <div style="background: #ffffff; border-radius: 12px; padding: 28px; box-shadow: 0 2px 8px rgba(0,0,0,0.06);">
        <p style="color: #0E1B33; font-size: 15px; margin: 0 0 16px;">Hello,</p>
        <p style="color: #5B6B85; font-size: 14px; margin: 0 0 20px;">Here is your new password reset OTP for Career Matrix:</p>
        <div style="text-align: center; margin: 24px 0;">
          <span style="display: inline-block; font-size: 32px; font-weight: 800; letter-spacing: 8px; color: #1957E0; background: #EAF1FF; padding: 16px 32px; border-radius: 12px;">${otp}</span>
        </div>
        <p style="color: #5B6B85; font-size: 13px; margin: 0 0 8px; text-align: center;">This OTP is valid for <strong>${expiryMinutes} minutes</strong>.</p>
        <p style="color: #677289; font-size: 12px; margin: 20px 0 0; text-align: center;">If you did not request this, please ignore this email.</p>
      </div>
      <p style="color: #9CA3AF; font-size: 11px; text-align: center; margin: 20px 0 0;">© Career Matrix · AI-Powered Career Ecosystem</p>
    </div>`;

  const textContent = `Career Matrix - Password Reset OTP (Resend)\n\nYour new OTP is: ${otp}\n\nThis OTP is valid for ${expiryMinutes} minutes.\n\nIf you did not request this, please ignore this email.`;

  try {
    await sendEmail({
      to: user.email,
      subject: 'Career Matrix - Password Reset OTP',
      html: htmlContent,
      text: textContent,
    });

    return sendResponse(res, 200, true, genericMessage);
  } catch (err) {
    user.clearResetFields();
    await user.save({ validateBeforeSave: false });

    return next(new ErrorResponse('Email could not be sent. Please try again later.', 500));
  }
});

module.exports = {
  register,
  login,
  getMe,
  forgotPassword,
  verifyResetOTP,
  resetPassword,
  resendResetOTP,
};

