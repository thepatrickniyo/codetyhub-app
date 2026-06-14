/**
 * pathway.js
 * ----------
 * Express router — Pathway Recommendation endpoints.
 *
 * Routes:
 *   POST /api/pathway/recommend              — Hybrid pathway recommendation
 *   GET  /api/pathway/graph/info             — Knowledge graph statistics
 *   GET  /api/pathway/graph/prerequisites/:skillId — Prerequisite lookup
 */

'use strict';

const express = require('express');
const { body, param, query, validationResult } = require('express-validator');
const mlClient = require('../services/mlClient');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

/** Return 422 with validation errors. */
function handleValidation(req, res) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({ error: 'Validation failed', details: errors.array() });
  }
  return null;
}

// ── POST /api/pathway/recommend ────────────────────────────────────────────────
router.post(
  '/recommend',
  requireAuth,
  [
    body('student_id').isString().notEmpty(),
    body('ikp.proficiency_scores').isObject(),
    body('top_n').optional().isInt({ min: 1, max: 20 }),
    body('include_collaborative').optional().isBoolean(),
  ],
  async (req, res) => {
    const invalid = handleValidation(req, res);
    if (invalid) return invalid;

    try {
      const { data } = await mlClient.post('/pathway/recommend', req.body);
      return res.json({ success: true, data });
    } catch (err) {
      const status = err.status || 502;
      return res.status(status).json({
        success: false,
        error: 'ML service error',
        message: err.message,
      });
    }
  },
);

// ── GET /api/pathway/graph/info ────────────────────────────────────────────────
router.get('/graph/info', async (req, res) => {
  try {
    const { data } = await mlClient.get('/pathway/graph/info');
    return res.json({ success: true, data });
  } catch (err) {
    return res.status(err.status || 502).json({
      success: false,
      error: err.message,
    });
  }
});

// ── GET /api/pathway/graph/prerequisites/:skillId ──────────────────────────────
router.get(
  '/graph/prerequisites/:skillId',
  [param('skillId').isString().notEmpty()],
  async (req, res) => {
    const invalid = handleValidation(req, res);
    if (invalid) return invalid;

    const { skillId } = req.params;
    try {
      const { data } = await mlClient.get(`/pathway/graph/prerequisites/${skillId}`);
      return res.json({ success: true, data });
    } catch (err) {
      const status = err.status || 502;
      return res.status(status).json({ success: false, error: err.message });
    }
  },
);

module.exports = router;
