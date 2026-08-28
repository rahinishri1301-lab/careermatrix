const jwt = require('jsonwebtoken');
const asyncHandler = require('../utils/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');
const User = require('../models/User');

/**
 * Protect routes - verifies JWT from the Authorization header (Bearer token)
 * or from a signed cookie, then attaches the authenticated user to req.user.
 */
const protect = asyncHandler(async (req, res, next) => {
  let token;

  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith('Bearer')
  ) {
    token = req.headers.authorization.split(' ')[1];
  } else if (req.cookies && req.cookies.token) {
    token = req.cookies.token;
  } else if (req.query && req.query.token) {
    // Allows authenticating direct-link requests (e.g. opening a resume/
    // certificate PDF in a new browser tab or an in-app webview) where an
    // Authorization header can't be attached.
    token = req.query.token;
  }

  if (!token) {
    return next(new ErrorResponse('Not authorized, no token provided', 401));
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    const user = await User.findById(decoded.id);

    if (!user) {
      return next(new ErrorResponse('User belonging to this token no longer exists', 401));
    }

    if (!user.isActive) {
      return next(new ErrorResponse('This account has been deactivated', 403));
    }

    req.user = user;
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return next(new ErrorResponse('Session expired, please log in again', 401));
    }
    return next(new ErrorResponse('Not authorized, invalid token', 401));
  }
});

module.exports = { protect };
