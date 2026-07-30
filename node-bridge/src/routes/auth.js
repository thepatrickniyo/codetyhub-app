/**
 * routes/auth.js
 * --------------
 * Express router for User Authentication & Learning Progress Persistence in PostgreSQL.
 *
 * Endpoints:
 *   POST /api/auth/register       — Create new user + initial progress in PostgreSQL
 *   POST /api/auth/login          — Authenticate user & fetch persisted progress
 *   GET  /api/auth/progress/:id   — Retrieve student's persisted XP, streak, & lessons
 *   POST /api/auth/progress/sync  — Save student's XP, streak, & completed lessons
 */

'use strict';

const express = require('express');
const crypto = require('crypto');
const db = require('../db');

const router = express.Router();

function hashPassword(password) {
  return crypto.createHash('sha256').update(password).digest('hex');
}

// ── POST /api/auth/register ──────────────────────────────────────────────────
router.post('/register', async (req, res) => {
  const { name, email, password } = req.body;

  if (!name || !email || !password) {
    return res.status(400).json({ success: false, error: 'Name, email, and password are required.' });
  }

  const normalizedEmail = email.trim().toLowerCase();
  const userId = `usr-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
  const pwdHash = hashPassword(password);

  try {
    // Check existing
    const existing = await db.query('SELECT id FROM users WHERE email = $1', [normalizedEmail]);
    if (existing.rows.length > 0) {
      return res.status(409).json({ success: false, error: 'An account with this email already exists.' });
    }

    // Insert User
    await db.query(
      'INSERT INTO users (id, name, email, password_hash) VALUES ($1, $2, $3, $4)',
      [userId, name.trim(), normalizedEmail, pwdHash]
    );

    // Insert Initial Progress
    const defaultProgress = {
      xp: 0,
      streak: 1,
      completed_lessons: [],
      completed_quizzes: [],
      ikp_scores: {},
      badges: ['first_step'],
    };

    await db.query(
      `INSERT INTO user_progress (user_id, xp, streak, completed_lessons, completed_quizzes, ikp_scores, badges)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [
        userId,
        defaultProgress.xp,
        defaultProgress.streak,
        JSON.stringify(defaultProgress.completed_lessons),
        JSON.stringify(defaultProgress.completed_quizzes),
        JSON.stringify(defaultProgress.ikp_scores),
        JSON.stringify(defaultProgress.badges),
      ]
    );

    const userObj = { id: userId, name: name.trim(), email: normalizedEmail };
    return res.json({
      success: true,
      user: userObj,
      progress: defaultProgress,
      token: `JWT-${userId}`,
    });
  } catch (err) {
    console.error('[auth] Register error:', err);
    return res.status(500).json({ success: false, error: 'Failed to create user account.', message: err.message });
  }
});

// ── POST /api/auth/login ─────────────────────────────────────────────────────
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ success: false, error: 'Email and password are required.' });
  }

  const normalizedEmail = email.trim().toLowerCase();
  const pwdHash = hashPassword(password);

  try {
    const result = await db.query('SELECT * FROM users WHERE email = $1', [normalizedEmail]);
    if (result.rows.length === 0) {
      return res.status(401).json({ success: false, error: 'Invalid email or password.' });
    }

    const user = result.rows[0];
    if (user.password_hash !== pwdHash) {
      return res.status(401).json({ success: false, error: 'Invalid email or password.' });
    }

    // Fetch user progress
    const progResult = await db.query('SELECT * FROM user_progress WHERE user_id = $1', [user.id]);
    let progress = {
      xp: 0,
      streak: 1,
      completed_lessons: [],
      completed_quizzes: [],
      ikp_scores: {},
      badges: [],
    };

    if (progResult.rows.length > 0) {
      const row = progResult.rows[0];
      progress = {
        xp: row.xp || 0,
        streak: row.streak || 1,
        completed_lessons: typeof row.completed_lessons === 'string' ? JSON.parse(row.completed_lessons) : (row.completed_lessons || []),
        completed_quizzes: typeof row.completed_quizzes === 'string' ? JSON.parse(row.completed_quizzes) : (row.completed_quizzes || []),
        ikp_scores: typeof row.ikp_scores === 'string' ? JSON.parse(row.ikp_scores) : (row.ikp_scores || {}),
        badges: typeof row.badges === 'string' ? JSON.parse(row.badges) : (row.badges || []),
      };
    }

    const userObj = { id: user.id, name: user.name, email: user.email };
    return res.json({
      success: true,
      user: userObj,
      progress,
      token: `JWT-${user.id}`,
    });
  } catch (err) {
    console.error('[auth] Login error:', err);
    return res.status(500).json({ success: false, error: 'Authentication error.', message: err.message });
  }
});

// ── GET /api/auth/progress/:userId ──────────────────────────────────────────
router.get('/progress/:userId', async (req, res) => {
  const { userId } = req.params;

  try {
    const result = await db.query('SELECT * FROM user_progress WHERE user_id = $1', [userId]);
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'User progress not found.' });
    }

    const row = result.rows[0];
    const progress = {
      xp: row.xp || 0,
      streak: row.streak || 1,
      completed_lessons: typeof row.completed_lessons === 'string' ? JSON.parse(row.completed_lessons) : (row.completed_lessons || []),
      completed_quizzes: typeof row.completed_quizzes === 'string' ? JSON.parse(row.completed_quizzes) : (row.completed_quizzes || []),
      ikp_scores: typeof row.ikp_scores === 'string' ? JSON.parse(row.ikp_scores) : (row.ikp_scores || {}),
      badges: typeof row.badges === 'string' ? JSON.parse(row.badges) : (row.badges || []),
    };

    return res.json({ success: true, progress });
  } catch (err) {
    console.error('[auth] Fetch progress error:', err);
    return res.status(500).json({ success: false, error: err.message });
  }
});

// ── POST /api/auth/progress/sync ─────────────────────────────────────────────
router.post('/progress/sync', async (req, res) => {
  const { user_id, xp, streak, completed_lessons, completed_quizzes, ikp_scores, badges } = req.body;

  if (!user_id) {
    return res.status(400).json({ success: false, error: 'user_id is required for progress sync.' });
  }

  try {
    await db.query(
      `INSERT INTO user_progress (user_id, xp, streak, completed_lessons, completed_quizzes, ikp_scores, badges, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, CURRENT_TIMESTAMP)
       ON CONFLICT (user_id) DO UPDATE SET
         xp = EXCLUDED.xp,
         streak = EXCLUDED.streak,
         completed_lessons = EXCLUDED.completed_lessons,
         completed_quizzes = EXCLUDED.completed_quizzes,
         ikp_scores = EXCLUDED.ikp_scores,
         badges = EXCLUDED.badges,
         updated_at = CURRENT_TIMESTAMP`,
      [
        user_id,
        xp || 0,
        streak || 1,
        JSON.stringify(completed_lessons || []),
        JSON.stringify(completed_quizzes || []),
        JSON.stringify(ikp_scores || {}),
        JSON.stringify(badges || []),
      ]
    );

    return res.json({ success: true, message: 'User progress persisted to PostgreSQL successfully.' });
  } catch (err) {
    console.error('[auth] Progress sync error:', err);
    return res.status(500).json({ success: false, error: 'Failed to sync progress.', message: err.message });
  }
});

module.exports = router;
