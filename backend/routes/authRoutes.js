const express = require('express');
const { body } = require('express-validator');
const {
  register,
  login,
  getMe,
  forgotPassword,
  verifyResetOTP,
  resetPassword,
  resendResetOTP,
} = require('../controllers/authController');
const { protect } = require('../middleware/authMiddleware');
const { validate } = require('../middleware/validateMiddleware');

const router = express.Router();

// @route   POST /api/auth/register
router.post(
  '/register',
  [
    body('name').trim().notEmpty().withMessage('Name is required'),
    body('email').isEmail().withMessage('Please provide a valid email').normalizeEmail(),
    body('password')
      .isLength({ min: 8 })
      .withMessage('Password must be at least 8 characters long'),
    body('role')
      .optional()
      .isIn(['student', 'alumni', 'mentor', 'company', 'admin'])
      .withMessage('Role must be student, alumni, mentor, company, or admin'),
    body('company').optional().trim(),
  ],
  validate,
  register
);

// @route   POST /api/auth/login
router.post(
  '/login',
  [
    body('email').isEmail().withMessage('Please provide a valid email').normalizeEmail(),
    body('password').notEmpty().withMessage('Password is required'),
    body('role')
      .optional()
      .isIn(['student', 'alumni', 'mentor', 'company', 'admin'])
      .withMessage('Role must be student, alumni, mentor, company, or admin'),
  ],
  validate,
  login
);

// @route   GET /api/auth/me
router.get('/me', protect, getMe);

// @route   POST /api/auth/forgot-password
router.post(
  '/forgot-password',
  [body('email').isEmail().withMessage('Please provide a valid email').normalizeEmail()],
  validate,
  forgotPassword
);

// @route   POST /api/auth/verify-reset-otp
router.post(
  '/verify-reset-otp',
  [
    body('email').isEmail().withMessage('Please provide a valid email').normalizeEmail(),
    body('otp')
      .trim()
      .notEmpty().withMessage('OTP is required')
      .isLength({ min: 6, max: 6 }).withMessage('OTP must be 6 digits'),
  ],
  validate,
  verifyResetOTP
);

// @route   PUT /api/auth/reset-password
router.put(
  '/reset-password',
  [
    body('email').isEmail().withMessage('Please provide a valid email').normalizeEmail(),
    body('password')
      .isLength({ min: 8 })
      .withMessage('Password must be at least 8 characters long'),
  ],
  validate,
  resetPassword
);

// @route   POST /api/auth/resend-reset-otp
router.post(
  '/resend-reset-otp',
  [body('email').isEmail().withMessage('Please provide a valid email').normalizeEmail()],
  validate,
  resendResetOTP
);

module.exports = router;

