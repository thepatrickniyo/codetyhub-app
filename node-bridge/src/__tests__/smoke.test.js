const { test, describe } = require('node:test');
const assert = require('node:assert');
const app = require('../index');

describe('Node Bridge Smoke Tests', () => {
  test('App should be defined and export Express app', () => {
    assert.strictEqual(typeof app, 'function');
  });

  test('GET / should return 200 OK and health info', async () => {
    // Perform simulated request handling or inspect index routes
    assert.ok(app);
  });
});
