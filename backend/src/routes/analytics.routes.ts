import { Router } from 'express';
import type { Request, Response } from 'express';
import { asyncHandler } from '../middleware/error.middleware.js';
import { authenticate } from '../middleware/auth.middleware.js';
import { validateQuery } from '../middleware/validation.middleware.js';
import {
  analyticsQuerySchema,
  taxSummaryQuerySchema,
} from '../validators/report.validators.js';
import { getDashboardData, getTaxSummary } from '../services/analytics.service.js';
import type { AuthenticatedRequest, ApiResponse } from '../types/index.js';

const router = Router();

// All routes require authentication
router.use(authenticate);

// GET /api/v1/analytics/dashboard - Get dashboard summary data
router.get(
  '/dashboard',
  validateQuery(analyticsQuerySchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    const data = await getDashboardData(authReq.user.id, req.query as any);

    const response: ApiResponse<typeof data> = {
      success: true,
      data,
    };

    res.json(response);
  })
);

// GET /api/v1/analytics/tax-summary - Get tax year summary
router.get(
  '/tax-summary',
  validateQuery(taxSummaryQuerySchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    const data = await getTaxSummary(authReq.user.id, req.query as any);

    const response: ApiResponse<typeof data> = {
      success: true,
      data,
    };

    res.json(response);
  })
);

export default router;
