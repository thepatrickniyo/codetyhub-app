const { test, describe } = require('node:test');
const assert = require('node:assert');
const mlClient = require('../services/mlClient');

describe('Node Bridge Services & Proxy Tests', () => {
  test('mlClient should export helper request functions', () => {
    assert.strictEqual(typeof mlClient.post, 'function');
    assert.strictEqual(typeof mlClient.get, 'function');
  });

  test('mlClient baseURL returns configured base URL', () => {
    assert.ok(mlClient.defaults.baseURL.startsWith('http'));
  });
});
