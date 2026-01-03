import { Router } from 'express';
import type { Request, Response } from 'express';
import { asyncHandler } from '../middleware/error.middleware.js';
import { authenticate } from '../middleware/auth.middleware.js';
import { validateBody, validateQuery, validateParams } from '../middleware/validation.middleware.js';
import {
  createVehicleSchema,
  updateVehicleSchema,
  createMaintenanceRecordSchema,
  vehicleIdParamSchema,
  vehicleFilterSchema,
} from '../validators/vehicle.validators.js';
import {
  createVehicle,
  getVehicle,
  updateVehicle,
  deleteVehicle,
  listVehicles,
  addMaintenanceRecord,
  getVehicleStats,
} from '../services/vehicle.service.js';
import type { AuthenticatedRequest, ApiResponse } from '../types/index.js';

const router = Router();

// All routes require authentication
router.use(authenticate);

// POST /api/v1/vehicles - Create new vehicle
router.post(
  '/',
  validateBody(createVehicleSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    const vehicle = await createVehicle(
      authReq.user.id,
      authReq.user.subscriptionTier,
      req.body
    );

    const response: ApiResponse<typeof vehicle> = {
      success: true,
      data: vehicle,
    };

    res.status(201).json(response);
  })
);

// GET /api/v1/vehicles - List vehicles
router.get(
  '/',
  validateQuery(vehicleFilterSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    const result = await listVehicles(authReq.user.id, req.query as any);

    res.json({
      success: true,
      ...result,
    });
  })
);

// GET /api/v1/vehicles/:vehicleId - Get single vehicle
router.get(
  '/:vehicleId',
  validateParams(vehicleIdParamSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    const vehicle = await getVehicle(authReq.user.id, req.params.vehicleId as string);

    const response: ApiResponse<typeof vehicle> = {
      success: true,
      data: vehicle,
    };

    res.json(response);
  })
);

// PATCH /api/v1/vehicles/:vehicleId - Update vehicle
router.patch(
  '/:vehicleId',
  validateParams(vehicleIdParamSchema),
  validateBody(updateVehicleSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    const vehicle = await updateVehicle(
      authReq.user.id,
      req.params.vehicleId as string,
      req.body
    );

    const response: ApiResponse<typeof vehicle> = {
      success: true,
      data: vehicle,
    };

    res.json(response);
  })
);

// DELETE /api/v1/vehicles/:vehicleId - Delete vehicle
router.delete(
  '/:vehicleId',
  validateParams(vehicleIdParamSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    await deleteVehicle(authReq.user.id, req.params.vehicleId as string);

    res.status(204).send();
  })
);

// POST /api/v1/vehicles/:vehicleId/maintenance - Add maintenance record
router.post(
  '/:vehicleId/maintenance',
  validateParams(vehicleIdParamSchema),
  validateBody(createMaintenanceRecordSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    const record = await addMaintenanceRecord(
      authReq.user.id,
      req.params.vehicleId as string,
      req.body
    );

    const response: ApiResponse<typeof record> = {
      success: true,
      data: record,
    };

    res.status(201).json(response);
  })
);

// GET /api/v1/vehicles/:vehicleId/stats - Get vehicle statistics
router.get(
  '/:vehicleId/stats',
  validateParams(vehicleIdParamSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    const stats = await getVehicleStats(authReq.user.id, req.params.vehicleId as string);

    const response: ApiResponse<typeof stats> = {
      success: true,
      data: stats,
    };

    res.json(response);
  })
);

export default router;
