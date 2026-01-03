import { Queue, Worker, Job } from 'bullmq';
import { redis } from '../config/redis.js';
import { jobLogger } from '../utils/logger.js';
import { config } from '../config/env.js';

// Queue configurations
const queueConfig = {
  connection: redis,
  defaultJobOptions: {
    attempts: 3,
    backoff: {
      type: 'exponential' as const,
      delay: 1000,
    },
    removeOnComplete: 100,
    removeOnFail: 500,
  },
};

// Define queues
export const tripProcessingQueue = new Queue('trip-processing', queueConfig);
export const reportGenerationQueue = new Queue('report-generation', queueConfig);
export const routeOptimizationQueue = new Queue('route-optimization', queueConfig);
export const notificationQueue = new Queue('notifications', queueConfig);
export const syncQueue = new Queue('sync', queueConfig);
export const cleanupQueue = new Queue('cleanup', queueConfig);

// Job types
export interface TripProcessingJob {
  tripId: string;
  userId: string;
}

export interface ReportGenerationJob {
  reportId: string;
  userId: string;
  format: 'pdf' | 'csv' | 'both';
}

export interface RouteOptimizationJob {
  routeId: string;
  userId: string;
}

export interface NotificationJob {
  userId: string;
  type: 'trip_start' | 'trip_end' | 'weekly_summary' | 'maintenance_due' | 'route_complete';
  title: string;
  body: string;
  data?: Record<string, unknown>;
}

export interface SyncJob {
  userId: string;
  deviceId: string;
  lastSyncAt: string;
}

// Add jobs to queues
export async function addTripProcessingJob(data: TripProcessingJob): Promise<Job<TripProcessingJob>> {
  const job = await tripProcessingQueue.add('process', data, {
    priority: 1,
    jobId: `trip-${data.tripId}`,
  });
  jobLogger.debug({ jobId: job.id, tripId: data.tripId }, 'Trip processing job added');
  return job;
}

export async function addReportGenerationJob(data: ReportGenerationJob): Promise<Job<ReportGenerationJob>> {
  const job = await reportGenerationQueue.add('generate', data, {
    priority: 2,
    jobId: `report-${data.reportId}`,
  });
  jobLogger.debug({ jobId: job.id, reportId: data.reportId }, 'Report generation job added');
  return job;
}

export async function addRouteOptimizationJob(data: RouteOptimizationJob): Promise<Job<RouteOptimizationJob>> {
  const job = await routeOptimizationQueue.add('optimize', data, {
    priority: 1,
    jobId: `route-${data.routeId}`,
  });
  jobLogger.debug({ jobId: job.id, routeId: data.routeId }, 'Route optimization job added');
  return job;
}

export async function addNotificationJob(data: NotificationJob): Promise<Job<NotificationJob>> {
  const job = await notificationQueue.add('send', data, {
    priority: 3,
  });
  jobLogger.debug({ jobId: job.id, type: data.type }, 'Notification job added');
  return job;
}

export async function addSyncJob(data: SyncJob): Promise<Job<SyncJob>> {
  const job = await syncQueue.add('sync', data, {
    priority: 4,
    jobId: `sync-${data.userId}-${data.deviceId}`,
  });
  jobLogger.debug({ jobId: job.id, userId: data.userId }, 'Sync job added');
  return job;
}

// Close all queues gracefully
export async function closeQueues(): Promise<void> {
  await Promise.all([
    tripProcessingQueue.close(),
    reportGenerationQueue.close(),
    routeOptimizationQueue.close(),
    notificationQueue.close(),
    syncQueue.close(),
    cleanupQueue.close(),
  ]);
  jobLogger.info('All queues closed');
}
