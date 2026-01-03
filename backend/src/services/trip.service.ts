import { prisma } from '../config/database.js';
import { tripLogger } from '../utils/logger.js';
import { NotFoundError, ForbiddenError, BadRequestError } from '../utils/errors.js';
import type {
  CreateTripInput,
  UpdateTripInput,
  AddWaypointsInput,
  CompleteTripInput,
  TripFilterInput,
  PaginatedResponse,
} from '../types/index.js';
import type { Trip, TripWaypoint, TripStatus, TripCategory, Prisma } from '@prisma/client';

// Meters to miles conversion
const METERS_TO_MILES = 0.000621371;

interface TripWithWaypoints extends Trip {
  waypoints?: TripWaypoint[];
}

export async function createTrip(
  userId: string,
  input: CreateTripInput
): Promise<Trip> {
  // If vehicleId provided, verify ownership
  if (input.vehicleId) {
    const vehicle = await prisma.vehicle.findFirst({
      where: {
        id: input.vehicleId,
        userId,
        deletedAt: null,
      },
    });

    if (!vehicle) {
      throw new NotFoundError('Vehicle');
    }
  }

  const trip = await prisma.trip.create({
    data: {
      userId,
      vehicleId: input.vehicleId,
      startLatitude: input.startLatitude,
      startLongitude: input.startLongitude,
      startTime: new Date(input.startTime),
      detectionMethod: input.detectionMethod ?? 'manual',
      status: 'recording',
    },
  });

  tripLogger.info({ tripId: trip.id, userId, detectionMethod: input.detectionMethod }, 'Trip created');

  return trip;
}

export async function getTrip(userId: string, tripId: string): Promise<TripWithWaypoints> {
  const trip = await prisma.trip.findFirst({
    where: {
      id: tripId,
      userId,
      deletedAt: null,
    },
    include: {
      waypoints: {
        orderBy: { sequenceNumber: 'asc' },
      },
      vehicle: {
        select: {
          id: true,
          nickname: true,
          make: true,
          model: true,
          year: true,
        },
      },
    },
  });

  if (!trip) {
    throw new NotFoundError('Trip');
  }

  return trip;
}

export async function updateTrip(
  userId: string,
  tripId: string,
  input: UpdateTripInput
): Promise<Trip> {
  const trip = await prisma.trip.findFirst({
    where: {
      id: tripId,
      userId,
      deletedAt: null,
    },
  });

  if (!trip) {
    throw new NotFoundError('Trip');
  }

  // If changing vehicle, verify ownership
  if (input.vehicleId) {
    const vehicle = await prisma.vehicle.findFirst({
      where: {
        id: input.vehicleId,
        userId,
        deletedAt: null,
      },
    });

    if (!vehicle) {
      throw new NotFoundError('Vehicle');
    }
  }

  const updateData: Prisma.TripUpdateInput = {};

  if (input.category !== undefined) updateData.category = input.category as TripCategory;
  if (input.purpose !== undefined) updateData.purpose = input.purpose;
  if (input.clientName !== undefined) updateData.clientName = input.clientName;
  if (input.projectName !== undefined) updateData.projectName = input.projectName;
  if (input.tags !== undefined) updateData.tags = input.tags;
  if (input.vehicleId !== undefined) updateData.vehicle = input.vehicleId ? { connect: { id: input.vehicleId } } : { disconnect: true };
  if (input.userVerified !== undefined) updateData.userVerified = input.userVerified;
  if (input.notes !== undefined) updateData.notes = input.notes;

  if (input.endLatitude !== undefined) updateData.endLatitude = input.endLatitude;
  if (input.endLongitude !== undefined) updateData.endLongitude = input.endLongitude;
  if (input.endTime !== undefined) updateData.endTime = new Date(input.endTime);

  const updated = await prisma.trip.update({
    where: { id: tripId },
    data: updateData,
  });

  tripLogger.info({ tripId, userId, fields: Object.keys(input) }, 'Trip updated');

  return updated;
}

export async function addWaypoints(
  userId: string,
  tripId: string,
  input: AddWaypointsInput
): Promise<{ count: number }> {
  const trip = await prisma.trip.findFirst({
    where: {
      id: tripId,
      userId,
      status: 'recording',
      deletedAt: null,
    },
  });

  if (!trip) {
    throw new NotFoundError('Trip');
  }

  // Get the current max sequence number
  const lastWaypoint = await prisma.tripWaypoint.findFirst({
    where: { tripId },
    orderBy: { sequenceNumber: 'desc' },
    select: { sequenceNumber: true },
  });

  let nextSequence = (lastWaypoint?.sequenceNumber ?? 0) + 1;

  const waypointData = input.waypoints.map((wp) => ({
    tripId,
    sequenceNumber: nextSequence++,
    latitude: wp.latitude,
    longitude: wp.longitude,
    timestamp: new Date(wp.timestamp),
    speedMps: wp.speedMps,
    heading: wp.heading,
    altitudeMeters: wp.altitudeMeters,
    horizontalAccuracy: wp.horizontalAccuracy,
    verticalAccuracy: wp.verticalAccuracy,
  }));

  const result = await prisma.tripWaypoint.createMany({
    data: waypointData,
  });

  tripLogger.debug({ tripId, count: result.count }, 'Waypoints added');

  return { count: result.count };
}

export async function completeTrip(
  userId: string,
  tripId: string,
  input: CompleteTripInput
): Promise<Trip> {
  const trip = await prisma.trip.findFirst({
    where: {
      id: tripId,
      userId,
      status: 'recording',
      deletedAt: null,
    },
  });

  if (!trip) {
    throw new NotFoundError('Trip');
  }

  // Add final waypoints if provided
  if (input.finalWaypoints && input.finalWaypoints.length > 0) {
    await addWaypoints(userId, tripId, { waypoints: input.finalWaypoints });
  }

  // Calculate trip statistics
  const waypoints = await prisma.tripWaypoint.findMany({
    where: { tripId },
    orderBy: { sequenceNumber: 'asc' },
  });

  let distanceMeters = 0;
  let maxSpeedMph = 0;
  let totalSpeed = 0;
  let speedCount = 0;
  let idleTimeSeconds = 0;

  for (let i = 1; i < waypoints.length; i++) {
    const prev = waypoints[i - 1]!;
    const curr = waypoints[i]!;

    // Calculate distance using Haversine formula
    distanceMeters += calculateDistance(
      Number(prev.latitude),
      Number(prev.longitude),
      Number(curr.latitude),
      Number(curr.longitude)
    );

    // Track speed stats
    if (curr.speedMps !== null) {
      const speedMph = Number(curr.speedMps) * 2.23694;
      maxSpeedMph = Math.max(maxSpeedMph, speedMph);
      totalSpeed += speedMph;
      speedCount++;

      // Detect idle time (speed < 2 mph for extended period)
      if (speedMph < 2) {
        const timeDiff = (curr.timestamp.getTime() - prev.timestamp.getTime()) / 1000;
        idleTimeSeconds += timeDiff;
      }
    }
  }

  const avgSpeedMph = speedCount > 0 ? totalSpeed / speedCount : null;
  const startTime = trip.startTime;
  const endTime = new Date(input.endTime);
  const durationSeconds = Math.floor((endTime.getTime() - startTime.getTime()) / 1000);

  // Update trip with calculated values
  const completedTrip = await prisma.trip.update({
    where: { id: tripId },
    data: {
      status: 'completed',
      endLatitude: input.endLatitude,
      endLongitude: input.endLongitude,
      endTime,
      distanceMeters: Math.round(distanceMeters),
      durationSeconds,
      idleTimeSeconds: Math.round(idleTimeSeconds),
      maxSpeedMph: maxSpeedMph > 0 ? maxSpeedMph : null,
      avgSpeedMph,
      irsCompliant: true, // Basic trip data is IRS compliant
    },
  });

  tripLogger.info({
    tripId,
    userId,
    distanceMiles: distanceMeters * METERS_TO_MILES,
    durationMinutes: durationSeconds / 60,
  }, 'Trip completed');

  return completedTrip;
}

export async function listTrips(
  userId: string,
  filters: TripFilterInput
): Promise<PaginatedResponse<Trip>> {
  const { page, perPage, vehicleId, category, startDate, endDate, minDistance, status, sort } = filters;
  const offset = (page - 1) * perPage;

  const where: Prisma.TripWhereInput = {
    userId,
    deletedAt: null,
  };

  if (vehicleId) where.vehicleId = vehicleId;
  if (category) where.category = category as TripCategory;
  if (status) where.status = status as TripStatus;
  if (minDistance) where.distanceMeters = { gte: minDistance };

  if (startDate || endDate) {
    where.startTime = {};
    if (startDate) where.startTime.gte = new Date(startDate);
    if (endDate) where.startTime.lte = new Date(endDate);
  }

  // Parse sort parameter
  const sortField = sort.startsWith('-') ? sort.slice(1) : sort;
  const sortOrder = sort.startsWith('-') ? 'desc' : 'asc';

  const orderBy: Prisma.TripOrderByWithRelationInput = {};
  if (sortField === 'startTime') orderBy.startTime = sortOrder;
  else if (sortField === 'distance') orderBy.distanceMeters = sortOrder;
  else if (sortField === 'duration') orderBy.durationSeconds = sortOrder;
  else orderBy.startTime = 'desc';

  const [trips, total] = await Promise.all([
    prisma.trip.findMany({
      where,
      orderBy,
      skip: offset,
      take: perPage,
      include: {
        vehicle: {
          select: {
            id: true,
            nickname: true,
            make: true,
            model: true,
          },
        },
      },
    }),
    prisma.trip.count({ where }),
  ]);

  const totalPages = Math.ceil(total / perPage);

  return {
    data: trips,
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

export async function deleteTrip(userId: string, tripId: string): Promise<void> {
  const trip = await prisma.trip.findFirst({
    where: {
      id: tripId,
      userId,
      deletedAt: null,
    },
  });

  if (!trip) {
    throw new NotFoundError('Trip');
  }

  await prisma.trip.update({
    where: { id: tripId },
    data: { deletedAt: new Date() },
  });

  tripLogger.info({ tripId, userId }, 'Trip deleted');
}

// Haversine formula to calculate distance between two coordinates
function calculateDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371000; // Earth's radius in meters
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c;
}

function toRad(deg: number): number {
  return deg * (Math.PI / 180);
}
