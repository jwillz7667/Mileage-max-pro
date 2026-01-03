import { z } from 'zod';

const tripCategorySchema = z.enum([
  'business',
  'personal',
  'medical',
  'charity',
  'moving',
  'commute',
]);

const detectionMethodSchema = z.enum(['automatic', 'manual', 'widget', 'shortcut']);

const tripStatusSchema = z.enum(['recording', 'completed', 'processing', 'verified']);

export const createTripSchema = z.object({
  vehicleId: z.string().uuid().optional(),
  startLatitude: z.number().min(-90).max(90),
  startLongitude: z.number().min(-180).max(180),
  startTime: z.string().datetime(),
  detectionMethod: detectionMethodSchema.optional().default('manual'),
});

export const updateTripSchema = z.object({
  category: tripCategorySchema.optional(),
  purpose: z.string().max(255).optional().nullable(),
  clientName: z.string().max(255).optional().nullable(),
  projectName: z.string().max(255).optional().nullable(),
  tags: z.array(z.string().max(50)).max(20).optional(),
  vehicleId: z.string().uuid().optional().nullable(),
  endLatitude: z.number().min(-90).max(90).optional(),
  endLongitude: z.number().min(-180).max(180).optional(),
  endTime: z.string().datetime().optional(),
  userVerified: z.boolean().optional(),
  notes: z.string().max(2000).optional().nullable(),
});

const waypointSchema = z.object({
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  timestamp: z.string().datetime(),
  speedMps: z.number().min(0).max(200).optional(),
  heading: z.number().min(0).max(360).optional(),
  altitudeMeters: z.number().min(-1000).max(50000).optional(),
  horizontalAccuracy: z.number().min(0).max(10000).optional(),
  verticalAccuracy: z.number().min(0).max(10000).optional(),
});

export const addWaypointsSchema = z.object({
  waypoints: z.array(waypointSchema).min(1).max(1000),
});

export const completeTripSchema = z.object({
  endLatitude: z.number().min(-90).max(90),
  endLongitude: z.number().min(-180).max(180),
  endTime: z.string().datetime(),
  finalWaypoints: z.array(waypointSchema).max(100).optional(),
});

export const tripFilterSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  perPage: z.coerce.number().int().min(1).max(100).default(20),
  vehicleId: z.string().uuid().optional(),
  category: tripCategorySchema.optional(),
  startDate: z.string().datetime().optional(),
  endDate: z.string().datetime().optional(),
  minDistance: z.coerce.number().int().min(0).optional(),
  status: tripStatusSchema.optional(),
  sort: z.string().optional().default('-startTime'),
});

export const tripIdParamSchema = z.object({
  tripId: z.string().uuid(),
});

export type CreateTripInput = z.infer<typeof createTripSchema>;
export type UpdateTripInput = z.infer<typeof updateTripSchema>;
export type AddWaypointsInput = z.infer<typeof addWaypointsSchema>;
export type CompleteTripInput = z.infer<typeof completeTripSchema>;
export type TripFilterInput = z.infer<typeof tripFilterSchema>;
