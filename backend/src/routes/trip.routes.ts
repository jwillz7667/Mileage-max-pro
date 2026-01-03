import { Router } from 'express';
import type { Request, Response } from 'express';
import { asyncHandler } from '../middleware/error.middleware.js';
import { authenticate } from '../middleware/auth.middleware.js';
import { validateBody, validateQuery, validateParams } from '../middleware/validation.middleware.js';
import {
  createTripSchema,
  updateTripSchema,
  addWaypointsSchema,
  completeTripSchema,
  tripFilterSchema,
  tripIdParamSchema,
} from '../validators/trip.validators.js';
import {
  createTrip,
  getTrip,
  updateTrip,
  addWaypoints,
  completeTrip,
  listTrips,
  deleteTrip,
} from '../services/trip.service.js';
import type { AuthenticatedRequest, ApiResponse } from '../types/index.js';

const router = Router();

// All routes require authentication
router.use(authenticate);

// POST /api/v1/trips - Create new trip
router.post(
  '/',
  validateBody(createTripSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    const trip = await createTrip(authReq.user.id, req.body);

    const response: ApiResponse<typeof trip> = {
      success: true,
      data: trip,
    };

    res.status(201).json(response);
  })
);

// GET /api/v1/trips - List trips with filtering
router.get(
  '/',
  validateQuery(tripFilterSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    const result = await listTrips(authReq.user.id, req.query as any);

    res.json({
      success: true,
      ...result,
    });
  })
);

// GET /api/v1/trips/:tripId - Get single trip
router.get(
  '/:tripId',
  validateParams(tripIdParamSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    const trip = await getTrip(authReq.user.id, req.params.tripId as string);

    const response: ApiResponse<typeof trip> = {
      success: true,
      data: trip,
    };

    res.json(response);
  })
);

// PATCH /api/v1/trips/:tripId - Update trip
router.patch(
  '/:tripId',
  validateParams(tripIdParamSchema),
  validateBody(updateTripSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    const trip = await updateTrip(authReq.user.id, req.params.tripId as string, req.body);

    const response: ApiResponse<typeof trip> = {
      success: true,
      data: trip,
    };

    res.json(response);
  })
);

// POST /api/v1/trips/:tripId/waypoints - Add waypoints
router.post(
  '/:tripId/waypoints',
  validateParams(tripIdParamSchema),
  validateBody(addWaypointsSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    const result = await addWaypoints(authReq.user.id, req.params.tripId as string, req.body);

    const response: ApiResponse<typeof result> = {
      success: true,
      data: result,
    };

    res.json(response);
  })
);

// POST /api/v1/trips/:tripId/complete - Complete trip
router.post(
  '/:tripId/complete',
  validateParams(tripIdParamSchema),
  validateBody(completeTripSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    const trip = await completeTrip(authReq.user.id, req.params.tripId as string, req.body);

    const response: ApiResponse<typeof trip> = {
      success: true,
      data: trip,
    };

    res.json(response);
  })
);

// DELETE /api/v1/trips/:tripId - Delete trip
router.delete(
  '/:tripId',
  validateParams(tripIdParamSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    await deleteTrip(authReq.user.id, req.params.tripId as string);

    res.status(204).send();
  })
);

export default router;
