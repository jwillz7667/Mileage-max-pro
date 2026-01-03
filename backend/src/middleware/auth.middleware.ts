import type { Request, Response, NextFunction } from 'express';
import { verifyAccessToken } from '../services/jwt.service.js';
import { getUserById } from '../services/auth.service.js';
import { prisma } from '../config/database.js';
import { UnauthorizedError, ForbiddenError, SubscriptionRequiredError } from '../utils/errors.js';
import type { AuthenticatedRequest, AuthenticatedUser } from '../types/index.js';
import type { SubscriptionTier } from '@prisma/client';

export async function authenticate(
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      throw new UnauthorizedError('Authorization header required');
    }

    const parts = authHeader.split(' ');
    if (parts.length !== 2 || parts[0] !== 'Bearer') {
      throw new UnauthorizedError('Invalid authorization format. Use: Bearer <token>');
    }

    const token = parts[1];
    if (!token) {
      throw new UnauthorizedError('Token required');
    }

    // Verify the access token
    const payload = await verifyAccessToken(token);

    // Get user from database
    const user = await getUserById(payload.sub);

    if (!user) {
      throw new UnauthorizedError('User not found');
    }

    if (user.deletedAt) {
      throw new UnauthorizedError('Account has been deleted');
    }

    // Attach user to request
    (req as AuthenticatedRequest).user = {
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      avatarUrl: user.avatarUrl,
      subscriptionTier: user.subscriptionTier,
      timezone: user.timezone,
      locale: user.locale,
    };

    // Extract session info from a valid session if needed
    const deviceId = req.headers['x-device-id'] as string | undefined;
    if (deviceId) {
      const session = await prisma.session.findFirst({
        where: {
          userId: user.id,
          deviceId,
          revokedAt: null,
          expiresAt: { gt: new Date() },
        },
        select: { id: true, deviceId: true },
      });

      if (session) {
        (req as AuthenticatedRequest).session = {
          id: session.id,
          deviceId: session.deviceId,
        };
      }
    }

    next();
  } catch (error) {
    next(error);
  }
}

export function requireSubscription(requiredTier: SubscriptionTier | SubscriptionTier[]) {
  const tiers = Array.isArray(requiredTier) ? requiredTier : [requiredTier];
  const tierHierarchy: Record<SubscriptionTier, number> = {
    free: 0,
    pro: 1,
    business: 2,
    enterprise: 3,
  };

  return (req: Request, _res: Response, next: NextFunction): void => {
    const authReq = req as AuthenticatedRequest;

    if (!authReq.user) {
      next(new UnauthorizedError('Authentication required'));
      return;
    }

    const userTierLevel = tierHierarchy[authReq.user.subscriptionTier];
    const requiredTierLevel = Math.min(...tiers.map(t => tierHierarchy[t]));

    if (userTierLevel < requiredTierLevel) {
      const minRequiredTier = tiers.find(t => tierHierarchy[t] === requiredTierLevel);
      next(new SubscriptionRequiredError(
        minRequiredTier ?? 'pro',
        'this feature'
      ));
      return;
    }

    next();
  };
}

export function requireProOrHigher(req: Request, res: Response, next: NextFunction): void {
  requireSubscription(['pro', 'business', 'enterprise'])(req, res, next);
}

export function requireBusinessOrHigher(req: Request, res: Response, next: NextFunction): void {
  requireSubscription(['business', 'enterprise'])(req, res, next);
}

export function requireEnterprise(req: Request, res: Response, next: NextFunction): void {
  requireSubscription('enterprise')(req, res, next);
}

export async function optionalAuth(
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      next();
      return;
    }

    const parts = authHeader.split(' ');
    if (parts.length !== 2 || parts[0] !== 'Bearer') {
      next();
      return;
    }

    const token = parts[1];
    if (!token) {
      next();
      return;
    }

    try {
      const payload = await verifyAccessToken(token);
      const user = await getUserById(payload.sub);

      if (user && !user.deletedAt) {
        (req as AuthenticatedRequest).user = {
          id: user.id,
          email: user.email,
          fullName: user.fullName,
          avatarUrl: user.avatarUrl,
          subscriptionTier: user.subscriptionTier,
          timezone: user.timezone,
          locale: user.locale,
        };
      }
    } catch {
      // Token invalid, continue without auth
    }

    next();
  } catch (error) {
    next(error);
  }
}
