const express = require('express');
const router = express.Router();

const startTime = Date.now();

// GET /api/health — Liveness & Readiness probe
router.get('/', (_req, res) => {
  const uptimeMs = Date.now() - startTime;
  const uptimeSeconds = Math.floor(uptimeMs / 1000);

  res.status(200).json({
    status: 'ok',
    uptime: uptimeSeconds,
    uptimeFormatted: formatUptime(uptimeSeconds),
    timestamp: new Date().toISOString(),
    checks: {
      memory: getMemoryStatus(),
      eventLoop: 'ok',
    },
  });
});

// GET /api/health/ready — Readiness probe (can add DB checks etc.)
router.get('/ready', (_req, res) => {
  res.status(200).json({
    status: 'ready',
    timestamp: new Date().toISOString(),
  });
});

// GET /api/health/live — Liveness probe
router.get('/live', (_req, res) => {
  res.status(200).json({
    status: 'alive',
    timestamp: new Date().toISOString(),
  });
});

function getMemoryStatus() {
  const mem = process.memoryUsage();
  return {
    rss: `${Math.round(mem.rss / 1024 / 1024)}MB`,
    heapUsed: `${Math.round(mem.heapUsed / 1024 / 1024)}MB`,
    heapTotal: `${Math.round(mem.heapTotal / 1024 / 1024)}MB`,
    external: `${Math.round(mem.external / 1024 / 1024)}MB`,
  };
}

function formatUptime(seconds) {
  const days = Math.floor(seconds / 86400);
  const hours = Math.floor((seconds % 86400) / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = seconds % 60;

  const parts = [];
  if (days > 0) parts.push(`${days}d`);
  if (hours > 0) parts.push(`${hours}h`);
  if (minutes > 0) parts.push(`${minutes}m`);
  parts.push(`${secs}s`);

  return parts.join(' ');
}

module.exports = router;
