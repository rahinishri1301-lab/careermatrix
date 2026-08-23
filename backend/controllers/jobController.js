const Job = require('../models/Job');
const Internship = require('../models/Internship');
const JobApplication = require('../models/JobApplication');
const InternshipApplication = require('../models/InternshipApplication');
const Resume = require('../models/Resume');
const Skill = require('../models/Skill');
const Profile = require('../models/Profile');
const Certificate = require('../models/Certificate');
const Notification = require('../models/Notification');
const asyncHandler = require('../utils/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');
const { sendResponse } = require('../utils/apiResponse');
const { attachMatchScores } = require('../services/matchScoreService');
const { escapeRegExp } = require('../utils/regexHelper');

/**
 * @desc    Create a new job posting
 * @route   POST /api/jobs
 * @access  Private (Alumni, Admin)
 */
const createJob = asyncHandler(async (req, res) => {
  const {
    title,
    description,
    company,
    location,
    jobType,
    skillsRequired,
    experienceRequired,
    qualification,
    salaryRange,
    applicationDeadline,
  } = req.body;

  const companyName = (company && company.trim()) ? company.trim() : req.user.name;

  const job = await Job.create({
    title,
    description,
    company: companyName,
    location,
    jobType,
    skillsRequired,
    experienceRequired,
    qualification,
    salaryRange,
    applicationDeadline,
    postedBy: req.user._id,
  });

  return sendResponse(res, 201, true, 'Job posted successfully', job);
});

/**
 * @desc    Get all jobs with pagination, search, and filters
 *          Filters: company, location, skills (comma-separated), jobType, status
 *          Search: free-text keyword across title/description/company
 * @route   GET /api/jobs?page=1&limit=10&search=backend&company=Google&location=Remote&skills=Node.js,MongoDB&jobType=Full-time
 * @access  Private
 */
const getAllJobs = asyncHandler(async (req, res) => {
  const page = Math.max(Number(req.query.page) || 1, 1);
  const limit = Math.min(Number(req.query.limit) || 10, 100);
  const skip = (page - 1) * limit;

  const filter = {};

  if (req.query.postedByMe === 'true') {
    filter.postedBy = req.user._id;
  }
  if (req.query.company) {
    filter.company = { $regex: req.query.company, $options: 'i' };
  }
  if (req.query.location) {
    filter.location = { $regex: req.query.location, $options: 'i' };
  }
  if (req.query.skills) {
    const skillsArray = req.query.skills.split(',').map((s) => s.trim());
    filter.skillsRequired = { $in: skillsArray.map((s) => new RegExp(`^${escapeRegExp(s)}$`, 'i')) };
  }
  if (req.query.jobType) {
    filter.jobType = req.query.jobType;
  }
  if (req.query.status) {
    filter.status = req.query.status;
  }
  if (req.query.search) {
    filter.$text = { $search: req.query.search };
  }

  const [jobs, total] = await Promise.all([
    Job.find(filter)
      .populate('postedBy', 'name email role')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit),
    Job.countDocuments(filter),
  ]);

  const userSkills = await Skill.find({ user: req.user._id }).distinct('skillName');
  const jobsWithMatch = attachMatchScores(jobs, userSkills);

  return sendResponse(res, 200, true, 'Jobs fetched successfully', jobsWithMatch, {
    pagination: { total, page, pages: Math.ceil(total / limit), limit },
  });
});

/**
 * @desc    Get a single job by ID
 * @route   GET /api/jobs/:id
 * @access  Private
 */
const getJobById = asyncHandler(async (req, res, next) => {
  const job = await Job.findById(req.params.id).populate('postedBy', 'name email role');

  if (!job) {
    return next(new ErrorResponse(`Job not found with id ${req.params.id}`, 404));
  }

  return sendResponse(res, 200, true, 'Job fetched successfully', job);
});

/**
 * @desc    Update a job (owner or admin only)
 * @route   PUT /api/jobs/:id
 * @access  Private (Owner/Admin)
 */
const updateJob = asyncHandler(async (req, res, next) => {
  const job = await Job.findById(req.params.id);

  if (!job) {
    return next(new ErrorResponse(`Job not found with id ${req.params.id}`, 404));
  }

  if (String(job.postedBy) !== String(req.user._id) && req.user.role !== 'admin') {
    return next(new ErrorResponse('Not authorized to update this job', 403));
  }

  const allowedFields = [
    'title',
    'description',
    'company',
    'location',
    'jobType',
    'skillsRequired',
    'experienceRequired',
    'qualification',
    'salaryRange',
    'applicationDeadline',
    'status',
  ];

  allowedFields.forEach((field) => {
    if (req.body[field] !== undefined) job[field] = req.body[field];
  });

  await job.save();

  return sendResponse(res, 200, true, 'Job updated successfully', job);
});

/**
 * @desc    Delete a job (owner or admin only)
 * @route   DELETE /api/jobs/:id
 * @access  Private (Owner/Admin)
 */
const deleteJob = asyncHandler(async (req, res, next) => {
  const job = await Job.findById(req.params.id);

  if (!job) {
    return next(new ErrorResponse(`Job not found with id ${req.params.id}`, 404));
  }

  if (String(job.postedBy) !== String(req.user._id) && req.user.role !== 'admin') {
    return next(new ErrorResponse('Not authorized to delete this job', 403));
  }

  await JobApplication.deleteMany({ job: job._id });
  await job.deleteOne();

  return sendResponse(res, 200, true, 'Job deleted successfully');
});

/**
 * @desc    Apply for a job
 * @route   POST /api/jobs/:id/apply
 * @access  Private (Student, Alumni)
 */
const applyForJob = asyncHandler(async (req, res, next) => {
  const job = await Job.findById(req.params.id);

  if (!job) {
    return next(new ErrorResponse(`Job not found with id ${req.params.id}`, 404));
  }

  if (job.status !== 'Open') {
    return next(new ErrorResponse('This job is no longer accepting applications', 400));
  }

  if (job.applicationDeadline && job.applicationDeadline < new Date()) {
    return next(new ErrorResponse('The application deadline for this job has passed', 400));
  }

  const existing = await JobApplication.findOne({ job: job._id, applicant: req.user._id });
  if (existing) {
    return next(new ErrorResponse('You have already applied for this job', 400));
  }

  // Attach the applicant's existing resume path, if any
  const resume = await Resume.findOne({ user: req.user._id });

  const application = await JobApplication.create({
    job: job._id,
    applicant: req.user._id,
    coverLetter: req.body.coverLetter,
    resumePath: resume ? resume.filePath : undefined,
  });

  // Notify company of new job application
  if (job.postedBy) {
    try {
      await Notification.create({
        user: job.postedBy,
        title: 'New Job Application Received',
        message: `${req.user.name} applied for your job posting "${job.title}".`,
        type: 'ApplicationReceived',
        relatedModel: 'Job',
        relatedId: job._id,
        createdBy: req.user._id,
      });
    } catch (_) {}
  }

  return sendResponse(res, 201, true, 'Application submitted successfully', application);
});

/**
 * @desc    Get the logged-in user's own job applications
 * @route   GET /api/jobs/applications/me
 * @access  Private
 */
const getMyApplications = asyncHandler(async (req, res) => {
  const applications = await JobApplication.find({ applicant: req.user._id })
    .populate('job', 'title company location status')
    .sort({ createdAt: -1 });

  return sendResponse(res, 200, true, 'Your applications fetched successfully', applications);
});

/**
 * @desc    Get all applicants for a specific job (owner or admin only)
 * @route   GET /api/jobs/:id/applicants
 * @access  Private (Owner/Admin)
 */
const getJobApplicants = asyncHandler(async (req, res, next) => {
  const job = await Job.findById(req.params.id);

  if (!job) {
    return next(new ErrorResponse(`Job not found with id ${req.params.id}`, 404));
  }

  if (String(job.postedBy) !== String(req.user._id) && req.user.role !== 'admin') {
    return next(new ErrorResponse('Not authorized to view applicants for this job', 403));
  }

  const applicants = await JobApplication.find({ job: job._id })
    .populate('applicant', 'name email role')
    .sort({ createdAt: -1 });

  return sendResponse(res, 200, true, 'Applicants fetched successfully', applicants);
});

/**
 * @desc    Update status of a job application (Pending, Shortlisted, Selected, Rejected)
 * @route   PUT /api/jobs/applications/:id/status
 * @access  Private (Owner/Admin)
 */
const updateJobApplicationStatus = asyncHandler(async (req, res, next) => {
  const { status } = req.body;
  if (!['Applied', 'Pending', 'Shortlisted', 'Selected', 'Hired', 'Rejected'].includes(status)) {
    return next(new ErrorResponse('Invalid application status', 400));
  }

  const application = await JobApplication.findById(req.params.id).populate('job');
  if (!application) {
    return next(new ErrorResponse(`Application not found with id ${req.params.id}`, 404));
  }

  if (String(application.job.postedBy) !== String(req.user._id) && req.user.role !== 'admin') {
    return next(new ErrorResponse('Not authorized to update this application', 403));
  }

  application.status = status;
  await application.save();

  // Notify student of status update
  if (application.applicant) {
    try {
      await Notification.create({
        user: application.applicant,
        title: 'Application Status Updated',
        message: `Your application for "${application.job.title}" has been updated to ${status}.`,
        type: 'ApplicationStatusUpdated',
        relatedModel: 'Job',
        relatedId: application.job._id,
        createdBy: req.user._id,
      });
    } catch (_) {}
  }

  return sendResponse(res, 200, true, 'Application status updated successfully', application);
});

/**
 * @desc    Aggregate stats for the logged-in company/alumni/admin's own
 *          postings (jobs + internships): active count and total
 *          applications received. Real, computed-from-Mongo data — not
 *          hardcoded frontend numbers.
 * @route   GET /api/jobs/stats/mine
 * @access  Private/Company,Alumni,Admin
 */
const getMyPostingStats = asyncHandler(async (req, res) => {
  const [userJobs, userInternships] = await Promise.all([
    Job.find({ postedBy: req.user._id }).select('_id status').lean(),
    Internship.find({ postedBy: req.user._id }).select('_id status').lean(),
  ]);

  const jobIds = userJobs.map((j) => j._id);
  const internshipIds = userInternships.map((i) => i._id);

  const activeJobs = userJobs.filter((j) => j.status === 'Open').length;
  const activeInternships = userInternships.filter((i) => i.status === 'Open').length;

  const [jobApps, internshipApps] = await Promise.all([
    JobApplication.find({ job: { $in: jobIds } }).select('status').lean(),
    InternshipApplication.find({ internship: { $in: internshipIds } }).select('status').lean(),
  ]);

  const allApps = [...jobApps, ...internshipApps];

  const totalJobsPosted = userJobs.length;
  const totalInternshipsPosted = userInternships.length;
  const activeOpportunities = activeJobs + activeInternships;
  const totalApplications = allApps.length;
  const pendingApplications = allApps.filter((a) => a.status === 'Applied' || a.status === 'Pending').length;
  const shortlistedCandidates = allApps.filter((a) => a.status === 'Shortlisted').length;
  const selectedCandidates = allApps.filter((a) => a.status === 'Selected' || a.status === 'Hired').length;
  const rejectedApplications = allApps.filter((a) => a.status === 'Rejected').length;

  return sendResponse(res, 200, true, 'Posting stats fetched successfully', {
    totalJobsPosted,
    totalInternshipsPosted,
    activeOpportunities,
    activePostings: activeOpportunities,
    totalApplications,
    pendingApplications,
    shortlistedCandidates,
    selectedCandidates,
    rejectedApplications,
  });
});

/**
 * @desc    Get all student applications received by the logged-in company (jobs + internships)
 *          populated with student user data, profile, skills, resume, and opportunity details.
 * @route   GET /api/jobs/applications/company
 * @access  Private (Company, Alumni, Admin)
 */
const getCompanyReceivedApplications = asyncHandler(async (req, res) => {
  const [userJobs, userInternships] = await Promise.all([
    Job.find({ postedBy: req.user._id }).select('_id').lean(),
    Internship.find({ postedBy: req.user._id }).select('_id').lean(),
  ]);

  const jobIds = userJobs.map((j) => j._id);
  const internshipIds = userInternships.map((i) => i._id);

  const [jobApps, internshipApps] = await Promise.all([
    JobApplication.find({ job: { $in: jobIds } })
      .populate('applicant', 'name email role')
      .populate('job', 'title company location jobType qualification experienceRequired')
      .sort({ createdAt: -1 })
      .lean(),
    InternshipApplication.find({ internship: { $in: internshipIds } })
      .populate('applicant', 'name email role')
      .populate('internship', 'title company location duration qualification stipend')
      .sort({ createdAt: -1 })
      .lean(),
  ]);

  const applicantIds = [
    ...new Set([
      ...jobApps.map((a) => a.applicant?._id?.toString()).filter(Boolean),
      ...internshipApps.map((a) => a.applicant?._id?.toString()).filter(Boolean),
    ]),
  ];

  const [profiles, skills, certificates] = await Promise.all([
    Profile.find({ user: { $in: applicantIds } }).lean(),
    Skill.find({ user: { $in: applicantIds } }).lean(),
    Certificate.find({ user: { $in: applicantIds } }).lean(),
  ]);

  const profileMap = new Map();
  profiles.forEach((p) => profileMap.set(p.user.toString(), p));

  const skillsMap = new Map();
  skills.forEach((s) => {
    const key = s.user.toString();
    if (!skillsMap.has(key)) skillsMap.set(key, []);
    skillsMap.get(key).push(s.skillName);
  });

  const certMap = new Map();
  certificates.forEach((c) => {
    const key = c.user.toString();
    if (!certMap.has(key)) certMap.set(key, []);
    certMap.get(key).push({
      _id: c._id,
      id: c._id,
      title: c.title,
      issuer: c.issuer,
      issueDate: c.issueDate,
      originalName: c.originalName,
      filePath: c.filePath,
    });
  });

  const formattedJobApps = jobApps.map((app) => {
    const applicantId = app.applicant?._id?.toString();
    const prof = applicantId ? profileMap.get(applicantId) : null;
    const userSkills = applicantId ? (skillsMap.get(applicantId) || []) : [];
    const userCerts = applicantId ? (certMap.get(applicantId) || []) : [];
    return {
      _id: app._id,
      id: app._id,
      applicant: app.applicant,
      opportunityType: 'Job',
      opportunityTitle: app.job?.title || 'Job',
      opportunityId: app.job?._id,
      coverLetter: app.coverLetter || '',
      resumePath: app.resumePath || null,
      status: app.status || 'Applied',
      createdAt: app.createdAt,
      profile: prof ? {
        bio: prof.bio,
        phone: prof.phone,
        department: prof.department,
        graduationYear: prof.graduationYear,
        currentPosition: prof.currentPosition,
        company: prof.company,
        linkedin: prof.linkedin,
        github: prof.github,
      } : null,
      skills: userSkills,
      certificates: userCerts,
    };
  });

  const formattedInternApps = internshipApps.map((app) => {
    const applicantId = app.applicant?._id?.toString();
    const prof = applicantId ? profileMap.get(applicantId) : null;
    const userSkills = applicantId ? (skillsMap.get(applicantId) || []) : [];
    const userCerts = applicantId ? (certMap.get(applicantId) || []) : [];
    return {
      _id: app._id,
      id: app._id,
      applicant: app.applicant,
      opportunityType: 'Internship',
      opportunityTitle: app.internship?.title || 'Internship',
      opportunityId: app.internship?._id,
      coverLetter: app.coverLetter || '',
      resumePath: app.resumePath || null,
      status: app.status || 'Applied',
      createdAt: app.createdAt,
      profile: prof ? {
        bio: prof.bio,
        phone: prof.phone,
        department: prof.department,
        graduationYear: prof.graduationYear,
        currentPosition: prof.currentPosition,
        company: prof.company,
        linkedin: prof.linkedin,
        github: prof.github,
      } : null,
      skills: userSkills,
      certificates: userCerts,
    };
  });

  const allApplications = [...formattedJobApps, ...formattedInternApps].sort(
    (a, b) => new Date(b.createdAt) - new Date(a.createdAt)
  );

  return sendResponse(res, 200, true, 'Company received applications fetched successfully', allApplications);
});

module.exports = {
  createJob,
  getAllJobs,
  getJobById,
  updateJob,
  deleteJob,
  applyForJob,
  getMyApplications,
  getJobApplicants,
  updateJobApplicationStatus,
  getMyPostingStats,
  getCompanyReceivedApplications,
};
