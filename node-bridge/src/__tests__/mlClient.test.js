const { test, describe } = require('node:test');
const assert = require('node:assert');
const mlClient = require('../services/mlClient');

describe('mlClient Service Tests', () => {
  test('mlClient exports correct configuration', () => {
    assert.strictEqual(typeof mlClient.get, 'function');
    assert.strictEqual(typeof mlClient.post, 'function');
    assert.ok(mlClient.defaults.baseURL.startsWith('http'));
  });

  test('mlClient request interceptor injects ML_SERVICE_TOKEN when set', async () => {
    process.env.ML_SERVICE_TOKEN = 'test-token-123';
    const config = { headers: {} };
    // Get the request interceptor function registered on mlClient
    const requestHandler = mlClient.interceptors.request.handlers[0].fulfilled;
    const resultConfig = requestHandler(config);
    assert.strictEqual(resultConfig.headers['X-Service-Token'], 'test-token-123');
    delete process.env.ML_SERVICE_TOKEN;
  });

  test('mlClient response interceptor passes successful response through', () => {
    const responseHandler = mlClient.interceptors.response.handlers[0].fulfilled;
    const mockRes = { status: 200, data: { ok: true } };
    assert.strictEqual(responseHandler(mockRes), mockRes);
  });

  test('mlClient response interceptor normalises errors', async () => {
    const errorHandler = mlClient.interceptors.response.handlers[0].rejected;
    const mockError = {
      response: { status: 404, data: { detail: 'Skill not found' } }
    };

    try {
      await errorHandler(mockError);
      assert.fail('Should have rejected');
    } catch (err) {
      assert.strictEqual(err.status, 404);
      assert.strictEqual(err.message, 'Skill not found');
      assert.strictEqual(err.isMLError, true);
    }

    // Fallback error without response status/detail
    try {
      await errorHandler(new Error('Connection refused'));
      assert.fail('Should have rejected');
    } catch (err) {
      assert.strictEqual(err.status, 503);
      assert.strictEqual(err.message, 'Connection refused');
      assert.strictEqual(err.isMLError, true);
    }
  });
});
