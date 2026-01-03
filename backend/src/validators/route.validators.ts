import { z } from 'zod';

const optimizationModeSchema = z.enum(['fastest', 'shortest', 'balanced']);
const stopStatusSchema = z.enum([
  'pending',
  'in_transit',
  'arrived',
  'completed',
  'failed',
  'skipped',
]);
const failureReasonSchema = z.enum([
  'not_home',
  'wrong_address',
  'refused',
  'damaged',
  'other',
]);

const createStopSchema = z.object({
  address: z.string().min(1).max(500),
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  locationId: z.string().uuid().optional().nullable(),
  recipientName: z.string().max(255).optional().nullable(),
  recipientPhone: z.string().max(20).optional().nullable(),
  deliveryInstructions: z.string().max(1000).optional().nullable(),
  timeWindowStart: z.string().optional().nullable(), // HH:mm format
  timeWindowEnd: z.string().optional().nullable(), // HH:mm format
  priority: z.number().int().min(1).max(10).optional().default(5),
  serviceDurationSeconds: z.number().int().min(0).max(7200).optional().default(300),
});

export const createRouteSchema = z.object({
  name: z.string().max(255).optional().nullable(),
  scheduledDate: z.string().datetime().optional().nullable(),
  scheduledStartTime: z.string().optional().nullable(), // HH:mm format
  startLocationId: z.string().uuid().optional().nullable(),
  endLocationId: z.string().uuid().optional().nullable(),
  returnToStart: z.boolean().optional().default(true),
  optimizationMode: optimizationModeSchema.optional().default('fastest'),
  stops: z.array(createStopSchema).min(1).max(100),
});

export const updateRouteSchema = z.object({
  name: z.string().max(255).optional().nullable(),
  scheduledDate: z.string().datetime().optional().nullable(),
  scheduledStartTime: z.string().optional().nullable(),
  optimizationMode: optimizationModeSchema.optional(),
  notes: z.string().max(2000).optional().nullable(),
});

export const updateStopSchema = z.object({
  status: stopStatusSchema.optional(),
  proofOfDeliveryUrl: z.string().url().optional().nullable(),
  signatureUrl: z.string().url().optional().nullable(),
  deliveryNotes: z.string().max(1000).optional().nullable(),
  failureReason: failureReasonSchema.optional().nullable(),
  failureNotes: z.string().max(1000).optional().nullable(),
});

export const addStopSchema = createStopSchema;

export const routeIdParamSchema = z.object({
  routeId: z.string().uuid(),
});

export const stopIdParamSchema = z.object({
  routeId: z.string().uuid(),
  stopId: z.string().uuid(),
});

export const routeFilterSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  perPage: z.coerce.number().int().min(1).max(100).default(20),
  status: z.enum(['planned', 'in_progress', 'completed', 'canceled']).optional(),
  startDate: z.string().datetime().optional(),
  endDate: z.string().datetime().optional(),
  sort: z.string().optional().default('-createdAt'),
});

export type CreateRouteInput = z.infer<typeof createRouteSchema>;
export type UpdateRouteInput = z.infer<typeof updateRouteSchema>;
export type CreateStopInput = z.infer<typeof createStopSchema>;
export type UpdateStopInput = z.infer<typeof updateStopSchema>;
export type RouteFilterInput = z.infer<typeof routeFilterSchema>;
