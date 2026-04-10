const express = require('express');
const os = require('os');
const router = express.Router();

const pkg = require('../../package.json');

// GET /api/info — Application information
router.get('/', (_req, res) => {
  res.status(200).json({
    app: {
      name: pkg.name,
      version: pkg.version,
      description: pkg.description,
    },
    environment: process.env.NODE_ENV || 'development',
    runtime: {
      nodeVersion: process.version,
      platform: process.platform,
      arch: process.arch,
      pid: process.pid,
    },
    host: {
      hostname: os.hostname(),
      cpus: os.cpus().length,
      totalMemory: `${Math.round(os.totalmem() / 1024 / 1024)}MB`,
      freeMemory: `${Math.round(os.freemem() / 1024 / 1024)}MB`,
    },
    deploy: {
      imageTag: process.env.IMAGE_TAG || 'local',
      buildDate: process.env.BUILD_DATE || 'unknown',
      commitSha: process.env.COMMIT_SHA || 'unknown',
    },
    timestamp: new Date().toISOString(),
  });
});

module.exports = router;
