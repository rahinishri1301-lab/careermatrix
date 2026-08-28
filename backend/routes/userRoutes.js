const express = require('express');
const { body, param } = require('express-validator');
const {
  getAllUsers,
  getUserById,
  createUser,
  updateUser,
  deleteUser,
  getCandidates,
  getAlumni,
} = require('../controllers/userController');
const { protect } = require('../middleware/authMiddleware');
const { authorize } = require('../middleware/roleMiddleware');
const { validate } = require('../middleware/validateMiddleware');

const router = express.Router();

// @route   GET /api/users/candidates
// NOTE: defined before the admin-only block below so company/alumni users
// (not just admins) can browse candidates.
router.get('/candidates', protect, authorize('company', 'alumni', 'admin'), getCandidates);

// @route   GET /api/users/alumni
// Any authenticated user (students especially) can browse alumni to find a
// mentor. Also defined before the admin-only block below.
router.get('/alumni', protect, getAlumni);

// All routes below require authentication + admin role
router.use(protect, authorize('admin'));

// @route   GET /api/users
router.get('/', getAllUsers);

// @route   POST /api/users
// Admin creates a Student/Alumni/Mentor/Company/Admin account directly.
// Uses the same User model + bcrypt hashing as /api/auth/register.
router.post(
  '/',
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
  ],
  validate,
  createUser
);

// @route   GET /api/users/:id
router.get(
  '/:id',
  [param('id').isMongoId().withMessage('Invalid user id')],
  validate,
  getUserById
);

// @route   PUT /api/users/:id
router.put(
  '/:id',
  [
    param('id').isMongoId().withMessage('Invalid user id'),
    body('email').optional().isEmail().withMessage('Please provide a valid email'),
    body('role')
      .optional()
      .isIn(['student', 'alumni', 'mentor', 'company', 'admin'])
      .withMessage('Role must be student, alumni, mentor, company, or admin'),
    body('isActive').optional().isBoolean().withMessage('isActive must be a boolean'),
  ],
  validate,
  updateUser
);

// @route   DELETE /api/users/:id
router.delete(
  '/:id',
  [param('id').isMongoId().withMessage('Invalid user id')],
  validate,
  deleteUser
);

module.exports = router;
