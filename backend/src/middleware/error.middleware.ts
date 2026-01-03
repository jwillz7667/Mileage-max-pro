import type { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { logger } from '../utils/logger.js';
import { AppError, isAppError, handlePrismaError, RateLimitError } from '../utils/errors.js';
import { config } from '../config/env.js';
import type { ApiResponse } from '../types/index.js';

export function notFoundHandler(_req: Request, res: Response): void {
  const response: ApiResponse = {
    success: false,
    error: {
      code: 'NOT_FOUND',
      message: 'The requested resource was not found',
    },
  };
  res.status(404).json(response);
}

export function errorHandler(
  error: Error,
  req: Request,
  res: Response,
  _next: NextFunction
): void {
  // Log the error
  const errorInfo = {
    message: error.message,
    stack: error.stack,
    path: req.path,
    method: req.method,
    userId: (req as { user?: { id: string } }).user?.id,
    ip: req.ip,
  };

  // Handle Zod validation errors
  if (error instanceof ZodError) {
    const validationErrors: Record<string, string[]> = {};

    for (const issue of error.issues) {
      const path = issue.path.join('.');
      if (!validationErrors[path]) {
        validationErrors[path] = [];
      }
      validationErrors[path].push(issue.message);
    }

    const response: ApiResponse = {
      success: false,
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Request validation failed',
        details: { errors: validationErrors },
      },
    };

    logger.warn({ ...errorInfo, validationErrors }, 'Validation error');
    res.status(422).json(response);
    return;
  }

  // Handle Prisma errors
  if (error.name === 'PrismaClientKnownRequestError' ||
      error.name === 'PrismaClientValidationError') {
    const prismaError = handlePrismaError(error);

    const response: ApiResponse = {
      success: false,
      error: {
        code: prismaError.code,
        message: prismaError.message,
        details: prismaError.details,
      },
    };

    logger.error(errorInfo, 'Database error');
    res.status(prismaError.statusCode).json(response);
    return;
  }

  // Handle our custom errors
  if (isAppError(error)) {
    const response: ApiResponse = {
      success: false,
      error: {
        code: error.code,
        message: error.message,
        details: error.details,
        ...(config.server.isDevelopment && { stack: error.stack }),
      },
    };

    // Add Retry-After header for rate limit errors
    if (error instanceof RateLimitError) {
      res.setHeader('Retry-After', Math.ceil(error.retryAfter / 1000));
    }

    if (error.statusCode >= 500) {
      logger.error(errorInfo, 'Application error');
    } else {
      logger.warn(errorInfo, 'Client error');
    }

    res.status(error.statusCode).json(response);
    return;
  }

  // Handle unexpected errors
  logger.error(errorInfo, 'Unexpected error');

  const response: ApiResponse = {
    success: false,
    error: {
      code: 'INTERNAL_ERROR',
      message: config.server.isProduction
        ? 'An unexpected error occurred'
        : error.message,
      ...(config.server.isDevelopment && { stack: error.stack }),
    },
  };

  res.status(500).json(response);
}

// Async handler wrapper
export function asyncHandler<T>(
  fn: (req: Request, res: Response, next: NextFunction) => Promise<T>
) {
  return (req: Request, res: Response, next: NextFunction): void => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}
