import { z } from 'zod';
import dotenv from 'dotenv';

dotenv.config();

const envSchema = z.object({
  // Server
  NODE_ENV: z.enum(['development', 'staging', 'production']).default('development'),
  PORT: z.string().transform(Number).default('3000'),
  API_VERSION: z.string().default('v1'),
  CORS_ORIGINS: z.string().default('http://localhost:3000'),

  // Database
  DATABASE_URL: z.string().url(),

  // Redis
  REDIS_URL: z.string().url(),

  // JWT
  JWT_ACCESS_SECRET: z.string().min(32),
  JWT_REFRESH_SECRET: z.string().min(32),
  JWT_ACCESS_EXPIRY: z.string().default('15m'),
  JWT_REFRESH_EXPIRY: z.string().default('30d'),

  // Apple Sign In
  APPLE_TEAM_ID: z.string().min(1),
  APPLE_KEY_ID: z.string().min(1),
  APPLE_BUNDLE_ID: z.string().min(1),
  APPLE_PRIVATE_KEY: z.string().min(1),

  // Google OAuth
  GOOGLE_CLIENT_ID: z.string().min(1),
  GOOGLE_CLIENT_SECRET: z.string().optional(),

  // Stripe
  STRIPE_SECRET_KEY: z.string().min(1),
  STRIPE_WEBHOOK_SECRET: z.string().min(1),
  STRIPE_PRICE_PRO_MONTHLY: z.string().optional(),
  STRIPE_PRICE_PRO_YEARLY: z.string().optional(),
  STRIPE_PRICE_BUSINESS_MONTHLY: z.string().optional(),
  STRIPE_PRICE_BUSINESS_YEARLY: z.string().optional(),

  // SendGrid
  SENDGRID_API_KEY: z.string().optional(),
  SENDGRID_FROM_EMAIL: z.string().email().optional(),
  SENDGRID_FROM_NAME: z.string().optional(),

  // External APIs
  OPENWEATHER_API_KEY: z.string().optional(),
  GASBUDDY_API_KEY: z.string().optional(),

  // MapKit
  MAPKIT_TEAM_ID: z.string().optional(),
  MAPKIT_KEY_ID: z.string().optional(),
  MAPKIT_PRIVATE_KEY: z.string().optional(),

  // S3/Storage
  S3_BUCKET: z.string().optional(),
  S3_REGION: z.string().optional(),
  S3_ACCESS_KEY_ID: z.string().optional(),
  S3_SECRET_ACCESS_KEY: z.string().optional(),
  S3_ENDPOINT: z.string().optional(),

  // Encryption
  ENCRYPTION_KEY: z.string().length(64).optional(),

  // Sentry
  SENTRY_DSN: z.string().optional(),

  // Rate Limiting
  RATE_LIMIT_WINDOW_MS: z.string().transform(Number).default('60000'),
  RATE_LIMIT_MAX_REQUESTS: z.string().transform(Number).default('100'),
});

function validateEnv() {
  const parsed = envSchema.safeParse(process.env);

  if (!parsed.success) {
    console.error('Environment validation failed:');
    for (const issue of parsed.error.issues) {
      console.error(`  ${issue.path.join('.')}: ${issue.message}`);
    }
    process.exit(1);
  }

  return parsed.data;
}

export const env = validateEnv();

/**
 * Normalize PEM private key from various env var formats:
 * - Literal \n characters (common in env vars)
 * - Base64 encoded (alternative for problematic environments)
 * - Already properly formatted with real newlines
 */
function normalizePrivateKey(key: string): string {
  // If it looks base64 encoded (no spaces, dashes, or newlines), decode it
  if (!key.includes('-') && !key.includes(' ') && !key.includes('\n')) {
    try {
      const decoded = Buffer.from(key, 'base64').toString('utf-8');
      if (decoded.includes('-----BEGIN')) {
        console.log('Apple private key decoded from base64');
        return decoded;
      }
    } catch {
      // Not base64, continue with other methods
    }
  }

  // Replace literal \n with actual newlines
  let normalized = key.replace(/\\n/g, '\n');

  // Handle double-escaped newlines (\\n -> \n)
  normalized = normalized.replace(/\\\\n/g, '\n');

  // Ensure proper PEM format with newlines after header and before footer
  if (normalized.includes('-----BEGIN') && !normalized.includes('\n-----BEGIN')) {
    normalized = normalized
      .replace(/-----BEGIN PRIVATE KEY-----/, '-----BEGIN PRIVATE KEY-----\n')
      .replace(/-----END PRIVATE KEY-----/, '\n-----END PRIVATE KEY-----');
  }

  // Remove any carriage returns
  normalized = normalized.replace(/\r/g, '');

  // Validate the key looks correct
  if (!normalized.includes('-----BEGIN PRIVATE KEY-----')) {
    console.error('Apple private key appears malformed - missing BEGIN header');
  }

  return normalized;
}

export const config = {
  server: {
    env: env.NODE_ENV,
    port: env.PORT,
    apiVersion: env.API_VERSION,
    corsOrigins: env.CORS_ORIGINS.split(',').map(o => o.trim()),
    isProduction: env.NODE_ENV === 'production',
    isDevelopment: env.NODE_ENV === 'development',
  },
  database: {
    url: env.DATABASE_URL,
  },
  redis: {
    url: env.REDIS_URL,
  },
  jwt: {
    accessSecret: env.JWT_ACCESS_SECRET,
    refreshSecret: env.JWT_REFRESH_SECRET,
    accessExpiry: env.JWT_ACCESS_EXPIRY,
    refreshExpiry: env.JWT_REFRESH_EXPIRY,
  },
  apple: {
    teamId: env.APPLE_TEAM_ID,
    keyId: env.APPLE_KEY_ID,
    bundleId: env.APPLE_BUNDLE_ID,
    privateKey: normalizePrivateKey(env.APPLE_PRIVATE_KEY),
  },
  google: {
    clientId: env.GOOGLE_CLIENT_ID,
    clientSecret: env.GOOGLE_CLIENT_SECRET,
  },
  stripe: {
    secretKey: env.STRIPE_SECRET_KEY,
    webhookSecret: env.STRIPE_WEBHOOK_SECRET,
    prices: {
      proMonthly: env.STRIPE_PRICE_PRO_MONTHLY,
      proYearly: env.STRIPE_PRICE_PRO_YEARLY,
      businessMonthly: env.STRIPE_PRICE_BUSINESS_MONTHLY,
      businessYearly: env.STRIPE_PRICE_BUSINESS_YEARLY,
    },
  },
  sendgrid: {
    apiKey: env.SENDGRID_API_KEY,
    fromEmail: env.SENDGRID_FROM_EMAIL,
    fromName: env.SENDGRID_FROM_NAME,
  },
  externalApis: {
    openWeatherApiKey: env.OPENWEATHER_API_KEY,
    gasBuddyApiKey: env.GASBUDDY_API_KEY,
  },
  mapkit: {
    teamId: env.MAPKIT_TEAM_ID,
    keyId: env.MAPKIT_KEY_ID,
    privateKey: env.MAPKIT_PRIVATE_KEY ? normalizePrivateKey(env.MAPKIT_PRIVATE_KEY) : undefined,
  },
  s3: {
    bucket: env.S3_BUCKET,
    region: env.S3_REGION,
    accessKeyId: env.S3_ACCESS_KEY_ID,
    secretAccessKey: env.S3_SECRET_ACCESS_KEY,
    endpoint: env.S3_ENDPOINT,
  },
  encryption: {
    key: env.ENCRYPTION_KEY,
  },
  sentry: {
    dsn: env.SENTRY_DSN,
  },
  rateLimit: {
    windowMs: env.RATE_LIMIT_WINDOW_MS,
    maxRequests: env.RATE_LIMIT_MAX_REQUESTS,
  },
} as const;
