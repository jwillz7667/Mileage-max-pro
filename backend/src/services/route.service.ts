import { prisma } from '../config/database.js';
import { routeLogger } from '../utils/logger.js';
import { NotFoundError, BadRequestError, QuotaExceededError } from '../utils/errors.js';
import type {
  CreateRouteInput,
  UpdateRouteInput,
  CreateStopInput,
  UpdateStopInput,
  RouteFilterInput,
  PaginatedResponse,
} from '../types/index.js';
import type { DeliveryRoute, DeliveryStop, SubscriptionTier, Prisma } from '@prisma/client';

const STOP_LIMITS: Record<SubscriptionTier, number> = {
  free: 5,
  pro: 15,
  business: 50,
  enterprise: 100,
};

type RouteWithStops = DeliveryRoute & { stops: DeliveryStop[] };

export async function createRoute(
  userId: string,
  subscriptionTier: SubscriptionTier,
  input: CreateRouteInput
): Promise<RouteWithStops> {
  // Check stop limit
  const limit = STOP_LIMITS[subscriptionTier];
  if (input.stops.length > limit) {
    throw new QuotaExceededError('stops per route', limit);
  }

  // Verify location ownership if provided
  if (input.startLocationId) {
    const startLocation = await prisma.savedLocation.findFirst({
      where: { id: input.startLocationId, userId },
    });
    if (!startLocation) throw new NotFoundError('Start location');
  }

  if (input.endLocationId) {
    const endLocation = await prisma.savedLocation.findFirst({
      where: { id: input.endLocationId, userId },
    });
    if (!endLocation) throw new NotFoundError('End location');
  }

  const route = await prisma.deliveryRoute.create({
    data: {
      userId,
      name: input.name,
      scheduledDate: input.scheduledDate ? new Date(input.scheduledDate) : null,
      scheduledStartTime: input.scheduledStartTime ? new Date(`1970-01-01T${input.scheduledStartTime}:00Z`) : null,
      startLocationId: input.startLocationId,
      endLocationId: input.endLocationId,
      returnToStart: input.returnToStart ?? true,
      optimizationMode: input.optimizationMode ?? 'fastest',
      totalStops: input.stops.length,
      stops: {
        create: input.stops.map((stop, index) => ({
          sequenceOriginal: index + 1,
          address: stop.address,
          latitude: stop.latitude,
          longitude: stop.longitude,
          locationId: stop.locationId,
          recipientName: stop.recipientName,
          recipientPhone: stop.recipientPhone,
          deliveryInstructions: stop.deliveryInstructions,
          timeWindowStart: stop.timeWindowStart ? new Date(`1970-01-01T${stop.timeWindowStart}:00Z`) : null,
          timeWindowEnd: stop.timeWindowEnd ? new Date(`1970-01-01T${stop.timeWindowEnd}:00Z`) : null,
          priority: stop.priority ?? 5,
          serviceDurationSeconds: stop.serviceDurationSeconds ?? 300,
        })),
      },
    },
    include: {
      stops: {
        orderBy: { sequenceOriginal: 'asc' },
      },
    },
  });

  routeLogger.info('Route created', { routeId: route.id, userId, stopCount: input.stops.length });

  return route;
}

export async function getRoute(userId: string, routeId: string): Promise<RouteWithStops> {
  const route = await prisma.deliveryRoute.findFirst({
    where: { id: routeId, userId },
    include: {
      stops: {
        orderBy: [{ sequenceOptimized: 'asc' }, { sequenceOriginal: 'asc' }],
      },
      startLocation: true,
      endLocation: true,
    },
  });

  if (!route) {
    throw new NotFoundError('Route');
  }

  return route;
}

export async function updateRoute(
  userId: string,
  routeId: string,
  input: UpdateRouteInput
): Promise<DeliveryRoute> {
  const route = await prisma.deliveryRoute.findFirst({
    where: { id: routeId, userId },
  });

  if (!route) {
    throw new NotFoundError('Route');
  }

  const updateData: Prisma.DeliveryRouteUpdateInput = {};

  if (input.name !== undefined) updateData.name = input.name;
  if (input.scheduledDate !== undefined) {
    updateData.scheduledDate = input.scheduledDate ? new Date(input.scheduledDate) : null;
  }
  if (input.scheduledStartTime !== undefined) {
    updateData.scheduledStartTime = input.scheduledStartTime
      ? new Date(`1970-01-01T${input.scheduledStartTime}:00Z`)
      : null;
  }
  if (input.optimizationMode !== undefined) updateData.optimizationMode = input.optimizationMode;
  if (input.notes !== undefined) updateData.notes = input.notes;

  const updated = await prisma.deliveryRoute.update({
    where: { id: routeId },
    data: updateData,
  });

  routeLogger.info('Route updated', { routeId, userId });

  return updated;
}

export async function deleteRoute(userId: string, routeId: string): Promise<void> {
  const route = await prisma.deliveryRoute.findFirst({
    where: { id: routeId, userId },
  });

  if (!route) {
    throw new NotFoundError('Route');
  }

  await prisma.deliveryRoute.delete({
    where: { id: routeId },
  });

  routeLogger.info('Route deleted', { routeId, userId });
}

export async function listRoutes(
  userId: string,
  filters: RouteFilterInput
): Promise<PaginatedResponse<DeliveryRoute>> {
  const { page, perPage, status, startDate, endDate, sort } = filters;
  const offset = (page - 1) * perPage;

  const where: Prisma.DeliveryRouteWhereInput = { userId };

  if (status) where.status = status as any;

  if (startDate || endDate) {
    where.scheduledDate = {};
    if (startDate) where.scheduledDate.gte = new Date(startDate);
    if (endDate) where.scheduledDate.lte = new Date(endDate);
  }

  const sortField = sort.startsWith('-') ? sort.slice(1) : sort;
  const sortOrder = sort.startsWith('-') ? 'desc' : 'asc';

  const orderBy: Prisma.DeliveryRouteOrderByWithRelationInput = {};
  if (sortField === 'scheduledDate') orderBy.scheduledDate = sortOrder;
  else if (sortField === 'createdAt') orderBy.createdAt = sortOrder;
  else orderBy.createdAt = 'desc';

  const [routes, total] = await Promise.all([
    prisma.deliveryRoute.findMany({
      where,
      orderBy,
      skip: offset,
      take: perPage,
      include: {
        _count: { select: { stops: true } },
      },
    }),
    prisma.deliveryRoute.count({ where }),
  ]);

  const totalPages = Math.ceil(total / perPage);

  return {
    data: routes,
    pagination: {
      page,
      perPage,
      total,
      totalPages,
      hasNext: page < totalPages,
      hasPrev: page > 1,
    },
  };
}

export async function optimizeRoute(userId: string, routeId: string): Promise<RouteWithStops> {
  const route = await prisma.deliveryRoute.findFirst({
    where: { id: routeId, userId },
    include: {
      stops: { orderBy: { sequenceOriginal: 'asc' } },
      startLocation: true,
    },
  });

  if (!route) {
    throw new NotFoundError('Route');
  }

  if (route.status !== 'planned') {
    throw new BadRequestError('Can only optimize planned routes');
  }

  // Simple nearest neighbor optimization
  const stops = [...route.stops];
  const optimizedOrder: number[] = [];
  const visited = new Set<string>();

  // Start from start location or first stop
  let currentLat = route.startLocation?.latitude
    ? Number(route.startLocation.latitude)
    : Number(stops[0]?.latitude ?? 0);
  let currentLon = route.startLocation?.longitude
    ? Number(route.startLocation.longitude)
    : Number(stops[0]?.longitude ?? 0);

  while (visited.size < stops.length) {
    let nearestStop: DeliveryStop | null = null;
    let nearestDistance = Infinity;

    for (const stop of stops) {
      if (visited.has(stop.id)) continue;

      // Consider priority - higher priority stops get a distance bonus
      const priorityBonus = (10 - stop.priority) * 0.1; // Up to 0.9 reduction

      const distance = calculateDistance(
        currentLat,
        currentLon,
        Number(stop.latitude),
        Number(stop.longitude)
      ) * (1 - priorityBonus);

      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestStop = stop;
      }
    }

    if (nearestStop) {
      visited.add(nearestStop.id);
      optimizedOrder.push(nearestStop.sequenceOriginal);
      currentLat = Number(nearestStop.latitude);
      currentLon = Number(nearestStop.longitude);
    }
  }

  // Calculate total distance
  let totalDistance = 0;
  let totalDuration = 0;
  let prevLat = route.startLocation ? Number(route.startLocation.latitude) : Number(stops[0]?.latitude ?? 0);
  let prevLon = route.startLocation ? Number(route.startLocation.longitude) : Number(stops[0]?.longitude ?? 0);

  // Update stops with optimized sequence and distance
  for (let i = 0; i < optimizedOrder.length; i++) {
    const originalSeq = optimizedOrder[i]!;
    const stop = stops.find((s) => s.sequenceOriginal === originalSeq)!;

    const distance = calculateDistance(
      prevLat,
      prevLon,
      Number(stop.latitude),
      Number(stop.longitude)
    );

    totalDistance += distance;
    totalDuration += Math.round(distance / 13.4); // Assume 30 mph average = 13.4 m/s
    totalDuration += stop.serviceDurationSeconds;

    await prisma.deliveryStop.update({
      where: { id: stop.id },
      data: {
        sequenceOptimized: i + 1,
        distanceFromPrevious: Math.round(distance),
      },
    });

    prevLat = Number(stop.latitude);
    prevLon = Number(stop.longitude);
  }

  // Add return distance if applicable
  if (route.returnToStart && route.startLocation) {
    const returnDistance = calculateDistance(
      prevLat,
      prevLon,
      Number(route.startLocation.latitude),
      Number(route.startLocation.longitude)
    );
    totalDistance += returnDistance;
    totalDuration += Math.round(returnDistance / 13.4);
  }

  // Update route with optimization results
  const optimizedRoute = await prisma.deliveryRoute.update({
    where: { id: routeId },
    data: {
      optimizedOrder,
      totalDistanceMeters: Math.round(totalDistance),
      totalDurationSeconds: totalDuration,
    },
    include: {
      stops: {
        orderBy: { sequenceOptimized: 'asc' },
      },
    },
  });

  routeLogger.info('Route optimized', {
    routeId,
    userId,
    totalDistanceKm: totalDistance / 1000,
    totalDurationMin: totalDuration / 60,
  });

  return optimizedRoute;
}

export async function startRoute(userId: string, routeId: string): Promise<DeliveryRoute> {
  const route = await prisma.deliveryRoute.findFirst({
    where: { id: routeId, userId },
  });

  if (!route) {
    throw new NotFoundError('Route');
  }

  if (route.status !== 'planned') {
    throw new BadRequestError('Route is not in planned status');
  }

  const updated = await prisma.deliveryRoute.update({
    where: { id: routeId },
    data: {
      status: 'in_progress',
      actualStartTime: new Date(),
    },
  });

  routeLogger.info('Route started', { routeId, userId });

  return updated;
}

export async function updateStop(
  userId: string,
  routeId: string,
  stopId: string,
  input: UpdateStopInput
): Promise<DeliveryStop> {
  const route = await prisma.deliveryRoute.findFirst({
    where: { id: routeId, userId },
  });

  if (!route) {
    throw new NotFoundError('Route');
  }

  const stop = await prisma.deliveryStop.findFirst({
    where: { id: stopId, routeId },
  });

  if (!stop) {
    throw new NotFoundError('Stop');
  }

  const updateData: Prisma.DeliveryStopUpdateInput = {};

  if (input.status !== undefined) {
    updateData.status = input.status;

    if (input.status === 'arrived') {
      updateData.actualArrival = new Date();
    } else if (input.status === 'completed' || input.status === 'failed' || input.status === 'skipped') {
      updateData.departureTime = new Date();

      if (stop.actualArrival) {
        updateData.actualServiceDuration = Math.round(
          (Date.now() - stop.actualArrival.getTime()) / 1000
        );
      }

      // Update completed stops count on route
      if (input.status === 'completed') {
        await prisma.deliveryRoute.update({
          where: { id: routeId },
          data: { completedStops: { increment: 1 } },
        });
      }
    }
  }

  if (input.proofOfDeliveryUrl !== undefined) updateData.proofOfDeliveryUrl = input.proofOfDeliveryUrl;
  if (input.signatureUrl !== undefined) updateData.signatureUrl = input.signatureUrl;
  if (input.deliveryNotes !== undefined) updateData.deliveryNotes = input.deliveryNotes;
  if (input.failureReason !== undefined) updateData.failureReason = input.failureReason;
  if (input.failureNotes !== undefined) updateData.failureNotes = input.failureNotes;

  const updated = await prisma.deliveryStop.update({
    where: { id: stopId },
    data: updateData,
  });

  routeLogger.info('Stop updated', { routeId, stopId, status: input.status });

  return updated;
}

export async function completeRoute(userId: string, routeId: string): Promise<DeliveryRoute> {
  const route = await prisma.deliveryRoute.findFirst({
    where: { id: routeId, userId },
  });

  if (!route) {
    throw new NotFoundError('Route');
  }

  if (route.status !== 'in_progress') {
    throw new BadRequestError('Route is not in progress');
  }

  const actualDuration = route.actualStartTime
    ? Math.round((Date.now() - route.actualStartTime.getTime()) / 1000)
    : null;

  const updated = await prisma.deliveryRoute.update({
    where: { id: routeId },
    data: {
      status: 'completed',
      actualEndTime: new Date(),
      actualDurationSeconds: actualDuration,
    },
  });

  routeLogger.info('Route completed', { routeId, userId, durationMinutes: actualDuration ? actualDuration / 60 : null });

  return updated;
}

// Haversine formula for distance calculation
function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371000; // Earth's radius in meters
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function toRad(deg: number): number {
  return deg * (Math.PI / 180);
}
