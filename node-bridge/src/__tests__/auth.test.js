const { test, describe } = require('node:test');
const assert = require('node:assert');
const { requireAuth, optionalAuth } = require('../middleware/auth');

describe('JWT Auth Middleware Tests', () => {
  test('requireAuth rejects missing Authorization header with 401', () => {
    const req = { headers: {} };
    let statusSent = null;
    let jsonSent = null;
    const res = {
      status(code) {
        statusSent = code;
        return this;
      },
      json(body) {
        jsonSent = body;
        return this;
      }
    };
    let nextCalled = false;
    requireAuth(req, res, () => { nextCalled = true; });

    assert.strictEqual(statusSent, 401);
    assert.strictEqual(jsonSent.error, 'Unauthorised');
    assert.strictEqual(nextCalled, false);
  });

  test('requireAuth rejects short/invalid token with 401', () => {
    const req = { headers: { authorization: 'Bearer short' } };
    let statusSent = null;
    let jsonSent = null;
    const res = {
      status(code) {
        statusSent = code;
        return this;
      },
      json(body) {
        jsonSent = body;
        return this;
      }
    };
    let nextCalled = false;
    requireAuth(req, res, () => { nextCalled = true; });

    assert.strictEqual(statusSent, 401);
    assert.strictEqual(jsonSent.message, 'Invalid or expired token.');
    assert.strictEqual(nextCalled, false);
  });

  test('requireAuth accepts valid Bearer token and attaches user to req', () => {
    const req = { headers: { authorization: 'Bearer valid-long-jwt-token-12345' } };
    let nextCalled = false;
    requireAuth(req, {}, () => { nextCalled = true; });

    assert.strictEqual(nextCalled, true);
    assert.ok(req.user);
    assert.strictEqual(req.user.role, 'student');
  });

  test('optionalAuth attaches user if valid token present', () => {
    const req = { headers: { authorization: 'Bearer valid-long-jwt-token-12345' } };
    let nextCalled = false;
    optionalAuth(req, {}, () => { nextCalled = true; });

    assert.strictEqual(nextCalled, true);
    assert.ok(req.user);
  });

  test('optionalAuth continues without user if no token present', () => {
    const req = { headers: {} };
    let nextCalled = false;
    optionalAuth(req, {}, () => { nextCalled = true; });

    assert.strictEqual(nextCalled, true);
    assert.strictEqual(req.user, undefined);
  });
});
