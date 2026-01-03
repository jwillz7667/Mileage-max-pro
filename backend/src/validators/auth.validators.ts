import { z } from 'zod';

export const appleAuthSchema = z.object({
  identityToken: z.string().min(1, 'Identity token is required'),
  authorizationCode: z.string().min(1, 'Authorization code is required'),
  user: z
    .object({
      email: z.string().email().optional(),
      name: z
        .object({
          firstName: z.string().optional(),
          lastName: z.string().optional(),
        })
        .optional(),
    })
    .optional(),
  deviceId: z.string().uuid('Invalid device ID'),
  deviceName: z.string().max(255).optional(),
  deviceModel: z.string().max(100).optional(),
  osVersion: z.string().max(50).optional(),
  appVersion: z.string().max(20).optional(),
  pushToken: z.string().optional(),
});

export const googleAuthSchema = z.object({
  idToken: z.string().min(1, 'ID token is required'),
  accessToken: z.string().min(1, 'Access token is required'),
  deviceId: z.string().uuid('Invalid device ID'),
  deviceName: z.string().max(255).optional(),
  deviceModel: z.string().max(100).optional(),
  osVersion: z.string().max(50).optional(),
  appVersion: z.string().max(20).optional(),
  pushToken: z.string().optional(),
});

export const refreshTokenSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token is required'),
  deviceId: z.string().uuid('Invalid device ID'),
});

export const logoutSchema = z.object({
  deviceId: z.string().uuid().optional(),
  allDevices: z.boolean().optional(),
});

export const updateProfileSchema = z.object({
  fullName: z.string().min(1).max(255).optional(),
  avatarUrl: z.string().url().optional().nullable(),
  timezone: z.string().max(50).optional(),
  locale: z.string().max(10).optional(),
  phoneNumber: z.string().max(20).optional().nullable(),
});

export type AppleAuthInput = z.infer<typeof appleAuthSchema>;
export type GoogleAuthInput = z.infer<typeof googleAuthSchema>;
export type RefreshTokenInput = z.infer<typeof refreshTokenSchema>;
export type LogoutInput = z.infer<typeof logoutSchema>;
export type UpdateProfileInput = z.infer<typeof updateProfileSchema>;
