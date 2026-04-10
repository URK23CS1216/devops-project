const winston = require('winston');

const LOG_LEVEL = process.env.LOG_LEVEL || 'info';
const NODE_ENV = process.env.NODE_ENV || 'development';

// Create Winston logger with structured JSON output
const logger = winston.createLogger({
  level: LOG_LEVEL,
  format: winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss.SSS' }),
    winston.format.errors({ stack: true }),
    NODE_ENV === 'production'
      ? winston.format.json()
      : winston.format.combine(
        winston.format.colorize(),
        winston.format.printf(({ timestamp, level, message, ...meta }) => {
          const metaStr = Object.keys(meta).length ? ` ${JSON.stringify(meta)}` : '';
          return `${timestamp} [${level}]: ${message}${metaStr}`;
        }),
      ),
  ),
  defaultMeta: {
    service: 'devops-demo',
    environment: NODE_ENV,
  },
  transports: [
    new winston.transports.Console(),
  ],
});

// HTTP request logging middleware
function httpLogger(req, res, next) {
  const start = Date.now();

  res.on('finish', () => {
    const duration = Date.now() - start;
    const logData = {
      method: req.method,
      url: req.originalUrl,
      statusCode: res.statusCode,
      duration: `${duration}ms`,
      contentLength: res.get('content-length') || 0,
      userAgent: req.get('user-agent'),
      ip: req.ip,
    };

    // Don't log health checks in production to reduce noise
    if (NODE_ENV === 'production' && req.path.includes('/health')) {
      return;
    }

    if (res.statusCode >= 500) {
      logger.error('HTTP Request', logData);
    } else if (res.statusCode >= 400) {
      logger.warn('HTTP Request', logData);
    } else {
      logger.info('HTTP Request', logData);
    }
  });

  next();
}

module.exports = { logger, httpLogger };
