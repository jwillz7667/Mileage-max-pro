import Redis from 'ioredis';
import { config } from './env.js';

export const redis = new Redis(config.redis.url, {
  maxRetriesPerRequest: 3,
  retryStrategy: (times: number) => {
    if (times > 10) {
      console.error('Redis connection failed after 10 retries');
      return null;
    }
    return Math.min(times * 200, 5000);
  },
  reconnectOnError: (err) => {
    const targetError = 'READONLY';
    if (err.message.includes(targetError)) {
      return true;
    }
    return false;
  },
});

redis.on('connect', () => {
  console.log('Redis connected successfully');
});

redis.on('error', (error) => {
  console.error('Redis connection error:', error);
});

redis.on('close', () => {
  console.log('Redis connection closed');
});

export async function connectRedis(): Promise<void> {
  if (redis.status === 'ready') {
    return;
  }

  return new Promise((resolve) => {
    const timeout = setTimeout(() => {
      console.warn('Redis connection timeout - continuing without Redis');
      resolve();
    }, 10000);

    redis.once('ready', () => {
      clearTimeout(timeout);
      resolve();
    });

    redis.once('error', (error) => {
      clearTimeout(timeout);
      console.warn('Redis connection failed - continuing without Redis:', error);
      resolve();
    });
  });
}

export async function disconnectRedis(): Promise<void> {
  await redis.quit();
  console.log('Redis disconnected');
}

// Cache utilities
export const cache = {
  async get<T>(key: string): Promise<T | null> {
    const value = await redis.get(key);
    if (!value) return null;
    try {
      return JSON.parse(value) as T;
    } catch {
      return value as unknown as T;
    }
  },

  async set(key: string, value: unknown, ttlSeconds?: number): Promise<void> {
    const serialized = typeof value === 'string' ? value : JSON.stringify(value);
    if (ttlSeconds) {
      await redis.setex(key, ttlSeconds, serialized);
    } else {
      await redis.set(key, serialized);
    }
  },

  async del(key: string): Promise<void> {
    await redis.del(key);
  },

  async delPattern(pattern: string): Promise<void> {
    const keys = await redis.keys(pattern);
    if (keys.length > 0) {
      await redis.del(...keys);
    }
  },

  async exists(key: string): Promise<boolean> {
    return (await redis.exists(key)) === 1;
  },

  async incr(key: string): Promise<number> {
    return redis.incr(key);
  },

  async expire(key: string, seconds: number): Promise<void> {
    await redis.expire(key, seconds);
  },
};

// Rate limiting utilities
export const rateLimit = {
  async check(key: string, limit: number, windowSeconds: number): Promise<{
    allowed: boolean;
    remaining: number;
    resetAt: number;
  }> {
    const now = Date.now();
    const windowStart = now - (windowSeconds * 1000);
    const redisKey = `ratelimit:${key}`;

    // Remove old entries
    await redis.zremrangebyscore(redisKey, 0, windowStart);

    // Count current entries
    const count = await redis.zcard(redisKey);

    if (count >= limit) {
      const oldestEntry = await redis.zrange(redisKey, 0, 0, 'WITHSCORES');
      const resetAt = oldestEntry[1] ? parseInt(oldestEntry[1], 10) + (windowSeconds * 1000) : now + (windowSeconds * 1000);

      return {
        allowed: false,
        remaining: 0,
        resetAt,
      };
    }

    // Add new entry
    await redis.zadd(redisKey, now, `${now}-${Math.random()}`);
    await redis.expire(redisKey, windowSeconds);

    return {
      allowed: true,
      remaining: limit - count - 1,
      resetAt: now + (windowSeconds * 1000),
    };
  },
};

// Session store
export const sessionStore = {
  async create(sessionId: string, data: Record<string, unknown>, ttlSeconds: number): Promise<void> {
    await cache.set(`session:${sessionId}`, data, ttlSeconds);
  },

  async get<T extends Record<string, unknown>>(sessionId: string): Promise<T | null> {
    return cache.get<T>(`session:${sessionId}`);
  },

  async update(sessionId: string, data: Record<string, unknown>, ttlSeconds?: number): Promise<void> {
    const key = `session:${sessionId}`;
    if (ttlSeconds) {
      await cache.set(key, data, ttlSeconds);
    } else {
      await cache.set(key, data);
    }
  },

  async destroy(sessionId: string): Promise<void> {
    await cache.del(`session:${sessionId}`);
  },

  async destroyUserSessions(userId: string): Promise<void> {
    await cache.delPattern(`session:*:${userId}`);
  },
};
