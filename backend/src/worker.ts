import { Worker } from 'bullmq';
import { redis } from './config/redis.js';
import { connectDatabase, disconnectDatabase } from './config/database.js';
import { jobLogger } from './utils/logger.js';
import {
  processTripJob,
  processReportJob,
  processRouteOptimizationJob,
  processNotificationJob,
  processSyncJob,
} from './jobs/processors.js';

const workerOptions = {
  connection: redis,
  concurrency: 5,
};

// Create workers
const tripWorker = new Worker('trip-processing', processTripJob, workerOptions);
const reportWorker = new Worker('report-generation', processReportJob, {
  ...workerOptions,
  concurrency: 2,
});
const routeWorker = new Worker('route-optimization', processRouteOptimizationJob, workerOptions);
const notificationWorker = new Worker('notifications', processNotificationJob, {
  ...workerOptions,
  concurrency: 10,
});
const syncWorker = new Worker('sync', processSyncJob, workerOptions);

// Event handlers for all workers
const workers = [tripWorker, reportWorker, routeWorker, notificationWorker, syncWorker];

workers.forEach((worker) => {
  worker.on('completed', (job) => {
    jobLogger.info('Job completed', {
      queue: worker.name,
      jobId: job.id,
      name: job.name,
    });
  });

  worker.on('failed', (job, error) => {
    jobLogger.error('Job failed', {
      queue: worker.name,
      jobId: job?.id,
      name: job?.name,
      error: error.message,
    });
  });

  worker.on('error', (error) => {
    jobLogger.error('Worker error', {
      queue: worker.name,
      error: error.message,
    });
  });
});

// Graceful shutdown
async function shutdown(): Promise<void> {
  jobLogger.info('Shutting down workers...');

  await Promise.all(workers.map((w) => w.close()));
  await disconnectDatabase();

  jobLogger.info('Workers shut down successfully');
  process.exit(0);
}

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

// Start workers
async function start(): Promise<void> {
  await connectDatabase();

  jobLogger.info('Workers started', {
    queues: workers.map((w) => w.name),
  });
}

start().catch((error) => {
  jobLogger.error('Failed to start workers', { error });
  process.exit(1);
});
