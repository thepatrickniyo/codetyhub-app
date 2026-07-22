const { test, describe, before, after } = require('node:test');
const assert = require('node:assert');
const app = require('../index');

let server;
let baseUrl;

describe('Node Bridge Smoke & Index Route Tests', () => {
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

  test('App should be defined and export Express app', () => {
    assert.strictEqual(typeof app, 'function');
  });

  test('GET / returns health info and route catalogue', async () => {
    const res = await fetch(`${baseUrl}/`);
    assert.strictEqual(res.status, 200);
    const json = await res.json();
    assert.strictEqual(json.service, 'CodetyHub Node Bridge');
    assert.strictEqual(json.status, 'ok');
    assert.ok(Array.isArray(json.routes));
  });

  test('GET /health returns status ok', async () => {
    const res = await fetch(`${baseUrl}/health`);
    assert.strictEqual(res.status, 200);
    const json = await res.json();
    assert.strictEqual(json.status, 'ok');
  });

  test('Unmatched route returns 404 Not Found', async () => {
    const res = await fetch(`${baseUrl}/non-existent-route`);
    assert.strictEqual(res.status, 404);
    const json = await res.json();
    assert.strictEqual(json.error, 'Not Found');
  });
});
