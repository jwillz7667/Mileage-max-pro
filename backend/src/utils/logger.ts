import pino from 'pino';
import { config } from '../config/env.js';

export const logger = pino({
  level: config.server.isDevelopment ? 'debug' : 'info',
  transport: config.server.isDevelopment
    ? {
        target: 'pino-pretty',
        options: {
          colorize: true,
          translateTime: 'SYS:standard',
          ignore: 'pid,hostname',
        },
      }
    : undefined,
  base: {
    env: config.server.env,
  },
  redact: {
    paths: [
      'req.headers.authorization',
      'req.headers.cookie',
      'res.headers["set-cookie"]',
      '*.password',
      '*.token',
      '*.accessToken',
      '*.refreshToken',
      '*.identityToken',
    ],
    remove: true,
  },
});

export const httpLogger = pino({
  level: config.server.isDevelopment ? 'debug' : 'info',
  transport: config.server.isDevelopment
    ? {
        target: 'pino-pretty',
        options: {
          colorize: true,
          translateTime: 'SYS:standard',
          ignore: 'pid,hostname',
        },
      }
    : undefined,
  serializers: {
    req: (req) => ({
      method: req.method,
      url: req.url,
      query: req.query,
      params: req.params,
    }),
    res: (res) => ({
      statusCode: res.statusCode,
    }),
  },
});

// Contextual loggers
export const authLogger = logger.child({ module: 'auth' });
export const tripLogger = logger.child({ module: 'trip' });
export const vehicleLogger = logger.child({ module: 'vehicle' });
export const routeLogger = logger.child({ module: 'route' });
export const expenseLogger = logger.child({ module: 'expense' });
export const reportLogger = logger.child({ module: 'report' });
export const jobLogger = logger.child({ module: 'job' });
export const webhookLogger = logger.child({ module: 'webhook' });
