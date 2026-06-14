/**
 * gamification.js
 * ---------------
 * Express router — Gamification & Dropout Prediction endpoints.
 *
 * Routes:
 *   POST /api/gamification/risk     — Single student dropout risk prediction
 *   POST /api/gamification/batch    — Batch risk assessment (daily pipeline)
 *   GET  /api/gamification/features — 34 feature catalogue
 */

'use strict';

const express = require('express');
const { body, validationResult } = require('express-validator');
const mlClient = require('../services/mlClient');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

function handleValidation(req, res) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({ error: 'Validation failed', details: errors.array() });
  }
  return null;
}

// ── POST /api/gamification/risk ────────────────────────────────────────────────
/**
 * @description
 * Run XGBoost dropout risk inference for a single student.
 *
 * Risk bands:
 *   LOW    (< 0.35)  — Standard pacing. No intervention.
 *   MEDIUM (0.35–0.65) — Light nudges pushed to mobile.
 *   HIGH   (≥ 0.65)  — Streak Recovery Token, bonus XP challenge,
 *                       peer study room invitation.
 */
router.post(
  '/risk',
  requireAuth,
  [
    body('student_id').isString().notEmpty(),
    body('ikp.proficiency_scores').isObject(),
    body('engagement').isObject(),
    body('interactions').optional().isArray(),
  ],
  async (req, res) => {
    const invalid = handleValidation(req, res);
    if (invalid) return invalid;

    try {
      const { data } = await mlClient.post('/gamification/risk', req.body);

      // Log high-risk students for monitoring
      if (data.risk_band === 'HIGH') {
        console.warn(
          `[gamification] HIGH RISK detected — student: ${data.student_id}, ` +
          `score: ${data.risk_score}, interventions: ${data.interventions?.length || 0}`,
        );
      }

      return res.json({ success: true, data });
    } catch (err) {
      return res.status(err.status || 502).json({
        success: false,
        error: 'ML service error',
        message: err.message,
      });
    }
  },
);

// ── POST /api/gamification/batch ───────────────────────────────────────────────
/**
 * @description
 * Batch daily risk assessment. Intended for a scheduled cron job.
 * Accepts an array of student objects and returns sorted risk summary.
 */
router.post(
  '/batch',
  requireAuth,
  [body().isArray({ min: 1, max: 500 }).withMessage('Expected array of 1–500 students.')],
  async (req, res) => {
    const invalid = handleValidation(req, res);
    if (invalid) return invalid;

    try {
      const { data } = await mlClient.post('/gamification/batch', req.body);
      return res.json({
        success: true,
        total: data.length,
        high_risk_count: data.filter((d) => d.risk_band === 'HIGH').length,
        data,
      });
    } catch (err) {
      return res.status(err.status || 502).json({
        success: false,
        error: err.message,
      });
    }
  },
);

// ── GET /api/gamification/features ─────────────────────────────────────────────
router.get('/features', async (req, res) => {
  try {
    const { data } = await mlClient.get('/gamification/features');
    return res.json({ success: true, data });
  } catch (err) {
    return res.status(err.status || 502).json({ success: false, error: err.message });
  }
});

module.exports = router;
