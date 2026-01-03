import type { Request, Response, NextFunction } from 'express';
import { rateLimit as redisRateLimit } from '../config/redis.js';
import { RateLimitError } from '../utils/errors.js';
import { config } from '../config/env.js';
import type { AuthenticatedRequest } from '../types/index.js';
import type { SubscriptionTier } from '@prisma/client';

interface RateLimitConfig {
  windowSeconds: number;
  maxRequests: number;
}

const tierLimits: Record<SubscriptionTier, RateLimitConfig> = {
  free: { windowSeconds: 60, maxRequests: 60 },
  pro: { windowSeconds: 60, maxRequests: 120 },
  business: { windowSeconds: 60, maxRequests: 300 },
  enterprise: { windowSeconds: 60, maxRequests: 600 },
};

const endpointLimits: Record<string, RateLimitConfig> = {
  'POST:/api/v1/auth/apple': { windowSeconds: 60, maxRequests: 10 },
  'POST:/api/v1/auth/google': { windowSeconds: 60, maxRequests: 10 },
  'POST:/api/v1/auth/refresh': { windowSeconds: 60, maxRequests: 30 },
  'POST:/api/v1/trips': { windowSeconds: 60, maxRequests: 30 },
  'POST:/api/v1/trips/:tripId/waypoints': { windowSeconds: 60, maxRequests: 60 },
  'POST:/api/v1/reports': { windowSeconds: 3600, maxRequests: 10 },
  'POST:/api/v1/routes/:routeId/optimize': { windowSeconds: 60, maxRequests: 10 },
  'POST:/api/v1/expenses/receipt': { windowSeconds: 60, maxRequests: 20 },
};

function getClientIdentifier(req: Request): string {
  const authReq = req as AuthenticatedRequest;

  // Use user ID if authenticated
  if (authReq.user?.id) {
    return `user:${authReq.user.id}`;
  }

  // Fall back to device ID if provided
  const deviceId = req.headers['x-device-id'];
  if (deviceId && typeof deviceId === 'string') {
    return `device:${deviceId}`;
  }

  // Fall back to IP address
  const ip = req.ip || req.socket.remoteAddress || 'unknown';
  return `ip:${ip}`;
}

function normalizeRoute(path: string, method: string): string {
  // Replace UUID patterns with placeholder
  const normalizedPath = path.replace(
    /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi,
    ':id'
  );
  return `${method}:${normalizedPath}`;
}

export async function rateLimiter(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const identifier = getClientIdentifier(req);
    const route = normalizeRoute(req.path, req.method);
    const authReq = req as AuthenticatedRequest;

    // Check for endpoint-specific limits
    let limitConfig: RateLimitConfig | undefined;

    for (const [pattern, config] of Object.entries(endpointLimits)) {
      const [method, path] = pattern.split(':');
      if (req.method === method) {
        // Convert route pattern to regex
        const regexPattern = path
          .replace(/:[^/]+/g, '[^/]+')
          .replace(/\//g, '\\/');

        if (new RegExp(`^${regexPattern}$`).test(req.path)) {
          limitConfig = config;
          break;
        }
      }
    }

    // Fall back to tier-based limits
    if (!limitConfig) {
      const tier = authReq.user?.subscriptionTier ?? 'free';
      limitConfig = tierLimits[tier];
    }

    // Perform rate limit check
    const key = `${route}:${identifier}`;
    const result = await redisRateLimit.check(
      key,
      limitConfig.maxRequests,
      limitConfig.windowSeconds
    );

    // Set rate limit headers
    res.setHeader('X-RateLimit-Limit', limitConfig.maxRequests);
    res.setHeader('X-RateLimit-Remaining', result.remaining);
    res.setHeader('X-RateLimit-Reset', Math.ceil(result.resetAt / 1000));

    if (!result.allowed) {
      const retryAfter = result.resetAt - Date.now();
      throw new RateLimitError(retryAfter, {
        limit: limitConfig.maxRequests,
        windowSeconds: limitConfig.windowSeconds,
        resetAt: new Date(result.resetAt).toISOString(),
      });
    }

    next();
  } catch (error) {
    next(error);
  }
}

// Stricter rate limiter for sensitive endpoints
export function strictRateLimiter(maxRequests: number, windowSeconds: number) {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const identifier = getClientIdentifier(req);
      const route = normalizeRoute(req.path, req.method);
      const key = `strict:${route}:${identifier}`;

      const result = await redisRateLimit.check(key, maxRequests, windowSeconds);

      res.setHeader('X-RateLimit-Limit', maxRequests);
      res.setHeader('X-RateLimit-Remaining', result.remaining);
      res.setHeader('X-RateLimit-Reset', Math.ceil(result.resetAt / 1000));

      if (!result.allowed) {
        const retryAfter = result.resetAt - Date.now();
        throw new RateLimitError(retryAfter);
      }

      next();
    } catch (error) {
      next(error);
    }
  };
}

// IP-based rate limiter (for unauthenticated endpoints)
export function ipRateLimiter(maxRequests: number, windowSeconds: number) {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const ip = req.ip || req.socket.remoteAddress || 'unknown';
      const key = `ip:${ip}`;

      const result = await redisRateLimit.check(key, maxRequests, windowSeconds);

      res.setHeader('X-RateLimit-Limit', maxRequests);
      res.setHeader('X-RateLimit-Remaining', result.remaining);
      res.setHeader('X-RateLimit-Reset', Math.ceil(result.resetAt / 1000));

      if (!result.allowed) {
        const retryAfter = result.resetAt - Date.now();
        throw new RateLimitError(retryAfter);
      }

      next();
    } catch (error) {
      next(error);
    }
  };
}
