import { z } from 'zod';

const fuelTypeSchema = z.enum([
  'gasoline',
  'diesel',
  'electric',
  'hybrid',
  'plugin_hybrid',
]);

const maintenanceTypeSchema = z.enum([
  'oil_change',
  'tire_rotation',
  'tire_replacement',
  'brake_service',
  'brake_replacement',
  'transmission_service',
  'coolant_flush',
  'air_filter',
  'cabin_filter',
  'spark_plugs',
  'battery_replacement',
  'wiper_blades',
  'alignment',
  'suspension',
  'inspection',
  'emissions_test',
  'registration_renewal',
  'insurance_renewal',
  'car_wash',
  'detail',
  'other',
]);

export const createVehicleSchema = z.object({
  nickname: z.string().min(1).max(100),
  make: z.string().min(1).max(100),
  model: z.string().min(1).max(100),
  year: z.number().int().min(1900).max(2100),
  color: z.string().max(50).optional().nullable(),
  licensePlate: z.string().max(20).optional().nullable(),
  licenseState: z.string().max(50).optional().nullable(),
  vin: z.string().length(17).optional().nullable(),
  fuelType: fuelTypeSchema.optional().default('gasoline'),
  fuelEconomyCity: z.number().positive().max(500).optional().nullable(),
  fuelEconomyHighway: z.number().positive().max(500).optional().nullable(),
  fuelTankCapacity: z.number().positive().max(500).optional().nullable(),
  odometerReading: z.number().int().min(0).max(10000000).optional().default(0),
  isPrimary: z.boolean().optional().default(false),
  photoUrl: z.string().url().optional().nullable(),
  insuranceProvider: z.string().max(255).optional().nullable(),
  insurancePolicyNumber: z.string().max(100).optional().nullable(),
  insuranceExpiresAt: z.string().datetime().optional().nullable(),
  registrationExpiresAt: z.string().datetime().optional().nullable(),
});

export const updateVehicleSchema = createVehicleSchema.partial().extend({
  isActive: z.boolean().optional(),
  odometerUpdatedAt: z.string().datetime().optional().nullable(),
});

export const createMaintenanceRecordSchema = z.object({
  maintenanceType: maintenanceTypeSchema,
  description: z.string().max(2000).optional().nullable(),
  performedAt: z.string().datetime(),
  odometerAtService: z.number().int().min(0).max(10000000),
  cost: z.number().positive().max(1000000).optional().nullable(),
  currency: z.string().length(3).optional().default('USD'),
  serviceProvider: z.string().max(255).optional().nullable(),
  serviceLocation: z.string().max(255).optional().nullable(),
  receiptUrl: z.string().url().optional().nullable(),
  nextServiceDate: z.string().datetime().optional().nullable(),
  nextServiceOdometer: z.number().int().min(0).max(10000000).optional().nullable(),
  notes: z.string().max(2000).optional().nullable(),
});

export const vehicleIdParamSchema = z.object({
  vehicleId: z.string().uuid(),
});

export const vehicleFilterSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  perPage: z.coerce.number().int().min(1).max(100).default(20),
  isActive: z.coerce.boolean().optional(),
  fuelType: fuelTypeSchema.optional(),
  sort: z.string().optional().default('-createdAt'),
});

export type CreateVehicleInput = z.infer<typeof createVehicleSchema>;
export type UpdateVehicleInput = z.infer<typeof updateVehicleSchema>;
export type CreateMaintenanceRecordInput = z.infer<typeof createMaintenanceRecordSchema>;
export type VehicleFilterInput = z.infer<typeof vehicleFilterSchema>;
