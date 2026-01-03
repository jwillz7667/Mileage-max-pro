import { PrismaClient } from '@prisma/client';
import { config } from './env.js';

declare global {
  // eslint-disable-next-line no-var
  var prisma: PrismaClient | undefined;
}

const prismaClientOptions = {
  log: config.server.isDevelopment
    ? ['query', 'error', 'warn'] as const
    : ['error'] as const,
};

export const prisma = globalThis.prisma ?? new PrismaClient(prismaClientOptions);

if (config.server.isDevelopment) {
  globalThis.prisma = prisma;
}

export async function connectDatabase(): Promise<void> {
  try {
    await prisma.$connect();
    console.log('Database connected successfully');
  } catch (error) {
    console.error('Failed to connect to database:', error);
    process.exit(1);
  }
}

export async function disconnectDatabase(): Promise<void> {
  await prisma.$disconnect();
  console.log('Database disconnected');
}

// Graceful shutdown
process.on('beforeExit', async () => {
  await disconnectDatabase();
});
