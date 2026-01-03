import type { Request } from 'express';
import type { User, Session, SubscriptionTier } from '@prisma/client';

// ============================================================================
// Auth Types
// ============================================================================

export interface AuthenticatedUser {
  id: string;
  email: string;
  fullName: string;
  avatarUrl: string | null;
  subscriptionTier: SubscriptionTier;
  timezone: string;
  locale: string;
}

export interface AuthenticatedRequest extends Request {
  user: AuthenticatedUser;
  session: {
    id: string;
    deviceId: string;
  };
}

export interface TokenPayload {
  sub: string;
  email: string;
  tier: SubscriptionTier;
  iat: number;
  exp: number;
  jti: string;
}

export interface RefreshTokenPayload {
  sub: string;
  sid: string;
  did: string;
  fam: string;
  iat: number;
  exp: number;
  jti: string;
}

export interface AppleAuthRequest {
  identityToken: string;
  authorizationCode: string;
  user?: {
    email?: string;
    name?: {
      firstName?: string;
      lastName?: string;
    };
  };
  deviceId: string;
  deviceName?: string;
  deviceModel?: string;
  osVersion?: string;
  appVersion?: string;
  pushToken?: string;
}

export interface GoogleAuthRequest {
  idToken: string;
  accessToken: string;
  deviceId: string;
  deviceName?: string;
  deviceModel?: string;
  osVersion?: string;
  appVersion?: string;
  pushToken?: string;
}

export interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  tokenType: 'Bearer';
  expiresIn: number;
  user: UserProfile;
  isNewUser: boolean;
}

export interface UserProfile {
  id: string;
  email: string;
  emailVerified: boolean;
  fullName: string;
  avatarUrl: string | null;
  timezone: string;
  locale: string;
  subscriptionTier: SubscriptionTier;
  subscriptionStatus: string;
  createdAt: string;
}

// ============================================================================
// API Types
// ============================================================================

export interface PaginationParams {
  page: number;
  perPage: number;
  offset: number;
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    perPage: number;
    total: number;
    totalPages: number;
    hasNext: boolean;
    hasPrev: boolean;
  };
}

export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: ApiError;
  meta?: Record<string, unknown>;
}

export interface ApiError {
  code: string;
  message: string;
  details?: Record<string, unknown>;
  stack?: string;
}

// ============================================================================
// Trip Types
// ============================================================================

export interface CreateTripRequest {
  vehicleId?: string;
  startLatitude: number;
  startLongitude: number;
  startTime: string;
  detectionMethod?: 'automatic' | 'manual' | 'widget' | 'shortcut';
}

export interface UpdateTripRequest {
  category?: 'business' | 'personal' | 'medical' | 'charity' | 'moving' | 'commute';
  purpose?: string;
  clientName?: string;
  projectName?: string;
  tags?: string[];
  vehicleId?: string;
  endLatitude?: number;
  endLongitude?: number;
  endTime?: string;
  userVerified?: boolean;
  notes?: string;
}

export interface CompleteTripRequest {
  endLatitude: number;
  endLongitude: number;
  endTime: string;
  finalWaypoints?: WaypointInput[];
}

export interface WaypointInput {
  latitude: number;
  longitude: number;
  timestamp: string;
  speedMps?: number;
  heading?: number;
  altitudeMeters?: number;
  horizontalAccuracy?: number;
  verticalAccuracy?: number;
}

export interface TripFilters {
  vehicleId?: string;
  category?: string;
  startDate?: string;
  endDate?: string;
  minDistance?: number;
  status?: string;
}

// ============================================================================
// Vehicle Types
// ============================================================================

export interface CreateVehicleRequest {
  nickname: string;
  make: string;
  model: string;
  year: number;
  color?: string;
  licensePlate?: string;
  licenseState?: string;
  vin?: string;
  fuelType?: 'gasoline' | 'diesel' | 'electric' | 'hybrid' | 'plugin_hybrid';
  fuelEconomyCity?: number;
  fuelEconomyHighway?: number;
  fuelTankCapacity?: number;
  odometerReading?: number;
  isPrimary?: boolean;
  photoUrl?: string;
  insuranceProvider?: string;
  insurancePolicyNumber?: string;
  insuranceExpiresAt?: string;
  registrationExpiresAt?: string;
}

export interface UpdateVehicleRequest extends Partial<CreateVehicleRequest> {
  isActive?: boolean;
}

export interface MaintenanceRecordRequest {
  maintenanceType: string;
  description?: string;
  performedAt: string;
  odometerAtService: number;
  cost?: number;
  currency?: string;
  serviceProvider?: string;
  serviceLocation?: string;
  receiptUrl?: string;
  nextServiceDate?: string;
  nextServiceOdometer?: number;
  notes?: string;
}

// ============================================================================
// Route Types
// ============================================================================

export interface CreateRouteRequest {
  name?: string;
  scheduledDate?: string;
  scheduledStartTime?: string;
  startLocationId?: string;
  endLocationId?: string;
  returnToStart?: boolean;
  optimizationMode?: 'fastest' | 'shortest' | 'balanced';
  stops: CreateStopRequest[];
}

export interface CreateStopRequest {
  address: string;
  latitude: number;
  longitude: number;
  locationId?: string;
  recipientName?: string;
  recipientPhone?: string;
  deliveryInstructions?: string;
  timeWindowStart?: string;
  timeWindowEnd?: string;
  priority?: number;
  serviceDurationSeconds?: number;
}

export interface UpdateStopRequest {
  status?: 'pending' | 'in_transit' | 'arrived' | 'completed' | 'failed' | 'skipped';
  proofOfDeliveryUrl?: string;
  signatureUrl?: string;
  deliveryNotes?: string;
  failureReason?: 'not_home' | 'wrong_address' | 'refused' | 'damaged' | 'other';
  failureNotes?: string;
}

// ============================================================================
// Expense Types
// ============================================================================

export interface CreateExpenseRequest {
  vehicleId?: string;
  tripId?: string;
  category: string;
  subcategory?: string;
  amount: number;
  currency?: string;
  expenseDate: string;
  vendorName?: string;
  vendorAddress?: string;
  vendorLatitude?: number;
  vendorLongitude?: number;
  description?: string;
  paymentMethod?: 'cash' | 'card' | 'check' | 'app' | 'other';
  isReimbursable?: boolean;
  isTaxDeductible?: boolean;
  taxCategory?: string;
  notes?: string;
}

export interface CreateFuelPurchaseRequest extends CreateExpenseRequest {
  fuelType: 'gasoline' | 'diesel' | 'electric' | 'hybrid' | 'plugin_hybrid';
  gallons: number;
  pricePerGallon: number;
  odometerReading?: number;
  isFullTank?: boolean;
  stationName?: string;
  stationBrand?: string;
}

// ============================================================================
// Report Types
// ============================================================================

export interface CreateReportRequest {
  reportType: 'weekly' | 'monthly' | 'quarterly' | 'annual' | 'custom' | 'irs_log';
  dateRangeStart: string;
  dateRangeEnd: string;
  vehicleIds?: string[];
  categories?: string[];
  includeExpenses?: boolean;
  includeEarnings?: boolean;
  format?: 'pdf' | 'csv' | 'both';
}

export interface ReportData {
  summary: {
    totalTrips: number;
    totalMiles: number;
    businessMiles: number;
    personalMiles: number;
    otherMiles: number;
    totalExpenses: number;
    fuelExpenses: number;
    maintenanceExpenses: number;
    otherExpenses: number;
    mileageDeduction: number;
    totalEarnings?: number;
    netProfit?: number;
  };
  tripsByCategory: Record<string, { count: number; miles: number }>;
  tripsByVehicle: Record<string, { count: number; miles: number }>;
  tripsByDay: Array<{ date: string; count: number; miles: number }>;
  expensesByCategory: Record<string, number>;
  trips: Array<{
    id: string;
    date: string;
    startAddress: string;
    endAddress: string;
    distance: number;
    category: string;
    purpose: string;
  }>;
}

// ============================================================================
// Analytics Types
// ============================================================================

export interface DashboardData {
  period: string;
  totalTrips: number;
  totalMiles: number;
  businessMiles: number;
  personalMiles: number;
  totalExpenses: number;
  fuelCosts: number;
  estimatedDeduction: number;
  avgDailyMiles: number;
  mostUsedVehicle: {
    id: string;
    nickname: string;
    tripCount: number;
  } | null;
  tripsByCategory: Record<string, number>;
  weeklyTrend: Array<{
    date: string;
    trips: number;
    miles: number;
  }>;
}

export interface TaxSummary {
  taxYear: number;
  businessMiles: number;
  medicalMiles: number;
  charityMiles: number;
  irsBusinessRate: number;
  irsMedicalRate: number;
  irsCharityRate: number;
  standardDeduction: number;
  actualExpenses: number;
  recommendedMethod: 'standard' | 'actual';
  savingsAmount: number;
}

// ============================================================================
// Settings Types
// ============================================================================

export interface UserSettingsUpdate {
  autoTrackingEnabled?: boolean;
  autoTrackingSensitivity?: 'low' | 'balanced' | 'high';
  motionActivityRequired?: boolean;
  minimumTripDistanceMeters?: number;
  minimumTripDurationSeconds?: number;
  stopDetectionDelaySeconds?: number;
  defaultTripCategory?: string;
  workHoursStart?: string;
  workHoursEnd?: string;
  workDays?: number[];
  classifyWorkHoursBusiness?: boolean;
  distanceUnit?: 'miles' | 'kilometers';
  currency?: string;
  fuelUnit?: 'gallons' | 'liters';
  fuelEconomyUnit?: 'mpg' | 'l100km' | 'kml';
  mapType?: 'standard' | 'satellite' | 'hybrid';
  navigationVoiceEnabled?: boolean;
  hapticFeedbackEnabled?: boolean;
  notificationTripStart?: boolean;
  notificationTripEnd?: boolean;
  notificationWeeklySummary?: boolean;
  notificationMaintenanceDue?: boolean;
  liveActivityEnabled?: boolean;
  widgetEnabled?: boolean;
  icloudSyncEnabled?: boolean;
  backgroundAppRefresh?: boolean;
  lowPowerModeBehavior?: 'normal' | 'reduce_accuracy' | 'pause';
  dataExportFormat?: 'pdf' | 'csv' | 'both';
}

// ============================================================================
// Subscription Types
// ============================================================================

export interface SubscriptionInfo {
  tier: SubscriptionTier;
  status: string;
  currentPeriodStart?: string;
  currentPeriodEnd?: string;
  cancelAtPeriodEnd: boolean;
  trialEndsAt?: string;
}

export interface CreateSubscriptionRequest {
  priceId: string;
  paymentMethodId?: string;
}

// ============================================================================
// Job Types
// ============================================================================

export interface JobPayload {
  type: string;
  data: Record<string, unknown>;
  userId?: string;
  priority?: number;
}

export interface TripProcessingPayload {
  tripId: string;
  userId: string;
}

export interface ReportGenerationPayload {
  reportId: string;
  userId: string;
  format: 'pdf' | 'csv' | 'both';
}

export interface RouteOptimizationPayload {
  routeId: string;
  userId: string;
}

export interface NotificationPayload {
  userId: string;
  type: string;
  title: string;
  body: string;
  data?: Record<string, unknown>;
}
