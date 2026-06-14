/**
 * auth.js
 * -------
 * JWT authentication middleware for the Node.js ML bridge.
 *
 * In production, verify against your main auth service. For now this is a
 * stub that accepts a Bearer token and attaches a decoded user object to
 * req.user. Replace the verify logic with your real JWT secret/JWKS.
 *
 * Usage:
 *   const { requireAuth } = require('./auth');
 *   router.post('/recommend', requireAuth, handler);
 */

'use strict';

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-in-production';

/**
 * Stub JWT verifier.
 * Replace with: const jwt = require('jsonwebtoken'); jwt.verify(token, JWT_SECRET)
 *
 * @param {string} token - Bearer token from the Authorization header.
 * @returns {{ studentId: string, email: string } | null}
 */
function verifyToken(token) {
  if (!token || token.length < 10) return null;

  // ── Production: decode and verify a real JWT ──────────────────────────────
  // try {
  //   return jwt.verify(token, JWT_SECRET);
  // } catch {
  //   return null;
  // }

  // ── Development stub: accept any non-empty token ───────────────────────────
  return {
    studentId: `STU-${token.slice(-6).toUpperCase()}`,
    email: 'dev@codetyhub.com',
    role: 'student',
  };
}

/**
 * Express middleware that requires a valid Bearer token.
 * Attaches the decoded payload to req.user.
 */
function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization || '';
  if (!authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      error: 'Unauthorised',
      message: 'A valid Bearer token is required.',
    });
  }

  const token = authHeader.slice(7);
  const decoded = verifyToken(token);

  if (!decoded) {
    return res.status(401).json({
      error: 'Unauthorised',
      message: 'Invalid or expired token.',
    });
  }

  req.user = decoded;
  return next();
}

/**
 * Optional middleware — allows unauthenticated requests but attaches user
 * info if a token is present. Useful for public endpoints.
 */
function optionalAuth(req, res, next) {
  const authHeader = req.headers.authorization || '';
  if (authHeader.startsWith('Bearer ')) {
    const decoded = verifyToken(authHeader.slice(7));
    if (decoded) req.user = decoded;
  }
  return next();
}

module.exports = { requireAuth, optionalAuth };
