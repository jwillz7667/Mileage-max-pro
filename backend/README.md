# MileageMax Pro Backend API

Enterprise-grade backend API for the MileageMax Pro iOS application.

## Technology Stack

- **Runtime**: Node.js 22.x LTS
- **Framework**: Express.js 5.x
- **Language**: TypeScript 5.7
- **Database**: PostgreSQL 16 with PostGIS 3.4
- **Cache/Queue**: Redis 7.x
- **ORM**: Prisma 6.x
- **Authentication**: Apple Sign In, Google OAuth, JWT
- **Background Jobs**: BullMQ

## Prerequisites

- Node.js 22+
- PostgreSQL 16+ with PostGIS extension
- Redis 7+

## Setup

1. **Clone and install dependencies**:
   ```bash
   npm install
   ```

2. **Configure environment variables**:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Generate Prisma client**:
   ```bash
   npm run db:generate
   ```

4. **Run database migrations**:
   ```bash
   npm run db:migrate:dev
   ```

5. **Start development server**:
   ```bash
   npm run dev
   ```

## Development Commands

| Command | Description |
|---------|-------------|
| `npm run dev` | Start development server with hot reload |
| `npm run build` | Build for production |
| `npm run start:prod` | Start production server |
| `npm run worker` | Start background job worker |
| `npm run db:generate` | Generate Prisma client |
| `npm run db:migrate:dev` | Create and apply migrations |
| `npm run db:migrate` | Apply pending migrations |
| `npm run db:studio` | Open Prisma Studio |
| `npm run test` | Run tests |
| `npm run lint` | Run linter |

## API Endpoints

### Authentication
- `POST /api/v1/auth/apple` - Sign in with Apple
- `POST /api/v1/auth/google` - Sign in with Google
- `POST /api/v1/auth/refresh` - Refresh access token
- `POST /api/v1/auth/logout` - Logout
- `GET /api/v1/auth/sessions` - List active sessions
- `GET /api/v1/auth/me` - Get current user profile

### Trips
- `POST /api/v1/trips` - Create trip
- `GET /api/v1/trips` - List trips
- `GET /api/v1/trips/:id` - Get trip details
- `PATCH /api/v1/trips/:id` - Update trip
- `POST /api/v1/trips/:id/waypoints` - Add waypoints
- `POST /api/v1/trips/:id/complete` - Complete trip
- `DELETE /api/v1/trips/:id` - Delete trip

### Vehicles
- `POST /api/v1/vehicles` - Create vehicle
- `GET /api/v1/vehicles` - List vehicles
- `GET /api/v1/vehicles/:id` - Get vehicle details
- `PATCH /api/v1/vehicles/:id` - Update vehicle
- `DELETE /api/v1/vehicles/:id` - Delete vehicle
- `POST /api/v1/vehicles/:id/maintenance` - Add maintenance record
- `GET /api/v1/vehicles/:id/stats` - Get vehicle statistics

### Routes
- `POST /api/v1/routes` - Create delivery route
- `GET /api/v1/routes` - List routes
- `GET /api/v1/routes/:id` - Get route details
- `PATCH /api/v1/routes/:id` - Update route
- `DELETE /api/v1/routes/:id` - Delete route
- `POST /api/v1/routes/:id/optimize` - Optimize route
- `POST /api/v1/routes/:id/start` - Start route
- `POST /api/v1/routes/:id/complete` - Complete route
- `PATCH /api/v1/routes/:id/stops/:stopId` - Update stop

### Expenses
- `POST /api/v1/expenses` - Create expense
- `GET /api/v1/expenses` - List expenses
- `GET /api/v1/expenses/:id` - Get expense details
- `PATCH /api/v1/expenses/:id` - Update expense
- `DELETE /api/v1/expenses/:id` - Delete expense
- `POST /api/v1/expenses/fuel` - Create fuel purchase

### Analytics
- `GET /api/v1/analytics/dashboard` - Get dashboard data
- `GET /api/v1/analytics/tax-summary` - Get tax summary

## Deployment

### Railway

1. Create a new project on Railway
2. Add PostgreSQL and Redis services
3. Connect your GitHub repository
4. Set environment variables in Railway dashboard
5. Deploy

The `railway.json` configuration handles build and deployment automatically.

### Docker

```bash
docker-compose up -d
```

## Security Features

- JWT-based authentication with token rotation
- Rate limiting per user/IP
- Input validation with Zod
- SQL injection prevention via Prisma
- Helmet security headers
- CORS configuration
- Encrypted token storage

## License

Proprietary - MileageMax Pro
