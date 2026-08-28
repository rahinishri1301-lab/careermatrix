const fs = require('fs');
const path = require('path');
const Certificate = require('../models/Certificate');
const asyncHandler = require('../utils/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');
const { sendResponse } = require('../utils/apiResponse');

const backendRoot = path.resolve(__dirname, '..');

// uploadMiddleware resolves upload destinations to absolute paths, so
// req.file.path comes back absolute. Store a forward-slash relative path
// (e.g. "uploads/certificates/xxx.pdf") instead so it works directly as a
// URL path with Express static serving and doesn't leak the server's
// absolute filesystem layout into the DB.
const toRelativeUrl = (absolutePath) =>
  path.relative(backendRoot, absolutePath).split(path.sep).join('/');

const safeUnlink = (relativeOrAbsolutePath) => {
  if (!relativeOrAbsolutePath) return;
  const resolved = path.resolve(backendRoot, relativeOrAbsolutePath);
  fs.access(resolved, fs.constants.F_OK, (err) => {
    if (!err) fs.unlink(resolved, () => {});
  });
};

/**
 * @desc    Add/upload a new certificate for the logged-in user (multipart upload)
 * @route   POST /api/certificates
 * @access  Private
 */
const addCertificate = asyncHandler(async (req, res, next) => {
  if (!req.file) {
    return next(new ErrorResponse('Please upload a certificate file (PDF, JPG, or PNG)', 400));
  }

  const title = (req.body.title || '').trim();
  if (!title) {
    safeUnlink(req.file.path);
    return next(new ErrorResponse('Certificate title is required', 400));
  }

  const certificate = await Certificate.create({
    user: req.user._id,
    title,
    issuer: (req.body.issuer || '').trim() || undefined,
    issueDate: req.body.issueDate ? new Date(req.body.issueDate) : undefined,
    fileName: req.file.filename,
    originalName: req.file.originalname,
    filePath: toRelativeUrl(req.file.path),
    fileSize: req.file.size,
    mimeType: req.file.mimetype,
  });

  return sendResponse(res, 201, true, 'Certificate added successfully', certificate);
});

/**
 * @desc    Update certificate details (owner only). Optionally replaces the file.
 * @route   PUT /api/certificates/:id
 * @access  Private
 */
const updateCertificate = asyncHandler(async (req, res, next) => {
  const certificate = await Certificate.findById(req.params.id);

  if (!certificate) {
    if (req.file) safeUnlink(req.file.path);
    return next(new ErrorResponse(`Certificate not found with id ${req.params.id}`, 404));
  }

  if (String(certificate.user) !== String(req.user._id) && req.user.role !== 'admin') {
    if (req.file) safeUnlink(req.file.path);
    return next(new ErrorResponse('Not authorized to update this certificate', 403));
  }

  const { title, issuer, issueDate } = req.body;
  if (title !== undefined && title.trim()) certificate.title = title.trim();
  if (issuer !== undefined) certificate.issuer = issuer.trim();
  if (issueDate !== undefined) certificate.issueDate = issueDate ? new Date(issueDate) : undefined;

  if (req.file) {
    safeUnlink(certificate.filePath || ('uploads/certificates/' + certificate.fileName));
    certificate.fileName = req.file.filename;
    certificate.originalName = req.file.originalname;
    certificate.filePath = toRelativeUrl(req.file.path);
    certificate.fileSize = req.file.size;
    certificate.mimeType = req.file.mimetype;
  }

  await certificate.save();

  return sendResponse(res, 200, true, 'Certificate updated successfully', certificate);
});

/**
 * @desc    Get all certificates for the logged-in user
 * @route   GET /api/certificates/me
 * @access  Private
 */
const getMyCertificates = asyncHandler(async (req, res) => {
  const certificates = await Certificate.find({ user: req.user._id }).sort({ createdAt: -1 });
  return sendResponse(res, 200, true, 'Certificates fetched successfully', certificates);
});

/**
 * @desc    Get a specific user's certificates (e.g. alumni/mentor/company
 *          reviewing a student's credentials)
 * @route   GET /api/certificates/user/:userId
 * @access  Private
 */
const getUserCertificates = asyncHandler(async (req, res) => {
  const certificates = await Certificate.find({ user: req.params.userId }).sort({ createdAt: -1 });
  return sendResponse(res, 200, true, 'Certificates fetched successfully', certificates);
});

/**
 * @desc    Delete a certificate (owner only)
 * @route   DELETE /api/certificates/:id
 * @access  Private
 */
const deleteCertificate = asyncHandler(async (req, res, next) => {
  const certificate = await Certificate.findById(req.params.id);

  if (!certificate) {
    return next(new ErrorResponse(`Certificate not found with id ${req.params.id}`, 404));
  }

  if (String(certificate.user) !== String(req.user._id) && req.user.role !== 'admin') {
    return next(new ErrorResponse('Not authorized to delete this certificate', 403));
  }

  safeUnlink(certificate.filePath || ('uploads/certificates/' + certificate.fileName));
  await certificate.deleteOne();

  return sendResponse(res, 200, true, 'Certificate deleted successfully');
});

/**
 * @desc    Download/view a certificate file. Owner, admin, or a
 *          company/alumni reviewing the candidate's credentials may access it.
 * @route   GET /api/certificates/:id/download
 * @access  Private
 */
const downloadCertificate = asyncHandler(async (req, res, next) => {
  const certificate = await Certificate.findById(req.params.id);

  if (!certificate) {
    return next(new ErrorResponse(`Certificate not found with id ${req.params.id}`, 404));
  }

  const allowedRoles = ['admin', 'company', 'alumni'];
  if (String(certificate.user) !== String(req.user._id) && !allowedRoles.includes(req.user.role)) {
    return next(new ErrorResponse('Not authorized to view this certificate', 403));
  }

  const filePath = path.resolve(backendRoot, certificate.filePath || ('uploads/certificates/' + certificate.fileName));
  if (!fs.existsSync(filePath)) {
    return next(new ErrorResponse('Certificate file is missing from the server', 404));
  }

  return res.download(filePath, certificate.originalName);
});

module.exports = {
  addCertificate,
  updateCertificate,
  deleteCertificate,
  getMyCertificates,
  getUserCertificates,
  downloadCertificate,
};
