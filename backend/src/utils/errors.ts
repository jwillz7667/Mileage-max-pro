export class AppError extends Error {
  public readonly statusCode: number;
  public readonly code: string;
  public readonly isOperational: boolean;
  public readonly details?: Record<string, unknown>;

  constructor(
    message: string,
    statusCode: number = 500,
    code: string = 'INTERNAL_ERROR',
    details?: Record<string, unknown>
  ) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.isOperational = true;
    this.details = details;

    Error.captureStackTrace(this, this.constructor);
  }
}

export class BadRequestError extends AppError {
  constructor(message: string = 'Bad request', details?: Record<string, unknown>) {
    super(message, 400, 'BAD_REQUEST', details);
  }
}

export class UnauthorizedError extends AppError {
  constructor(message: string = 'Unauthorized', details?: Record<string, unknown>) {
    super(message, 401, 'UNAUTHORIZED', details);
  }
}

export class ForbiddenError extends AppError {
  constructor(message: string = 'Forbidden', details?: Record<string, unknown>) {
    super(message, 403, 'FORBIDDEN', details);
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string = 'Resource', details?: Record<string, unknown>) {
    super(`${resource} not found`, 404, 'NOT_FOUND', details);
  }
}

export class ConflictError extends AppError {
  constructor(message: string = 'Conflict', details?: Record<string, unknown>) {
    super(message, 409, 'CONFLICT', details);
  }
}

export class ValidationError extends AppError {
  constructor(message: string = 'Validation failed', details?: Record<string, unknown>) {
    super(message, 422, 'VALIDATION_ERROR', details);
  }
}

export class RateLimitError extends AppError {
  public readonly retryAfter: number;

  constructor(retryAfter: number, details?: Record<string, unknown>) {
    super('Too many requests', 429, 'RATE_LIMIT_EXCEEDED', details);
    this.retryAfter = retryAfter;
  }
}

export class InternalError extends AppError {
  constructor(message: string = 'Internal server error', details?: Record<string, unknown>) {
    super(message, 500, 'INTERNAL_ERROR', details);
  }
}

export class ServiceUnavailableError extends AppError {
  constructor(message: string = 'Service unavailable', details?: Record<string, unknown>) {
    super(message, 503, 'SERVICE_UNAVAILABLE', details);
  }
}

export class TokenExpiredError extends AppError {
  constructor(tokenType: 'access' | 'refresh' = 'access') {
    super(`${tokenType === 'access' ? 'Access' : 'Refresh'} token expired`, 401, 'TOKEN_EXPIRED');
  }
}

export class InvalidTokenError extends AppError {
  constructor(message: string = 'Invalid token') {
    super(message, 401, 'INVALID_TOKEN');
  }
}

export class SessionRevokedError extends AppError {
  constructor() {
    super('Session has been revoked', 401, 'SESSION_REVOKED');
  }
}

export class SubscriptionRequiredError extends AppError {
  constructor(requiredTier: string, feature: string) {
    super(
      `${requiredTier} subscription required for ${feature}`,
      403,
      'SUBSCRIPTION_REQUIRED',
      { requiredTier, feature }
    );
  }
}

export class QuotaExceededError extends AppError {
  constructor(resource: string, limit: number) {
    super(
      `${resource} quota exceeded. Limit: ${limit}`,
      403,
      'QUOTA_EXCEEDED',
      { resource, limit }
    );
  }
}

export function isAppError(error: unknown): error is AppError {
  return error instanceof AppError;
}

export function handlePrismaError(error: unknown): AppError {
  if (typeof error !== 'object' || error === null) {
    return new InternalError('Database error');
  }

  const prismaError = error as { code?: string; meta?: { target?: string[] } };

  switch (prismaError.code) {
    case 'P2002':
      const field = prismaError.meta?.target?.[0] ?? 'field';
      return new ConflictError(`A record with this ${field} already exists`);
    case 'P2025':
      return new NotFoundError('Record');
    case 'P2003':
      return new BadRequestError('Invalid reference to related record');
    case 'P2014':
      return new BadRequestError('Invalid relation');
    default:
      return new InternalError('Database error');
  }
}
