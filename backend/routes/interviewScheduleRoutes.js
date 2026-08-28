const express = require('express');
const {
  scheduleInterview,
  getCompanyScheduledInterviews,
  getCandidateScheduledInterviews,
  updateScheduledInterview,
  cancelScheduledInterview,
} = require('../controllers/interviewScheduleController');
const { protect } = require('../middleware/authMiddleware');
const { authorize } = require('../middleware/roleMiddleware');

const router = express.Router();

router.use(protect);

router.post('/schedule', authorize('company', 'alumni', 'admin'), scheduleInterview);
router.get('/schedule/company', authorize('company', 'alumni', 'admin'), getCompanyScheduledInterviews);
router.get('/schedule/candidate', getCandidateScheduledInterviews);
router.put('/schedule/:id', updateScheduledInterview);
router.delete('/schedule/:id', cancelScheduledInterview);

module.exports = router;
