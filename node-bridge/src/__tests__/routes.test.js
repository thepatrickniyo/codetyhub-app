const { test, describe, before, after } = require('node:test');
const assert = require('node:assert');
const app = require('../index');
const mlClient = require('../services/mlClient');

let server;
let baseUrl;

describe('Express Route Endpoints & Handler Tests', () => {
  before(async () => {
    await new Promise((resolve) => {
      server = app.listen(0, () => {
        const port = server.address().port;
        baseUrl = `http://127.0.0.1:${port}`;
        resolve();
      });
    });
  });

  after(async () => {
    await new Promise((resolve) => server.close(resolve));
  });

  const authHeader = {
    authorization: 'Bearer valid-test-bearer-token-12345',
    'content-type': 'application/json'
  };

  // ── Pathway Routes ──────────────────────────────────────────────────────────
  describe('Pathway Routes', () => {
    test('POST /api/pathway/recommend validation failure (422)', async () => {
      const res = await fetch(`${baseUrl}/api/pathway/recommend`, {
        method: 'POST',
        headers: authHeader,
        body: JSON.stringify({})
      });
      assert.strictEqual(res.status, 422);
      const json = await res.json();
      assert.strictEqual(json.error, 'Validation failed');
    });

    test('POST /api/pathway/recommend success', async () => {
      const origPost = mlClient.post;
      mlClient.post = async () => ({ data: { recommendations: ['python_basics'] } });

      const payload = {
        student_id: 'STU-001',
        ikp: { proficiency_scores: { python_basics: 0.9 } }
      };
      const res = await fetch(`${baseUrl}/api/pathway/recommend`, {
        method: 'POST',
        headers: authHeader,
        body: JSON.stringify(payload)
      });
      assert.strictEqual(res.status, 200);
      const json = await res.json();
      assert.strictEqual(json.success, true);
      assert.deepStrictEqual(json.data.recommendations, ['python_basics']);

      mlClient.post = origPost;
    });

    test('POST /api/pathway/recommend error handling (502)', async () => {
      const origPost = mlClient.post;
      mlClient.post = async () => {
        const err = new Error('ML connection failed');
        err.status = 502;
        throw err;
      };

      const payload = {
        student_id: 'STU-001',
        ikp: { proficiency_scores: { python_basics: 0.9 } }
      };
      const res = await fetch(`${baseUrl}/api/pathway/recommend`, {
        method: 'POST',
        headers: authHeader,
        body: JSON.stringify(payload)
      });
      assert.strictEqual(res.status, 502);
      const json = await res.json();
      assert.strictEqual(json.success, false);
      assert.strictEqual(json.error, 'ML service error');

      mlClient.post = origPost;
    });

    test('GET /api/pathway/graph/info success & error', async () => {
      const origGet = mlClient.get;
      mlClient.get = async () => ({ data: { nodes_count: 32 } });

      let res = await fetch(`${baseUrl}/api/pathway/graph/info`);
      assert.strictEqual(res.status, 200);
      let json = await res.json();
      assert.strictEqual(json.data.nodes_count, 32);

      mlClient.get = async () => {
        const err = new Error('Graph service offline');
        err.status = 503;
        throw err;
      };
      res = await fetch(`${baseUrl}/api/pathway/graph/info`);
      assert.strictEqual(res.status, 503);
      json = await res.json();
      assert.strictEqual(json.success, false);

      mlClient.get = origGet;
    });

    test('GET /api/pathway/graph/prerequisites/:skillId success', async () => {
      const origGet = mlClient.get;
      mlClient.get = async () => ({ data: { prerequisites: ['python_basics'] } });

      const res = await fetch(`${baseUrl}/api/pathway/graph/prerequisites/numpy_basics`);
      assert.strictEqual(res.status, 200);
      const json = await res.json();
      assert.strictEqual(json.success, true);

      mlClient.get = async () => { throw new Error('Prerequisite error'); };
      const errRes = await fetch(`${baseUrl}/api/pathway/graph/prerequisites/numpy_basics`);
      assert.strictEqual(errRes.status, 502);

      mlClient.get = origGet;
    });
  });

  // ── Gamification Routes ──────────────────────────────────────────────────────
  describe('Gamification Routes', () => {
    test('POST /api/gamification/risk validation failure & success (including HIGH risk)', async () => {
      let res = await fetch(`${baseUrl}/api/gamification/risk`, {
        method: 'POST',
        headers: authHeader,
        body: JSON.stringify({})
      });
      assert.strictEqual(res.status, 422);

      const origPost = mlClient.post;
      mlClient.post = async () => ({
        data: {
          student_id: 'STU-001',
          risk_score: 0.85,
          risk_band: 'HIGH',
          interventions: [{ type: 'STREAK_FREEZE' }]
        }
      });

      const payload = {
        student_id: 'STU-001',
        ikp: { proficiency_scores: { python_basics: 0.5 } },
        engagement: { current_streak: 2 }
      };
      res = await fetch(`${baseUrl}/api/gamification/risk`, {
        method: 'POST',
        headers: authHeader,
        body: JSON.stringify(payload)
      });
      assert.strictEqual(res.status, 200);
      let json = await res.json();
      assert.strictEqual(json.data.risk_band, 'HIGH');

      mlClient.post = async () => { throw new Error('Gamification error'); };
      res = await fetch(`${baseUrl}/api/gamification/risk`, {
        method: 'POST',
        headers: authHeader,
        body: JSON.stringify(payload)
      });
      assert.strictEqual(res.status, 502);

      mlClient.post = origPost;
    });

    test('POST /api/gamification/batch success & error', async () => {
      const origPost = mlClient.post;
      mlClient.post = async () => ({
        data: [
          { student_id: 'STU-001', risk_band: 'HIGH' },
          { student_id: 'STU-002', risk_band: 'LOW' }
        ]
      });

      let res = await fetch(`${baseUrl}/api/gamification/batch`, {
        method: 'POST',
        headers: authHeader,
        body: JSON.stringify([{ student_id: 'STU-001' }])
      });
      assert.strictEqual(res.status, 200);
      let json = await res.json();
      assert.strictEqual(json.high_risk_count, 1);

      mlClient.post = async () => { throw new Error('Batch error'); };
      res = await fetch(`${baseUrl}/api/gamification/batch`, {
        method: 'POST',
        headers: authHeader,
        body: JSON.stringify([{ student_id: 'STU-001' }])
      });
      assert.strictEqual(res.status, 502);

      mlClient.post = origPost;
    });

    test('GET /api/gamification/features success & error', async () => {
      const origGet = mlClient.get;
      mlClient.get = async () => ({ data: { features: 34 } });

      let res = await fetch(`${baseUrl}/api/gamification/features`);
      assert.strictEqual(res.status, 200);

      mlClient.get = async () => { throw new Error('Feature error'); };
      res = await fetch(`${baseUrl}/api/gamification/features`);
      assert.strictEqual(res.status, 502);

      mlClient.get = origGet;
    });
  });

  // ── Code Review Routes ───────────────────────────────────────────────────────
  describe('Code Review Routes', () => {
    test('POST /api/code-review/evaluate validation failure & success', async () => {
      let res = await fetch(`${baseUrl}/api/code-review/evaluate`, {
        method: 'POST',
        headers: authHeader,
        body: JSON.stringify({})
      });
      assert.strictEqual(res.status, 422);

      const origPost = mlClient.post;
      mlClient.post = async () => ({
        data: { vss: 88.0, leaderboard_rank: 1 }
      });

      const payload = {
        student_id: 'STU-001',
        skill_node: 'linear_regression',
        code_text: 'import numpy as np\ndef test(): pass'
      };
      res = await fetch(`${baseUrl}/api/code-review/evaluate`, {
        method: 'POST',
        headers: authHeader,
        body: JSON.stringify(payload)
      });
      assert.strictEqual(res.status, 200);
      let json = await res.json();
      assert.strictEqual(json.data.vss, 88.0);

      mlClient.post = async () => { throw new Error('Code review error'); };
      res = await fetch(`${baseUrl}/api/code-review/evaluate`, {
        method: 'POST',
        headers: authHeader,
        body: JSON.stringify(payload)
      });
      assert.strictEqual(res.status, 502);

      mlClient.post = origPost;
    });

    test('GET /api/code-review/leaderboard success & error', async () => {
      const origGet = mlClient.get;
      mlClient.get = async () => ({ data: [{ rank: 1, student_id: 'STU-001' }] });

      let res = await fetch(`${baseUrl}/api/code-review/leaderboard?limit=10`, {
        headers: authHeader
      });
      assert.strictEqual(res.status, 200);
      let json = await res.json();
      assert.ok(json.viewer);

      mlClient.get = async () => { throw new Error('Leaderboard error'); };
      res = await fetch(`${baseUrl}/api/code-review/leaderboard`);
      assert.strictEqual(res.status, 502);

      mlClient.get = origGet;
    });

    test('GET /api/code-review/rubric success & error', async () => {
      const origGet = mlClient.get;
      mlClient.get = async () => ({ data: { code_correctness: 0.35 } });

      let res = await fetch(`${baseUrl}/api/code-review/rubric`);
      assert.strictEqual(res.status, 200);

      mlClient.get = async () => { throw new Error('Rubric error'); };
      res = await fetch(`${baseUrl}/api/code-review/rubric`);
      assert.strictEqual(res.status, 502);

      mlClient.get = origGet;
    });
  });
});
