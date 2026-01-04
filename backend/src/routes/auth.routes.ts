import { Router } from 'express';
import type { Request, Response } from 'express';
import { asyncHandler } from '../middleware/error.middleware.js';
import { authenticate } from '../middleware/auth.middleware.js';
import { validateBody } from '../middleware/validation.middleware.js';
import { strictRateLimiter } from '../middleware/rate-limit.middleware.js';
import {
  appleAuthSchema,
  googleAuthSchema,
  refreshTokenSchema,
  logoutSchema,
  updateProfileSchema,
} from '../validators/auth.validators.js';
import {
  authenticateWithApple,
  authenticateWithGoogle,
  refreshAccessToken,
  logout,
  getActiveSessions,
  revokeSession,
  updateUserProfile,
  deleteUser,
} from '../services/auth.service.js';
import type { AuthenticatedRequest, ApiResponse, AuthResponse, UserProfile } from '../types/index.js';

const router = Router();

// POST /api/v1/auth/apple - Sign in with Apple
router.post(
  '/apple',
  strictRateLimiter(10, 60),
  validateBody(appleAuthSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const result = await authenticateWithApple({
      identityToken: req.body.identityToken,
      authorizationCode: req.body.authorizationCode,
      user: req.body.user,
      deviceId: req.body.deviceId,
      deviceName: req.body.deviceName,
      deviceModel: req.body.deviceModel,
      osVersion: req.body.osVersion,
      appVersion: req.body.appVersion,
      pushToken: req.body.pushToken,
    });

    const statusCode = result.is_new_user ? 201 : 200;
    const response: ApiResponse<AuthResponse> = {
      success: true,
      data: result,
    };

    res.status(statusCode).json(response);
  })
);

// POST /api/v1/auth/google - Sign in with Google
router.post(
  '/google',
  strictRateLimiter(10, 60),
  validateBody(googleAuthSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const result = await authenticateWithGoogle({
      idToken: req.body.idToken,
      accessToken: req.body.accessToken,
      deviceId: req.body.deviceId,
      deviceName: req.body.deviceName,
      deviceModel: req.body.deviceModel,
      osVersion: req.body.osVersion,
      appVersion: req.body.appVersion,
      pushToken: req.body.pushToken,
    });

    const statusCode = result.is_new_user ? 201 : 200;
    const response: ApiResponse<AuthResponse> = {
      success: true,
      data: result,
    };

    res.status(statusCode).json(response);
  })
);

// POST /api/v1/auth/refresh - Refresh access token
router.post(
  '/refresh',
  strictRateLimiter(30, 60),
  validateBody(refreshTokenSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const result = await refreshAccessToken(
      req.body.refreshToken,
      req.body.deviceId
    );

    const response: ApiResponse<{
      accessToken: string;
      refreshToken: string;
      tokenType: 'Bearer';
      expiresIn: number;
    }> = {
      success: true,
      data: {
        ...result,
        tokenType: 'Bearer',
      },
    };

    res.json(response);
  })
);

// POST /api/v1/auth/logout - Logout (revoke session)
router.post(
  '/logout',
  authenticate,
  validateBody(logoutSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;

    await logout(
      authReq.user.id,
      authReq.session?.id,
      req.body.deviceId,
      req.body.allDevices
    );

    res.status(204).send();
  })
);

// GET /api/v1/auth/sessions - List active sessions
router.get(
  '/sessions',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    const result = await getActiveSessions(authReq.user.id);

    const response: ApiResponse<typeof result> = {
      success: true,
      data: result,
    };

    res.json(response);
  })
);

// DELETE /api/v1/auth/sessions/:sessionId - Revoke specific session
router.delete(
  '/sessions/:sessionId',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    await revokeSession(authReq.user.id, req.params.sessionId as string);

    res.status(204).send();
  })
);

// GET /api/v1/auth/me - Get current user profile
router.get(
  '/me',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;

    const response: ApiResponse<UserProfile> = {
      success: true,
      data: {
        id: authReq.user.id,
        email: authReq.user.email,
        email_verified: true, // If they're authenticated, email is verified
        full_name: authReq.user.fullName,
        avatar_url: authReq.user.avatarUrl,
        phone_number: null,
        phone_verified: false,
        timezone: authReq.user.timezone,
        locale: authReq.user.locale,
        subscription_tier: authReq.user.subscriptionTier,
        subscription_status: 'active',
        trial_ends_at: null,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      },
    };

    res.json(response);
  })
);

// PATCH /api/v1/auth/me - Update user profile
router.patch(
  '/me',
  authenticate,
  validateBody(updateProfileSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;

    const updatedUser = await updateUserProfile(authReq.user.id, req.body);

    const response: ApiResponse<UserProfile> = {
      success: true,
      data: {
        id: updatedUser.id,
        email: updatedUser.email,
        email_verified: updatedUser.emailVerified,
        full_name: updatedUser.fullName,
        avatar_url: updatedUser.avatarUrl,
        phone_number: updatedUser.phoneNumber,
        phone_verified: updatedUser.phoneVerified,
        timezone: updatedUser.timezone,
        locale: updatedUser.locale,
        subscription_tier: updatedUser.subscriptionTier,
        subscription_status: updatedUser.subscriptionStatus,
        trial_ends_at: updatedUser.trialEndsAt?.toISOString() ?? null,
        created_at: updatedUser.createdAt.toISOString(),
        updated_at: updatedUser.updatedAt.toISOString(),
      },
    };

    res.json(response);
  })
);

// DELETE /api/v1/auth/me - Delete user account
router.delete(
  '/me',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthenticatedRequest;
    await deleteUser(authReq.user.id);

    res.status(204).send();
  })
);

export default router;
