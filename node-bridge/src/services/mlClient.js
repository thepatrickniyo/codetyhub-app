/**
 * mlClient.js
 * -----------
 * Axios HTTP client for communicating with the CodetyHub FastAPI ML microservice.
 *
 * All ML-facing requests flow through this single module, giving us:
 *   - Centralised base URL configuration (via ML_API_URL env var)
 *   - Uniform timeout and error handling
 *   - Request/response logging hooks
 *   - Easy swap to a remote URL in staging/production
 *
 * Usage:
 *   const mlClient = require('./mlClient');
 *   const result = await mlClient.post('/pathway/recommend', { ... });
 */

'use strict';

const axios = require('axios');

const ML_API_URL = process.env.ML_API_URL || 'http://localhost:8000';
const ML_API_TIMEOUT = parseInt(process.env.ML_API_TIMEOUT_MS || '15000', 10);

const client = axios.create({
  baseURL: ML_API_URL,
  timeout: ML_API_TIMEOUT,
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  },
});

// ── Request interceptor: inject internal service token ─────────────────────
client.interceptors.request.use((config) => {
  const serviceToken = process.env.ML_SERVICE_TOKEN;
  if (serviceToken) {
    config.headers['X-Service-Token'] = serviceToken;
  }
  return config;
});

// ── Response interceptor: normalise errors ─────────────────────────────────
client.interceptors.response.use(
  (response) => response,
  (error) => {
    const status = error.response?.status || 503;
    const detail = error.response?.data?.detail || error.message || 'ML service unavailable';
    const normalised = new Error(detail);
    normalised.status = status;
    normalised.isMLError = true;
    return Promise.reject(normalised);
  },
);

module.exports = client;
