const ScheduledInterview = require('../models/ScheduledInterview');
const User = require('../models/User');
const Notification = require('../models/Notification');
const asyncHandler = require('../utils/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');
const { sendResponse } = require('../utils/apiResponse');

/**
 * @desc    Schedule a new interview for a candidate (Company/Admin only)
 * @route   POST /api/interviews/schedule
 * @access  Private (Company, Admin)
 */
const scheduleInterview = asyncHandler(async (req, res, next) => {
  const {
    candidateId,
    jobId,
    internshipId,
    title,
    interviewType,
    scheduledDate,
    durationMinutes,
    meetingLink,
    location,
    notes,
  } = req.body;

  const candidate = await User.findById(candidateId);
  if (!candidate) {
    return next(new ErrorResponse(`Candidate not found with id ${candidateId}`, 404));
  }

  const interview = await ScheduledInterview.create({
    company: req.user._id,
    candidate: candidateId,
    job: jobId || undefined,
    internship: internshipId || undefined,
    title: title || `${interviewType || 'Technical'} Interview`,
    interviewType: interviewType || 'Technical',
    scheduledDate: new Date(scheduledDate),
    durationMinutes: Number(durationMinutes) || 45,
    meetingLink: meetingLink || '',
    location: location || 'Online Video Call',
    notes: notes || '',
    status: 'Scheduled',
  });

  // Automatically notify candidate of scheduled interview
  try {
    const formattedDate = new Date(scheduledDate).toLocaleString();
    await Notification.create({
      user: candidateId,
      title: 'Interview Scheduled 📅',
      message: `${req.user.name} has scheduled a ${interviewType || 'Technical'} interview for "${interview.title}" on ${formattedDate}.`,
      type: 'Info',
      relatedModel: 'ScheduledInterview',
      relatedId: interview._id,
      createdBy: req.user._id,
    });
  } catch (_) {}

  return sendResponse(res, 201, true, 'Interview scheduled successfully', interview);
});

/**
 * @desc    Get all scheduled interviews for the logged-in company
 * @route   GET /api/interviews/schedule/company
 * @access  Private (Company, Admin)
 */
const getCompanyScheduledInterviews = asyncHandler(async (req, res) => {
  const interviews = await ScheduledInterview.find({ company: req.user._id })
    .populate('candidate', 'name email role')
    .populate('job', 'title company')
    .populate('internship', 'title company')
    .sort({ scheduledDate: 1 })
    .lean();

  return sendResponse(res, 200, true, 'Company scheduled interviews fetched successfully', interviews);
});

/**
 * @desc    Get all scheduled interviews for the logged-in candidate/student
 * @route   GET /api/interviews/schedule/candidate
 * @access  Private (Student, Candidate)
 */
const getCandidateScheduledInterviews = asyncHandler(async (req, res) => {
  const interviews = await ScheduledInterview.find({ candidate: req.user._id })
    .populate('company', 'name email company')
    .populate('job', 'title company')
    .populate('internship', 'title company')
    .sort({ scheduledDate: 1 })
    .lean();

  return sendResponse(res, 200, true, 'Candidate scheduled interviews fetched successfully', interviews);
});

/**
 * @desc    Update / reschedule an existing interview
 * @route   PUT /api/interviews/schedule/:id
 * @access  Private (Owner Company or Admin)
 */
const updateScheduledInterview = asyncHandler(async (req, res, next) => {
  const interview = await ScheduledInterview.findById(req.params.id);
  if (!interview) {
    return next(new ErrorResponse(`Interview not found with id ${req.params.id}`, 404));
  }

  if (String(interview.company) !== String(req.user._id) && req.user.role !== 'admin') {
    return next(new ErrorResponse('Not authorized to update this interview', 403));
  }

  const { status, scheduledDate, meetingLink, location, notes, interviewType } = req.body;

  if (status) interview.status = status;
  if (scheduledDate) interview.scheduledDate = new Date(scheduledDate);
  if (meetingLink !== undefined) interview.meetingLink = meetingLink;
  if (location !== undefined) interview.location = location;
  if (notes !== undefined) interview.notes = notes;
  if (interviewType) interview.interviewType = interviewType;

  await interview.save();

  // Notify candidate of status update / rescheduling
  try {
    const formattedDate = new Date(interview.scheduledDate).toLocaleString();
    await Notification.create({
      user: interview.candidate,
      title: 'Interview Status Updated 📅',
      message: `Your interview "${interview.title}" status is now ${interview.status} (${formattedDate}).`,
      type: 'Info',
      relatedModel: 'ScheduledInterview',
      relatedId: interview._id,
      createdBy: req.user._id,
    });
  } catch (_) {}

  return sendResponse(res, 200, true, 'Interview updated successfully', interview);
});

/**
 * @desc    Cancel an interview
 * @route   DELETE /api/interviews/schedule/:id
 * @access  Private (Owner Company or Admin)
 */
const cancelScheduledInterview = asyncHandler(async (req, res, next) => {
  const interview = await ScheduledInterview.findById(req.params.id);
  if (!interview) {
    return next(new ErrorResponse(`Interview not found with id ${req.params.id}`, 404));
  }

  if (String(interview.company) !== String(req.user._id) && req.user.role !== 'admin') {
    return next(new ErrorResponse('Not authorized to cancel this interview', 403));
  }

  interview.status = 'Cancelled';
  await interview.save();

  try {
    await Notification.create({
      user: interview.candidate,
      title: 'Interview Cancelled ❌',
      message: `Your scheduled interview "${interview.title}" has been cancelled by the company.`,
      type: 'Info',
      relatedModel: 'ScheduledInterview',
      relatedId: interview._id,
      createdBy: req.user._id,
    });
  } catch (_) {}

  return sendResponse(res, 200, true, 'Interview cancelled successfully', interview);
});

module.exports = {
  scheduleInterview,
  getCompanyScheduledInterviews,
  getCandidateScheduledInterviews,
  updateScheduledInterview,
  cancelScheduledInterview,
};
