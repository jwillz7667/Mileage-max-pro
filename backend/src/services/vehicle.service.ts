import { prisma } from '../config/database.js';
import { vehicleLogger } from '../utils/logger.js';
import { NotFoundError, QuotaExceededError } from '../utils/errors.js';
import type {
  CreateVehicleInput,
  UpdateVehicleInput,
  CreateMaintenanceRecordInput,
  VehicleFilterInput,
  PaginatedResponse,
} from '../types/index.js';
import type { Vehicle, VehicleMaintenanceRecord, SubscriptionTier, Prisma, FuelType } from '@prisma/client';

const VEHICLE_LIMITS: Record<SubscriptionTier, number> = {
  free: 1,
  pro: 5,
  business: 50,
  enterprise: 1000,
};

export async function createVehicle(
  userId: string,
  subscriptionTier: SubscriptionTier,
  input: CreateVehicleInput
): Promise<Vehicle> {
  // Check vehicle limit
  const currentCount = await prisma.vehicle.count({
    where: { userId, deletedAt: null },
  });

  const limit = VEHICLE_LIMITS[subscriptionTier];
  if (currentCount >= limit) {
    throw new QuotaExceededError('vehicles', limit);
  }

  // If this is set as primary, unset other primary vehicles
  if (input.isPrimary) {
    await prisma.vehicle.updateMany({
      where: { userId, isPrimary: true },
      data: { isPrimary: false },
    });
  }

  // If this is the first vehicle, make it primary
  const shouldBePrimary = input.isPrimary || currentCount === 0;

  const vehicle = await prisma.vehicle.create({
    data: {
      userId,
      nickname: input.nickname,
      make: input.make,
      model: input.model,
      year: input.year,
      color: input.color,
      licensePlate: input.licensePlate,
      licenseState: input.licenseState,
      vin: input.vin,
      fuelType: input.fuelType ?? 'gasoline',
      fuelEconomyCity: input.fuelEconomyCity,
      fuelEconomyHighway: input.fuelEconomyHighway,
      fuelTankCapacity: input.fuelTankCapacity,
      odometerReading: input.odometerReading ?? 0,
      isPrimary: shouldBePrimary,
      photoUrl: input.photoUrl,
      insuranceProvider: input.insuranceProvider,
      insurancePolicyNumber: input.insurancePolicyNumber,
      insuranceExpiresAt: input.insuranceExpiresAt ? new Date(input.insuranceExpiresAt) : null,
      registrationExpiresAt: input.registrationExpiresAt ? new Date(input.registrationExpiresAt) : null,
    },
  });

  vehicleLogger.info({ vehicleId: vehicle.id, userId }, 'Vehicle created');

  return vehicle;
}

export async function getVehicle(userId: string, vehicleId: string): Promise<Vehicle & { maintenanceRecords: VehicleMaintenanceRecord[] }> {
  const vehicle = await prisma.vehicle.findFirst({
    where: {
      id: vehicleId,
      userId,
      deletedAt: null,
    },
    include: {
      maintenanceRecords: {
        orderBy: { performedAt: 'desc' },
        take: 20,
      },
    },
  });

  if (!vehicle) {
    throw new NotFoundError('Vehicle');
  }

  return vehicle;
}

export async function updateVehicle(
  userId: string,
  vehicleId: string,
  input: UpdateVehicleInput
): Promise<Vehicle> {
  const vehicle = await prisma.vehicle.findFirst({
    where: {
      id: vehicleId,
      userId,
      deletedAt: null,
    },
  });

  if (!vehicle) {
    throw new NotFoundError('Vehicle');
  }

  // If setting as primary, unset other primary vehicles
  if (input.isPrimary && !vehicle.isPrimary) {
    await prisma.vehicle.updateMany({
      where: { userId, isPrimary: true, id: { not: vehicleId } },
      data: { isPrimary: false },
    });
  }

  const updateData: Prisma.VehicleUpdateInput = {};

  if (input.nickname !== undefined) updateData.nickname = input.nickname;
  if (input.make !== undefined) updateData.make = input.make;
  if (input.model !== undefined) updateData.model = input.model;
  if (input.year !== undefined) updateData.year = input.year;
  if (input.color !== undefined) updateData.color = input.color;
  if (input.licensePlate !== undefined) updateData.licensePlate = input.licensePlate;
  if (input.licenseState !== undefined) updateData.licenseState = input.licenseState;
  if (input.vin !== undefined) updateData.vin = input.vin;
  if (input.fuelType !== undefined) updateData.fuelType = input.fuelType;
  if (input.fuelEconomyCity !== undefined) updateData.fuelEconomyCity = input.fuelEconomyCity;
  if (input.fuelEconomyHighway !== undefined) updateData.fuelEconomyHighway = input.fuelEconomyHighway;
  if (input.fuelTankCapacity !== undefined) updateData.fuelTankCapacity = input.fuelTankCapacity;
  if (input.odometerReading !== undefined) {
    updateData.odometerReading = input.odometerReading;
    updateData.odometerUpdatedAt = new Date();
  }
  if (input.isPrimary !== undefined) updateData.isPrimary = input.isPrimary;
  if (input.isActive !== undefined) updateData.isActive = input.isActive;
  if (input.photoUrl !== undefined) updateData.photoUrl = input.photoUrl;
  if (input.insuranceProvider !== undefined) updateData.insuranceProvider = input.insuranceProvider;
  if (input.insurancePolicyNumber !== undefined) updateData.insurancePolicyNumber = input.insurancePolicyNumber;
  if (input.insuranceExpiresAt !== undefined) {
    updateData.insuranceExpiresAt = input.insuranceExpiresAt ? new Date(input.insuranceExpiresAt) : null;
  }
  if (input.registrationExpiresAt !== undefined) {
    updateData.registrationExpiresAt = input.registrationExpiresAt ? new Date(input.registrationExpiresAt) : null;
  }

  const updated = await prisma.vehicle.update({
    where: { id: vehicleId },
    data: updateData,
  });

  vehicleLogger.info({ vehicleId, userId }, 'Vehicle updated');

  return updated;
}

export async function deleteVehicle(userId: string, vehicleId: string): Promise<void> {
  const vehicle = await prisma.vehicle.findFirst({
    where: {
      id: vehicleId,
      userId,
      deletedAt: null,
    },
  });

  if (!vehicle) {
    throw new NotFoundError('Vehicle');
  }

  await prisma.vehicle.update({
    where: { id: vehicleId },
    data: { deletedAt: new Date(), isActive: false },
  });

  // If this was primary, set another vehicle as primary
  if (vehicle.isPrimary) {
    const nextVehicle = await prisma.vehicle.findFirst({
      where: { userId, deletedAt: null, id: { not: vehicleId } },
      orderBy: { createdAt: 'desc' },
    });

    if (nextVehicle) {
      await prisma.vehicle.update({
        where: { id: nextVehicle.id },
        data: { isPrimary: true },
      });
    }
  }

  vehicleLogger.info({ vehicleId, userId }, 'Vehicle deleted');
}

export async function listVehicles(
  userId: string,
  filters: VehicleFilterInput
): Promise<PaginatedResponse<Vehicle>> {
  const { page, perPage, isActive, fuelType, sort } = filters;
  const offset = (page - 1) * perPage;

  const where: Prisma.VehicleWhereInput = {
    userId,
    deletedAt: null,
  };

  if (isActive !== undefined) where.isActive = isActive;
  if (fuelType) where.fuelType = fuelType as FuelType;

  const sortField = sort.startsWith('-') ? sort.slice(1) : sort;
  const sortOrder = sort.startsWith('-') ? 'desc' : 'asc';

  const orderBy: Prisma.VehicleOrderByWithRelationInput = {};
  if (sortField === 'createdAt') orderBy.createdAt = sortOrder;
  else if (sortField === 'nickname') orderBy.nickname = sortOrder;
  else if (sortField === 'year') orderBy.year = sortOrder;
  else orderBy.createdAt = 'desc';

  const [vehicles, total] = await Promise.all([
    prisma.vehicle.findMany({
      where,
      orderBy: [{ isPrimary: 'desc' }, orderBy],
      skip: offset,
      take: perPage,
    }),
    prisma.vehicle.count({ where }),
  ]);

  const totalPages = Math.ceil(total / perPage);

  return {
    data: vehicles,
    pagination: {
      page,
      perPage,
      total,
      totalPages,
      hasNext: page < totalPages,
      hasPrev: page > 1,
    },
  };
}

export async function addMaintenanceRecord(
  userId: string,
  vehicleId: string,
  input: CreateMaintenanceRecordInput
): Promise<VehicleMaintenanceRecord> {
  const vehicle = await prisma.vehicle.findFirst({
    where: {
      id: vehicleId,
      userId,
      deletedAt: null,
    },
  });

  if (!vehicle) {
    throw new NotFoundError('Vehicle');
  }

  const record = await prisma.vehicleMaintenanceRecord.create({
    data: {
      vehicleId,
      maintenanceType: input.maintenanceType as any,
      description: input.description,
      performedAt: new Date(input.performedAt),
      odometerAtService: input.odometerAtService,
      cost: input.cost,
      currency: input.currency ?? 'USD',
      serviceProvider: input.serviceProvider,
      serviceLocation: input.serviceLocation,
      receiptUrl: input.receiptUrl,
      nextServiceDate: input.nextServiceDate ? new Date(input.nextServiceDate) : null,
      nextServiceOdometer: input.nextServiceOdometer,
      notes: input.notes,
    },
  });

  // Update vehicle odometer if service odometer is higher
  if (input.odometerAtService > vehicle.odometerReading) {
    await prisma.vehicle.update({
      where: { id: vehicleId },
      data: {
        odometerReading: input.odometerAtService,
        odometerUpdatedAt: new Date(),
      },
    });
  }

  vehicleLogger.info({ vehicleId, recordId: record.id, type: input.maintenanceType }, 'Maintenance record added');

  return record;
}

export async function getVehicleStats(userId: string, vehicleId: string): Promise<{
  totalTrips: number;
  totalMiles: number;
  totalExpenses: number;
  fuelExpenses: number;
  maintenanceExpenses: number;
  averageMpg: number | null;
}> {
  const vehicle = await prisma.vehicle.findFirst({
    where: {
      id: vehicleId,
      userId,
      deletedAt: null,
    },
  });

  if (!vehicle) {
    throw new NotFoundError('Vehicle');
  }

  const [tripStats, expenseStats, fuelStats] = await Promise.all([
    prisma.trip.aggregate({
      where: { vehicleId, deletedAt: null },
      _count: true,
      _sum: { distanceMeters: true },
    }),
    prisma.expense.aggregate({
      where: { vehicleId, deletedAt: null },
      _sum: { amount: true },
    }),
    prisma.fuelPurchase.aggregate({
      where: { vehicleId },
      _sum: { gallons: true, totalCost: true },
      _avg: { mpgCalculated: true },
    }),
  ]);

  const maintenanceExpenses = await prisma.vehicleMaintenanceRecord.aggregate({
    where: { vehicleId },
    _sum: { cost: true },
  });

  return {
    totalTrips: tripStats._count,
    totalMiles: (tripStats._sum.distanceMeters ?? 0) * 0.000621371,
    totalExpenses: Number(expenseStats._sum.amount ?? 0),
    fuelExpenses: Number(fuelStats._sum.totalCost ?? 0),
    maintenanceExpenses: Number(maintenanceExpenses._sum.cost ?? 0),
    averageMpg: fuelStats._avg.mpgCalculated ? Number(fuelStats._avg.mpgCalculated) : null,
  };
}
