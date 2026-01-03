import * as jose from 'jose';
import { config } from '../config/env.js';
import { generateSecureToken } from '../utils/crypto.js';
import type { TokenPayload, RefreshTokenPayload } from '../types/index.js';
import { TokenExpiredError, InvalidTokenError } from '../utils/errors.js';

// Convert string to Uint8Array for jose
const accessSecret = new TextEncoder().encode(config.jwt.accessSecret);
const refreshSecret = new TextEncoder().encode(config.jwt.refreshSecret);

function parseExpiry(expiry: string): number {
  const match = expiry.match(/^(\d+)([smhd])$/);
  if (!match || !match[1] || !match[2]) {
    throw new Error(`Invalid expiry format: ${expiry}`);
  }

  const value = parseInt(match[1], 10);
  const unit = match[2];

  switch (unit) {
    case 's':
      return value;
    case 'm':
      return value * 60;
    case 'h':
      return value * 60 * 60;
    case 'd':
      return value * 60 * 60 * 24;
    default:
      throw new Error(`Invalid expiry unit: ${unit}`);
  }
}

export async function generateAccessToken(payload: {
  userId: string;
  email: string;
  tier: string;
}): Promise<{ token: string; expiresIn: number }> {
  const jti = generateSecureToken(16);
  const expiresIn = parseExpiry(config.jwt.accessExpiry);

  const token = await new jose.SignJWT({
    sub: payload.userId,
    email: payload.email,
    tier: payload.tier,
    jti,
  })
    .setProtectedHeader({ alg: 'HS256', typ: 'JWT' })
    .setIssuedAt()
    .setExpirationTime(`${expiresIn}s`)
    .setIssuer('mileagemax-pro')
    .setAudience('mileagemax-pro-ios')
    .sign(accessSecret);

  return { token, expiresIn };
}

export async function generateRefreshToken(payload: {
  userId: string;
  sessionId: string;
  deviceId: string;
  familyId: string;
}): Promise<{ token: string; expiresAt: Date }> {
  const jti = generateSecureToken(16);
  const expiresIn = parseExpiry(config.jwt.refreshExpiry);
  const expiresAt = new Date(Date.now() + expiresIn * 1000);

  const token = await new jose.SignJWT({
    sub: payload.userId,
    sid: payload.sessionId,
    did: payload.deviceId,
    fam: payload.familyId,
    jti,
  })
    .setProtectedHeader({ alg: 'HS256', typ: 'JWT' })
    .setIssuedAt()
    .setExpirationTime(expiresAt)
    .setIssuer('mileagemax-pro')
    .setAudience('mileagemax-pro-ios')
    .sign(refreshSecret);

  return { token, expiresAt };
}

export async function verifyAccessToken(token: string): Promise<TokenPayload> {
  try {
    const { payload } = await jose.jwtVerify(token, accessSecret, {
      issuer: 'mileagemax-pro',
      audience: 'mileagemax-pro-ios',
    });

    return {
      sub: payload.sub as string,
      email: payload.email as string,
      tier: payload.tier as TokenPayload['tier'],
      iat: payload.iat as number,
      exp: payload.exp as number,
      jti: payload.jti as string,
    };
  } catch (error) {
    if (error instanceof jose.errors.JWTExpired) {
      throw new TokenExpiredError('access');
    }
    throw new InvalidTokenError('Invalid access token');
  }
}

export async function verifyRefreshToken(token: string): Promise<RefreshTokenPayload> {
  try {
    const { payload } = await jose.jwtVerify(token, refreshSecret, {
      issuer: 'mileagemax-pro',
      audience: 'mileagemax-pro-ios',
    });

    return {
      sub: payload.sub as string,
      sid: payload.sid as string,
      did: payload.did as string,
      fam: payload.fam as string,
      iat: payload.iat as number,
      exp: payload.exp as number,
      jti: payload.jti as string,
    };
  } catch (error) {
    if (error instanceof jose.errors.JWTExpired) {
      throw new TokenExpiredError('refresh');
    }
    throw new InvalidTokenError('Invalid refresh token');
  }
}

export async function decodeToken(token: string): Promise<jose.JWTPayload | null> {
  try {
    return jose.decodeJwt(token);
  } catch {
    return null;
  }
}
