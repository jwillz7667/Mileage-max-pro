import { PrismaClient } from '@prisma/client';
import { config } from './env.js';

declare global {
  // eslint-disable-next-line no-var
  var prisma: PrismaClient | undefined;
}

export const prisma = globalThis.prisma ?? new PrismaClient({
  log: config.server.isDevelopment
    ? [{ emit: 'stdout', level: 'query' }, { emit: 'stdout', level: 'error' }, { emit: 'stdout', level: 'warn' }]
    : [{ emit: 'stdout', level: 'error' }],
});

if (config.server.isDevelopment) {
  globalThis.prisma = prisma;
}

export async function connectDatabase(): Promise<void> {
  const maxRetries = 5;
  const retryDelay = 3000;

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      console.log(`Attempting database connection (${attempt}/${maxRetries})...`);
      await prisma.$connect();
      console.log('Database connected successfully');
      return;
    } catch (error) {
      console.error(`Database connection attempt ${attempt} failed:`, error);
      if (attempt < maxRetries) {
        console.log(`Retrying in ${retryDelay}ms...`);
        await new Promise(resolve => setTimeout(resolve, retryDelay));
      }
    }
  }
  console.error('All database connection attempts failed. Continuing without database...');
}

export async function disconnectDatabase(): Promise<void> {
  await prisma.$disconnect();
  console.log('Database disconnected');
}

// Graceful shutdown
process.on('beforeExit', async () => {
  await disconnectDatabase();
});
