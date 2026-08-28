const multer = require('multer');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const ErrorResponse = require('../utils/errorResponse');

// Resolve upload directories relative to the backend root (__dirname/..)
// so that paths are always correct regardless of CWD when `node server.js`
// is executed. Environment variables, if set, are still honoured but are
// also resolved to absolute paths for the same reason.
const backendRoot = path.resolve(__dirname, '..');
const profileDir = path.resolve(backendRoot, process.env.PROFILE_IMAGE_UPLOAD_PATH || './uploads/profiles');
const resumeDir = path.resolve(backendRoot, process.env.RESUME_UPLOAD_PATH || './uploads/resumes');
const certificateDir = path.resolve(backendRoot, process.env.CERTIFICATE_UPLOAD_PATH || './uploads/certificates');

[profileDir, resumeDir, certificateDir].forEach((dir) => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

/**
 * Generates a collision-safe filename: <userId>-<randomHex>-<timestamp><ext>
 */
const generateFileName = (req, file) => {
  const ext = path.extname(file.originalname || '').toLowerCase();
  const random = crypto.randomBytes(8).toString('hex');
  const userId = req.user ? req.user._id : 'anonymous';
  return `${userId}-${Date.now()}-${random}${ext}`;
};

// ---------- Profile Image Storage ----------
const profileImageStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, profileDir),
  filename: (req, file, cb) => cb(null, generateFileName(req, file)),
});

const profileImageFilter = (req, file, cb) => {
  const allowedExts = /^\.(jpeg|jpg|png|webp)$/i;
  const extValid = allowedExts.test(path.extname(file.originalname || '').toLowerCase());
  const mimeValid = !file.mimetype || file.mimetype === 'application/octet-stream' || /^image\/(jpeg|jpg|png|webp)$/i.test(file.mimetype);

  if (extValid && mimeValid) {
    return cb(null, true);
  }
  cb(new ErrorResponse('Only JPEG, JPG, PNG, or WEBP images are allowed for profile photo', 400));
};

const uploadProfileImage = multer({
  storage: profileImageStorage,
  fileFilter: profileImageFilter,
  limits: {
    fileSize: Number(process.env.MAX_PROFILE_IMAGE_SIZE) || 2 * 1024 * 1024, // 2MB default
  },
});

// ---------- Resume (PDF) Storage ----------
const resumeStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, resumeDir),
  filename: (req, file, cb) => cb(null, generateFileName(req, file)),
});

const resumeFilter = (req, file, cb) => {
  const isPdfExt = path.extname(file.originalname || '').toLowerCase() === '.pdf';
  const isPdfMime = !file.mimetype || file.mimetype === 'application/octet-stream' || file.mimetype === 'application/pdf' || file.mimetype === 'application/x-pdf';

  if (isPdfExt && isPdfMime) {
    return cb(null, true);
  }
  cb(new ErrorResponse('Only PDF files are allowed for resumes', 400));
};

const uploadResume = multer({
  storage: resumeStorage,
  fileFilter: resumeFilter,
  limits: {
    fileSize: Number(process.env.MAX_RESUME_SIZE) || 5 * 1024 * 1024, // 5MB default
  },
});

// ---------- Certificate Storage (PDF or image) ----------
const certificateStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, certificateDir),
  filename: (req, file, cb) => cb(null, generateFileName(req, file)),
});

const certificateFilter = (req, file, cb) => {
  const allowedExts = /^\.(jpeg|jpg|png|webp|pdf)$/i;
  const extValid = allowedExts.test(path.extname(file.originalname || '').toLowerCase());
  const mimeValid = !file.mimetype || file.mimetype === 'application/octet-stream' || /^image\/(jpeg|jpg|png|webp)$|^application\/(pdf|x-pdf)$/i.test(file.mimetype);

  if (extValid && mimeValid) {
    return cb(null, true);
  }
  cb(new ErrorResponse('Only PDF, JPEG, JPG, PNG, or WEBP files are allowed for certificates', 400));
};

const uploadCertificate = multer({
  storage: certificateStorage,
  fileFilter: certificateFilter,
  limits: {
    fileSize: Number(process.env.MAX_CERTIFICATE_SIZE) || 5 * 1024 * 1024, // 5MB default
  },
});

module.exports = { uploadProfileImage, uploadResume, uploadCertificate };
