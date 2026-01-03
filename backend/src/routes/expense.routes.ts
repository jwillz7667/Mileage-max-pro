import { Router } from 'express';
import type { Request, Response } from 'express';
import { asyncHandler } from '../middleware/error.middleware.js';
import { authenticate, requireProOrHigher } from '../middleware/auth.middleware.js';
import { validateBody, validateQuery, validateParams } from '../middleware/validation.middleware.js';
import {
  createExpenseSchema,
  updateExpenseSchema,
  createFuelPurchaseSchema,
  expenseIdParamSchema,
  expenseFilterSchema,
} from '../validators/expense.validators.js';
import {
  createExpense,
  getExpense,
  updateExpense,
  deleteExpense,
  listExpenses,
  createFuelPurchase,
} from '../services/expense.service.js';
import type { AuthenticatedRequest, ApiResponse } from '../types/index.js';

const router = Router();

// All routes require authentication
router.use(authenticate);

// POST /api/v1/expenses - Create new expense
router.post(
  '/',
  requireProOrHigher,
  validateBody(createExpenseSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    const expense = await createExpense(authReq.user.id, req.body);

    const response: ApiResponse<typeof expense> = {
      success: true,
      data: expense,
    };

    res.status(201).json(response);
  })
);

// GET /api/v1/expenses - List expenses
router.get(
  '/',
  validateQuery(expenseFilterSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    const result = await listExpenses(authReq.user.id, req.query as any);

    res.json({
      success: true,
      ...result,
    });
  })
);

// GET /api/v1/expenses/:expenseId - Get single expense
router.get(
  '/:expenseId',
  validateParams(expenseIdParamSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    const expense = await getExpense(authReq.user.id, req.params.expenseId as string);

    const response: ApiResponse<typeof expense> = {
      success: true,
      data: expense,
    };

    res.json(response);
  })
);

// PATCH /api/v1/expenses/:expenseId - Update expense
router.patch(
  '/:expenseId',
  requireProOrHigher,
  validateParams(expenseIdParamSchema),
  validateBody(updateExpenseSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    const expense = await updateExpense(
      authReq.user.id,
      req.params.expenseId as string,
      req.body
    );

    const response: ApiResponse<typeof expense> = {
      success: true,
      data: expense,
    };

    res.json(response);
  })
);

// DELETE /api/v1/expenses/:expenseId - Delete expense
router.delete(
  '/:expenseId',
  validateParams(expenseIdParamSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    await deleteExpense(authReq.user.id, req.params.expenseId as string);

    res.status(204).send();
  })
);

// POST /api/v1/expenses/fuel - Create fuel purchase
router.post(
  '/fuel',
  requireProOrHigher,
  validateBody(createFuelPurchaseSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    const result = await createFuelPurchase(authReq.user.id, req.body);

    const response: ApiResponse<typeof result> = {
      success: true,
      data: result,
    };

    res.status(201).json(response);
  })
);

export default router;
