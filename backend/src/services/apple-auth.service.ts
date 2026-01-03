import * as jose from 'jose';
import { config } from '../config/env.js';
import { logger } from '../utils/logger.js';
import { UnauthorizedError, InternalError } from '../utils/errors.js';

interface ApplePublicKey {
  kty: string;
  kid: string;
  use: string;
  alg: string;
  n: string;
  e: string;
}

interface AppleKeysResponse {
  keys: ApplePublicKey[];
}

interface AppleTokenPayload {
  iss: string;
  aud: string;
  exp: number;
  iat: number;
  sub: string;
  at_hash?: string;
  email?: string;
  email_verified?: string | boolean;
  is_private_email?: string | boolean;
  auth_time?: number;
  nonce_supported?: boolean;
}

// Cache for Apple's public keys
let cachedAppleKeys: AppleKeysResponse | null = null;
let keysLastFetched = 0;
const KEYS_CACHE_TTL = 86400000; // 24 hours

async function fetchApplePublicKeys(): Promise<AppleKeysResponse> {
  const now = Date.now();

  if (cachedAppleKeys && now - keysLastFetched < KEYS_CACHE_TTL) {
    return cachedAppleKeys;
  }

  try {
    const response = await fetch('https://appleid.apple.com/auth/keys');

    if (!response.ok) {
      throw new Error(`Failed to fetch Apple keys: ${response.status}`);
    }

    cachedAppleKeys = await response.json() as AppleKeysResponse;
    keysLastFetched = now;

    logger.info('Apple public keys fetched successfully');
    return cachedAppleKeys;
  } catch (error) {
    logger.error('Failed to fetch Apple public keys', { error });
    throw new InternalError('Failed to verify Apple credentials');
  }
}

export async function verifyAppleIdentityToken(identityToken: string): Promise<{
  userId: string;
  email?: string;
  emailVerified: boolean;
  isPrivateEmail: boolean;
}> {
  try {
    // Decode the header to get the key ID
    const header = jose.decodeProtectedHeader(identityToken);
    const kid = header.kid;

    if (!kid) {
      throw new UnauthorizedError('Invalid Apple identity token: missing key ID');
    }

    // Fetch Apple's public keys
    const keysResponse = await fetchApplePublicKeys();
    const appleKey = keysResponse.keys.find((k) => k.kid === kid);

    if (!appleKey) {
      // Invalidate cache and retry once
      cachedAppleKeys = null;
      const refreshedKeys = await fetchApplePublicKeys();
      const retryKey = refreshedKeys.keys.find((k) => k.kid === kid);

      if (!retryKey) {
        throw new UnauthorizedError('Invalid Apple identity token: unknown key');
      }
    }

    const keyToUse = appleKey ?? (await fetchApplePublicKeys()).keys.find((k) => k.kid === kid)!;

    // Import the public key
    const publicKey = await jose.importJWK(keyToUse as jose.JWK, keyToUse.alg);

    // Verify the token
    const { payload } = await jose.jwtVerify(identityToken, publicKey, {
      issuer: 'https://appleid.apple.com',
      audience: config.apple.bundleId,
    }) as { payload: AppleTokenPayload };

    // Validate the token hasn't expired (extra check)
    const now = Math.floor(Date.now() / 1000);
    if (payload.exp < now) {
      throw new UnauthorizedError('Apple identity token has expired');
    }

    return {
      userId: payload.sub,
      email: payload.email,
      emailVerified: payload.email_verified === 'true' || payload.email_verified === true,
      isPrivateEmail: payload.is_private_email === 'true' || payload.is_private_email === true,
    };
  } catch (error) {
    if (error instanceof jose.errors.JWTExpired) {
      throw new UnauthorizedError('Apple identity token has expired');
    }
    if (error instanceof jose.errors.JWTClaimValidationFailed) {
      throw new UnauthorizedError('Invalid Apple identity token claims');
    }
    if (error instanceof UnauthorizedError) {
      throw error;
    }

    logger.error('Apple token verification failed', { error });
    throw new UnauthorizedError('Failed to verify Apple identity token');
  }
}

export async function generateAppleClientSecret(): Promise<string> {
  const privateKey = await jose.importPKCS8(config.apple.privateKey, 'ES256');

  const now = Math.floor(Date.now() / 1000);
  const expirationTime = now + 15777000; // 6 months

  const clientSecret = await new jose.SignJWT({})
    .setProtectedHeader({ alg: 'ES256', kid: config.apple.keyId })
    .setIssuer(config.apple.teamId)
    .setIssuedAt(now)
    .setExpirationTime(expirationTime)
    .setAudience('https://appleid.apple.com')
    .setSubject(config.apple.bundleId)
    .sign(privateKey);

  return clientSecret;
}

export async function validateAppleAuthorizationCode(
  authorizationCode: string
): Promise<{
  accessToken: string;
  refreshToken: string;
  idToken: string;
  expiresIn: number;
}> {
  const clientSecret = await generateAppleClientSecret();

  const params = new URLSearchParams({
    client_id: config.apple.bundleId,
    client_secret: clientSecret,
    code: authorizationCode,
    grant_type: 'authorization_code',
  });

  try {
    const response = await fetch('https://appleid.apple.com/auth/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: params.toString(),
    });

    if (!response.ok) {
      const errorBody = await response.text();
      logger.error('Apple token exchange failed', { status: response.status, body: errorBody });
      throw new UnauthorizedError('Failed to exchange Apple authorization code');
    }

    const data = await response.json() as {
      access_token: string;
      refresh_token: string;
      id_token: string;
      expires_in: number;
    };

    return {
      accessToken: data.access_token,
      refreshToken: data.refresh_token,
      idToken: data.id_token,
      expiresIn: data.expires_in,
    };
  } catch (error) {
    if (error instanceof UnauthorizedError) {
      throw error;
    }
    logger.error('Apple authorization code validation failed', { error });
    throw new UnauthorizedError('Failed to validate Apple authorization');
  }
}

export async function revokeAppleTokens(refreshToken: string): Promise<void> {
  const clientSecret = await generateAppleClientSecret();

  const params = new URLSearchParams({
    client_id: config.apple.bundleId,
    client_secret: clientSecret,
    token: refreshToken,
    token_type_hint: 'refresh_token',
  });

  try {
    const response = await fetch('https://appleid.apple.com/auth/revoke', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: params.toString(),
    });

    if (!response.ok) {
      logger.warn('Failed to revoke Apple token', { status: response.status });
    }
  } catch (error) {
    logger.error('Error revoking Apple token', { error });
  }
}
