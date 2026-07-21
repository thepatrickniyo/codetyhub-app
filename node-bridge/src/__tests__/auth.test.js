const { test, describe } = require('node:test');
const assert = require('node:assert');
const { requireAuth, optionalAuth } = require('../middleware/auth');

describe('JWT Auth Middleware Tests', () => {
  test('requireAuth should reject missing Authorization header with 401', () => {
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
    const next = () => { nextCalled = true; };

    requireAuth(req, res, next);

    assert.strictEqual(statusSent, 401);
    assert.strictEqual(jsonSent.error, 'Unauthorised');
    assert.strictEqual(nextCalled, false);
  });

  test('requireAuth should accept valid Bearer token and attach user to req', () => {
    const req = { headers: { authorization: 'Bearer test-valid-jwt-token-12345' } };
    const res = {};
    let nextCalled = false;
    const next = () => { nextCalled = true; };

    requireAuth(req, res, next);

    assert.strictEqual(nextCalled, true);
    assert.ok(req.user);
    assert.strictEqual(req.user.role, 'student');
  });

  test('optionalAuth should attach user if Bearer token present but continue anyway', () => {
    const reqWithToken = { headers: { authorization: 'Bearer test-valid-jwt-token-12345' } };
    let nextCalled = false;
    optionalAuth(reqWithToken, {}, () => { nextCalled = true; });

    assert.strictEqual(nextCalled, true);
    assert.ok(reqWithToken.user);

    const reqWithoutToken = { headers: {} };
    nextCalled = false;
    optionalAuth(reqWithoutToken, {}, () => { nextCalled = true; });

    assert.strictEqual(nextCalled, true);
    assert.strictEqual(reqWithoutToken.user, undefined);
  });
});
