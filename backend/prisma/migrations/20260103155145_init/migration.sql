-- CreateEnum
CREATE TYPE "SubscriptionTier" AS ENUM ('free', 'pro', 'business', 'enterprise');

-- CreateEnum
CREATE TYPE "SubscriptionStatus" AS ENUM ('active', 'past_due', 'canceled', 'paused', 'trialing');

-- CreateEnum
CREATE TYPE "AuthProvider" AS ENUM ('apple', 'google', 'email');

-- CreateEnum
CREATE TYPE "FuelType" AS ENUM ('gasoline', 'diesel', 'electric', 'hybrid', 'plugin_hybrid');

-- CreateEnum
CREATE TYPE "OdometerUnit" AS ENUM ('miles', 'kilometers');

-- CreateEnum
CREATE TYPE "MaintenanceType" AS ENUM ('oil_change', 'tire_rotation', 'tire_replacement', 'brake_service', 'brake_replacement', 'transmission_service', 'coolant_flush', 'air_filter', 'cabin_filter', 'spark_plugs', 'battery_replacement', 'wiper_blades', 'alignment', 'suspension', 'inspection', 'emissions_test', 'registration_renewal', 'insurance_renewal', 'car_wash', 'detail', 'other');

-- CreateEnum
CREATE TYPE "TripStatus" AS ENUM ('recording', 'completed', 'processing', 'verified');

-- CreateEnum
CREATE TYPE "TripCategory" AS ENUM ('business', 'personal', 'medical', 'charity', 'moving', 'commute');

-- CreateEnum
CREATE TYPE "DetectionMethod" AS ENUM ('automatic', 'manual', 'widget', 'shortcut');

-- CreateEnum
CREATE TYPE "LocationType" AS ENUM ('home', 'work', 'client', 'warehouse', 'restaurant', 'store', 'gas_station', 'other');

-- CreateEnum
CREATE TYPE "RouteStatus" AS ENUM ('planned', 'in_progress', 'completed', 'canceled');

-- CreateEnum
CREATE TYPE "OptimizationMode" AS ENUM ('fastest', 'shortest', 'balanced');

-- CreateEnum
CREATE TYPE "StopStatus" AS ENUM ('pending', 'in_transit', 'arrived', 'completed', 'failed', 'skipped');

-- CreateEnum
CREATE TYPE "FailureReason" AS ENUM ('not_home', 'wrong_address', 'refused', 'damaged', 'other');

-- CreateEnum
CREATE TYPE "ExpenseCategory" AS ENUM ('fuel', 'parking', 'tolls', 'maintenance', 'repairs', 'insurance', 'registration', 'car_wash', 'supplies', 'phone', 'equipment', 'meals', 'lodging', 'other');

-- CreateEnum
CREATE TYPE "PaymentMethod" AS ENUM ('cash', 'card', 'check', 'app', 'other');

-- CreateEnum
CREATE TYPE "ReimbursementStatus" AS ENUM ('not_applicable', 'pending', 'submitted', 'approved', 'paid', 'rejected');

-- CreateEnum
CREATE TYPE "EarningsPlatform" AS ENUM ('uber', 'lyft', 'doordash', 'instacart', 'amazon_flex', 'grubhub', 'uber_eats', 'spark', 'shipt', 'other');

-- CreateEnum
CREATE TYPE "ReportType" AS ENUM ('weekly', 'monthly', 'quarterly', 'annual', 'custom', 'irs_log');

-- CreateEnum
CREATE TYPE "ReportStatus" AS ENUM ('generating', 'ready', 'failed');

-- CreateEnum
CREATE TYPE "FilingStatus" AS ENUM ('single', 'married_joint', 'married_separate', 'head_household', 'widow');

-- CreateEnum
CREATE TYPE "TrackingSensitivity" AS ENUM ('low', 'balanced', 'high');

-- CreateEnum
CREATE TYPE "DistanceUnit" AS ENUM ('miles', 'kilometers');

-- CreateEnum
CREATE TYPE "FuelUnit" AS ENUM ('gallons', 'liters');

-- CreateEnum
CREATE TYPE "FuelEconomyUnit" AS ENUM ('mpg', 'l100km', 'kml');

-- CreateEnum
CREATE TYPE "MapType" AS ENUM ('standard', 'satellite', 'hybrid');

-- CreateEnum
CREATE TYPE "LowPowerModeBehavior" AS ENUM ('normal', 'reduce_accuracy', 'pause');

-- CreateEnum
CREATE TYPE "ExportFormat" AS ENUM ('pdf', 'csv', 'both');

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL,
    "email" VARCHAR(255) NOT NULL,
    "email_verified" BOOLEAN NOT NULL DEFAULT false,
    "phone_number" VARCHAR(20),
    "phone_verified" BOOLEAN NOT NULL DEFAULT false,
    "full_name" VARCHAR(255) NOT NULL,
    "avatar_url" TEXT,
    "timezone" VARCHAR(50) NOT NULL DEFAULT 'America/New_York',
    "locale" VARCHAR(10) NOT NULL DEFAULT 'en-US',
    "subscription_tier" "SubscriptionTier" NOT NULL DEFAULT 'free',
    "subscription_status" "SubscriptionStatus" NOT NULL DEFAULT 'active',
    "stripe_customer_id" VARCHAR(255),
    "trial_ends_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deleted_at" TIMESTAMPTZ,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "auth_providers" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "provider" "AuthProvider" NOT NULL,
    "provider_user_id" VARCHAR(255) NOT NULL,
    "provider_email" VARCHAR(255),
    "access_token_encrypted" BYTEA,
    "refresh_token_encrypted" BYTEA,
    "token_expires_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "auth_providers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sessions" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "device_id" VARCHAR(255) NOT NULL,
    "device_name" VARCHAR(255),
    "device_model" VARCHAR(100),
    "os_version" VARCHAR(50),
    "app_version" VARCHAR(20),
    "push_token" TEXT,
    "ip_address" INET,
    "user_agent" TEXT,
    "last_active_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires_at" TIMESTAMPTZ NOT NULL,
    "revoked_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "refresh_token_hash" VARCHAR(64),
    "refresh_token_family" UUID NOT NULL,

    CONSTRAINT "sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "vehicles" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "nickname" VARCHAR(100) NOT NULL,
    "make" VARCHAR(100) NOT NULL,
    "model" VARCHAR(100) NOT NULL,
    "year" INTEGER NOT NULL,
    "color" VARCHAR(50),
    "license_plate" VARCHAR(20),
    "license_state" VARCHAR(50),
    "vin" VARCHAR(17),
    "fuel_type" "FuelType" NOT NULL DEFAULT 'gasoline',
    "fuel_economy_city" DECIMAL(5,2),
    "fuel_economy_highway" DECIMAL(5,2),
    "fuel_tank_capacity" DECIMAL(6,2),
    "odometer_reading" INTEGER NOT NULL DEFAULT 0,
    "odometer_unit" "OdometerUnit" NOT NULL DEFAULT 'miles',
    "odometer_updated_at" TIMESTAMPTZ,
    "is_primary" BOOLEAN NOT NULL DEFAULT false,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "photo_url" TEXT,
    "insurance_provider" VARCHAR(255),
    "insurance_policy_number" VARCHAR(100),
    "insurance_expires_at" DATE,
    "registration_expires_at" DATE,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deleted_at" TIMESTAMPTZ,

    CONSTRAINT "vehicles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "vehicle_maintenance_records" (
    "id" UUID NOT NULL,
    "vehicle_id" UUID NOT NULL,
    "maintenance_type" "MaintenanceType" NOT NULL,
    "description" TEXT,
    "performed_at" DATE NOT NULL,
    "odometer_at_service" INTEGER NOT NULL,
    "cost" DECIMAL(10,2),
    "currency" VARCHAR(3) NOT NULL DEFAULT 'USD',
    "service_provider" VARCHAR(255),
    "service_location" VARCHAR(255),
    "receipt_url" TEXT,
    "next_service_date" DATE,
    "next_service_odometer" INTEGER,
    "notes" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "vehicle_maintenance_records_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "trips" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "vehicle_id" UUID,
    "status" "TripStatus" NOT NULL DEFAULT 'recording',
    "category" "TripCategory" NOT NULL DEFAULT 'business',
    "purpose" VARCHAR(255),
    "client_name" VARCHAR(255),
    "project_name" VARCHAR(255),
    "tags" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "start_time" TIMESTAMPTZ NOT NULL,
    "end_time" TIMESTAMPTZ,
    "start_address" TEXT,
    "start_place_name" VARCHAR(255),
    "start_latitude" DECIMAL(10,7) NOT NULL,
    "start_longitude" DECIMAL(10,7) NOT NULL,
    "end_address" TEXT,
    "end_place_name" VARCHAR(255),
    "end_latitude" DECIMAL(10,7),
    "end_longitude" DECIMAL(10,7),
    "distance_meters" INTEGER NOT NULL DEFAULT 0,
    "duration_seconds" INTEGER NOT NULL DEFAULT 0,
    "idle_time_seconds" INTEGER NOT NULL DEFAULT 0,
    "max_speed_mph" DECIMAL(6,2),
    "avg_speed_mph" DECIMAL(6,2),
    "fuel_consumed_gallons" DECIMAL(6,3),
    "fuel_cost" DECIMAL(10,2),
    "carbon_emissions_kg" DECIMAL(8,3),
    "route_polyline" TEXT,
    "route_geojson" JSONB,
    "weather_conditions" JSONB,
    "detection_method" "DetectionMethod" NOT NULL DEFAULT 'automatic',
    "auto_classified" BOOLEAN NOT NULL DEFAULT false,
    "classification_confidence" DECIMAL(3,2),
    "user_verified" BOOLEAN NOT NULL DEFAULT false,
    "irs_compliant" BOOLEAN NOT NULL DEFAULT false,
    "notes" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deleted_at" TIMESTAMPTZ,

    CONSTRAINT "trips_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "trip_waypoints" (
    "id" UUID NOT NULL,
    "trip_id" UUID NOT NULL,
    "sequence_number" INTEGER NOT NULL,
    "latitude" DECIMAL(10,7) NOT NULL,
    "longitude" DECIMAL(10,7) NOT NULL,
    "altitude_meters" DECIMAL(8,2),
    "horizontal_accuracy" DECIMAL(6,2),
    "vertical_accuracy" DECIMAL(6,2),
    "speed_mps" DECIMAL(6,2),
    "heading" DECIMAL(5,2),
    "timestamp" TIMESTAMPTZ NOT NULL,
    "is_stop" BOOLEAN NOT NULL DEFAULT false,
    "stop_duration_seconds" INTEGER,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "trip_waypoints_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "saved_locations" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "location_type" "LocationType" NOT NULL DEFAULT 'other',
    "address" TEXT NOT NULL,
    "latitude" DECIMAL(10,7) NOT NULL,
    "longitude" DECIMAL(10,7) NOT NULL,
    "radius_meters" INTEGER NOT NULL DEFAULT 100,
    "auto_classify_as" "TripCategory",
    "visit_count" INTEGER NOT NULL DEFAULT 0,
    "last_visited_at" TIMESTAMPTZ,
    "is_favorite" BOOLEAN NOT NULL DEFAULT false,
    "notes" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "saved_locations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "delivery_routes" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "name" VARCHAR(255),
    "status" "RouteStatus" NOT NULL DEFAULT 'planned',
    "optimization_mode" "OptimizationMode" NOT NULL DEFAULT 'fastest',
    "scheduled_date" DATE,
    "scheduled_start_time" TIME,
    "actual_start_time" TIMESTAMPTZ,
    "actual_end_time" TIMESTAMPTZ,
    "total_stops" INTEGER NOT NULL DEFAULT 0,
    "completed_stops" INTEGER NOT NULL DEFAULT 0,
    "total_distance_meters" INTEGER,
    "total_duration_seconds" INTEGER,
    "actual_distance_meters" INTEGER,
    "actual_duration_seconds" INTEGER,
    "start_location_id" UUID,
    "end_location_id" UUID,
    "return_to_start" BOOLEAN NOT NULL DEFAULT true,
    "optimized_order" INTEGER[],
    "route_polyline" TEXT,
    "notes" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "delivery_routes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "delivery_stops" (
    "id" UUID NOT NULL,
    "route_id" UUID NOT NULL,
    "sequence_original" INTEGER NOT NULL,
    "sequence_optimized" INTEGER,
    "status" "StopStatus" NOT NULL DEFAULT 'pending',
    "location_id" UUID,
    "address" TEXT NOT NULL,
    "latitude" DECIMAL(10,7) NOT NULL,
    "longitude" DECIMAL(10,7) NOT NULL,
    "recipient_name" VARCHAR(255),
    "recipient_phone" VARCHAR(20),
    "delivery_instructions" TEXT,
    "time_window_start" TIME,
    "time_window_end" TIME,
    "priority" INTEGER NOT NULL DEFAULT 5,
    "estimated_arrival" TIMESTAMPTZ,
    "actual_arrival" TIMESTAMPTZ,
    "departure_time" TIMESTAMPTZ,
    "service_duration_seconds" INTEGER NOT NULL DEFAULT 300,
    "actual_service_duration" INTEGER,
    "distance_from_previous" INTEGER,
    "proof_of_delivery_url" TEXT,
    "signature_url" TEXT,
    "delivery_notes" TEXT,
    "failure_reason" "FailureReason",
    "failure_notes" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "delivery_stops_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "expenses" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "vehicle_id" UUID,
    "trip_id" UUID,
    "category" "ExpenseCategory" NOT NULL,
    "subcategory" VARCHAR(100),
    "amount" DECIMAL(10,2) NOT NULL,
    "currency" VARCHAR(3) NOT NULL DEFAULT 'USD',
    "expense_date" DATE NOT NULL,
    "vendor_name" VARCHAR(255),
    "vendor_address" TEXT,
    "vendor_latitude" DECIMAL(10,7),
    "vendor_longitude" DECIMAL(10,7),
    "description" TEXT,
    "payment_method" "PaymentMethod" NOT NULL DEFAULT 'card',
    "is_reimbursable" BOOLEAN NOT NULL DEFAULT false,
    "reimbursement_status" "ReimbursementStatus" NOT NULL DEFAULT 'not_applicable',
    "receipt_url" TEXT,
    "receipt_ocr_data" JSONB,
    "is_tax_deductible" BOOLEAN NOT NULL DEFAULT false,
    "tax_category" VARCHAR(100),
    "notes" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deleted_at" TIMESTAMPTZ,

    CONSTRAINT "expenses_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "fuel_purchases" (
    "id" UUID NOT NULL,
    "expense_id" UUID NOT NULL,
    "vehicle_id" UUID NOT NULL,
    "fuel_type" "FuelType" NOT NULL,
    "gallons" DECIMAL(6,3) NOT NULL,
    "price_per_gallon" DECIMAL(5,3) NOT NULL,
    "total_cost" DECIMAL(10,2) NOT NULL,
    "odometer_reading" INTEGER,
    "is_full_tank" BOOLEAN NOT NULL DEFAULT true,
    "station_name" VARCHAR(255),
    "station_brand" VARCHAR(100),
    "station_address" TEXT,
    "station_latitude" DECIMAL(10,7),
    "station_longitude" DECIMAL(10,7),
    "mpg_calculated" DECIMAL(5,2),
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "fuel_purchases_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "earnings" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "platform" "EarningsPlatform" NOT NULL,
    "platform_other" VARCHAR(100),
    "earnings_date" DATE NOT NULL,
    "gross_earnings" DECIMAL(10,2) NOT NULL,
    "tips" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "bonuses" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "tolls_reimbursed" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "platform_fees" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "trips_completed" INTEGER NOT NULL DEFAULT 0,
    "hours_worked" DECIMAL(5,2),
    "active_hours" DECIMAL(5,2),
    "notes" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "earnings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "mileage_reports" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "report_type" "ReportType" NOT NULL,
    "report_name" VARCHAR(255) NOT NULL,
    "date_range_start" DATE NOT NULL,
    "date_range_end" DATE NOT NULL,
    "vehicle_ids" UUID[],
    "categories" TEXT[],
    "total_trips" INTEGER NOT NULL,
    "total_miles" DECIMAL(10,2) NOT NULL,
    "business_miles" DECIMAL(10,2) NOT NULL,
    "personal_miles" DECIMAL(10,2) NOT NULL,
    "other_miles" DECIMAL(10,2) NOT NULL,
    "total_expenses" DECIMAL(10,2) NOT NULL,
    "fuel_expenses" DECIMAL(10,2) NOT NULL,
    "maintenance_expenses" DECIMAL(10,2) NOT NULL,
    "other_expenses" DECIMAL(10,2) NOT NULL,
    "irs_rate_used" DECIMAL(4,3) NOT NULL,
    "total_earnings" DECIMAL(10,2),
    "net_profit" DECIMAL(10,2),
    "report_data" JSONB NOT NULL,
    "pdf_url" TEXT,
    "csv_url" TEXT,
    "status" "ReportStatus" NOT NULL DEFAULT 'generating',
    "generated_at" TIMESTAMPTZ,
    "expires_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "mileage_reports_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tax_years" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "tax_year" INTEGER NOT NULL,
    "filing_status" "FilingStatus",
    "irs_standard_rate" DECIMAL(4,3) NOT NULL,
    "irs_medical_rate" DECIMAL(4,3) NOT NULL,
    "irs_charity_rate" DECIMAL(4,3) NOT NULL,
    "total_business_miles" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "total_medical_miles" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "total_charity_miles" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "actual_expenses" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "recommended_method" VARCHAR(20),
    "notes" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tax_years_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_settings" (
    "user_id" UUID NOT NULL,
    "auto_tracking_enabled" BOOLEAN NOT NULL DEFAULT true,
    "auto_tracking_sensitivity" "TrackingSensitivity" NOT NULL DEFAULT 'balanced',
    "motion_activity_required" BOOLEAN NOT NULL DEFAULT true,
    "minimum_trip_distance_meters" INTEGER NOT NULL DEFAULT 200,
    "minimum_trip_duration_seconds" INTEGER NOT NULL DEFAULT 120,
    "stop_detection_delay_seconds" INTEGER NOT NULL DEFAULT 180,
    "default_trip_category" "TripCategory" NOT NULL DEFAULT 'business',
    "work_hours_start" TIME,
    "work_hours_end" TIME,
    "work_days" INTEGER[] DEFAULT ARRAY[1, 2, 3, 4, 5]::INTEGER[],
    "classify_work_hours_business" BOOLEAN NOT NULL DEFAULT true,
    "distance_unit" "DistanceUnit" NOT NULL DEFAULT 'miles',
    "currency" VARCHAR(3) NOT NULL DEFAULT 'USD',
    "fuel_unit" "FuelUnit" NOT NULL DEFAULT 'gallons',
    "fuel_economy_unit" "FuelEconomyUnit" NOT NULL DEFAULT 'mpg',
    "map_type" "MapType" NOT NULL DEFAULT 'standard',
    "navigation_voice_enabled" BOOLEAN NOT NULL DEFAULT true,
    "haptic_feedback_enabled" BOOLEAN NOT NULL DEFAULT true,
    "notification_trip_start" BOOLEAN NOT NULL DEFAULT true,
    "notification_trip_end" BOOLEAN NOT NULL DEFAULT true,
    "notification_weekly_summary" BOOLEAN NOT NULL DEFAULT true,
    "notification_maintenance_due" BOOLEAN NOT NULL DEFAULT true,
    "live_activity_enabled" BOOLEAN NOT NULL DEFAULT true,
    "widget_enabled" BOOLEAN NOT NULL DEFAULT true,
    "icloud_sync_enabled" BOOLEAN NOT NULL DEFAULT true,
    "background_app_refresh" BOOLEAN NOT NULL DEFAULT true,
    "low_power_mode_behavior" "LowPowerModeBehavior" NOT NULL DEFAULT 'reduce_accuracy',
    "data_export_format" "ExportFormat" NOT NULL DEFAULT 'pdf',
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_settings_pkey" PRIMARY KEY ("user_id")
);

-- CreateTable
CREATE TABLE "subscriptions" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "stripe_subscription_id" VARCHAR(255) NOT NULL,
    "stripe_price_id" VARCHAR(255) NOT NULL,
    "status" VARCHAR(50) NOT NULL,
    "current_period_start" TIMESTAMPTZ NOT NULL,
    "current_period_end" TIMESTAMPTZ NOT NULL,
    "cancel_at_period_end" BOOLEAN NOT NULL DEFAULT false,
    "canceled_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "audit_logs" (
    "id" UUID NOT NULL,
    "user_id" UUID,
    "action" VARCHAR(100) NOT NULL,
    "entity_type" VARCHAR(50) NOT NULL,
    "entity_id" UUID,
    "old_value" JSONB,
    "new_value" JSONB,
    "ip_address" INET,
    "user_agent" TEXT,
    "metadata" JSONB,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "job_records" (
    "id" UUID NOT NULL,
    "job_id" VARCHAR(255) NOT NULL,
    "queue_name" VARCHAR(100) NOT NULL,
    "job_type" VARCHAR(100) NOT NULL,
    "status" VARCHAR(50) NOT NULL,
    "payload" JSONB NOT NULL,
    "result" JSONB,
    "error" TEXT,
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "max_attempts" INTEGER NOT NULL DEFAULT 3,
    "started_at" TIMESTAMPTZ,
    "completed_at" TIMESTAMPTZ,
    "failed_at" TIMESTAMPTZ,
    "scheduled_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "job_records_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "users_stripe_customer_id_key" ON "users"("stripe_customer_id");

-- CreateIndex
CREATE INDEX "users_email_idx" ON "users"("email");

-- CreateIndex
CREATE INDEX "users_stripe_customer_id_idx" ON "users"("stripe_customer_id");

-- CreateIndex
CREATE INDEX "users_subscription_tier_idx" ON "users"("subscription_tier");

-- CreateIndex
CREATE INDEX "users_created_at_idx" ON "users"("created_at");

-- CreateIndex
CREATE INDEX "auth_providers_user_id_idx" ON "auth_providers"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "auth_providers_provider_provider_user_id_key" ON "auth_providers"("provider", "provider_user_id");

-- CreateIndex
CREATE INDEX "sessions_user_id_idx" ON "sessions"("user_id");

-- CreateIndex
CREATE INDEX "sessions_device_id_idx" ON "sessions"("device_id");

-- CreateIndex
CREATE INDEX "sessions_expires_at_idx" ON "sessions"("expires_at");

-- CreateIndex
CREATE INDEX "sessions_refresh_token_family_idx" ON "sessions"("refresh_token_family");

-- CreateIndex
CREATE INDEX "vehicles_user_id_idx" ON "vehicles"("user_id");

-- CreateIndex
CREATE INDEX "vehicles_is_primary_idx" ON "vehicles"("is_primary");

-- CreateIndex
CREATE INDEX "vehicles_is_active_idx" ON "vehicles"("is_active");

-- CreateIndex
CREATE INDEX "vehicle_maintenance_records_vehicle_id_idx" ON "vehicle_maintenance_records"("vehicle_id");

-- CreateIndex
CREATE INDEX "vehicle_maintenance_records_performed_at_idx" ON "vehicle_maintenance_records"("performed_at");

-- CreateIndex
CREATE INDEX "vehicle_maintenance_records_maintenance_type_idx" ON "vehicle_maintenance_records"("maintenance_type");

-- CreateIndex
CREATE INDEX "trips_user_id_idx" ON "trips"("user_id");

-- CreateIndex
CREATE INDEX "trips_vehicle_id_idx" ON "trips"("vehicle_id");

-- CreateIndex
CREATE INDEX "trips_status_idx" ON "trips"("status");

-- CreateIndex
CREATE INDEX "trips_category_idx" ON "trips"("category");

-- CreateIndex
CREATE INDEX "trips_start_time_idx" ON "trips"("start_time");

-- CreateIndex
CREATE INDEX "trips_end_time_idx" ON "trips"("end_time");

-- CreateIndex
CREATE INDEX "trips_created_at_idx" ON "trips"("created_at");

-- CreateIndex
CREATE INDEX "trip_waypoints_trip_id_sequence_number_idx" ON "trip_waypoints"("trip_id", "sequence_number");

-- CreateIndex
CREATE INDEX "trip_waypoints_trip_id_timestamp_idx" ON "trip_waypoints"("trip_id", "timestamp");

-- CreateIndex
CREATE INDEX "saved_locations_user_id_idx" ON "saved_locations"("user_id");

-- CreateIndex
CREATE INDEX "saved_locations_location_type_idx" ON "saved_locations"("location_type");

-- CreateIndex
CREATE INDEX "saved_locations_is_favorite_idx" ON "saved_locations"("is_favorite");

-- CreateIndex
CREATE INDEX "delivery_routes_user_id_idx" ON "delivery_routes"("user_id");

-- CreateIndex
CREATE INDEX "delivery_routes_status_idx" ON "delivery_routes"("status");

-- CreateIndex
CREATE INDEX "delivery_routes_scheduled_date_idx" ON "delivery_routes"("scheduled_date");

-- CreateIndex
CREATE INDEX "delivery_stops_route_id_idx" ON "delivery_stops"("route_id");

-- CreateIndex
CREATE INDEX "delivery_stops_status_idx" ON "delivery_stops"("status");

-- CreateIndex
CREATE INDEX "delivery_stops_sequence_optimized_idx" ON "delivery_stops"("sequence_optimized");

-- CreateIndex
CREATE INDEX "expenses_user_id_idx" ON "expenses"("user_id");

-- CreateIndex
CREATE INDEX "expenses_vehicle_id_idx" ON "expenses"("vehicle_id");

-- CreateIndex
CREATE INDEX "expenses_trip_id_idx" ON "expenses"("trip_id");

-- CreateIndex
CREATE INDEX "expenses_category_idx" ON "expenses"("category");

-- CreateIndex
CREATE INDEX "expenses_expense_date_idx" ON "expenses"("expense_date");

-- CreateIndex
CREATE UNIQUE INDEX "fuel_purchases_expense_id_key" ON "fuel_purchases"("expense_id");

-- CreateIndex
CREATE INDEX "fuel_purchases_vehicle_id_idx" ON "fuel_purchases"("vehicle_id");

-- CreateIndex
CREATE INDEX "fuel_purchases_created_at_idx" ON "fuel_purchases"("created_at");

-- CreateIndex
CREATE INDEX "earnings_user_id_idx" ON "earnings"("user_id");

-- CreateIndex
CREATE INDEX "earnings_platform_idx" ON "earnings"("platform");

-- CreateIndex
CREATE INDEX "earnings_earnings_date_idx" ON "earnings"("earnings_date");

-- CreateIndex
CREATE UNIQUE INDEX "earnings_user_id_platform_earnings_date_key" ON "earnings"("user_id", "platform", "earnings_date");

-- CreateIndex
CREATE INDEX "mileage_reports_user_id_idx" ON "mileage_reports"("user_id");

-- CreateIndex
CREATE INDEX "mileage_reports_report_type_idx" ON "mileage_reports"("report_type");

-- CreateIndex
CREATE INDEX "mileage_reports_status_idx" ON "mileage_reports"("status");

-- CreateIndex
CREATE INDEX "mileage_reports_created_at_idx" ON "mileage_reports"("created_at");

-- CreateIndex
CREATE INDEX "tax_years_user_id_idx" ON "tax_years"("user_id");

-- CreateIndex
CREATE INDEX "tax_years_tax_year_idx" ON "tax_years"("tax_year");

-- CreateIndex
CREATE UNIQUE INDEX "tax_years_user_id_tax_year_key" ON "tax_years"("user_id", "tax_year");

-- CreateIndex
CREATE UNIQUE INDEX "subscriptions_stripe_subscription_id_key" ON "subscriptions"("stripe_subscription_id");

-- CreateIndex
CREATE INDEX "subscriptions_user_id_idx" ON "subscriptions"("user_id");

-- CreateIndex
CREATE INDEX "subscriptions_status_idx" ON "subscriptions"("status");

-- CreateIndex
CREATE INDEX "audit_logs_user_id_idx" ON "audit_logs"("user_id");

-- CreateIndex
CREATE INDEX "audit_logs_action_idx" ON "audit_logs"("action");

-- CreateIndex
CREATE INDEX "audit_logs_entity_type_idx" ON "audit_logs"("entity_type");

-- CreateIndex
CREATE INDEX "audit_logs_created_at_idx" ON "audit_logs"("created_at");

-- CreateIndex
CREATE UNIQUE INDEX "job_records_job_id_key" ON "job_records"("job_id");

-- CreateIndex
CREATE INDEX "job_records_queue_name_idx" ON "job_records"("queue_name");

-- CreateIndex
CREATE INDEX "job_records_job_type_idx" ON "job_records"("job_type");

-- CreateIndex
CREATE INDEX "job_records_status_idx" ON "job_records"("status");

-- CreateIndex
CREATE INDEX "job_records_created_at_idx" ON "job_records"("created_at");

-- AddForeignKey
ALTER TABLE "auth_providers" ADD CONSTRAINT "auth_providers_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vehicles" ADD CONSTRAINT "vehicles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vehicle_maintenance_records" ADD CONSTRAINT "vehicle_maintenance_records_vehicle_id_fkey" FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trips" ADD CONSTRAINT "trips_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trips" ADD CONSTRAINT "trips_vehicle_id_fkey" FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trip_waypoints" ADD CONSTRAINT "trip_waypoints_trip_id_fkey" FOREIGN KEY ("trip_id") REFERENCES "trips"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "saved_locations" ADD CONSTRAINT "saved_locations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "delivery_routes" ADD CONSTRAINT "delivery_routes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "delivery_routes" ADD CONSTRAINT "delivery_routes_start_location_id_fkey" FOREIGN KEY ("start_location_id") REFERENCES "saved_locations"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "delivery_routes" ADD CONSTRAINT "delivery_routes_end_location_id_fkey" FOREIGN KEY ("end_location_id") REFERENCES "saved_locations"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "delivery_stops" ADD CONSTRAINT "delivery_stops_route_id_fkey" FOREIGN KEY ("route_id") REFERENCES "delivery_routes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "delivery_stops" ADD CONSTRAINT "delivery_stops_location_id_fkey" FOREIGN KEY ("location_id") REFERENCES "saved_locations"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "expenses" ADD CONSTRAINT "expenses_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "expenses" ADD CONSTRAINT "expenses_vehicle_id_fkey" FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "expenses" ADD CONSTRAINT "expenses_trip_id_fkey" FOREIGN KEY ("trip_id") REFERENCES "trips"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "fuel_purchases" ADD CONSTRAINT "fuel_purchases_expense_id_fkey" FOREIGN KEY ("expense_id") REFERENCES "expenses"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "fuel_purchases" ADD CONSTRAINT "fuel_purchases_vehicle_id_fkey" FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "earnings" ADD CONSTRAINT "earnings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mileage_reports" ADD CONSTRAINT "mileage_reports_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tax_years" ADD CONSTRAINT "tax_years_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_settings" ADD CONSTRAINT "user_settings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
