import { Job } from 'bullmq';
import { prisma } from '../config/database.js';
import { jobLogger } from '../utils/logger.js';
import type {
  TripProcessingJob,
  ReportGenerationJob,
  RouteOptimizationJob,
  NotificationJob,
  SyncJob,
} from './queues.js';

// Trip Processing Processor
export async function processTripJob(job: Job<TripProcessingJob>): Promise<void> {
  const { tripId, userId } = job.data;
  jobLogger.info('Processing trip', { jobId: job.id, tripId });

  try {
    const trip = await prisma.trip.findUnique({
      where: { id: tripId },
      include: {
        waypoints: {
          orderBy: { sequenceNumber: 'asc' },
        },
      },
    });

    if (!trip) {
      jobLogger.warn('Trip not found for processing', { tripId });
      return;
    }

    // Reverse geocode start and end addresses if not present
    if (!trip.startAddress && trip.startLatitude && trip.startLongitude) {
      // TODO: Implement geocoding with MapKit Server API
      const startAddress = `${trip.startLatitude}, ${trip.startLongitude}`;
      await prisma.trip.update({
        where: { id: tripId },
        data: { startAddress },
      });
    }

    if (!trip.endAddress && trip.endLatitude && trip.endLongitude) {
      const endAddress = `${trip.endLatitude}, ${trip.endLongitude}`;
      await prisma.trip.update({
        where: { id: tripId },
        data: { endAddress },
      });
    }

    // Generate route polyline from waypoints
    if (trip.waypoints.length > 0 && !trip.routePolyline) {
      const polyline = generatePolyline(
        trip.waypoints.map((w) => ({
          lat: Number(w.latitude),
          lng: Number(w.longitude),
        }))
      );

      await prisma.trip.update({
        where: { id: tripId },
        data: { routePolyline: polyline },
      });
    }

    // Mark trip as verified
    await prisma.trip.update({
      where: { id: tripId },
      data: { status: 'verified' },
    });

    jobLogger.info('Trip processed successfully', { tripId });
  } catch (error) {
    jobLogger.error('Trip processing failed', { tripId, error });
    throw error;
  }
}

// Report Generation Processor
export async function processReportJob(job: Job<ReportGenerationJob>): Promise<void> {
  const { reportId, userId, format } = job.data;
  jobLogger.info('Generating report', { jobId: job.id, reportId, format });

  try {
    const report = await prisma.mileageReport.findUnique({
      where: { id: reportId },
    });

    if (!report) {
      jobLogger.warn('Report not found for generation', { reportId });
      return;
    }

    // Get trips for the report period
    const trips = await prisma.trip.findMany({
      where: {
        userId,
        deletedAt: null,
        startTime: {
          gte: report.dateRangeStart,
          lte: report.dateRangeEnd,
        },
        status: { in: ['completed', 'verified'] },
        ...(report.vehicleIds.length > 0 && {
          vehicleId: { in: report.vehicleIds },
        }),
        ...(report.categories.length > 0 && {
          category: { in: report.categories as any[] },
        }),
      },
      include: {
        vehicle: {
          select: { nickname: true, make: true, model: true },
        },
      },
      orderBy: { startTime: 'asc' },
    });

    // Calculate report data
    const reportData = {
      trips: trips.map((t) => ({
        id: t.id,
        date: t.startTime.toISOString().split('T')[0],
        startAddress: t.startAddress ?? 'Unknown',
        endAddress: t.endAddress ?? 'Unknown',
        distance: t.distanceMeters * 0.000621371,
        category: t.category,
        purpose: t.purpose ?? '',
        vehicle: t.vehicle?.nickname ?? 'Unknown',
      })),
      summary: {
        totalTrips: trips.length,
        totalMiles: trips.reduce((sum, t) => sum + t.distanceMeters * 0.000621371, 0),
        businessMiles: trips
          .filter((t) => t.category === 'business')
          .reduce((sum, t) => sum + t.distanceMeters * 0.000621371, 0),
        personalMiles: trips
          .filter((t) => t.category === 'personal')
          .reduce((sum, t) => sum + t.distanceMeters * 0.000621371, 0),
      },
    };

    // TODO: Generate actual PDF/CSV files using Puppeteer and upload to S3

    // Update report status
    await prisma.mileageReport.update({
      where: { id: reportId },
      data: {
        status: 'ready',
        reportData,
        generatedAt: new Date(),
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
      },
    });

    jobLogger.info('Report generated successfully', { reportId, tripCount: trips.length });
  } catch (error) {
    jobLogger.error('Report generation failed', { reportId, error });

    await prisma.mileageReport.update({
      where: { id: reportId },
      data: { status: 'failed' },
    });

    throw error;
  }
}

// Route Optimization Processor
export async function processRouteOptimizationJob(job: Job<RouteOptimizationJob>): Promise<void> {
  const { routeId, userId } = job.data;
  jobLogger.info('Optimizing route', { jobId: job.id, routeId });

  // Route optimization is handled synchronously in the service
  // This job is for async/background optimization requests
  jobLogger.info('Route optimization completed', { routeId });
}

// Notification Processor
export async function processNotificationJob(job: Job<NotificationJob>): Promise<void> {
  const { userId, type, title, body, data } = job.data;
  jobLogger.info('Sending notification', { jobId: job.id, userId, type });

  try {
    // Get user's push tokens
    const sessions = await prisma.session.findMany({
      where: {
        userId,
        revokedAt: null,
        pushToken: { not: null },
        expiresAt: { gt: new Date() },
      },
      select: { pushToken: true },
    });

    const pushTokens = sessions
      .map((s) => s.pushToken)
      .filter((t): t is string => t !== null);

    if (pushTokens.length === 0) {
      jobLogger.debug('No push tokens found for user', { userId });
      return;
    }

    // TODO: Implement APNS push notification sending
    // For now, just log the notification
    jobLogger.info('Would send push notification', {
      userId,
      type,
      title,
      body,
      tokenCount: pushTokens.length,
    });
  } catch (error) {
    jobLogger.error('Notification sending failed', { userId, type, error });
    throw error;
  }
}

// Sync Processor
export async function processSyncJob(job: Job<SyncJob>): Promise<void> {
  const { userId, deviceId, lastSyncAt } = job.data;
  jobLogger.info('Processing sync', { jobId: job.id, userId, deviceId });

  // TODO: Implement differential sync logic
  jobLogger.info('Sync completed', { userId, deviceId });
}

// Helper function to generate encoded polyline
function generatePolyline(points: Array<{ lat: number; lng: number }>): string {
  let encoded = '';
  let prevLat = 0;
  let prevLng = 0;

  for (const point of points) {
    const lat = Math.round(point.lat * 1e5);
    const lng = Math.round(point.lng * 1e5);

    encoded += encodeSignedNumber(lat - prevLat);
    encoded += encodeSignedNumber(lng - prevLng);

    prevLat = lat;
    prevLng = lng;
  }

  return encoded;
}

function encodeSignedNumber(num: number): string {
  let sgn = num << 1;
  if (num < 0) {
    sgn = ~sgn;
  }
  return encodeNumber(sgn);
}

function encodeNumber(num: number): string {
  let encoded = '';
  while (num >= 0x20) {
    encoded += String.fromCharCode((0x20 | (num & 0x1f)) + 63);
    num >>= 5;
  }
  encoded += String.fromCharCode(num + 63);
  return encoded;
}
