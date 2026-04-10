const express = require('express');
const path = require('path');
const { register } = require('prom-client');
const { metricsMiddleware, initMetrics } = require('./middleware/metrics');
const { logger, httpLogger } = require('./middleware/logger');
const healthRouter = require('./routes/health');
const infoRouter = require('./routes/info');

require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;
const NODE_ENV = process.env.NODE_ENV || 'development';

// Initialize Prometheus metrics
initMetrics();

// Middleware
app.use(express.json());
app.use(httpLogger);
app.use(metricsMiddleware);

// Static files
app.use(express.static(path.join(__dirname, 'public')));

// API Routes
app.use('/api/health', healthRouter);
app.use('/api/info', infoRouter);

// Prometheus metrics endpoint
app.get('/metrics', async (_req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
  } catch (err) {
    logger.error('Error collecting metrics', { error: err.message });
    res.status(500).end();
  }
});

// Root — serve dashboard
app.get('/', (_req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// 404 handler
app.use((_req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: 'The requested resource does not exist',
    timestamp: new Date().toISOString(),
  });
});

// Global error handler
app.use((err, _req, res, _next) => {
  logger.error('Unhandled error', {
    error: err.message,
    stack: err.stack,
  });
  res.status(500).json({
    error: 'Internal Server Error',
    message: NODE_ENV === 'production' ? 'Something went wrong' : err.message,
    timestamp: new Date().toISOString(),
  });
});

// Start server (only if not in test mode)
let server;
if (process.env.NODE_ENV !== 'test') {
  server = app.listen(PORT, () => {
    logger.info('DevOps Demo server running', {
      port: PORT,
      environment: NODE_ENV,
      pid: process.pid,
      nodeVersion: process.version,
    });
  });
}

// Graceful shutdown
const gracefulShutdown = (signal) => {
  logger.info(`${signal} received. Starting graceful shutdown...`);

  if (server) {
    server.close(() => {
      logger.info('HTTP server closed');
      process.exit(0);
    });

    // Force shutdown after 30s
    setTimeout(() => {
      logger.error('Forced shutdown after timeout');
      process.exit(1);
    }, 30000);
  } else {
    process.exit(0);
  }
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Export for testing
module.exports = app;
