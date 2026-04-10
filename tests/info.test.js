const request = require('supertest');
const app = require('../src/server');

describe('Info Endpoint', () => {
  describe('GET /api/info', () => {
    it('should return 200 with app information', async () => {
      const res = await request(app).get('/api/info');

      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('app');
      expect(res.body.app).toHaveProperty('name', 'devops-demo');
      expect(res.body.app).toHaveProperty('version');
      expect(res.body.app).toHaveProperty('description');
    });

    it('should include runtime information', async () => {
      const res = await request(app).get('/api/info');

      expect(res.body).toHaveProperty('runtime');
      expect(res.body.runtime).toHaveProperty('nodeVersion');
      expect(res.body.runtime).toHaveProperty('platform');
      expect(res.body.runtime).toHaveProperty('arch');
      expect(res.body.runtime).toHaveProperty('pid');
    });

    it('should include host information', async () => {
      const res = await request(app).get('/api/info');

      expect(res.body).toHaveProperty('host');
      expect(res.body.host).toHaveProperty('hostname');
      expect(res.body.host).toHaveProperty('cpus');
      expect(res.body.host).toHaveProperty('totalMemory');
    });

    it('should include deployment metadata', async () => {
      const res = await request(app).get('/api/info');

      expect(res.body).toHaveProperty('deploy');
      expect(res.body.deploy).toHaveProperty('imageTag');
      expect(res.body.deploy).toHaveProperty('buildDate');
      expect(res.body.deploy).toHaveProperty('commitSha');
    });

    it('should return valid timestamp', async () => {
      const res = await request(app).get('/api/info');
      const timestamp = new Date(res.body.timestamp);
      expect(timestamp.toISOString()).toBe(res.body.timestamp);
    });
  });
});

describe('404 Handler', () => {
  it('should return 404 for unknown routes', async () => {
    const res = await request(app).get('/api/nonexistent');

    expect(res.statusCode).toBe(404);
    expect(res.body).toHaveProperty('error', 'Not Found');
    expect(res.body).toHaveProperty('message');
  });
});
