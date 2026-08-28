const mongoose = require('mongoose');

const ScheduledInterviewSchema = new mongoose.Schema(
  {
    company: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    candidate: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    job: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Job',
    },
    internship: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Internship',
    },
    title: {
      type: String,
      required: [true, 'Interview title is required'],
      trim: true,
    },
    interviewType: {
      type: String,
      enum: ['Technical', 'HR', 'Managerial', 'Screening', 'Final Round'],
      default: 'Technical',
    },
    scheduledDate: {
      type: Date,
      required: [true, 'Scheduled date and time is required'],
    },
    durationMinutes: {
      type: Number,
      default: 45,
    },
    meetingLink: {
      type: String,
      default: '',
    },
    location: {
      type: String,
      default: 'Online Video Call',
    },
    notes: {
      type: String,
      default: '',
    },
    status: {
      type: String,
      enum: ['Scheduled', 'Rescheduled', 'Completed', 'Cancelled'],
      default: 'Scheduled',
    },
  },
  {
    timestamps: true,
  }
);

ScheduledInterviewSchema.index({ company: 1, candidate: 1, scheduledDate: -1 });

module.exports = mongoose.model('ScheduledInterview', ScheduledInterviewSchema);
