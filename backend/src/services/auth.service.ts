import { prisma } from '../config/database.js';
import { redis, cache } from '../config/redis.js';
import { verifyAppleIdentityToken, validateAppleAuthorizationCode } from './apple-auth.service.js';
import { verifyGoogleIdToken, getGoogleUserInfo } from './google-auth.service.js';
import { generateAccessToken, generateRefreshToken, verifyRefreshToken } from './jwt.service.js';
import { hashToken, encryptBuffer, generateSecureToken } from '../utils/crypto.js';
import { authLogger } from '../utils/logger.js';
import {
  UnauthorizedError,
  NotFoundError,
  ConflictError,
  SessionRevokedError,
  InvalidTokenError,
} from '../utils/errors.js';
import type {
  AppleAuthRequest,
  GoogleAuthRequest,
  AuthResponse,
  UserProfile,
} from '../types/index.js';
import type { User, Session, AuthProvider } from '@prisma/client';

const SESSION_TTL_SECONDS = 30 * 24 * 60 * 60; // 30 days

function formatUserProfile(user: User): UserProfile {
  // Return snake_case keys to match iOS client expectations
  return {
    id: user.id,
    email: user.email,
    email_verified: user.emailVerified,
    full_name: user.fullName,
    avatar_url: user.avatarUrl,
    timezone: user.timezone,
    locale: user.locale,
    subscription_tier: user.subscriptionTier,
    subscription_status: user.subscriptionStatus,
    created_at: user.createdAt.toISOString(),
    updated_at: user.updatedAt.toISOString(),
    phone_number: user.phoneNumber,
    phone_verified: user.phoneVerified,
    trial_ends_at: user.trialEndsAt?.toISOString() ?? null,
  };
}

async function createSession(
  userId: string,
  deviceInfo: {
    deviceId: string;
    deviceName?: string;
    deviceModel?: string;
    osVersion?: string;
    appVersion?: string;
    pushToken?: string;
    ipAddress?: string;
    userAgent?: string;
  }
): Promise<{ session: Session; refreshToken: string }> {
  const familyId = generateSecureToken(16);
  const expiresAt = new Date(Date.now() + SESSION_TTL_SECONDS * 1000);

  // Generate refresh token
  const { token: refreshToken, expiresAt: tokenExpiresAt } = await generateRefreshToken({
    userId,
    sessionId: '', // Will be set after session creation
    deviceId: deviceInfo.deviceId,
    familyId,
  });

  const refreshTokenHash = hashToken(refreshToken);

  // Create session
  const session = await prisma.session.create({
    data: {
      userId,
      deviceId: deviceInfo.deviceId,
      deviceName: deviceInfo.deviceName,
      deviceModel: deviceInfo.deviceModel,
      osVersion: deviceInfo.osVersion,
      appVersion: deviceInfo.appVersion,
      pushToken: deviceInfo.pushToken,
      ipAddress: deviceInfo.ipAddress,
      userAgent: deviceInfo.userAgent,
      expiresAt,
      refreshTokenHash,
      refreshTokenFamily: familyId,
    },
  });

  // Generate the actual refresh token with the session ID
  const { token: finalRefreshToken } = await generateRefreshToken({
    userId,
    sessionId: session.id,
    deviceId: deviceInfo.deviceId,
    familyId,
  });

  // Update the hash with the final token
  await prisma.session.update({
    where: { id: session.id },
    data: { refreshTokenHash: hashToken(finalRefreshToken) },
  });

  authLogger.info({ userId, sessionId: session.id, deviceId: deviceInfo.deviceId }, 'Session created');

  return { session, refreshToken: finalRefreshToken };
}

async function findOrCreateUser(
  provider: AuthProvider,
  providerUserId: string,
  email: string,
  fullName: string,
  emailVerified: boolean,
  avatarUrl?: string
): Promise<{ user: User; isNewUser: boolean }> {
  // Check if auth provider link exists
  const existingLink = await prisma.authProviderLink.findUnique({
    where: {
      provider_providerUserId: {
        provider,
        providerUserId,
      },
    },
    include: { user: true },
  });

  if (existingLink) {
    // Update last login info
    await prisma.user.update({
      where: { id: existingLink.userId },
      data: { updatedAt: new Date() },
    });

    return { user: existingLink.user, isNewUser: false };
  }

  // Check if user exists with this email
  const existingUser = await prisma.user.findUnique({
    where: { email },
  });

  if (existingUser) {
    // Link the new provider to existing user
    await prisma.authProviderLink.create({
      data: {
        userId: existingUser.id,
        provider,
        providerUserId,
        providerEmail: email,
      },
    });

    authLogger.info({
      userId: existingUser.id,
      provider,
    }, 'Auth provider linked to existing user');

    return { user: existingUser, isNewUser: false };
  }

  // Create new user with auth provider link
  const newUser = await prisma.user.create({
    data: {
      email,
      emailVerified,
      fullName,
      avatarUrl,
      trialEndsAt: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000), // 14-day trial
      authProviders: {
        create: {
          provider,
          providerUserId,
          providerEmail: email,
        },
      },
      settings: {
        create: {}, // Create default settings
      },
    },
  });

  authLogger.info({ userId: newUser.id, provider, email }, 'New user created');

  return { user: newUser, isNewUser: true };
}

export async function authenticateWithApple(request: AppleAuthRequest): Promise<AuthResponse> {
  // Verify the identity token
  const appleUser = await verifyAppleIdentityToken(request.identityToken);

  // Validate authorization code and get tokens
  const appleTokens = await validateAppleAuthorizationCode(request.authorizationCode);

  // Determine user name
  let fullName = 'Apple User';
  if (request.user?.name) {
    const firstName = request.user.name.firstName ?? '';
    const lastName = request.user.name.lastName ?? '';
    fullName = `${firstName} ${lastName}`.trim() || 'Apple User';
  }

  // Determine email
  const email = request.user?.email ?? appleUser.email;
  if (!email) {
    throw new UnauthorizedError('Email is required for authentication');
  }

  // Find or create user
  const { user, isNewUser } = await findOrCreateUser(
    'apple',
    appleUser.userId,
    email,
    fullName,
    appleUser.emailVerified,
    undefined
  );

  // Store encrypted tokens for future use
  if (appleTokens.refreshToken) {
    const encryptedRefreshToken = encryptBuffer(Buffer.from(appleTokens.refreshToken));
    const encryptedAccessToken = encryptBuffer(Buffer.from(appleTokens.accessToken));

    await prisma.authProviderLink.update({
      where: {
        provider_providerUserId: {
          provider: 'apple',
          providerUserId: appleUser.userId,
        },
      },
      data: {
        accessTokenEncrypted: encryptedAccessToken as Uint8Array<ArrayBuffer>,
        refreshTokenEncrypted: encryptedRefreshToken as Uint8Array<ArrayBuffer>,
        tokenExpiresAt: new Date(Date.now() + appleTokens.expiresIn * 1000),
      },
    });
  }

  // Create session
  const { session, refreshToken } = await createSession(user.id, {
    deviceId: request.deviceId,
    deviceName: request.deviceName,
    deviceModel: request.deviceModel,
    osVersion: request.osVersion,
    appVersion: request.appVersion,
    pushToken: request.pushToken,
  });

  // Generate access token
  const { token: accessToken, expiresIn } = await generateAccessToken({
    userId: user.id,
    email: user.email,
    tier: user.subscriptionTier,
  });

  return {
    access_token: accessToken,
    refresh_token: refreshToken,
    token_type: 'Bearer',
    expires_in: expiresIn,
    user: formatUserProfile(user),
    is_new_user: isNewUser,
  };
}

export async function authenticateWithGoogle(request: GoogleAuthRequest): Promise<AuthResponse> {
  // Verify the ID token
  const googleIdTokenData = await verifyGoogleIdToken(request.idToken);

  // Get additional user info
  let userInfo = {
    picture: googleIdTokenData.picture,
    name: googleIdTokenData.name,
    givenName: googleIdTokenData.givenName,
    familyName: googleIdTokenData.familyName,
  };

  try {
    const fullUserInfo = await getGoogleUserInfo(request.accessToken);
    userInfo = {
      picture: fullUserInfo.picture ?? googleIdTokenData.picture,
      name: fullUserInfo.name ?? googleIdTokenData.name,
      givenName: fullUserInfo.givenName ?? googleIdTokenData.givenName,
      familyName: fullUserInfo.familyName ?? googleIdTokenData.familyName,
    };
  } catch {
    // Continue with ID token data
  }

  // Determine user name
  let fullName = userInfo.name ?? 'Google User';
  if (!fullName && userInfo.givenName) {
    fullName = `${userInfo.givenName} ${userInfo.familyName ?? ''}`.trim();
  }

  // Find or create user
  const { user, isNewUser } = await findOrCreateUser(
    'google',
    googleIdTokenData.userId,
    googleIdTokenData.email,
    fullName,
    googleIdTokenData.emailVerified,
    userInfo.picture
  );

  // Create session
  const { session, refreshToken } = await createSession(user.id, {
    deviceId: request.deviceId,
    deviceName: request.deviceName,
    deviceModel: request.deviceModel,
    osVersion: request.osVersion,
    appVersion: request.appVersion,
    pushToken: request.pushToken,
  });

  // Generate access token
  const { token: accessToken, expiresIn } = await generateAccessToken({
    userId: user.id,
    email: user.email,
    tier: user.subscriptionTier,
  });

  return {
    access_token: accessToken,
    refresh_token: refreshToken,
    token_type: 'Bearer',
    expires_in: expiresIn,
    user: formatUserProfile(user),
    is_new_user: isNewUser,
  };
}

export async function refreshAccessToken(
  refreshToken: string,
  deviceId: string
): Promise<{
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}> {
  // Verify the refresh token
  const tokenPayload = await verifyRefreshToken(refreshToken);

  // Validate device ID matches
  if (tokenPayload.did !== deviceId) {
    authLogger.warn({
      expectedDeviceId: tokenPayload.did,
      providedDeviceId: deviceId,
    }, 'Device ID mismatch in token refresh');
    throw new UnauthorizedError('Device ID mismatch');
  }

  // Find the session
  const session = await prisma.session.findUnique({
    where: { id: tokenPayload.sid },
    include: { user: true },
  });

  if (!session) {
    throw new NotFoundError('Session');
  }

  // Check if session is revoked
  if (session.revokedAt) {
    throw new SessionRevokedError();
  }

  // Check if session has expired
  if (session.expiresAt < new Date()) {
    await prisma.session.update({
      where: { id: session.id },
      data: { revokedAt: new Date() },
    });
    throw new SessionRevokedError();
  }

  // Verify refresh token hash (detect token reuse)
  const providedTokenHash = hashToken(refreshToken);
  if (session.refreshTokenHash !== providedTokenHash) {
    // Potential token theft - revoke entire token family
    authLogger.warn({
      sessionId: session.id,
      userId: session.userId,
      familyId: session.refreshTokenFamily,
    }, 'Potential token reuse detected, revoking token family');

    await prisma.session.updateMany({
      where: { refreshTokenFamily: session.refreshTokenFamily },
      data: { revokedAt: new Date() },
    });

    throw new InvalidTokenError('Token has already been used');
  }

  // Generate new tokens (token rotation)
  const { token: newRefreshToken, expiresAt } = await generateRefreshToken({
    userId: session.userId,
    sessionId: session.id,
    deviceId: session.deviceId,
    familyId: session.refreshTokenFamily,
  });

  const { token: newAccessToken, expiresIn } = await generateAccessToken({
    userId: session.user.id,
    email: session.user.email,
    tier: session.user.subscriptionTier,
  });

  // Update session with new refresh token hash
  await prisma.session.update({
    where: { id: session.id },
    data: {
      refreshTokenHash: hashToken(newRefreshToken),
      lastActiveAt: new Date(),
      expiresAt,
    },
  });

  authLogger.info({ userId: session.userId, sessionId: session.id }, 'Token refreshed');

  return {
    accessToken: newAccessToken,
    refreshToken: newRefreshToken,
    expiresIn,
  };
}

export async function logout(
  userId: string,
  sessionId?: string,
  deviceId?: string,
  allDevices?: boolean
): Promise<void> {
  if (allDevices) {
    // Revoke all sessions for this user
    await prisma.session.updateMany({
      where: {
        userId,
        revokedAt: null,
      },
      data: { revokedAt: new Date() },
    });

    authLogger.info({ userId }, 'All sessions revoked');
    return;
  }

  if (sessionId) {
    // Revoke specific session
    await prisma.session.update({
      where: { id: sessionId },
      data: { revokedAt: new Date() },
    });

    authLogger.info({ userId, sessionId }, 'Session revoked');
    return;
  }

  if (deviceId) {
    // Revoke sessions for specific device
    await prisma.session.updateMany({
      where: {
        userId,
        deviceId,
        revokedAt: null,
      },
      data: { revokedAt: new Date() },
    });

    authLogger.info({ userId, deviceId }, 'Device sessions revoked');
  }
}

export async function getActiveSessions(userId: string): Promise<{
  sessions: Array<{
    id: string;
    deviceName: string | null;
    deviceModel: string | null;
    lastActiveAt: Date;
    createdAt: Date;
    isCurrent: boolean;
  }>;
}> {
  const sessions = await prisma.session.findMany({
    where: {
      userId,
      revokedAt: null,
      expiresAt: { gt: new Date() },
    },
    orderBy: { lastActiveAt: 'desc' },
    select: {
      id: true,
      deviceName: true,
      deviceModel: true,
      lastActiveAt: true,
      createdAt: true,
    },
  });

  return {
    sessions: sessions.map((s, index) => ({
      ...s,
      isCurrent: index === 0, // Most recently active is current
    })),
  };
}

export async function revokeSession(userId: string, sessionId: string): Promise<void> {
  const session = await prisma.session.findFirst({
    where: {
      id: sessionId,
      userId,
    },
  });

  if (!session) {
    throw new NotFoundError('Session');
  }

  await prisma.session.update({
    where: { id: sessionId },
    data: { revokedAt: new Date() },
  });

  authLogger.info({ userId, sessionId }, 'Session revoked by user');
}

export async function getUserById(userId: string): Promise<User | null> {
  return prisma.user.findUnique({
    where: { id: userId, deletedAt: null },
  });
}

export async function updateUserProfile(
  userId: string,
  updates: Partial<{
    fullName: string;
    avatarUrl: string;
    timezone: string;
    locale: string;
    phoneNumber: string;
  }>
): Promise<User> {
  return prisma.user.update({
    where: { id: userId },
    data: updates,
  });
}

export async function deleteUser(userId: string): Promise<void> {
  // Soft delete the user
  await prisma.user.update({
    where: { id: userId },
    data: { deletedAt: new Date() },
  });

  // Revoke all sessions
  await prisma.session.updateMany({
    where: { userId },
    data: { revokedAt: new Date() },
  });

  authLogger.info({ userId }, 'User account deleted');
}
