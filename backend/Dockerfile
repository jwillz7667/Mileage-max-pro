# Build stage
FROM node:22-alpine AS builder

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci

# Copy source code
COPY . .

# Generate Prisma client and build
RUN npm run db:generate
RUN npm run build

# Production stage
FROM node:22-alpine AS production

# Create non-root user first
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001 -G nodejs

WORKDIR /app

# Install production dependencies only
COPY --chown=nodejs:nodejs package*.json ./
RUN npm ci --only=production

# Copy Prisma schema and generated client
COPY --chown=nodejs:nodejs --from=builder /app/prisma ./prisma
COPY --chown=nodejs:nodejs --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --chown=nodejs:nodejs --from=builder /app/node_modules/@prisma ./node_modules/@prisma

# Copy built application
COPY --chown=nodejs:nodejs --from=builder /app/dist ./dist

# Set proper ownership of node_modules
RUN chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# Start command
CMD ["npm", "run", "start:prod"]
