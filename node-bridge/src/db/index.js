/**
 * db/index.js
 * -----------
 * PostgreSQL database pool connection and schema auto-initializer.
 */

'use strict';

const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5435', 10),
  database: process.env.DB_NAME || 'codetyhub_db',
  user: process.env.DB_USER || 'codetyhub_user',
  password: process.env.DB_PASSWORD || 'codetyhub_password',
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

async function initDatabase() {
  try {
    const client = await pool.connect();
    console.log('[db] Connected to PostgreSQL database successfully.');

    // Ensure schema tables exist
    const initSqlPath = path.join(__dirname, 'init.sql');
    if (fs.existsSync(initSqlPath)) {
      const sql = fs.readFileSync(initSqlPath, 'utf8');
      await client.query(sql);
      console.log('[db] Verified PostgreSQL tables (users, user_progress).');
    }
    client.release();
    return true;
  } catch (err) {
    console.warn('[db] PostgreSQL connection warning:', err.message);
    console.warn('[db] Running with database fallback capability.');
    return false;
  }
}

module.exports = {
  pool,
  query: (text, params) => pool.query(text, params),
  initDatabase,
};
