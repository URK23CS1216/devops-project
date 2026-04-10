const request = require('supertest');
const app = require('../src/server');

describe('Health Check Endpoints', () => {
  describe('GET /api/health', () => {
    it('should return 200 with status ok', async () => {
      const res = await request(app).get('/api/health');

      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('status', 'ok');
      expect(res.body).toHaveProperty('uptime');
      expect(res.body).toHaveProperty('uptimeFormatted');
      expect(res.body).toHaveProperty('timestamp');
      expect(res.body).toHaveProperty('checks');
    });

    it('should include memory status in checks', async () => {
      const res = await request(app).get('/api/health');

      expect(res.body.checks).toHaveProperty('memory');
      expect(res.body.checks.memory).toHaveProperty('rss');
      expect(res.body.checks.memory).toHaveProperty('heapUsed');
      expect(res.body.checks.memory).toHaveProperty('heapTotal');
    });

    it('should return valid ISO timestamp', async () => {
      const res = await request(app).get('/api/health');

      const timestamp = new Date(res.body.timestamp);
      expect(timestamp.toISOString()).toBe(res.body.timestamp);
    });
  });

  describe('GET /api/health/ready', () => {
    it('should return 200 with ready status', async () => {
      const res = await request(app).get('/api/health/ready');

      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('status', 'ready');
      expect(res.body).toHaveProperty('timestamp');
    });
  });

  describe('GET /api/health/live', () => {
    it('should return 200 with alive status', async () => {
      const res = await request(app).get('/api/health/live');

      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('status', 'alive');
      expect(res.body).toHaveProperty('timestamp');
    });
  });
});
