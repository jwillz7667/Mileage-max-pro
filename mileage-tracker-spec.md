# MileageMax Pro
## Enterprise iOS Mileage Tracking & Delivery Driver Assistance Application
### Complete Technical Specification Document v1.0


## Document Purpose & AI Assistant Instructions

This document serves as the authoritative technical specification for MileageMax Pro. It functions both as a product requirements document and as directive instructions for AI coding assistants generating the codebase.

### Critical Development Directives

**Code Quality Standards:**
- All generated code must meet Fortune 500 enterprise production standards
- Zero tolerance for placeholder implementations, TODO comments, or mock data structures
- Every function must be fully implemented with proper error handling, logging, and edge case management
- Before writing any component, mentally visualize the complete user flow from app launch through feature completion
- Code must be immediately deployable without modification

**Visualization Requirement:**
Before implementing any feature, construct a complete mental model of:
- The user's journey through the feature
- All possible states (loading, success, error, empty, offline)
- Data flow from UI gesture through network layer to database and back
- Animation choreography and timing relationships
- Accessibility considerations for each interaction

---

## 1. Executive Summary

### 1.1 Product Vision

MileageMax Pro is a premium iOS application designed for delivery drivers, rideshare operators, field service professionals, and any mobile workforce requiring precise mileage documentation and route optimization. The application automatically tracks vehicle trips using advanced GPS technology, categorizes business versus personal mileage, optimizes multi-stop delivery routes, and generates IRS-compliant documentation for tax deduction purposes.

### 1.2 Target Audience

| Segment | Description | Key Needs |
|---------|-------------|-----------|
| Gig Economy Drivers | DoorDash, Uber Eats, Instacart, Amazon Flex contractors | Automatic tracking, earnings correlation, tax reports |
| Rideshare Operators | Uber, Lyft drivers | Trip classification, passenger fare tracking, expense management |
| Field Service Technicians | HVAC, plumbing, electrical service providers | Customer visit logging, route optimization, mileage reimbursement |
| Sales Representatives | Traveling sales professionals | Client visit documentation, expense reporting, CRM integration |
| Medical/Home Healthcare | Nurses, therapists providing in-home care | Patient visit tracking, HIPAA-compliant notes, mileage reimbursement |

### 1.3 Competitive Differentiators

- Fully automatic trip detection with zero manual intervention required
- Sub-meter GPS accuracy using Apple CoreLocation sensor fusion
- Real-time multi-stop route optimization with traffic prediction
- Native iOS 26.1 Liquid Glass design language throughout
- Offline-first architecture with seamless background synchronization
- Enterprise-grade security with end-to-end encryption
- IRS audit-ready documentation with digital signatures

---

## 2. Technical Architecture Overview

### 2.1 System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CLIENT LAYER                                    │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    iOS 26.1 Application                              │   │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌─────────────┐ │   │
│  │  │   SwiftUI    │ │  Core Data   │ │ CoreLocation │ │   MapKit    │ │   │
│  │  │   Views      │ │   + Swift    │ │   Manager    │ │  Integration│ │   │
│  │  │              │ │    Data      │ │              │ │             │ │   │
│  │  └──────────────┘ └──────────────┘ └──────────────┘ └─────────────┘ │   │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌─────────────┐ │   │
│  │  │  Background  │ │   Network    │ │  Keychain    │ │ActivityKit/ │ │   │
│  │  │    Tasks     │ │    Layer     │ │   Service    │ │Dynamic Isle │ │   │
│  │  └──────────────┘ └──────────────┘ └──────────────┘ └─────────────┘ │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ HTTPS/WSS
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           RAILWAY INFRASTRUCTURE                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         API Gateway Layer                            │   │
│  │              Node.js 22.x LTS + Express 5.x + Helmet                │   │
│  │                    Rate Limiting + Request Validation                │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                      │                                       │
│         ┌────────────────────────────┼────────────────────────────┐         │
│         ▼                            ▼                            ▼         │
│  ┌─────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐ │
│  │  Auth Service   │    │    Core API Service │    │  Background Workers │ │
│  │  OAuth 2.0/OIDC │    │    Business Logic   │    │   Bull MQ + Redis   │ │
│  │  JWT Management │    │    Trip Processing  │    │   Report Generation │ │
│  └─────────────────┘    └─────────────────────┘    └─────────────────────┘ │
│         │                            │                            │         │
│         └────────────────────────────┼────────────────────────────┘         │
│                                      ▼                                       │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        Data Layer                                    │   │
│  │  ┌──────────────────┐  ┌────────────────┐  ┌─────────────────────┐  │   │
│  │  │  PostgreSQL 16   │  │   Redis 7.x    │  │  Railway Object     │  │   │
│  │  │  Primary DB      │  │   Cache/Queue  │  │  Storage (S3-compat)│  │   │
│  │  │  + PostGIS 3.4   │  │   Sessions     │  │  Report PDFs        │  │   │
│  │  └──────────────────┘  └────────────────┘  └─────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         EXTERNAL SERVICES                                    │
│  ┌────────────────┐ ┌────────────────┐ ┌────────────────┐ ┌──────────────┐  │
│  │  Apple Sign In │ │  Google OAuth  │ │  MapKit Server │ │   Stripe     │  │
│  │     OIDC       │ │    2.0         │ │     API        │ │   Payments   │  │
│  └────────────────┘ └────────────────┘ └────────────────┘ └──────────────┘  │
│  ┌────────────────┐ ┌────────────────┐ ┌────────────────┐ ┌──────────────┐  │
│  │  Weather API   │ │  Gas Price API │ │  APNS (Push)   │ │  SendGrid    │  │
│  │   (OpenWeather)│ │  (GasBuddy)    │ │  Notifications │ │   Email      │  │
│  └────────────────┘ └────────────────┘ └────────────────┘ └──────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Technology Stack Specification

#### 2.2.1 iOS Application Layer

| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| Language | Swift | 6.1 | Primary development language |
| UI Framework | SwiftUI | iOS 26.1 SDK | Declarative UI with Liquid Glass |
| Minimum Target | iOS | 26.1 | Deployment target |
| IDE | Xcode | 17.x | Development environment |
| Local Database | SwiftData | iOS 26.1 | On-device persistence with CloudKit sync |
| Networking | Swift Concurrency + URLSession | Native | Async/await HTTP operations |
| Location | CoreLocation | iOS 26.1 | GPS tracking with sensor fusion |
| Maps | MapKit | iOS 26.1 | Route display and navigation |
| Background Processing | BGTaskScheduler | iOS 26.1 | Background sync and processing |
| Live Activities | ActivityKit | iOS 26.1 | Dynamic Island and Lock Screen |
| Widgets | WidgetKit | iOS 26.1 | Home and Lock Screen widgets |
| Authentication | AuthenticationServices | iOS 26.1 | Sign in with Apple |
| Keychain | Security Framework | Native | Secure credential storage |
| Analytics | TelemetryDeck | 2.x | Privacy-respecting analytics |
| Crash Reporting | Firebase Crashlytics | 11.x | Crash and error tracking |

#### 2.2.2 Backend Infrastructure (Railway)

| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| Runtime | Node.js | 22.12.0 LTS | JavaScript runtime |
| Framework | Express.js | 5.0.1 | HTTP server framework |
| Language | TypeScript | 5.7.x | Type-safe JavaScript |
| ORM | Prisma | 6.1.x | Database toolkit and ORM |
| Validation | Zod | 3.24.x | Schema validation |
| Authentication | Passport.js | 0.7.x | OAuth strategy management |
| JWT | jose | 5.9.x | JWT creation and verification |
| Rate Limiting | express-rate-limit | 7.5.x | API rate limiting |
| Security | Helmet | 8.0.x | HTTP security headers |
| CORS | cors | 2.8.x | Cross-origin resource sharing |
| Logging | Pino | 9.6.x | Structured logging |
| Queue | BullMQ | 5.34.x | Background job processing |
| WebSocket | Socket.io | 4.8.x | Real-time communication |
| File Upload | Multer | 1.4.x | Multipart form handling |
| PDF Generation | Puppeteer | 23.x | Report PDF rendering |
| Email | SendGrid/mail | 8.1.x | Transactional email |
| Testing | Vitest | 2.1.x | Unit and integration testing |

#### 2.2.3 Database Layer (Railway)

| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| Primary Database | PostgreSQL | 16.x | Relational data storage |
| Geospatial Extension | PostGIS | 3.4.x | GPS coordinate processing |
| Cache Layer | Redis | 7.4.x | Session cache, rate limiting, queues |
| Object Storage | Railway Volumes / S3 | - | PDF reports, receipt images |
| Connection Pooling | PgBouncer | 1.23.x | Database connection management |

#### 2.2.4 External Service Integrations

| Service | Provider | Purpose |
|---------|----------|---------|
| Push Notifications | Apple Push Notification Service | Real-time alerts |
| Email Delivery | SendGrid | Transactional emails, reports |
| Payment Processing | Stripe | Subscription billing |
| Weather Data | OpenWeatherMap API 3.0 | Driving condition context |
| Gas Prices | GasBuddy API | Fuel cost estimation |
| Geocoding | Apple MapKit Server API | Address resolution |
| Directions | Apple MapKit Server API | Route calculation |

---

## 3. Database Schema Design

### 3.1 Entity Relationship Overview

The database follows a multi-tenant architecture with row-level security. All tables include audit columns for compliance tracking.

### 3.2 Complete Schema Definition

#### 3.2.1 User & Authentication Domain

**Table: users**
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique user identifier |
| email | VARCHAR(255) | UNIQUE, NOT NULL | User email address |
| email_verified | BOOLEAN | DEFAULT false | Email verification status |
| phone_number | VARCHAR(20) | NULLABLE | Optional phone for SMS alerts |
| phone_verified | BOOLEAN | DEFAULT false | Phone verification status |
| full_name | VARCHAR(255) | NOT NULL | User's display name |
| avatar_url | TEXT | NULLABLE | Profile image URL |
| timezone | VARCHAR(50) | DEFAULT 'America/New_York' | User timezone for reporting |
| locale | VARCHAR(10) | DEFAULT 'en-US' | Localization preference |
| subscription_tier | ENUM | DEFAULT 'free' | 'free', 'pro', 'business', 'enterprise' |
| subscription_status | ENUM | DEFAULT 'active' | 'active', 'past_due', 'canceled', 'paused' |
| stripe_customer_id | VARCHAR(255) | NULLABLE, UNIQUE | Stripe customer reference |
| trial_ends_at | TIMESTAMPTZ | NULLABLE | Trial period expiration |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Account creation timestamp |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Last modification timestamp |
| deleted_at | TIMESTAMPTZ | NULLABLE | Soft delete timestamp |

**Table: auth_providers**
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Provider link identifier |
| user_id | UUID | FOREIGN KEY → users(id) ON DELETE CASCADE | Associated user |
| provider | ENUM | NOT NULL | 'apple', 'google', 'email' |
| provider_user_id | VARCHAR(255) | NOT NULL | External provider's user ID |
| provider_email | VARCHAR(255) | NULLABLE | Email from provider |
| access_token_encrypted | BYTEA | NULLABLE | Encrypted OAuth token |
| refresh_token_encrypted | BYTEA | NULLABLE | Encrypted refresh token |
| token_expires_at | TIMESTAMPTZ | NULLABLE | Token expiration |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Link creation time |
| UNIQUE | | (provider, provider_user_id) | One link per provider account |

**Table: sessions**
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Session identifier |
| user_id | UUID | FOREIGN KEY → users(id) ON DELETE CASCADE | Session owner |
| device_id | VARCHAR(255) | NOT NULL | Unique device identifier |
| device_name | VARCHAR(255) | NULLABLE | Human-readable device name |
| device_model | VARCHAR(100) | NULLABLE | e.g., "iPhone 17 Pro" |
| os_version | VARCHAR(50) | NULLABLE | e.g., "iOS 26.1" |
| app_version | VARCHAR(20) | NULLABLE | e.g., "1.0.0" |
| push_token | TEXT | NULLABLE | APNS device token |
| ip_address | INET | NULLABLE | Last known IP |
| user_agent | TEXT | NULLABLE | Client user agent |
| last_active_at | TIMESTAMPTZ | DEFAULT NOW() | Last activity timestamp |
| expires_at | TIMESTAMPTZ | NOT NULL | Session expiration |
| revoked_at | TIMESTAMPTZ | NULLABLE | Manual revocation time |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Session creation |

#### 3.2.2 Vehicle Domain

**Table: vehicles**
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Vehicle identifier |
| user_id | UUID | FOREIGN KEY → users(id) ON DELETE CASCADE | Vehicle owner |
| nickname | VARCHAR(100) | NOT NULL | User-defined name |
| make | VARCHAR(100) | NOT NULL | Manufacturer (Toyota, Ford, etc.) |
| model | VARCHAR(100) | NOT NULL | Model name (Camry, F-150, etc.) |
| year | INTEGER | CHECK (year >= 1900 AND year <= 2100) | Model year |
| color | VARCHAR(50) | NULLABLE | Vehicle color |
| license_plate | VARCHAR(20) | NULLABLE | License plate number |
| license_state | VARCHAR(50) | NULLABLE | Registration state/province |
| vin | VARCHAR(17) | NULLABLE | Vehicle identification number |
| fuel_type | ENUM | DEFAULT 'gasoline' | 'gasoline', 'diesel', 'electric', 'hybrid', 'plugin_hybrid' |
| fuel_economy_city | DECIMAL(5,2) | NULLABLE | City MPG or kWh/100mi |
| fuel_economy_highway | DECIMAL(5,2) | NULLABLE | Highway MPG or kWh/100mi |
| fuel_tank_capacity | DECIMAL(6,2) | NULLABLE | Tank size in gallons/kWh |
| odometer_reading | INTEGER | DEFAULT 0 | Current odometer |
| odometer_unit | ENUM | DEFAULT 'miles' | 'miles', 'kilometers' |
| odometer_updated_at | TIMESTAMPTZ | NULLABLE | Last odometer update |
| is_primary | BOOLEAN | DEFAULT false | Primary vehicle flag |
| is_active | BOOLEAN | DEFAULT true | Active/archived status |
| photo_url | TEXT | NULLABLE | Vehicle photo |
| insurance_provider | VARCHAR(255) | NULLABLE | Insurance company |
| insurance_policy_number | VARCHAR(100) | NULLABLE | Policy number |
| insurance_expires_at | DATE | NULLABLE | Policy expiration |
| registration_expires_at | DATE | NULLABLE | Registration expiration |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Record creation |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Last modification |
| deleted_at | TIMESTAMPTZ | NULLABLE | Soft delete |

**Table: vehicle_maintenance_records**
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Record identifier |
| vehicle_id | UUID | FOREIGN KEY → vehicles(id) ON DELETE CASCADE | Associated vehicle |
| maintenance_type | ENUM | NOT NULL | See maintenance type enum |
| description | TEXT | NULLABLE | Detailed description |
| performed_at | DATE | NOT NULL | Service date |
| odometer_at_service | INTEGER | NOT NULL | Odometer reading at service |
| cost | DECIMAL(10,2) | NULLABLE | Service cost |
| currency | VARCHAR(3) | DEFAULT 'USD' | Currency code |
| service_provider | VARCHAR(255) | NULLABLE | Shop/mechanic name |
| service_location | VARCHAR(255) | NULLABLE | Service location |
| receipt_url | TEXT | NULLABLE | Receipt image URL |
| next_service_date | DATE | NULLABLE | Recommended next service |
| next_service_odometer | INTEGER | NULLABLE | Recommended next mileage |
| notes | TEXT | NULLABLE | Additional notes |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Record creation |

**Maintenance Type Enum Values:**
'oil_change', 'tire_rotation', 'tire_replacement', 'brake_service', 'brake_replacement', 'transmission_service', 'coolant_flush', 'air_filter', 'cabin_filter', 'spark_plugs', 'battery_replacement', 'wiper_blades', 'alignment', 'suspension', 'inspection', 'emissions_test', 'registration_renewal', 'insurance_renewal', 'car_wash', 'detail', 'other'

#### 3.2.3 Trip & Mileage Domain

**Table: trips**
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Trip identifier |
| user_id | UUID | FOREIGN KEY → users(id) ON DELETE CASCADE | Trip owner |
| vehicle_id | UUID | FOREIGN KEY → vehicles(id) ON DELETE SET NULL | Vehicle used |
| status | ENUM | DEFAULT 'recording' | 'recording', 'completed', 'processing', 'verified' |
| category | ENUM | DEFAULT 'business' | 'business', 'personal', 'medical', 'charity', 'moving', 'commute' |
| purpose | VARCHAR(255) | NULLABLE | Trip purpose description |
| client_name | VARCHAR(255) | NULLABLE | Associated client/customer |
| project_name | VARCHAR(255) | NULLABLE | Associated project |
| tags | TEXT[] | DEFAULT '{}' | User-defined tags array |
| start_time | TIMESTAMPTZ | NOT NULL | Trip start timestamp |
| end_time | TIMESTAMPTZ | NULLABLE | Trip end timestamp |
| start_address | TEXT | NULLABLE | Resolved start address |
| start_place_name | VARCHAR(255) | NULLABLE | Start location name |
| start_latitude | DECIMAL(10,7) | NOT NULL | Start latitude |
| start_longitude | DECIMAL(10,7) | NOT NULL | Start longitude |
| end_address | TEXT | NULLABLE | Resolved end address |
| end_place_name | VARCHAR(255) | NULLABLE | End location name |
| end_latitude | DECIMAL(10,7) | NULLABLE | End latitude |
| end_longitude | DECIMAL(10,7) | NULLABLE | End longitude |
| distance_meters | INTEGER | DEFAULT 0 | Total distance in meters |
| distance_miles | DECIMAL(10,3) | GENERATED ALWAYS AS (distance_meters * 0.000621371) STORED | Distance in miles |
| duration_seconds | INTEGER | DEFAULT 0 | Trip duration |
| idle_time_seconds | INTEGER | DEFAULT 0 | Time spent stationary |
| max_speed_mph | DECIMAL(6,2) | NULLABLE | Maximum speed recorded |
| avg_speed_mph | DECIMAL(6,2) | NULLABLE | Average speed |
| fuel_consumed_gallons | DECIMAL(6,3) | NULLABLE | Estimated fuel used |
| fuel_cost | DECIMAL(10,2) | NULLABLE | Estimated fuel cost |
| carbon_emissions_kg | DECIMAL(8,3) | NULLABLE | Estimated CO2 emissions |
| route_polyline | TEXT | NULLABLE | Encoded polyline for map display |
| route_geojson | JSONB | NULLABLE | Full route GeoJSON |
| weather_conditions | JSONB | NULLABLE | Weather at trip time |
| detection_method | ENUM | DEFAULT 'automatic' | 'automatic', 'manual', 'widget', 'shortcut' |
| auto_classified | BOOLEAN | DEFAULT false | ML classification flag |
| classification_confidence | DECIMAL(3,2) | NULLABLE | ML confidence score 0-1 |
| user_verified | BOOLEAN | DEFAULT false | User confirmed classification |
| irs_compliant | BOOLEAN | DEFAULT false | Meets IRS requirements |
| notes | TEXT | NULLABLE | User notes |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Record creation |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Last modification |
| deleted_at | TIMESTAMPTZ | NULLABLE | Soft delete |

**Table: trip_waypoints**
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Waypoint identifier |
| trip_id | UUID | FOREIGN KEY → trips(id) ON DELETE CASCADE | Parent trip |
| sequence_number | INTEGER | NOT NULL | Order in trip |
| latitude | DECIMAL(10,7) | NOT NULL | Waypoint latitude |
| longitude | DECIMAL(10,7) | NOT NULL | Waypoint longitude |
| altitude_meters | DECIMAL(8,2) | NULLABLE | Elevation |
| horizontal_accuracy | DECIMAL(6,2) | NULLABLE | GPS accuracy meters |
| vertical_accuracy | DECIMAL(6,2) | NULLABLE | Altitude accuracy |
| speed_mps | DECIMAL(6,2) | NULLABLE | Speed meters/second |
| heading | DECIMAL(5,2) | NULLABLE | Heading degrees 0-360 |
| timestamp | TIMESTAMPTZ | NOT NULL | Waypoint capture time |
| is_stop | BOOLEAN | DEFAULT false | Detected stop flag |
| stop_duration_seconds | INTEGER | NULLABLE | Duration if stop |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Record creation |
| INDEX | | (trip_id, sequence_number) | Ordered retrieval |
| INDEX | | (trip_id, timestamp) | Time-based queries |

**Table: saved_locations**
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Location identifier |
| user_id | UUID | FOREIGN KEY → users(id) ON DELETE CASCADE | Owner |
| name | VARCHAR(255) | NOT NULL | Location name |
| location_type | ENUM | DEFAULT 'other' | 'home', 'work', 'client', 'warehouse', 'restaurant', 'store', 'gas_station', 'other' |
| address | TEXT | NOT NULL | Full address |
| latitude | DECIMAL(10,7) | NOT NULL | Latitude |
| longitude | DECIMAL(10,7) | NOT NULL | Longitude |
| radius_meters | INTEGER | DEFAULT 100 | Geofence radius |
| auto_classify_as | ENUM | NULLABLE | Auto-classification category |
| visit_count | INTEGER | DEFAULT 0 | Number of visits |
| last_visited_at | TIMESTAMPTZ | NULLABLE | Last visit time |
| is_favorite | BOOLEAN | DEFAULT false | Favorited flag |
| notes | TEXT | NULLABLE | Location notes |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Record creation |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Last modification |
| INDEX | | USING GIST (geography(ST_MakePoint(longitude, latitude))) | Spatial index |

#### 3.2.4 Delivery & Route Domain

**Table: delivery_routes**
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Route identifier |
| user_id | UUID | FOREIGN KEY → users(id) ON DELETE CASCADE | Route owner |
| name | VARCHAR(255) | NULLABLE | Route name |
| status | ENUM | DEFAULT 'planned' | 'planned', 'in_progress', 'completed', 'canceled' |
| optimization_mode | ENUM | DEFAULT 'fastest' | 'fastest', 'shortest', 'balanced' |
| scheduled_date | DATE | NULLABLE | Planned date |
| scheduled_start_time | TIME | NULLABLE | Planned start time |
| actual_start_time | TIMESTAMPTZ | NULLABLE | Actual start |
| actual_end_time | TIMESTAMPTZ | NULLABLE | Actual completion |
| total_stops | INTEGER | DEFAULT 0 | Number of stops |
| completed_stops | INTEGER | DEFAULT 0 | Completed count |
| total_distance_meters | INTEGER | NULLABLE | Optimized distance |
| total_duration_seconds | INTEGER | NULLABLE | Estimated duration |
| actual_distance_meters | INTEGER | NULLABLE | Actual distance traveled |
| actual_duration_seconds | INTEGER | NULLABLE | Actual time taken |
| start_location_id | UUID | FOREIGN KEY → saved_locations(id) | Starting point |
| end_location_id | UUID | FOREIGN KEY → saved_locations(id) | Ending point |
| return_to_start | BOOLEAN | DEFAULT true | Round trip flag |
| optimized_order | INTEGER[] | NULLABLE | Stop order after optimization |
| route_polyline | TEXT | NULLABLE | Full route polyline |
| notes | TEXT | NULLABLE | Route notes |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Record creation |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Last modification |

**Table: delivery_stops**
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Stop identifier |
| route_id | UUID | FOREIGN KEY → delivery_routes(id) ON DELETE CASCADE | Parent route |
| sequence_original | INTEGER | NOT NULL | Original user order |
| sequence_optimized | INTEGER | NULLABLE | Optimized order |
| status | ENUM | DEFAULT 'pending' | 'pending', 'in_transit', 'arrived', 'completed', 'failed', 'skipped' |
| location_id | UUID | FOREIGN KEY → saved_locations(id) | Saved location reference |
| address | TEXT | NOT NULL | Delivery address |
| latitude | DECIMAL(10,7) | NOT NULL | Latitude |
| longitude | DECIMAL(10,7) | NOT NULL | Longitude |
| recipient_name | VARCHAR(255) | NULLABLE | Recipient name |
| recipient_phone | VARCHAR(20) | NULLABLE | Contact phone |
| delivery_instructions | TEXT | NULLABLE | Special instructions |
| time_window_start | TIME | NULLABLE | Earliest delivery time |
| time_window_end | TIME | NULLABLE | Latest delivery time |
| priority | INTEGER | DEFAULT 5 | 1-10, higher = more important |
| estimated_arrival | TIMESTAMPTZ | NULLABLE | ETA |
| actual_arrival | TIMESTAMPTZ | NULLABLE | Actual arrival time |
| departure_time | TIMESTAMPTZ | NULLABLE | When driver left |
| service_duration_seconds | INTEGER | DEFAULT 300 | Expected time at stop |
| actual_service_duration | INTEGER | NULLABLE | Actual time spent |
| distance_from_previous | INTEGER | NULLABLE | Distance from last stop |
| proof_of_delivery_url | TEXT | NULLABLE | POD photo URL |
| signature_url | TEXT | NULLABLE | Signature image URL |
| delivery_notes | TEXT | NULLABLE | Completion notes |
| failure_reason | ENUM | NULLABLE | 'not_home', 'wrong_address', 'refused', 'damaged', 'other' |
| failure_notes | TEXT | NULLABLE | Failure description |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Record creation |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Last modification |

#### 3.2.5 Expense & Financial Domain

**Table: expenses**
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Expense identifier |
| user_id | UUID | FOREIGN KEY → users(id) ON DELETE CASCADE | Expense owner |
| vehicle_id | UUID | FOREIGN KEY → vehicles(id) ON DELETE SET NULL | Associated vehicle |
| trip_id | UUID | FOREIGN KEY → trips(id) ON DELETE SET NULL | Associated trip |
| category | ENUM | NOT NULL | See expense category enum |
| subcategory | VARCHAR(100) | NULLABLE | Detailed category |
| amount | DECIMAL(10,2) | NOT NULL | Expense amount |
| currency | VARCHAR(3) | DEFAULT 'USD' | Currency code |
| expense_date | DATE | NOT NULL | Date of expense |
| vendor_name | VARCHAR(255) | NULLABLE | Merchant/vendor |
| vendor_address | TEXT | NULLABLE | Vendor location |
| vendor_latitude | DECIMAL(10,7) | NULLABLE | Vendor latitude |
| vendor_longitude | DECIMAL(10,7) | NULLABLE | Vendor longitude |
| description | TEXT | NULLABLE | Expense description |
| payment_method | ENUM | DEFAULT 'card' | 'cash', 'card', 'check', 'app', 'other' |
| is_reimbursable | BOOLEAN | DEFAULT false | Reimbursement flag |
| reimbursement_status | ENUM | DEFAULT 'not_applicable' | 'not_applicable', 'pending', 'submitted', 'approved', 'paid', 'rejected' |
| receipt_url | TEXT | NULLABLE | Receipt image URL |
| receipt_ocr_data | JSONB | NULLABLE | Extracted receipt data |
| is_tax_deductible | BOOLEAN | DEFAULT false | Tax deduction flag |
| tax_category | VARCHAR(100) | NULLABLE | IRS category |
| notes | TEXT | NULLABLE | Additional notes |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Record creation |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Last modification |
| deleted_at | TIMESTAMPTZ | NULLABLE | Soft delete |

**Expense Category Enum Values:**
'fuel', 'parking', 'tolls', 'maintenance', 'repairs', 'insurance', 'registration', 'car_wash', 'supplies', 'phone', 'equipment', 'meals', 'lodging', 'other'

**Table: fuel_purchases**
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Purchase identifier |
| expense_id | UUID | FOREIGN KEY → expenses(id) ON DELETE CASCADE | Parent expense |
| vehicle_id | UUID | FOREIGN KEY → vehicles(id) ON DELETE CASCADE | Vehicle fueled |
| fuel_type | ENUM | NOT NULL | Fuel type purchased |
| gallons | DECIMAL(6,3) | NOT NULL | Quantity purchased |
| price_per_gallon | DECIMAL(5,3) | NOT NULL | Unit price |
| total_cost | DECIMAL(10,2) | NOT NULL | Total cost |
| odometer_reading | INTEGER | NULLABLE | Current odometer |
| is_full_tank | BOOLEAN | DEFAULT true | Full fill-up flag |
| station_name | VARCHAR(255) | NULLABLE | Gas station name |
| station_brand | VARCHAR(100) | NULLABLE | Brand (Shell, BP, etc.) |
| station_address | TEXT | NULLABLE | Station address |
| station_latitude | DECIMAL(10,7) | NULLABLE | Station latitude |
| station_longitude | DECIMAL(10,7) | NULLABLE | Station longitude |
| mpg_calculated | DECIMAL(5,2) | NULLABLE | Calculated MPG since last fill |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Record creation |

**Table: earnings**
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Earnings identifier |
| user_id | UUID | FOREIGN KEY → users(id) ON DELETE CASCADE | Earner |
| platform | ENUM | NOT NULL | 'uber', 'lyft', 'doordash', 'instacart', 'amazon_flex', 'grubhub', 'uber_eats', 'spark', 'shipt', 'other' |
| platform_other | VARCHAR(100) | NULLABLE | If platform = 'other' |
| earnings_date | DATE | NOT NULL | Date earned |
| gross_earnings | DECIMAL(10,2) | NOT NULL | Total before deductions |
| tips | DECIMAL(10,2) | DEFAULT 0 | Tips received |
| bonuses | DECIMAL(10,2) | DEFAULT 0 | Bonuses/promotions |
| tolls_reimbursed | DECIMAL(10,2) | DEFAULT 0 | Toll reimbursements |
| platform_fees | DECIMAL(10,2) | DEFAULT 0 | Platform deductions |
| net_earnings | DECIMAL(10,2) | GENERATED ALWAYS AS (gross_earnings + tips + bonuses + tolls_reimbursed - platform_fees) STORED | Net earnings |
| trips_completed | INTEGER | DEFAULT 0 | Number of trips/deliveries |
| hours_worked | DECIMAL(5,2) | NULLABLE | Hours online |
| active_hours | DECIMAL(5,2) | NULLABLE | Hours with passenger/delivery |
| notes | TEXT | NULLABLE | Additional notes |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Record creation |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Last modification |
| UNIQUE | | (user_id, platform, earnings_date) | One record per platform per day |

#### 3.2.6 Reporting & Tax Domain

**Table: mileage_reports**
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Report identifier |
| user_id | UUID | FOREIGN KEY → users(id) ON DELETE CASCADE | Report owner |
| report_type | ENUM | NOT NULL | 'weekly', 'monthly', 'quarterly', 'annual', 'custom', 'irs_log' |
| report_name | VARCHAR(255) | NOT NULL | Report title |
| date_range_start | DATE | NOT NULL | Period start |
| date_range_end | DATE | NOT NULL | Period end |
| vehicle_ids | UUID[] | NULLABLE | Filtered vehicles |
| categories | TEXT[] | NULLABLE | Filtered categories |
| total_trips | INTEGER | NOT NULL | Trip count |
| total_miles | DECIMAL(10,2) | NOT NULL | Total mileage |
| business_miles | DECIMAL(10,2) | NOT NULL | Business mileage |
| personal_miles | DECIMAL(10,2) | NOT NULL | Personal mileage |
| other_miles | DECIMAL(10,2) | NOT NULL | Other category miles |
| total_expenses | DECIMAL(10,2) | NOT NULL | Total expenses |
| fuel_expenses | DECIMAL(10,2) | NOT NULL | Fuel costs |
| maintenance_expenses | DECIMAL(10,2) | NOT NULL | Maintenance costs |
| other_expenses | DECIMAL(10,2) | NOT NULL | Other expenses |
| irs_rate_used | DECIMAL(4,3) | NOT NULL | IRS mileage rate applied |
| mileage_deduction | DECIMAL(10,2) | GENERATED ALWAYS AS (business_miles * irs_rate_used) STORED | Calculated deduction |
| total_earnings | DECIMAL(10,2) | NULLABLE | Period earnings |
| net_profit | DECIMAL(10,2) | NULLABLE | Earnings minus expenses |
| report_data | JSONB | NOT NULL | Full report data |
| pdf_url | TEXT | NULLABLE | Generated PDF URL |
| csv_url | TEXT | NULLABLE | Generated CSV URL |
| status | ENUM | DEFAULT 'generating' | 'generating', 'ready', 'failed' |
| generated_at | TIMESTAMPTZ | NULLABLE | Generation completion |
| expires_at | TIMESTAMPTZ | NULLABLE | Download expiration |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Record creation |

**Table: tax_years**
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Record identifier |
| user_id | UUID | FOREIGN KEY → users(id) ON DELETE CASCADE | User |
| tax_year | INTEGER | NOT NULL | Tax year (e.g., 2026) |
| filing_status | ENUM | NULLABLE | 'single', 'married_joint', 'married_separate', 'head_household', 'widow' |
| irs_standard_rate | DECIMAL(4,3) | NOT NULL | Standard mileage rate |
| irs_medical_rate | DECIMAL(4,3) | NOT NULL | Medical/moving rate |
| irs_charity_rate | DECIMAL(4,3) | NOT NULL | Charity rate |
| total_business_miles | DECIMAL(10,2) | DEFAULT 0 | Accumulated business miles |
| total_medical_miles | DECIMAL(10,2) | DEFAULT 0 | Accumulated medical miles |
| total_charity_miles | DECIMAL(10,2) | DEFAULT 0 | Accumulated charity miles |
| standard_deduction | DECIMAL(10,2) | GENERATED | Calculated deduction |
| actual_expenses | DECIMAL(10,2) | DEFAULT 0 | Actual expense method total |
| recommended_method | ENUM | NULLABLE | 'standard', 'actual' |
| notes | TEXT | NULLABLE | Tax notes |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Record creation |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Last modification |
| UNIQUE | | (user_id, tax_year) | One record per year |

#### 3.2.7 Settings & Configuration Domain

**Table: user_settings**
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| user_id | UUID | PRIMARY KEY, FOREIGN KEY → users(id) ON DELETE CASCADE | User |
| auto_tracking_enabled | BOOLEAN | DEFAULT true | Automatic trip detection |
| auto_tracking_sensitivity | ENUM | DEFAULT 'balanced' | 'low', 'balanced', 'high' |
| motion_activity_required | BOOLEAN | DEFAULT true | Require motion detection |
| minimum_trip_distance_meters | INTEGER | DEFAULT 200 | Min distance to record |
| minimum_trip_duration_seconds | INTEGER | DEFAULT 120 | Min duration to record |
| stop_detection_delay_seconds | INTEGER | DEFAULT 180 | Delay before ending trip |
| default_trip_category | ENUM | DEFAULT 'business' | Default classification |
| work_hours_start | TIME | NULLABLE | Business hours start |
| work_hours_end | TIME | NULLABLE | Business hours end |
| work_days | INTEGER[] | DEFAULT '{1,2,3,4,5}' | Work days (1=Mon, 7=Sun) |
| classify_work_hours_business | BOOLEAN | DEFAULT true | Auto-classify during work hours |
| distance_unit | ENUM | DEFAULT 'miles' | 'miles', 'kilometers' |
| currency | VARCHAR(3) | DEFAULT 'USD' | Preferred currency |
| fuel_unit | ENUM | DEFAULT 'gallons' | 'gallons', 'liters' |
| fuel_economy_unit | ENUM | DEFAULT 'mpg' | 'mpg', 'l100km', 'kml' |
| map_type | ENUM | DEFAULT 'standard' | 'standard', 'satellite', 'hybrid' |
| navigation_voice_enabled | BOOLEAN | DEFAULT true | Voice navigation |
| haptic_feedback_enabled | BOOLEAN | DEFAULT true | Haptic feedback |
| notification_trip_start | BOOLEAN | DEFAULT true | Trip start notification |
| notification_trip_end | BOOLEAN | DEFAULT true | Trip end notification |
| notification_weekly_summary | BOOLEAN | DEFAULT true | Weekly report notification |
| notification_maintenance_due | BOOLEAN | DEFAULT true | Maintenance reminders |
| live_activity_enabled | BOOLEAN | DEFAULT true | Dynamic Island/Lock Screen |
| widget_enabled | BOOLEAN | DEFAULT true | Home screen widget |
| icloud_sync_enabled | BOOLEAN | DEFAULT true | iCloud synchronization |
| background_app_refresh | BOOLEAN | DEFAULT true | Background refresh |
| low_power_mode_behavior | ENUM | DEFAULT 'reduce_accuracy' | 'normal', 'reduce_accuracy', 'pause' |
| data_export_format | ENUM | DEFAULT 'pdf' | 'pdf', 'csv', 'both' |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Record creation |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Last modification |

---

## 4. API Specification

### 4.1 Authentication Endpoints

#### 4.1.1 OAuth Flow

**POST /api/v1/auth/apple**
Initiates Sign in with Apple authentication flow.

Request Body:
- `identity_token` (string, required): Apple-provided identity token
- `authorization_code` (string, required): Apple authorization code
- `user` (object, optional): User info from Apple (first sign-in only)
  - `email` (string)
  - `name` (object): `{ givenName, familyName }`
- `device_id` (string, required): Unique device identifier
- `device_name` (string, optional): Human-readable device name
- `push_token` (string, optional): APNS push token

Response (201 Created or 200 OK):
- `access_token` (string): JWT access token (15 min expiry)
- `refresh_token` (string): Refresh token (30 day expiry)
- `token_type` (string): "Bearer"
- `expires_in` (integer): Seconds until expiry
- `user` (object): User profile
- `is_new_user` (boolean): First-time registration flag

**POST /api/v1/auth/google**
Initiates Google OAuth authentication flow.

Request Body:
- `id_token` (string, required): Google ID token
- `access_token` (string, required): Google access token
- `device_id` (string, required): Unique device identifier
- `device_name` (string, optional): Human-readable device name
- `push_token` (string, optional): APNS push token

Response: Same as Apple auth

**POST /api/v1/auth/refresh**
Refreshes an expired access token.

Request Body:
- `refresh_token` (string, required): Current refresh token
- `device_id` (string, required): Device identifier

Response:
- `access_token` (string): New JWT access token
- `refresh_token` (string): New refresh token (rotated)
- `expires_in` (integer): Seconds until expiry

**POST /api/v1/auth/logout**
Revokes current session.

Headers:
- `Authorization: Bearer <access_token>`

Request Body:
- `device_id` (string, optional): Specific device to logout
- `all_devices` (boolean, optional): Logout all devices

Response (204 No Content)

**GET /api/v1/auth/sessions**
Lists all active sessions for the user.

Response:
- `sessions` (array): Active session objects
  - `id`, `device_name`, `device_model`, `last_active_at`, `created_at`, `is_current`

**DELETE /api/v1/auth/sessions/:session_id**
Revokes a specific session.

### 4.2 Trip Management Endpoints

**POST /api/v1/trips**
Creates a new trip record.

Request Body:
- `vehicle_id` (uuid, optional): Vehicle for trip
- `start_latitude` (number, required): Starting latitude
- `start_longitude` (number, required): Starting longitude
- `start_time` (iso8601, required): Trip start time
- `detection_method` (enum, optional): How trip was started

Response (201 Created):
- Complete trip object with generated ID

**PATCH /api/v1/trips/:trip_id**
Updates an existing trip.

Request Body (all optional):
- `category`, `purpose`, `client_name`, `project_name`, `tags`, `notes`
- `vehicle_id`, `end_latitude`, `end_longitude`, `end_time`
- `user_verified` (boolean): Mark as verified

**POST /api/v1/trips/:trip_id/waypoints**
Batch uploads waypoints for a trip.

Request Body:
- `waypoints` (array, required): Array of waypoint objects
  - `latitude`, `longitude`, `timestamp`, `speed_mps`, `heading`, `altitude_meters`
  - `horizontal_accuracy`, `vertical_accuracy`

**POST /api/v1/trips/:trip_id/complete**
Marks a trip as completed and triggers processing.

Request Body:
- `end_latitude` (number, required)
- `end_longitude` (number, required)
- `end_time` (iso8601, required)
- `final_waypoints` (array, optional): Any remaining waypoints

Response:
- Complete processed trip with calculated distances, addresses, and route

**GET /api/v1/trips**
Lists trips with filtering and pagination.

Query Parameters:
- `page` (integer, default: 1)
- `per_page` (integer, default: 20, max: 100)
- `vehicle_id` (uuid, optional)
- `category` (enum, optional)
- `start_date` (date, optional)
- `end_date` (date, optional)
- `min_distance` (integer, optional): Minimum meters
- `status` (enum, optional)
- `sort` (string, default: "-start_time"): Field to sort by

**GET /api/v1/trips/:trip_id**
Gets a single trip with full details including waypoints.

**DELETE /api/v1/trips/:trip_id**
Soft deletes a trip.

### 4.3 Vehicle Endpoints

**GET /api/v1/vehicles**
Lists all vehicles for the user.

**POST /api/v1/vehicles**
Creates a new vehicle.

**GET /api/v1/vehicles/:vehicle_id**
Gets vehicle details including maintenance history.

**PATCH /api/v1/vehicles/:vehicle_id**
Updates vehicle information.

**DELETE /api/v1/vehicles/:vehicle_id**
Soft deletes a vehicle.

**POST /api/v1/vehicles/:vehicle_id/maintenance**
Adds a maintenance record.

**GET /api/v1/vehicles/:vehicle_id/stats**
Gets vehicle statistics (total miles, fuel economy, costs).

### 4.4 Delivery Route Endpoints

**POST /api/v1/routes**
Creates a new delivery route.

Request Body:
- `name` (string, optional)
- `scheduled_date` (date, optional)
- `scheduled_start_time` (time, optional)
- `start_location_id` (uuid, optional)
- `end_location_id` (uuid, optional)
- `return_to_start` (boolean, default: true)
- `optimization_mode` (enum, default: 'fastest')
- `stops` (array, required): Array of stop objects

**POST /api/v1/routes/:route_id/optimize**
Optimizes stop order using routing algorithms.

Response:
- Updated route with optimized stop sequence
- Total distance and duration estimates
- Individual leg distances and durations

**POST /api/v1/routes/:route_id/start**
Starts the delivery route.

**PATCH /api/v1/routes/:route_id/stops/:stop_id**
Updates a delivery stop status.

Request Body:
- `status` (enum): 'arrived', 'completed', 'failed', 'skipped'
- `proof_of_delivery_url` (string, optional)
- `signature_url` (string, optional)
- `delivery_notes` (string, optional)
- `failure_reason` (enum, optional)
- `failure_notes` (string, optional)

**POST /api/v1/routes/:route_id/complete**
Completes the entire route.

### 4.5 Expense Endpoints

**GET /api/v1/expenses**
Lists expenses with filtering.

**POST /api/v1/expenses**
Creates a new expense.

**POST /api/v1/expenses/receipt**
Uploads a receipt image and performs OCR extraction.

Request: multipart/form-data with image file

Response:
- `receipt_url` (string): Stored image URL
- `extracted_data` (object): OCR results
  - `vendor_name`, `date`, `total`, `line_items`, `payment_method`

**POST /api/v1/expenses/fuel**
Creates a fuel purchase expense.

### 4.6 Reporting Endpoints

**POST /api/v1/reports**
Generates a new report.

Request Body:
- `report_type` (enum, required)
- `date_range_start` (date, required)
- `date_range_end` (date, required)
- `vehicle_ids` (array, optional)
- `categories` (array, optional)
- `include_expenses` (boolean, default: true)
- `include_earnings` (boolean, default: false)
- `format` (enum, default: 'pdf')

Response (202 Accepted):
- `report_id` (uuid): Report identifier
- `status` (string): 'generating'
- `estimated_completion` (iso8601): ETA

**GET /api/v1/reports/:report_id**
Gets report status and download URLs when ready.

**GET /api/v1/reports/:report_id/download**
Downloads the generated report file.

### 4.7 Analytics Endpoints

**GET /api/v1/analytics/dashboard**
Gets dashboard summary data.

Query Parameters:
- `period` (enum): 'today', 'week', 'month', 'year', 'all_time'

Response:
- `total_trips`, `total_miles`, `business_miles`, `personal_miles`
- `total_expenses`, `fuel_costs`, `estimated_deduction`
- `avg_daily_miles`, `most_used_vehicle`
- `trips_by_category` (object): Breakdown by category
- `weekly_trend` (array): Last 7 days/weeks data

**GET /api/v1/analytics/tax-summary**
Gets tax year summary for deduction planning.

---

## 5. iOS Application Architecture

### 5.1 Project Structure

```
MileageMaxPro/
├── App/
│   ├── MileageMaxProApp.swift
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   └── AppConfiguration.swift
├── Core/
│   ├── Extensions/
│   │   ├── Date+Extensions.swift
│   │   ├── Double+Extensions.swift
│   │   ├── Color+Extensions.swift
│   │   ├── View+Extensions.swift
│   │   └── CLLocation+Extensions.swift
│   ├── Utilities/
│   │   ├── Logger.swift
│   │   ├── HapticManager.swift
│   │   ├── BiometricAuthManager.swift
│   │   └── FormatterCache.swift
│   ├── Constants/
│   │   ├── AppConstants.swift
│   │   ├── APIConstants.swift
│   │   └── ColorConstants.swift
│   └── Protocols/
│       ├── Identifiable+Hashable.swift
│       └── LoadableState.swift
├── Design/
│   ├── Theme/
│   │   ├── AppTheme.swift
│   │   ├── LiquidGlassTheme.swift
│   │   ├── Typography.swift
│   │   └── Spacing.swift
│   ├── Components/
│   │   ├── Cards/
│   │   │   ├── GlassMorphicCard.swift
│   │   │   ├── TripCard.swift
│   │   │   ├── VehicleCard.swift
│   │   │   ├── ExpenseCard.swift
│   │   │   └── StatCard.swift
│   │   ├── Buttons/
│   │   │   ├── NeumorphicButton.swift
│   │   │   ├── GlassButton.swift
│   │   │   ├── FloatingActionButton.swift
│   │   │   └── PillButton.swift
│   │   ├── Inputs/
│   │   │   ├── GlassTextField.swift
│   │   │   ├── GlassSearchBar.swift
│   │   │   ├── GlassSegmentedControl.swift
│   │   │   └── GlassDatePicker.swift
│   │   ├── Feedback/
│   │   │   ├── LoadingView.swift
│   │   │   ├── EmptyStateView.swift
│   │   │   ├── ErrorView.swift
│   │   │   └── ToastView.swift
│   │   ├── Navigation/
│   │   │   ├── GlassNavigationBar.swift
│   │   │   ├── GlassTabBar.swift
│   │   │   └── GlassToolbar.swift
│   │   └── Charts/
│   │       ├── MileageChart.swift
│   │       ├── ExpenseChart.swift
│   │       └── EarningsChart.swift
│   └── Animations/
│       ├── MicroAnimations.swift
│       ├── TransitionAnimations.swift
│       ├── LoadingAnimations.swift
│       └── GestureAnimations.swift
├── Features/
│   ├── Authentication/
│   │   ├── Views/
│   │   │   ├── AuthenticationView.swift
│   │   │   ├── SignInWithAppleButton.swift
│   │   │   ├── GoogleSignInButton.swift
│   │   │   └── OnboardingView.swift
│   │   ├── ViewModels/
│   │   │   └── AuthenticationViewModel.swift
│   │   └── Services/
│   │       ├── AuthenticationService.swift
│   │       ├── AppleAuthProvider.swift
│   │       ├── GoogleAuthProvider.swift
│   │       └── KeychainService.swift
│   ├── Dashboard/
│   │   ├── Views/
│   │   │   ├── DashboardView.swift
│   │   │   ├── QuickStatsSection.swift
│   │   │   ├── RecentTripsSection.swift
│   │   │   ├── ActiveRouteCard.swift
│   │   │   └── WeeklyChartSection.swift
│   │   └── ViewModels/
│   │       └── DashboardViewModel.swift
│   ├── Trips/
│   │   ├── Views/
│   │   │   ├── TripsListView.swift
│   │   │   ├── TripDetailView.swift
│   │   │   ├── TripMapView.swift
│   │   │   ├── TripEditSheet.swift
│   │   │   ├── TripFilterSheet.swift
│   │   │   └── ManualTripEntryView.swift
│   │   ├── ViewModels/
│   │   │   ├── TripsListViewModel.swift
│   │   │   ├── TripDetailViewModel.swift
│   │   │   └── ManualTripViewModel.swift
│   │   └── Components/
│   │       ├── TripCategoryPicker.swift
│   │       ├── TripRouteRenderer.swift
│   │       └── TripStopAnnotation.swift
│   ├── Tracking/
│   │   ├── Views/
│   │   │   ├── ActiveTripView.swift
│   │   │   ├── TrackingControlsView.swift
│   │   │   └── TrackingStatsOverlay.swift
│   │   ├── ViewModels/
│   │   │   └── ActiveTripViewModel.swift
│   │   └── Services/
│   │       ├── LocationTrackingService.swift
│   │       ├── MotionActivityService.swift
│   │       ├── TripDetectionEngine.swift
│   │       └── BackgroundTrackingManager.swift
│   ├── Routes/
│   │   ├── Views/
│   │   │   ├── RoutePlannerView.swift
│   │   │   ├── RouteMapView.swift
│   │   │   ├── StopListView.swift
│   │   │   ├── AddStopSheet.swift
│   │   │   ├── StopDetailSheet.swift
│   │   │   ├── ActiveNavigationView.swift
│   │   │   └── ProofOfDeliverySheet.swift
│   │   ├── ViewModels/
│   │   │   ├── RoutePlannerViewModel.swift
│   │   │   └── ActiveNavigationViewModel.swift
│   │   └── Services/
│   │       ├── RouteOptimizationService.swift
│   │       └── NavigationService.swift
│   ├── Vehicles/
│   │   ├── Views/
│   │   │   ├── VehiclesListView.swift
│   │   │   ├── VehicleDetailView.swift
│   │   │   ├── AddVehicleSheet.swift
│   │   │   ├── MaintenanceLogView.swift
│   │   │   └── AddMaintenanceSheet.swift
│   │   └── ViewModels/
│   │       ├── VehiclesListViewModel.swift
│   │       └── VehicleDetailViewModel.swift
│   ├── Expenses/
│   │   ├── Views/
│   │   │   ├── ExpensesListView.swift
│   │   │   ├── ExpenseDetailView.swift
│   │   │   ├── AddExpenseSheet.swift
│   │   │   ├── ReceiptCaptureView.swift
│   │   │   └── FuelLogView.swift
│   │   ├── ViewModels/
│   │   │   ├── ExpensesListViewModel.swift
│   │   │   └── AddExpenseViewModel.swift
│   │   └── Services/
│   │       └── ReceiptOCRService.swift
│   ├── Reports/
│   │   ├── Views/
│   │   │   ├── ReportsView.swift
│   │   │   ├── ReportGeneratorSheet.swift
│   │   │   ├── ReportPreviewView.swift
│   │   │   └── TaxSummaryView.swift
│   │   └── ViewModels/
│   │       └── ReportsViewModel.swift
│   ├── Analytics/
│   │   ├── Views/
│   │   │   ├── AnalyticsView.swift
│   │   │   ├── MileageAnalyticsView.swift
│   │   │   ├── ExpenseAnalyticsView.swift
│   │   │   └── EarningsAnalyticsView.swift
│   │   └── ViewModels/
│   │       └── AnalyticsViewModel.swift
│   ├── Locations/
│   │   ├── Views/
│   │   │   ├── SavedLocationsView.swift
│   │   │   ├── LocationDetailView.swift
│   │   │   └── AddLocationSheet.swift
│   │   └── ViewModels/
│   │       └── SavedLocationsViewModel.swift
│   └── Settings/
│       ├── Views/
│       │   ├── SettingsView.swift
│       │   ├── ProfileSection.swift
│       │   ├── TrackingSettingsView.swift
│       │   ├── NotificationSettingsView.swift
│       │   ├── DataExportView.swift
│       │   ├── SubscriptionView.swift
│       │   └── AboutView.swift
│       └── ViewModels/
│           └── SettingsViewModel.swift
├── Data/
│   ├── Models/
│   │   ├── User.swift
│   │   ├── Vehicle.swift
│   │   ├── Trip.swift
│   │   ├── TripWaypoint.swift
│   │   ├── DeliveryRoute.swift
│   │   ├── DeliveryStop.swift
│   │   ├── Expense.swift
│   │   ├── FuelPurchase.swift
│   │   ├── Earning.swift
│   │   ├── SavedLocation.swift
│   │   ├── MileageReport.swift
│   │   └── UserSettings.swift
│   ├── SwiftData/
│   │   ├── ModelContainer+Configuration.swift
│   │   ├── LocalTrip.swift
│   │   ├── LocalWaypoint.swift
│   │   ├── LocalVehicle.swift
│   │   └── SyncMetadata.swift
│   ├── Network/
│   │   ├── APIClient.swift
│   │   ├── APIEndpoint.swift
│   │   ├── APIError.swift
│   │   ├── RequestBuilder.swift
│   │   ├── ResponseHandler.swift
│   │   ├── TokenRefreshInterceptor.swift
│   │   ├── NetworkMonitor.swift
│   │   └── Endpoints/
│   │       ├── AuthEndpoints.swift
│   │       ├── TripEndpoints.swift
│   │       ├── VehicleEndpoints.swift
│   │       ├── RouteEndpoints.swift
│   │       ├── ExpenseEndpoints.swift
│   │       └── ReportEndpoints.swift
│   └── Repositories/
│       ├── UserRepository.swift
│       ├── TripRepository.swift
│       ├── VehicleRepository.swift
│       ├── RouteRepository.swift
│       ├── ExpenseRepository.swift
│       └── SyncRepository.swift
├── Services/
│   ├── LocationService.swift
│   ├── NotificationService.swift
│   ├── BackgroundTaskService.swift
│   ├── LiveActivityService.swift
│   ├── WidgetService.swift
│   ├── SyncService.swift
│   ├── AnalyticsService.swift
│   └── CrashReportingService.swift
├── Widgets/
│   ├── MileageWidget/
│   │   ├── MileageWidget.swift
│   │   ├── MileageWidgetEntry.swift
│   │   ├── MileageWidgetProvider.swift
│   │   └── MileageWidgetView.swift
│   ├── QuickActionsWidget/
│   │   └── QuickActionsWidget.swift
│   └── ActiveTripWidget/
│       └── ActiveTripWidget.swift
├── LiveActivities/
│   ├── TripLiveActivity.swift
│   ├── TripActivityAttributes.swift
│   └── TripActivityView.swift
├── Intents/
│   ├── StartTripIntent.swift
│   ├── StopTripIntent.swift
│   └── QuickLogIntent.swift
└── Resources/
    ├── Assets.xcassets/
    ├── Localizable.strings/
    ├── Info.plist
    └── Entitlements.plist
```

### 5.2 SwiftData Model Definitions

All SwiftData models must use the `@Model` macro and define relationships, indices, and computed properties appropriately for efficient querying and synchronization.

### 5.3 State Management Architecture

The application uses a unidirectional data flow architecture:

**Global State (via Observable):**
- `AppState`: Authentication status, current user, active subscription
- `LocationState`: Current location, tracking status, active trip
- `SyncState`: Sync status, pending changes, last sync time

**Feature State (via @Observable ViewModels):**
- Each feature module contains ViewModels managing local state
- ViewModels communicate with Repositories for data operations
- Repositories abstract SwiftData and network layer interactions

**State Principles:**
- Single source of truth for each piece of data
- State changes flow down through view hierarchy
- User actions flow up through explicit callbacks
- Side effects handled in ViewModels with async/await

---

## 6. iOS 26.1 UI/UX Implementation

### 6.1 Liquid Glass Design System

iOS 26.1 introduces Liquid Glass as the primary visual language. All UI components must implement this design system with the following characteristics:

**Visual Properties:**
- Translucent backgrounds with variable blur (20-40 point radius)
- Subtle gradient overlays responding to ambient lighting
- Soft shadows with colored tinting based on background content
- Edge highlights suggesting glass depth and refraction
- Dynamic material that responds to scroll position and content behind

**Implementation Approach:**
- Use `.glassBackgroundEffect()` modifier for standard glass treatment
- Apply `.liquidGlass()` for enhanced refractive effects
- Combine with `.shadow(color:radius:)` for depth
- Implement custom materials using `Material` and `VisualEffect` APIs
- Utilize `ContainerRelativeShape` for consistent corner radius inheritance

### 6.2 Neumorphic Elements

For interactive controls requiring tactile feedback impression:

**Button States:**
- Rest: Soft convex surface with subtle shadow underneath
- Pressed: Concave surface with inner shadow
- Disabled: Flat, desaturated appearance

**Implementation:**
- Light source assumed from top-left (315°)
- Shadow pairs: light color offset top-left, dark color offset bottom-right
- Shadow blur radius proportional to element size (typically 8-12 points)
- Use `.neumorphic(isPressed:)` custom modifier

### 6.3 Micro-Animation Specifications

All interactions must include subtle animations for polish:

**Timing Curves:**
- Standard interactions: `.spring(response: 0.35, dampingFraction: 0.7)`
- Quick feedback: `.spring(response: 0.25, dampingFraction: 0.8)`
- Smooth transitions: `.easeInOut(duration: 0.3)`
- Elastic bounce: `.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.1)`

**Animation Catalog:**

| Interaction | Animation | Duration |
|-------------|-----------|----------|
| Button tap | Scale 0.95 → 1.0 with spring | 0.25s |
| Card selection | Scale 1.02 + shadow increase | 0.3s |
| List item appear | Fade + slide from bottom | 0.2s staggered |
| Modal present | Scale 0.9 → 1.0 + fade | 0.35s |
| Tab switch | Cross-fade + subtle slide | 0.25s |
| Pull to refresh | Rubber band + rotation | Physics-based |
| Swipe action reveal | Slide with resistance | Gesture-driven |
| Success state | Checkmark draw + haptic | 0.4s |
| Error shake | Horizontal oscillation | 0.3s |
| Loading pulse | Opacity 0.3 ↔ 1.0 | 1.0s repeating |
| Value change | Number counter roll | 0.5s |

**Haptic Feedback Mapping:**

| Event | Haptic Type |
|-------|-------------|
| Button tap | `.light` impact |
| Selection change | `.selection` |
| Toggle switch | `.medium` impact |
| Success action | `.success` notification |
| Error state | `.error` notification |
| Warning | `.warning` notification |
| Drag threshold | `.rigid` impact |
| Delete action | `.heavy` impact |

### 6.4 Color System

**Primary Palette:**
- Background: Adaptive system background with glass overlay
- Surface: `Material.thin` to `Material.ultraThin` based on layer
- Primary: `#007AFF` (iOS Blue) with vibrancy
- Secondary: `#5856D6` (iOS Purple)
- Accent: `#34C759` (iOS Green) for positive actions

**Semantic Colors:**
- Success: `#34C759`
- Warning: `#FF9500`
- Error: `#FF3B30`
- Info: `#5AC8FA`

**Dark Mode Considerations:**
- Glass effects increase blur and reduce transparency
- Shadow colors shift to luminance-based highlights
- Neumorphic elements reverse light source implications
- Maintain WCAG 2.1 AA contrast ratios (4.5:1 for text)

### 6.5 Typography Scale

Using SF Pro with Dynamic Type support:

| Style | Size | Weight | Use Case |
|-------|------|--------|----------|
| Large Title | 34pt | Bold | Screen titles |
| Title 1 | 28pt | Bold | Section headers |
| Title 2 | 22pt | Bold | Card titles |
| Title 3 | 20pt | Semibold | Subsections |
| Headline | 17pt | Semibold | Emphasis |
| Body | 17pt | Regular | Primary content |
| Callout | 16pt | Regular | Supporting text |
| Subhead | 15pt | Regular | Secondary content |
| Footnote | 13pt | Regular | Tertiary content |
| Caption 1 | 12pt | Regular | Labels |
| Caption 2 | 11pt | Regular | Timestamps |

All text must support Dynamic Type scaling from `xSmall` to `AX5`.

### 6.6 Layout Guidelines

**Spacing Scale (points):**
- `xxs`: 4
- `xs`: 8
- `sm`: 12
- `md`: 16
- `lg`: 24
- `xl`: 32
- `xxl`: 48

**Safe Areas:**
- Always respect safe area insets
- Add additional padding (16pt minimum) from safe edges
- Cards: 16pt internal padding, 12pt between cards
- Lists: 16pt horizontal margins

**Grid System:**
- 4-point grid for all measurements
- Card widths: Full width minus 32pt (16pt margins)
- Maximum content width on large screens: 428pt

---

## 7. Core Feature Implementations

### 7.1 Automatic Trip Detection Engine

The trip detection system uses sensor fusion combining GPS, motion activity, and device state to automatically identify driving trips with minimal battery impact.

**Detection Algorithm:**
1. Motion Activity Recognition monitors for `.automotive` activity classification
2. Upon detection, system requests temporary precise location
3. If speed exceeds threshold (> 5 mph for 30 seconds), trip recording initiates
4. Location updates switch to balanced accuracy (50m) during trip
5. Significant speed reduction or stationary detection triggers stop evaluation
6. After configurable delay (default 3 minutes) without movement, trip ends
7. Post-processing calculates route, distance, addresses, and statistics

**Power Optimization:**
- Use `CLBackgroundActivitySession` for background tracking
- Leverage deferred location updates when possible
- Implement `CLMonitor` for geofence-based detection at saved locations
- Reduce GPS frequency on straight highways using motion sensors
- Batch waypoint uploads to minimize network operations

### 7.2 Route Optimization Algorithm

Multi-stop route optimization uses a hybrid approach:

**For 2-10 stops:**
- Exact solution using branch-and-bound algorithm
- Considers time windows and priorities
- Returns optimal order guaranteed

**For 11-25 stops:**
- Nearest neighbor heuristic with 2-opt improvement
- Returns near-optimal solution in < 2 seconds

**For 25+ stops:**
- Genetic algorithm with local search
- Iterative improvement over 5-second window
- Returns quality solution with improvement indicator

**Optimization Factors:**
- Real-time traffic data from MapKit
- Delivery time windows (hard and soft constraints)
- Stop priority rankings
- Driver break requirements
- Vehicle capacity constraints
- Return-to-origin preference

### 7.3 Offline-First Data Architecture

**Local Storage Strategy:**
- SwiftData for all user data with optimistic UI
- Queue pending changes with automatic retry
- Conflict resolution using last-write-wins with user override option
- Background sync triggered on network availability

**Sync Protocol:**
1. On app foreground, fetch changes since last sync timestamp
2. Merge remote changes with local modifications
3. Push local changes to server
4. Update sync metadata with new timestamp
5. Notify UI of any conflicts requiring attention

**Conflict Resolution:**
- Trips: Server version wins (prevents duplicate records)
- Edits: Most recent timestamp wins
- Deletes: Delete propagates (tombstone sync)
- User settings: Client wins (user preference)

### 7.4 IRS Compliance Module

**Mileage Log Requirements:**
Per IRS Publication 463, logs must include:
- Date of trip
- Destination (address or general description)
- Business purpose
- Miles driven

**Implementation:**
- All business trips automatically capture required fields
- Export generates IRS-compliant format
- Digital signature option for audit trail
- 7-year data retention recommendation displayed
- Reminders for unclassified trips

**Report Formats:**
- Standard mileage rate calculation
- Actual expense method comparison
- Summary by category
- Chronological detailed log
- Annual summary for tax filing

---

## 8. Backend Implementation Details

### 8.1 Railway Deployment Configuration

**Service Architecture:**

```yaml
services:
  api:
    source: ./api
    buildCommand: npm run build
    startCommand: npm run start:prod
    envVars:
      NODE_ENV: production
      DATABASE_URL: ${{Postgres.DATABASE_URL}}
      REDIS_URL: ${{Redis.REDIS_URL}}
    scaling:
      minInstances: 2
      maxInstances: 10
      targetCPU: 70
    healthcheck:
      path: /health
      interval: 30s

  worker:
    source: ./worker
    buildCommand: npm run build
    startCommand: npm run worker
    envVars:
      NODE_ENV: production
      DATABASE_URL: ${{Postgres.DATABASE_URL}}
      REDIS_URL: ${{Redis.REDIS_URL}}

  postgres:
    plugin: postgresql
    version: "16"
    extensions:
      - postgis
      - pg_trgm
    
  redis:
    plugin: redis
    version: "7"
```

### 8.2 Authentication Flow Implementation

**JWT Token Structure:**

Access Token Claims:
- `sub`: User UUID
- `email`: User email
- `tier`: Subscription tier
- `iat`: Issued at timestamp
- `exp`: Expiration (15 minutes)
- `jti`: Unique token ID

Refresh Token Claims:
- `sub`: User UUID
- `sid`: Session UUID
- `did`: Device ID
- `iat`: Issued at timestamp
- `exp`: Expiration (30 days)
- `jti`: Unique token ID

**Token Rotation:**
- Refresh tokens are single-use
- New refresh token issued with each access token refresh
- Old refresh token immediately invalidated
- Token reuse detected = immediate session revocation (potential theft)

### 8.3 Rate Limiting Strategy

**Tier-Based Limits:**

| Tier | Requests/Minute | Concurrent Trips | Waypoints/Trip | Reports/Day |
|------|-----------------|------------------|----------------|-------------|
| Free | 60 | 1 | 500 | 2 |
| Pro | 120 | 3 | 2000 | 10 |
| Business | 300 | 10 | 5000 | Unlimited |
| Enterprise | 600 | Unlimited | Unlimited | Unlimited |

**Implementation:**
- Redis-backed sliding window algorithm
- Key pattern: `ratelimit:{user_id}:{endpoint}:{window}`
- Headers returned: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`
- 429 response includes `Retry-After` header

### 8.4 Background Job Processing

**Job Queues:**

| Queue | Purpose | Priority | Retry Strategy |
|-------|---------|----------|----------------|
| trip-processing | Post-trip calculations | High | 3 attempts, exponential backoff |
| route-optimization | Route calculations | High | 3 attempts, 10s delay |
| report-generation | PDF/CSV creation | Medium | 3 attempts, 30s delay |
| receipt-ocr | Receipt text extraction | Medium | 2 attempts, 60s delay |
| sync | Data synchronization | Low | 5 attempts, exponential |
| notifications | Push/email delivery | Low | 3 attempts, 30s delay |
| cleanup | Data maintenance | Lowest | 1 attempt |

### 8.5 Security Implementation

**Data Encryption:**
- All data encrypted at rest (PostgreSQL TDE)
- TLS 1.3 for all connections
- Sensitive fields (tokens) encrypted at application layer using AES-256-GCM
- Encryption keys managed via Railway secrets

**API Security:**
- Helmet.js security headers
- CORS restricted to app bundle identifiers
- Request size limits (10MB max)
- SQL injection prevention via parameterized Prisma queries
- Input validation with Zod schemas
- Rate limiting per user and IP

**Audit Logging:**
- All authentication events
- All data modifications
- All admin actions
- All API errors
- Retention: 90 days (hot), 2 years (cold)

---

## 9. Testing Strategy

### 9.1 iOS Testing Requirements

**Unit Testing (XCTest):**
- Minimum 80% code coverage for business logic
- All ViewModels must have comprehensive tests
- Repository layer fully tested with mock network
- Location processing algorithms tested with sample data

**UI Testing (XCUITest):**
- Critical user flows automated
- Onboarding and authentication
- Trip recording start/stop
- Route creation and navigation
- Report generation

**Snapshot Testing:**
- All reusable components
- Light and Dark mode variants
- Dynamic Type size extremes
- Accessibility audit integration

### 9.2 Backend Testing Requirements

**Unit Testing (Vitest):**
- Minimum 85% code coverage
- All service layer functions
- Authentication flows
- Data validation

**Integration Testing:**
- Database operations with test containers
- API endpoint testing
- Queue processing verification

**Load Testing:**
- 1000 concurrent users baseline
- Trip recording under load
- Report generation queue stress

---

## 10. Performance Requirements

### 10.1 iOS Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| Cold launch | < 1.5s | Time to interactive |
| Warm launch | < 0.5s | Time to interactive |
| Frame rate | 60 fps | During scrolling/animation |
| Memory footprint | < 150MB | Normal operation |
| Battery (tracking) | < 5%/hr | Active GPS recording |
| Battery (background) | < 1%/hr | Background monitoring |
| Trip sync | < 2s | Single trip upload |
| Dashboard load | < 1s | From network cache |

### 10.2 API Performance Targets

| Endpoint Category | P50 Latency | P99 Latency | Throughput |
|-------------------|-------------|-------------|------------|
| Authentication | < 100ms | < 300ms | 100 rps |
| Trip CRUD | < 50ms | < 150ms | 500 rps |
| Waypoint upload | < 100ms | < 500ms | 200 rps |
| Route optimization | < 2s | < 5s | 50 rps |
| Report generation | < 10s | < 30s | 10 rps |

---

## 11. Subscription Tiers

### 11.1 Feature Matrix

| Feature | Free | Pro ($9.99/mo) | Business ($24.99/mo) |
|---------|------|----------------|----------------------|
| Automatic tracking | ✓ | ✓ | ✓ |
| Manual trip entry | ✓ | ✓ | ✓ |
| Vehicles | 1 | 5 | Unlimited |
| Trip history | 90 days | 2 years | Unlimited |
| Basic reports | ✓ | ✓ | ✓ |
| IRS-compliant export | – | ✓ | ✓ |
| Route optimization | 5 stops | 15 stops | 50 stops |
| Proof of delivery | – | ✓ | ✓ |
| Expense tracking | – | ✓ | ✓ |
| Receipt OCR | – | ✓ | ✓ |
| Team features | – | – | ✓ |
| API access | – | – | ✓ |
| Priority support | – | – | ✓ |

### 11.2 Payment Integration

**Stripe Implementation:**
- Apple In-App Purchase as primary
- Stripe web fallback for management
- Subscription webhooks for status sync
- Grace period: 3 days past due
- Trial period: 14 days

---

## 12. Accessibility Requirements

**VoiceOver:**
- All interactive elements labeled
- Logical focus order
- Custom rotor actions for complex views
- Announcement of state changes

**Dynamic Type:**
- Full support through AX5
- Layout adapts without truncation
- Minimum touch targets: 44x44 points

**Color and Contrast:**
- WCAG 2.1 AA compliance
- Differentiate without color alone
- Increased contrast mode support

**Motion:**
- Reduce motion preference respected
- Essential animations preserved
- Parallax effects disabled when requested

---

## 13. Localization

**Initial Languages:**
- English (US) - Primary
- Spanish (Latin America)
- French (Canada)
- Portuguese (Brazil)

**Implementation:**
- All user-facing strings externalized
- Pluralization rules implemented
- Date/time/number formatting localized
- Right-to-left layout support prepared

---

## 14. Privacy and Compliance

**Data Collection:**
- Location data only during active tracking
- No third-party tracking SDKs
- Analytics via privacy-respecting TelemetryDeck
- No data selling or sharing

**User Rights:**
- Data export in standard formats
- Account deletion with full data removal
- Consent management for optional features

**Compliance:**
- GDPR compliant
- CCPA compliant
- App Tracking Transparency implemented
- Privacy nutrition labels accurate

---

## 15. Launch Checklist

**Pre-Submission:**
- [ ] All features complete and tested
- [ ] Performance benchmarks met
- [ ] Accessibility audit passed
- [ ] Privacy policy and terms updated
- [ ] App Store metadata prepared
- [ ] Screenshots and preview video ready
- [ ] Backend scaled for launch traffic
- [ ] Monitoring and alerting configured
- [ ] Customer support workflows ready
- [ ] Beta tester feedback incorporated

**Post-Launch:**
- [ ] Monitor crash-free rate (target: 99.5%)
- [ ] Track subscription conversion
- [ ] Monitor API error rates
- [ ] Gather and respond to reviews
- [ ] Plan first update based on feedback

---

## Appendix A: Environment Variables

### iOS (via .xcconfig)

```
API_BASE_URL = https://api.mileagemaxpro.com
APPLE_TEAM_ID = [TEAM_ID]
GOOGLE_CLIENT_ID = [CLIENT_ID]
TELEMETRY_APP_ID = [APP_ID]
FIREBASE_CONFIG = [CONFIG]
```

### Backend (.env)

```
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://...
REDIS_URL=redis://...
JWT_ACCESS_SECRET=[SECRET]
JWT_REFRESH_SECRET=[SECRET]
APPLE_TEAM_ID=[ID]
APPLE_KEY_ID=[ID]
APPLE_PRIVATE_KEY=[KEY]
GOOGLE_CLIENT_ID=[ID]
GOOGLE_CLIENT_SECRET=[SECRET]
STRIPE_SECRET_KEY=[KEY]
STRIPE_WEBHOOK_SECRET=[SECRET]
SENDGRID_API_KEY=[KEY]
OPENWEATHER_API_KEY=[KEY]
GASBUDDY_API_KEY=[KEY]
SENTRY_DSN=[DSN]
```

---

## Appendix B: IRS Standard Mileage Rates

| Year | Business | Medical/Moving | Charity |
|------|----------|----------------|---------|
| 2024 | $0.67 | $0.21 | $0.14 |
| 2025 | $0.70 | $0.22 | $0.14 |
| 2026 | $0.70* | $0.22* | $0.14* |

*Projected - update when IRS announces official rates

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | January 2026 | MileageMax Team | Initial specification |

---

**END OF SPECIFICATION DOCUMENT**
