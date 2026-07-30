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
const db = require('../db');
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

      // Persist updated VSS score and submission history into PostgreSQL
      if (req.body.student_id && data.vss != null) {
        db.query(
          `UPDATE user_progress SET vss_score = $1, updated_at = CURRENT_TIMESTAMP WHERE user_id = $2`,
          [data.vss, req.body.student_id]
        ).catch(e => console.warn('[codeReview] VSS DB update warning:', e.message));

        db.query(
          `INSERT INTO code_submissions (user_id, skill_node, code_text, vss_score, dimension_scores, feedback)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [
            req.body.student_id,
            req.body.skill_node,
            req.body.code_text,
            data.vss,
            JSON.stringify(data.dimension_scores || {}),
            JSON.stringify(data.feedback || {}),
          ]
        ).catch(e => console.warn('[codeReview] Submission history DB insert warning:', e.message));
      }

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
router.get(
  '/leaderboard',
  optionalAuth,
  [query('limit').optional().isInt({ min: 1, max: 100 })],
  async (req, res) => {
    const limit = parseInt(req.query.limit || '20', 10);
    try {
      const result = await db.query(
        `SELECT u.id as student_id, u.name, u.email, up.xp, up.streak, COALESCE(up.vss_score, 0.0) as vss
         FROM users u
         JOIN user_progress up ON u.id = up.user_id
         ORDER BY up.vss_score DESC, up.xp DESC
         LIMIT $1`,
        [limit]
      );

      const leaderboard = result.rows.map((row, idx) => ({
        rank: idx + 1,
        student_id: row.student_id,
        name: row.name,
        email: row.email,
        xp: row.xp,
        streak: row.streak,
        vss: parseFloat(row.vss).toFixed(1),
      }));

      return res.json({
        success: true,
        viewer: req.user?.studentId || null,
        total_students_ranked: leaderboard.length,
        data: leaderboard,
      });
    } catch (err) {
      console.warn('[codeReview] DB leaderboard fallback:', err.message);
      try {
        const { data } = await mlClient.get('/code-review/leaderboard', { params: { limit } });
        return res.json({ success: true, viewer: req.user?.studentId || null, data });
      } catch (mlErr) {
        return res.status(502).json({ success: false, error: mlErr.message });
      }
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
