/**
 * index.js
 * --------
 * CodetyHub Node.js ML Bridge — Express application entry point.
 *
 * This service acts as an API gateway between any Node.js consumers
 * (mobile BFF, web backend, admin dashboard) and the FastAPI ML microservice.
 *
 * Architecture:
 *   [Flutter / React Native] ──→ [node-bridge (Express)] ──→ [ML/ (FastAPI)]
 *
 * Mounted routes:
 *   /api/pathway       — Pathway recommendation
 *   /api/gamification  — Dropout risk & gamification engine
 *   /api/code-review   — CodeBERT VSS evaluation & leaderboard
 *
 * Environment variables (see .env.example):
 *   PORT              — HTTP port (default: 3001)
 *   ML_API_URL        — FastAPI base URL (default: http://localhost:8000)
 *   ML_API_TIMEOUT_MS — Axios timeout in ms (default: 15000)
 *   JWT_SECRET        — Secret for JWT verification
 *   ML_SERVICE_TOKEN  — Internal service-to-service token for FastAPI
 *
 * Usage:
 *   node src/index.js       (production)
 *   npx nodemon src/index.js  (development)
 */

'use strict';

require('dotenv').config();

const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

const pathwayRouter = require('./routes/pathway');
const gamificationRouter = require('./routes/gamification');
const codeReviewRouter = require('./routes/codeReview');

const app = express();
const PORT = parseInt(process.env.PORT || '3001', 10);
const ML_API_URL = process.env.ML_API_URL || 'http://localhost:8000';

// ── Middleware ─────────────────────────────────────────────────────────────────
app.use(cors());
app.use(express.json({ limit: '2mb' }));   // Allow large code submissions
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// ── Health check ───────────────────────────────────────────────────────────────
app.get('/', (req, res) => {
  res.json({
    service: 'CodetyHub Node Bridge',
    version: '1.0.0',
    status: 'ok',
    ml_api: ML_API_URL,
    routes: [
      'POST /api/pathway/recommend',
      'GET  /api/pathway/graph/info',
      'GET  /api/pathway/graph/prerequisites/:skillId',
      'POST /api/gamification/risk',
      'POST /api/gamification/batch',
      'GET  /api/gamification/features',
      'POST /api/code-review/evaluate',
      'GET  /api/code-review/leaderboard',
      'GET  /api/code-review/rubric',
    ],
  });
});

app.get('/health', (req, res) => res.json({ status: 'ok' }));

// ── Routers ────────────────────────────────────────────────────────────────────
app.use('/api/pathway', pathwayRouter);
app.use('/api/gamification', gamificationRouter);
app.use('/api/code-review', codeReviewRouter);

// ── 404 handler ───────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.method} ${req.path} does not exist.`,
  });
});

// ── Global error handler ──────────────────────────────────────────────────────
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  console.error('[node-bridge] Unhandled error:', err);
  res.status(err.status || 500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'production' ? 'Something went wrong.' : err.message,
  });
});

// ── Start ──────────────────────────────────────────────────────────────────────
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`\n🚀 CodetyHub Node Bridge running on http://localhost:${PORT}`);
    console.log(`   ML API target: ${ML_API_URL}`);
    console.log(`   Routes: /api/pathway | /api/gamification | /api/code-review\n`);
  });
}

module.exports = app;   // Export for testing
