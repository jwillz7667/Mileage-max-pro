import { Router } from 'express';
import type { Request, Response } from 'express';
import { asyncHandler } from '../middleware/error.middleware.js';
import { authenticate } from '../middleware/auth.middleware.js';
import { validateBody, validateQuery, validateParams } from '../middleware/validation.middleware.js';
import {
  createRouteSchema,
  updateRouteSchema,
  updateStopSchema,
  routeIdParamSchema,
  stopIdParamSchema,
  routeFilterSchema,
} from '../validators/route.validators.js';
import {
  createRoute,
  getRoute,
  updateRoute,
  deleteRoute,
  listRoutes,
  optimizeRoute,
  startRoute,
  updateStop,
  completeRoute,
} from '../services/route.service.js';
import type { AuthenticatedRequest, ApiResponse } from '../types/index.js';

const router = Router();

// All routes require authentication
router.use(authenticate);

// POST /api/v1/routes - Create new route
router.post(
  '/',
  validateBody(createRouteSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    const route = await createRoute(
      authReq.user.id,
      authReq.user.subscriptionTier,
      req.body
    );

    const response: ApiResponse<typeof route> = {
      success: true,
      data: route,
    };

    res.status(201).json(response);
  })
);

// GET /api/v1/routes - List routes
router.get(
  '/',
  validateQuery(routeFilterSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    const result = await listRoutes(authReq.user.id, req.query as any);

    res.json({
      success: true,
      ...result,
    });
  })
);

// GET /api/v1/routes/:routeId - Get single route
router.get(
  '/:routeId',
  validateParams(routeIdParamSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    const route = await getRoute(authReq.user.id, req.params.routeId as string);

    const response: ApiResponse<typeof route> = {
      success: true,
      data: route,
    };

    res.json(response);
  })
);

// PATCH /api/v1/routes/:routeId - Update route
router.patch(
  '/:routeId',
  validateParams(routeIdParamSchema),
  validateBody(updateRouteSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    const route = await updateRoute(
      authReq.user.id,
      req.params.routeId as string,
      req.body
    );

    const response: ApiResponse<typeof route> = {
      success: true,
      data: route,
    };

    res.json(response);
  })
);

// DELETE /api/v1/routes/:routeId - Delete route
router.delete(
  '/:routeId',
  validateParams(routeIdParamSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    await deleteRoute(authReq.user.id, req.params.routeId as string);

    res.status(204).send();
  })
);

// POST /api/v1/routes/:routeId/optimize - Optimize route
router.post(
  '/:routeId/optimize',
  validateParams(routeIdParamSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    const route = await optimizeRoute(authReq.user.id, req.params.routeId as string);

    const response: ApiResponse<typeof route> = {
      success: true,
      data: route,
    };

    res.json(response);
  })
);

// POST /api/v1/routes/:routeId/start - Start route
router.post(
  '/:routeId/start',
  validateParams(routeIdParamSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    const route = await startRoute(authReq.user.id, req.params.routeId as string);

    const response: ApiResponse<typeof route> = {
      success: true,
      data: route,
    };

    res.json(response);
  })
);

// POST /api/v1/routes/:routeId/complete - Complete route
router.post(
  '/:routeId/complete',
  validateParams(routeIdParamSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    const route = await completeRoute(authReq.user.id, req.params.routeId as string);

    const response: ApiResponse<typeof route> = {
      success: true,
      data: route,
    };

    res.json(response);
  })
);

// PATCH /api/v1/routes/:routeId/stops/:stopId - Update stop
router.patch(
  '/:routeId/stops/:stopId',
  validateParams(stopIdParamSchema),
  validateBody(updateStopSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    const stop = await updateStop(
      authReq.user.id,
      req.params.routeId as string,
      req.params.stopId as string,
      req.body
    );

    const response: ApiResponse<typeof stop> = {
      success: true,
      data: stop,
    };

    res.json(response);
  })
);

export default router;
