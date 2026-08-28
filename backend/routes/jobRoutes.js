const express = require('express');
const {
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
} = require('../controllers/jobController');
const { protect } = require('../middleware/authMiddleware');
const { authorize } = require('../middleware/roleMiddleware');
const { validate } = require('../middleware/validateMiddleware');
const {
  createJobValidator,
  updateJobValidator,
  jobIdValidator,
  applyJobValidator,
  getAllJobsValidator,
} = require('../validators/jobValidator');

const router = express.Router();

router.use(protect);

// @route   GET /api/jobs/applications/me
router.get('/applications/me', getMyApplications);

// @route   GET /api/jobs/applications/company
router.get('/applications/company', authorize('company', 'alumni', 'admin'), getCompanyReceivedApplications);

// @route   PUT /api/jobs/applications/:id/status
router.put('/applications/:id/status', authorize('company', 'alumni', 'admin'), updateJobApplicationStatus);

// @route   GET /api/jobs/stats/mine
router.get('/stats/mine', authorize('company', 'alumni', 'admin'), getMyPostingStats);

// @route   POST /api/jobs
router.post('/', authorize('alumni', 'company', 'admin'), createJobValidator, validate, createJob);

// @route   GET /api/jobs
router.get('/', getAllJobsValidator, validate, getAllJobs);

// @route   GET /api/jobs/:id
router.get('/:id', jobIdValidator, validate, getJobById);

// @route   PUT /api/jobs/:id
router.put('/:id', authorize('company', 'alumni', 'admin'), updateJobValidator, validate, updateJob);

// @route   DELETE /api/jobs/:id
router.delete('/:id', authorize('company', 'alumni', 'admin'), jobIdValidator, validate, deleteJob);

// @route   POST /api/jobs/:id/apply
router.post(
  '/:id/apply',
  authorize('student', 'alumni'),
  applyJobValidator,
  validate,
  applyForJob
);

// @route   GET /api/jobs/:id/applicants
router.get('/:id/applicants', authorize('company', 'alumni', 'admin'), jobIdValidator, validate, getJobApplicants);

module.exports = router;
