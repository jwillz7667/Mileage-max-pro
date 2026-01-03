import * as jose from 'jose';
import { config } from '../config/env.js';
import { logger } from '../utils/logger.js';
import { UnauthorizedError, InternalError } from '../utils/errors.js';

interface GooglePublicKey {
  kid: string;
  alg: string;
  use: string;
  n: string;
  e: string;
  kty: string;
}

interface GoogleKeysResponse {
  keys: GooglePublicKey[];
}

interface GoogleTokenPayload {
  iss: string;
  azp: string;
  aud: string;
  sub: string;
  email: string;
  email_verified: boolean;
  at_hash?: string;
  name?: string;
  picture?: string;
  given_name?: string;
  family_name?: string;
  locale?: string;
  iat: number;
  exp: number;
}

// Cache for Google's public keys
let cachedGoogleKeys: GoogleKeysResponse | null = null;
let keysLastFetched = 0;
const KEYS_CACHE_TTL = 86400000; // 24 hours

async function fetchGooglePublicKeys(): Promise<GoogleKeysResponse> {
  const now = Date.now();

  if (cachedGoogleKeys && now - keysLastFetched < KEYS_CACHE_TTL) {
    return cachedGoogleKeys;
  }

  try {
    const response = await fetch('https://www.googleapis.com/oauth2/v3/certs');

    if (!response.ok) {
      throw new Error(`Failed to fetch Google keys: ${response.status}`);
    }

    cachedGoogleKeys = await response.json() as GoogleKeysResponse;
    keysLastFetched = now;

    logger.info('Google public keys fetched successfully');
    return cachedGoogleKeys;
  } catch (error) {
    logger.error('Failed to fetch Google public keys', { error });
    throw new InternalError('Failed to verify Google credentials');
  }
}

export async function verifyGoogleIdToken(idToken: string): Promise<{
  userId: string;
  email: string;
  emailVerified: boolean;
  name?: string;
  picture?: string;
  givenName?: string;
  familyName?: string;
}> {
  try {
    // Decode the header to get the key ID
    const header = jose.decodeProtectedHeader(idToken);
    const kid = header.kid;

    if (!kid) {
      throw new UnauthorizedError('Invalid Google ID token: missing key ID');
    }

    // Fetch Google's public keys
    const keysResponse = await fetchGooglePublicKeys();
    let googleKey = keysResponse.keys.find((k) => k.kid === kid);

    if (!googleKey) {
      // Invalidate cache and retry once
      cachedGoogleKeys = null;
      const refreshedKeys = await fetchGooglePublicKeys();
      googleKey = refreshedKeys.keys.find((k) => k.kid === kid);

      if (!googleKey) {
        throw new UnauthorizedError('Invalid Google ID token: unknown key');
      }
    }

    // Import the public key
    const publicKey = await jose.importJWK(googleKey as jose.JWK, googleKey.alg);

    // Verify the token
    const { payload } = await jose.jwtVerify(idToken, publicKey, {
      issuer: ['https://accounts.google.com', 'accounts.google.com'],
      audience: config.google.clientId,
    }) as { payload: GoogleTokenPayload };

    // Validate the token hasn't expired (extra check)
    const now = Math.floor(Date.now() / 1000);
    if (payload.exp < now) {
      throw new UnauthorizedError('Google ID token has expired');
    }

    return {
      userId: payload.sub,
      email: payload.email,
      emailVerified: payload.email_verified,
      name: payload.name,
      picture: payload.picture,
      givenName: payload.given_name,
      familyName: payload.family_name,
    };
  } catch (error) {
    if (error instanceof jose.errors.JWTExpired) {
      throw new UnauthorizedError('Google ID token has expired');
    }
    if (error instanceof jose.errors.JWTClaimValidationFailed) {
      throw new UnauthorizedError('Invalid Google ID token claims');
    }
    if (error instanceof UnauthorizedError) {
      throw error;
    }

    logger.error('Google token verification failed', { error });
    throw new UnauthorizedError('Failed to verify Google ID token');
  }
}

export async function verifyGoogleAccessToken(accessToken: string): Promise<{
  userId: string;
  email: string;
  emailVerified: boolean;
  scope: string;
  expiresIn: number;
}> {
  try {
    const response = await fetch(
      `https://oauth2.googleapis.com/tokeninfo?access_token=${accessToken}`
    );

    if (!response.ok) {
      throw new UnauthorizedError('Invalid Google access token');
    }

    const data = await response.json() as {
      sub: string;
      email: string;
      email_verified: string;
      scope: string;
      expires_in: string;
      azp: string;
      aud: string;
    };

    // Verify the client ID matches
    if (data.aud !== config.google.clientId && data.azp !== config.google.clientId) {
      throw new UnauthorizedError('Google access token was not issued for this application');
    }

    return {
      userId: data.sub,
      email: data.email,
      emailVerified: data.email_verified === 'true',
      scope: data.scope,
      expiresIn: parseInt(data.expires_in, 10),
    };
  } catch (error) {
    if (error instanceof UnauthorizedError) {
      throw error;
    }
    logger.error('Google access token verification failed', { error });
    throw new UnauthorizedError('Failed to verify Google access token');
  }
}

export async function getGoogleUserInfo(accessToken: string): Promise<{
  id: string;
  email: string;
  verifiedEmail: boolean;
  name?: string;
  givenName?: string;
  familyName?: string;
  picture?: string;
  locale?: string;
}> {
  try {
    const response = await fetch('https://www.googleapis.com/oauth2/v2/userinfo', {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    });

    if (!response.ok) {
      throw new UnauthorizedError('Failed to fetch Google user info');
    }

    const data = await response.json() as {
      id: string;
      email: string;
      verified_email: boolean;
      name?: string;
      given_name?: string;
      family_name?: string;
      picture?: string;
      locale?: string;
    };

    return {
      id: data.id,
      email: data.email,
      verifiedEmail: data.verified_email,
      name: data.name,
      givenName: data.given_name,
      familyName: data.family_name,
      picture: data.picture,
      locale: data.locale,
    };
  } catch (error) {
    if (error instanceof UnauthorizedError) {
      throw error;
    }
    logger.error('Failed to get Google user info', { error });
    throw new UnauthorizedError('Failed to fetch Google user info');
  }
}

export async function revokeGoogleToken(token: string): Promise<void> {
  try {
    const response = await fetch(`https://oauth2.googleapis.com/revoke?token=${token}`, {
      method: 'POST',
    });

    if (!response.ok) {
      logger.warn('Failed to revoke Google token', { status: response.status });
    }
  } catch (error) {
    logger.error('Error revoking Google token', { error });
  }
}
