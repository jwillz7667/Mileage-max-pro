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
  jobLogger.info({ jobId: job.id, tripId }, 'Processing trip');

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
      jobLogger.warn({ tripId }, 'Trip not found for processing');
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

    jobLogger.info({ tripId }, 'Trip processed successfully');
  } catch (error) {
    jobLogger.error({ tripId, error }, 'Trip processing failed');
    throw error;
  }
}

// Report Generation Processor
export async function processReportJob(job: Job<ReportGenerationJob>): Promise<void> {
  const { reportId, userId, format } = job.data;
  jobLogger.info({ jobId: job.id, reportId, format }, 'Generating report');

  try {
    const report = await prisma.mileageReport.findUnique({
      where: { id: reportId },
    });

    if (!report) {
      jobLogger.warn({ reportId }, 'Report not found for generation');
      return;
    }

    // Get trips for the report period
    const whereClause: any = {
      userId,
      deletedAt: null,
      startTime: {
        gte: report.dateRangeStart,
        lte: report.dateRangeEnd,
      },
      status: { in: ['completed', 'verified'] },
    };

    if (report.vehicleIds.length > 0) {
      whereClause.vehicleId = { in: report.vehicleIds };
    }

    if (report.categories.length > 0) {
      whereClause.category = { in: report.categories };
    }

    const trips = await prisma.trip.findMany({
      where: whereClause,
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
        vehicle: (t as unknown as { vehicle?: { nickname?: string } }).vehicle?.nickname ?? 'Unknown',
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

    jobLogger.info({ reportId, tripCount: trips.length }, 'Report generated successfully');
  } catch (error) {
    jobLogger.error({ reportId, error }, 'Report generation failed');

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
  jobLogger.info({ jobId: job.id, routeId }, 'Optimizing route');

  // Route optimization is handled synchronously in the service
  // This job is for async/background optimization requests
  jobLogger.info({ routeId }, 'Route optimization completed');
}

// Notification Processor
export async function processNotificationJob(job: Job<NotificationJob>): Promise<void> {
  const { userId, type, title, body, data } = job.data;
  jobLogger.info({ jobId: job.id, userId, type }, 'Sending notification');

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
      jobLogger.debug({ userId }, 'No push tokens found for user');
      return;
    }

    // TODO: Implement APNS push notification sending
    // For now, just log the notification
    jobLogger.info({
      userId,
      type,
      title,
      body,
      tokenCount: pushTokens.length,
    }, 'Would send push notification');
  } catch (error) {
    jobLogger.error({ userId, type, error }, 'Notification sending failed');
    throw error;
  }
}

// Sync Processor
export async function processSyncJob(job: Job<SyncJob>): Promise<void> {
  const { userId, deviceId, lastSyncAt } = job.data;
  jobLogger.info({ jobId: job.id, userId, deviceId }, 'Processing sync');

  // TODO: Implement differential sync logic
  jobLogger.info({ userId, deviceId }, 'Sync completed');
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
