import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import cookieParser from 'cookie-parser';
import pinoHttp from 'pino-http';
import { config } from './config/env.js';
import { connectDatabase, disconnectDatabase } from './config/database.js';
import { connectRedis, disconnectRedis } from './config/redis.js';
import { logger, httpLogger } from './utils/logger.js';
import { rateLimiter } from './middleware/rate-limit.middleware.js';
import { notFoundHandler, errorHandler } from './middleware/error.middleware.js';
import { closeQueues } from './jobs/queues.js';

// Import routes
import authRoutes from './routes/auth.routes.js';
import tripRoutes from './routes/trip.routes.js';
import vehicleRoutes from './routes/vehicle.routes.js';
import routeRoutes from './routes/route.routes.js';
import expenseRoutes from './routes/expense.routes.js';
import analyticsRoutes from './routes/analytics.routes.js';

const app = express();

// Trust proxy (for Railway)
app.set('trust proxy', 1);

// Security middleware
app.use(
  helmet({
    contentSecurityPolicy: config.server.isProduction,
    crossOriginEmbedderPolicy: false,
  })
);

// CORS configuration
app.use(
  cors({
    origin: (origin, callback) => {
      // Allow requests with no origin (mobile apps, Postman)
      if (!origin) {
        callback(null, true);
        return;
      }

      // Check against configured origins
      if (config.server.corsOrigins.includes(origin)) {
        callback(null, true);
        return;
      }

      // Allow mileagemaxpro:// scheme for iOS app
      if (origin.startsWith('mileagemaxpro://')) {
        callback(null, true);
        return;
      }

      callback(new Error('Not allowed by CORS'));
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Device-Id', 'X-Request-Id'],
    exposedHeaders: ['X-RateLimit-Limit', 'X-RateLimit-Remaining', 'X-RateLimit-Reset'],
    maxAge: 86400,
  })
);

// Compression
app.use(compression());

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(cookieParser());

// Request logging
app.use(
  pinoHttp({
    logger: httpLogger,
    autoLogging: {
      ignore: (req) => req.url === '/health' || req.url === '/ready',
    },
    customProps: (req) => ({
      userId: (req as { user?: { id: string } }).user?.id,
    }),
  })
);

// Rate limiting (applied to all API routes)
app.use('/api', rateLimiter);

// Health check endpoints
app.get('/health', (_req, res) => {
  console.log('Health check hit');
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Debug: Log all incoming requests
app.use((req, _res, next) => {
  console.log(`[DEBUG] ${req.method} ${req.path} from ${req.ip}`);
  next();
});

app.get('/ready', async (_req, res) => {
  try {
    // Add database/redis checks here if needed
    res.json({ status: 'ready', timestamp: new Date().toISOString() });
  } catch {
    res.status(503).json({ status: 'not ready' });
  }
});

// API versioning
const apiRouter = express.Router();

// Mount routes
apiRouter.use('/auth', authRoutes);
apiRouter.use('/trips', tripRoutes);
apiRouter.use('/vehicles', vehicleRoutes);
apiRouter.use('/routes', routeRoutes);
apiRouter.use('/expenses', expenseRoutes);
apiRouter.use('/analytics', analyticsRoutes);

// Mount API router
app.use(`/api/${config.server.apiVersion}`, apiRouter);

// 404 handler
app.use(notFoundHandler);

// Error handler
app.use(errorHandler);

// Graceful shutdown
async function shutdown(): Promise<void> {
  logger.info('Shutting down server...');

  await closeQueues();
  await disconnectDatabase();
  await disconnectRedis();

  logger.info('Server shut down successfully');
  process.exit(0);
}

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

// Start server
async function start(): Promise<void> {
  try {
    logger.info({ port: config.server.port }, 'Starting server...');

    // Start HTTP server first (so healthcheck passes during DB connection)
    // Explicitly bind to 0.0.0.0 for Railway compatibility
    const server = app.listen(config.server.port, '0.0.0.0', () => {
      logger.info({
        env: config.server.env,
        apiVersion: config.server.apiVersion,
        port: config.server.port,
      }, `Server running on port ${config.server.port}`);
    });

    // Handle server errors
    server.on('error', (error: NodeJS.ErrnoException) => {
      if (error.code === 'EADDRINUSE') {
        logger.error(`Port ${config.server.port} is already in use`);
        process.exit(1);
      }
      throw error;
    });

    // Connect to database and Redis after server is listening
    await connectDatabase();
    await connectRedis();

    logger.info('All connections established successfully');
  } catch (error) {
    logger.error({ error }, 'Failed to start server');
    process.exit(1);
  }
}

start();

export default app;
