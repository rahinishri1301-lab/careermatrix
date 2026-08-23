const User = require('../models/User');
const Skill = require('../models/Skill');
const Profile = require('../models/Profile');
const Job = require('../models/Job');
const Internship = require('../models/Internship');
const { computeCandidateMatchScore } = require('../services/matchScoreService');
const asyncHandler = require('../utils/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');
const { sendResponse } = require('../utils/apiResponse');
const { escapeRegExp } = require('../utils/regexHelper');

/**
 * @desc    Get all users (supports pagination, search, and role filter)
 * @route   GET /api/users?page=1&limit=10&role=student&search=john
 * @access  Private/Admin
 */
const getAllUsers = asyncHandler(async (req, res) => {
  const page = Math.max(Number(req.query.page) || 1, 1);
  const limit = Math.min(Number(req.query.limit) || 10, 100);
  const skip = (page - 1) * limit;

  const filter = {};
  if (req.query.role) filter.role = req.query.role;
  if (req.query.search) {
    const searchVal = escapeRegExp(req.query.search);
    filter.$or = [
      { name: { $regex: searchVal, $options: 'i' } },
      { email: { $regex: searchVal, $options: 'i' } },
    ];
  }

  const [users, total] = await Promise.all([
    User.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
    User.countDocuments(filter),
  ]);

  return sendResponse(res, 200, true, 'Users fetched successfully', users, {
    pagination: {
      total,
      page,
      pages: Math.ceil(total / limit),
      limit,
    },
  });
});

/**
 * @desc    Get single user by ID
 * @route   GET /api/users/:id
 * @access  Private/Admin
 */
const getUserById = asyncHandler(async (req, res, next) => {
  const user = await User.findById(req.params.id);

  if (!user) {
    return next(new ErrorResponse(`User not found with id ${req.params.id}`, 404));
  }

  return sendResponse(res, 200, true, 'User fetched successfully', user);
});

/**
 * @desc    Create a new user account (used by Admin to create Student /
 *          Alumni / Mentor / Company / Admin accounts). Reuses the same
 *          User model + bcrypt password hashing as the public register
 *          endpoint - this is NOT a second auth system, just an
 *          admin-only entry point into it.
 * @route   POST /api/users
 * @access  Private/Admin
 */
const createUser = asyncHandler(async (req, res, next) => {
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

  return sendResponse(res, 201, true, 'User created successfully', user);
});

/**
 * @desc    Update a user (admin only - can change role/isActive; self-update handled separately if needed)
 * @route   PUT /api/users/:id
 * @access  Private/Admin
 */
const updateUser = asyncHandler(async (req, res, next) => {
  const allowedFields = ['name', 'email', 'role', 'isActive'];
  const updates = {};

  allowedFields.forEach((field) => {
    if (req.body[field] !== undefined) updates[field] = req.body[field];
  });

  if (Object.keys(updates).length === 0) {
    return next(new ErrorResponse('No valid fields provided to update', 400));
  }

  const user = await User.findByIdAndUpdate(req.params.id, updates, {
    new: true,
    runValidators: true,
  });

  if (!user) {
    return next(new ErrorResponse(`User not found with id ${req.params.id}`, 404));
  }

  return sendResponse(res, 200, true, 'User updated successfully', user);
});

/**
 * @desc    Delete a user
 * @route   DELETE /api/users/:id
 * @access  Private/Admin
 */
const deleteUser = asyncHandler(async (req, res, next) => {
  if (req.params.id === String(req.user._id)) {
    return next(new ErrorResponse('Admins cannot delete their own account via this route', 400));
  }

  const user = await User.findByIdAndDelete(req.params.id);

  if (!user) {
    return next(new ErrorResponse(`User not found with id ${req.params.id}`, 404));
  }

  return sendResponse(res, 200, true, 'User deleted successfully');
});

/**
 * @desc    Browse & filter candidates (students/alumni) by skills, domain, qualification, experience, location, and job match
 * @route   GET /api/users/candidates?skill=React&domain=CS&location=NewYork&jobId=xxx
 * @access  Private (Company, Alumni, Admin)
 */
const getCandidates = asyncHandler(async (req, res) => {
  const page = Math.max(Number(req.query.page) || 1, 1);
  const limit = Math.min(Number(req.query.limit) || 10, 100);
  const skip = (page - 1) * limit;

  const { search, skill, domain, qualification, experience, location, jobId, internshipId } = req.query;

  // 1. Build profile query if domain/qualification/experience/location filters are provided
  const profileFilter = {};
  if (domain || qualification) {
    const val = escapeRegExp(domain || qualification);
    profileFilter.$or = [
      { department: { $regex: val, $options: 'i' } },
      { industry: { $regex: val, $options: 'i' } },
    ];
  }
  if (experience) {
    profileFilter.currentPosition = { $regex: escapeRegExp(experience), $options: 'i' };
  }
  if (location) {
    profileFilter.address = { $regex: escapeRegExp(location), $options: 'i' };
  }

  let profileMatchingUserIds = null;
  if (Object.keys(profileFilter).length > 0) {
    profileMatchingUserIds = await Profile.find(profileFilter).distinct('user');
  }

  // 2. Build skill query if skill filter is provided
  let skillMatchingUserIds = null;
  if (skill) {
    skillMatchingUserIds = await Skill.find({
      skillName: { $regex: escapeRegExp(skill), $options: 'i' },
    }).distinct('user');
  }

  // 3. Construct userFilter
  const userFilter = { role: 'student', isActive: { $ne: false } };

  if (search) {
    userFilter.$or = [
      { name: { $regex: escapeRegExp(search), $options: 'i' } },
      { email: { $regex: escapeRegExp(search), $options: 'i' } },
    ];
  }

  if (profileMatchingUserIds !== null && skillMatchingUserIds !== null) {
    const setSkill = new Set(skillMatchingUserIds.map((id) => id.toString()));
    const matched = profileMatchingUserIds.filter((id) => setSkill.has(id.toString()));
    userFilter._id = { $in: matched };
  } else if (profileMatchingUserIds !== null) {
    userFilter._id = { $in: profileMatchingUserIds };
  } else if (skillMatchingUserIds !== null) {
    userFilter._id = { $in: skillMatchingUserIds };
  }

  const [users, total] = await Promise.all([
    User.find(userFilter).select('name email role createdAt').sort({ createdAt: -1 }).skip(skip).limit(limit).lean(),
    User.countDocuments(userFilter),
  ]);

  const userIds = users.map((u) => u._id);
  const [skills, profiles] = await Promise.all([
    Skill.find({ user: { $in: userIds } }).select('user skillName proficiencyLevel').lean(),
    Profile.find({ user: { $in: userIds } }).select('user bio phone address department graduationYear currentPosition company linkedin github').lean(),
  ]);

  // Fetch target job/internship details if jobId/internshipId specified
  let targetPosting = null;
  if (jobId) {
    targetPosting = await Job.findById(jobId);
  } else if (internshipId) {
    targetPosting = await Internship.findById(internshipId);
  }

  const skillsByUser = {};
  skills.forEach((s) => {
    const key = String(s.user);
    if (!skillsByUser[key]) skillsByUser[key] = [];
    skillsByUser[key].push(s.skillName);
  });

  const profileByUser = {};
  profiles.forEach((p) => {
    profileByUser[String(p.user)] = p;
  });

  const candidates = users.map((u) => {
    const candidateSkills = skillsByUser[String(u._id)] || [];
    const candidateProfile = profileByUser[String(u._id)] || null;
    const matchPercent = computeCandidateMatchScore(candidateSkills, candidateProfile, targetPosting);

    return {
      _id: u._id,
      id: u._id,
      name: u.name,
      email: u.email,
      role: u.role,
      matchPercent,
      skills: candidateSkills,
      profile: profileByUser[String(u._id)] || null,
    };
  });

  return sendResponse(res, 200, true, 'Candidates fetched successfully', candidates, {
    pagination: { total, page, pages: Math.ceil(total / limit), limit },
  });
});

module.exports = {
  getAllUsers,
  getUserById,
  createUser,
  updateUser,
  deleteUser,
  getCandidates,
};
