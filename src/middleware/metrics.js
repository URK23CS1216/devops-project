const client = require('prom-client');

// Create a custom registry or use the default
const register = client.register;

// Metrics
let httpRequestDuration;
let httpRequestTotal;
let httpRequestErrors;
let activeConnections;

function initMetrics() {
  // Collect default Node.js metrics (GC, event loop, memory, etc.)
  client.collectDefaultMetrics({
    register,
    prefix: 'devops_demo_',
  });

  // HTTP request duration histogram
  httpRequestDuration = new client.Histogram({
    name: 'devops_demo_http_request_duration_seconds',
    help: 'Duration of HTTP requests in seconds',
    labelNames: ['method', 'route', 'status_code'],
    buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 2, 5],
  });

  // HTTP request counter
  httpRequestTotal = new client.Counter({
    name: 'devops_demo_http_requests_total',
    help: 'Total number of HTTP requests',
    labelNames: ['method', 'route', 'status_code'],
  });

  // HTTP error counter
  httpRequestErrors = new client.Counter({
    name: 'devops_demo_http_request_errors_total',
    help: 'Total number of HTTP request errors (4xx and 5xx)',
    labelNames: ['method', 'route', 'status_code'],
  });

  // Active connections gauge
  activeConnections = new client.Gauge({
    name: 'devops_demo_active_connections',
    help: 'Number of active connections',
  });
}

// Middleware to track HTTP metrics
function metricsMiddleware(req, res, next) {
  // Skip metrics endpoint to avoid recursion
  if (req.path === '/metrics') {
    return next();
  }

  activeConnections.inc();
  const start = process.hrtime.bigint();

  res.on('finish', () => {
    activeConnections.dec();

    const durationNs = Number(process.hrtime.bigint() - start);
    const durationSeconds = durationNs / 1e9;

    // Normalize route to avoid high cardinality
    const route = normalizeRoute(req.path);
    const labels = {
      method: req.method,
      route,
      status_code: res.statusCode,
    };

    httpRequestDuration.observe(labels, durationSeconds);
    httpRequestTotal.inc(labels);

    if (res.statusCode >= 400) {
      httpRequestErrors.inc(labels);
    }
  });

  next();
}

function normalizeRoute(path) {
  // Collapse IDs and UUIDs to avoid high-cardinality labels
  return path
    .replace(/\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi, '/:id')
    .replace(/\/\d+/g, '/:id');
}

module.exports = { metricsMiddleware, initMetrics };
