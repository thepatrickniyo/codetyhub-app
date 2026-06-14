/**
 * codeReview.js
 * -------------
 * Express router — CodeBERT Code Review & Verified Skill Score endpoints.
 *
 * Routes:
 *   POST /api/code-review/evaluate       — Evaluate code submission → VSS
 *   GET  /api/code-review/leaderboard    — VSS-ranked talent leaderboard
 *   GET  /api/code-review/rubric         — Evaluation rubric & dimension weights
 */

'use strict';

const express = require('express');
const { body, query, validationResult } = require('express-validator');
const mlClient = require('../services/mlClient');
const { requireAuth, optionalAuth } = require('../middleware/auth');

const router = express.Router();

function handleValidation(req, res) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({ error: 'Validation failed', details: errors.array() });
  }
  return null;
}

// ── POST /api/code-review/evaluate ────────────────────────────────────────────
/**
 * @description
 * Submit a code repository for CodeBERT evaluation.
 *
 * The backend:
 *   1. Preprocesses and truncates the code.
 *   2. Calls the HuggingFace CodeBERT Inference API (or heuristic fallback).
 *   3. Computes a weighted Verified Skill Score (VSS) in [0–100].
 *   4. Updates the Redis Sorted Set (ZADD) — instantly reshuffling leaderboard.
 *
 * Returns VSS, per-dimension scores, actionable feedback, and new rank.
 */
router.post(
  '/evaluate',
  requireAuth,
  [
    body('student_id').isString().notEmpty(),
    body('skill_node').isString().notEmpty(),
    body('code_text').isString().isLength({ min: 10, max: 50000 }),
  ],
  async (req, res) => {
    const invalid = handleValidation(req, res);
    if (invalid) return invalid;

    try {
      const { data } = await mlClient.post('/code-review/evaluate', req.body);

      console.info(
        `[code-review] Evaluated ${req.body.student_id} on "${req.body.skill_node}" ` +
        `→ VSS: ${data.vss} | Rank: #${data.leaderboard_rank}`,
      );

      return res.json({ success: true, data });
    } catch (err) {
      return res.status(err.status || 502).json({
        success: false,
        error: 'Evaluation service error',
        message: err.message,
      });
    }
  },
);

// ── GET /api/code-review/leaderboard ──────────────────────────────────────────
/**
 * @description
 * Returns the employer-visible talent leaderboard sorted by VSS (desc).
 * Public route — no auth required (optional token for personalised rank context).
 */
router.get(
  '/leaderboard',
  optionalAuth,
  [query('limit').optional().isInt({ min: 1, max: 100 })],
  async (req, res) => {
    const limit = parseInt(req.query.limit || '20', 10);
    try {
      const { data } = await mlClient.get('/code-review/leaderboard', {
        params: { limit },
      });
      return res.json({
        success: true,
        viewer: req.user?.studentId || null,
        data,
      });
    } catch (err) {
      return res.status(err.status || 502).json({ success: false, error: err.message });
    }
  },
);

// ── GET /api/code-review/rubric ────────────────────────────────────────────────
router.get('/rubric', async (req, res) => {
  try {
    const { data } = await mlClient.get('/code-review/rubric');
    return res.json({ success: true, data });
  } catch (err) {
    return res.status(err.status || 502).json({ success: false, error: err.message });
  }
});

module.exports = router;
