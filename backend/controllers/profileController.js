const fs = require('fs');
const path = require('path');
const Profile = require('../models/Profile');
const User = require('../models/User');
const asyncHandler = require('../utils/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');
const { sendResponse } = require('../utils/apiResponse');

/**
 * @desc    Create a profile for the logged-in user
 * @route   POST /api/profile
 * @access  Private
 */
const createProfile = asyncHandler(async (req, res, next) => {
  const existing = await Profile.findOne({ user: req.user._id });
  if (existing) {
    return next(new ErrorResponse('Profile already exists for this user. Use update instead.', 400));
  }

  const {
    bio,
    phone,
    address,
    department,
    graduationYear,
    currentPosition,
    company,
    linkedin,
    github,
    cgpa,
    areaOfInterest,
    careerGoal,
    website,
    industry,
    description,
  } = req.body;

  const profile = await Profile.create({
    user: req.user._id,
    bio,
    phone,
    address,
    department,
    graduationYear,
    currentPosition,
    company,
    linkedin,
    github,
    cgpa,
    areaOfInterest,
    careerGoal,
    website,
    industry,
    description,
  });

  return sendResponse(res, 201, true, 'Profile created successfully', profile);
});

/**
 * @desc    Get the logged-in user's own profile
 * @route   GET /api/profile/me
 * @access  Private
 */
const getMyProfile = asyncHandler(async (req, res, next) => {
  const profile = await Profile.findOne({ user: req.user._id }).populate(
    'user',
    'name email role'
  );

  if (!profile) {
    return next(new ErrorResponse('Profile not found. Please create one first.', 404));
  }

  return sendResponse(res, 200, true, 'Profile fetched successfully', profile);
});

/**
 * @desc    Get any user's profile by userId
 * @route   GET /api/profile/:userId
 * @access  Private
 */
const getProfileByUserId = asyncHandler(async (req, res, next) => {
  const profile = await Profile.findOne({ user: req.params.userId }).populate(
    'user',
    'name email role'
  );

  if (!profile) {
    return next(new ErrorResponse('Profile not found for this user', 404));
  }

  return sendResponse(res, 200, true, 'Profile fetched successfully', profile);
});

/**
 * @desc    Update the logged-in user's profile
 * @route   PUT /api/profile
 * @access  Private
 */
const updateProfile = asyncHandler(async (req, res, next) => {
  const allowedFields = [
    'bio',
    'phone',
    'address',
    'department',
    'graduationYear',
    'currentPosition',
    'company',
    'linkedin',
    'github',
    'cgpa',
    'areaOfInterest',
    'careerGoal',
    'website',
    'industry',
    'description',
  ];

  const updates = {};
  allowedFields.forEach((field) => {
    if (req.body[field] !== undefined) updates[field] = req.body[field];
  });

  // If user passed a updated name/companyName, also update User.name
  const newName = req.body.name || req.body.companyName;
  if (newName && newName.trim()) {
    await User.findByIdAndUpdate(req.user._id, { name: newName.trim() });
  }

  let profile = await Profile.findOneAndUpdate(
    { user: req.user._id },
    updates,
    { new: true, runValidators: true, upsert: true }
  ).populate('user', 'name email role');

  return sendResponse(res, 200, true, 'Profile updated successfully', profile);
});

/**
 * @desc    Upload / replace the logged-in user's profile image
 * @route   PUT /api/profile/upload-image
 * @access  Private
 */
const uploadProfileImage = asyncHandler(async (req, res, next) => {
  if (!req.file) {
    return next(new ErrorResponse('Please upload an image file', 400));
  }

  // Store a forward-slash relative path (e.g. "uploads/profiles/xxx.jpg")
  // so it works directly as a URL path in Express static serving, and
  // doesn't leak the server's absolute filesystem layout into the DB.
  // On Windows req.file.path uses backslashes — normalise them.
  const backendRoot = path.resolve(__dirname, '..');
  const relativePath = path.relative(backendRoot, req.file.path).split(path.sep).join('/');

  let profile = await Profile.findOne({ user: req.user._id });

  if (!profile) {
    profile = await Profile.create({
      user: req.user._id,
      profileImage: relativePath,
    });
  } else {
    // Remove old profile image from disk if it exists
    if (profile.profileImage) {
      const oldPath = path.resolve(backendRoot, profile.profileImage);
      fs.access(oldPath, fs.constants.F_OK, (err) => {
        if (!err) fs.unlink(oldPath, () => {});
      });
    }
    profile.profileImage = relativePath;
    await profile.save();
  }

  return sendResponse(res, 200, true, 'Profile image uploaded successfully', {
    profileImage: profile.profileImage,
  });
});

module.exports = {
  createProfile,
  getMyProfile,
  getProfileByUserId,
  updateProfile,
  uploadProfileImage,
};
