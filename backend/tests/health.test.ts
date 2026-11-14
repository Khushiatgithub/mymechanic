import request from 'supertest';
import { createApp } from '../src/app';

describe('MyMechanic Backend API - Health & Base Infrastructure', () => {
  const app = createApp();

  describe('GET /api/v1/health', () => {
    it('should return 200 OK and valid health payload', async () => {
      const response = await request(app).get('/api/v1/health');

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('success', true);
      expect(response.body).toHaveProperty('message', 'MyMechanic API is healthy');
      expect(response.body).toHaveProperty('data');
      expect(response.body.data).toHaveProperty('environment');
      expect(response.body.data).toHaveProperty('timestamp');
      expect(response.body.data).toHaveProperty('uptimeSeconds');
      expect(response.body.data).toHaveProperty('database');
      expect(response.body.data.database).toHaveProperty('isConnected');
      expect(response.body.data.database).toHaveProperty('state');
    });
  });

  describe('GET / (Root Gateway)', () => {
    it('should return 200 and API welcome information', async () => {
      const response = await request(app).get('/');

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('service', 'MyMechanic Backend API');
      expect(response.body.data).toHaveProperty('version', 'v1');
    });
  });

  describe('404 Not Found Middleware', () => {
    it('should return 404 and standardized error envelope for unknown endpoints', async () => {
      const response = await request(app).get('/api/v1/non-existent-route-xyz');

      expect(response.status).toBe(404);
      expect(response.body).toEqual({
        success: false,
        message: expect.stringContaining('Endpoint not found'),
        error: {
          code: 'NOT_FOUND',
        },
      });
    });
  });
});
