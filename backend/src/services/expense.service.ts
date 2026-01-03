import { prisma } from '../config/database.js';
import { expenseLogger } from '../utils/logger.js';
import { NotFoundError } from '../utils/errors.js';
import type {
  CreateExpenseInput,
  UpdateExpenseInput,
  CreateFuelPurchaseInput,
  ExpenseFilterInput,
  PaginatedResponse,
} from '../types/index.js';
import type { Expense, FuelPurchase, Prisma } from '@prisma/client';

export async function createExpense(
  userId: string,
  input: CreateExpenseInput
): Promise<Expense> {
  // Verify vehicle ownership if provided
  if (input.vehicleId) {
    const vehicle = await prisma.vehicle.findFirst({
      where: { id: input.vehicleId, userId, deletedAt: null },
    });
    if (!vehicle) throw new NotFoundError('Vehicle');
  }

  // Verify trip ownership if provided
  if (input.tripId) {
    const trip = await prisma.trip.findFirst({
      where: { id: input.tripId, userId, deletedAt: null },
    });
    if (!trip) throw new NotFoundError('Trip');
  }

  const expense = await prisma.expense.create({
    data: {
      userId,
      vehicleId: input.vehicleId,
      tripId: input.tripId,
      category: input.category as any,
      subcategory: input.subcategory,
      amount: input.amount,
      currency: input.currency ?? 'USD',
      expenseDate: new Date(input.expenseDate),
      vendorName: input.vendorName,
      vendorAddress: input.vendorAddress,
      vendorLatitude: input.vendorLatitude,
      vendorLongitude: input.vendorLongitude,
      description: input.description,
      paymentMethod: input.paymentMethod ?? 'card',
      isReimbursable: input.isReimbursable ?? false,
      isTaxDeductible: input.isTaxDeductible ?? false,
      taxCategory: input.taxCategory,
      notes: input.notes,
    },
  });

  expenseLogger.info('Expense created', { expenseId: expense.id, userId, category: input.category });

  return expense;
}

export async function getExpense(userId: string, expenseId: string): Promise<Expense & { fuelPurchase: FuelPurchase | null }> {
  const expense = await prisma.expense.findFirst({
    where: {
      id: expenseId,
      userId,
      deletedAt: null,
    },
    include: {
      fuelPurchase: true,
      vehicle: {
        select: { id: true, nickname: true, make: true, model: true },
      },
      trip: {
        select: { id: true, startAddress: true, endAddress: true, startTime: true },
      },
    },
  });

  if (!expense) {
    throw new NotFoundError('Expense');
  }

  return expense;
}

export async function updateExpense(
  userId: string,
  expenseId: string,
  input: UpdateExpenseInput
): Promise<Expense> {
  const expense = await prisma.expense.findFirst({
    where: { id: expenseId, userId, deletedAt: null },
  });

  if (!expense) {
    throw new NotFoundError('Expense');
  }

  const updateData: Prisma.ExpenseUpdateInput = {};

  if (input.vehicleId !== undefined) {
    if (input.vehicleId) {
      const vehicle = await prisma.vehicle.findFirst({
        where: { id: input.vehicleId, userId, deletedAt: null },
      });
      if (!vehicle) throw new NotFoundError('Vehicle');
      updateData.vehicle = { connect: { id: input.vehicleId } };
    } else {
      updateData.vehicle = { disconnect: true };
    }
  }

  if (input.category !== undefined) updateData.category = input.category as any;
  if (input.subcategory !== undefined) updateData.subcategory = input.subcategory;
  if (input.amount !== undefined) updateData.amount = input.amount;
  if (input.currency !== undefined) updateData.currency = input.currency;
  if (input.expenseDate !== undefined) updateData.expenseDate = new Date(input.expenseDate);
  if (input.vendorName !== undefined) updateData.vendorName = input.vendorName;
  if (input.vendorAddress !== undefined) updateData.vendorAddress = input.vendorAddress;
  if (input.description !== undefined) updateData.description = input.description;
  if (input.paymentMethod !== undefined) updateData.paymentMethod = input.paymentMethod;
  if (input.isReimbursable !== undefined) updateData.isReimbursable = input.isReimbursable;
  if (input.reimbursementStatus !== undefined) updateData.reimbursementStatus = input.reimbursementStatus;
  if (input.receiptUrl !== undefined) updateData.receiptUrl = input.receiptUrl;
  if (input.isTaxDeductible !== undefined) updateData.isTaxDeductible = input.isTaxDeductible;
  if (input.taxCategory !== undefined) updateData.taxCategory = input.taxCategory;
  if (input.notes !== undefined) updateData.notes = input.notes;

  const updated = await prisma.expense.update({
    where: { id: expenseId },
    data: updateData,
  });

  expenseLogger.info('Expense updated', { expenseId, userId });

  return updated;
}

export async function deleteExpense(userId: string, expenseId: string): Promise<void> {
  const expense = await prisma.expense.findFirst({
    where: { id: expenseId, userId, deletedAt: null },
  });

  if (!expense) {
    throw new NotFoundError('Expense');
  }

  await prisma.expense.update({
    where: { id: expenseId },
    data: { deletedAt: new Date() },
  });

  expenseLogger.info('Expense deleted', { expenseId, userId });
}

export async function listExpenses(
  userId: string,
  filters: ExpenseFilterInput
): Promise<PaginatedResponse<Expense>> {
  const { page, perPage, category, vehicleId, tripId, startDate, endDate, minAmount, maxAmount, isReimbursable, isTaxDeductible, sort } = filters;
  const offset = (page - 1) * perPage;

  const where: Prisma.ExpenseWhereInput = {
    userId,
    deletedAt: null,
  };

  if (category) where.category = category as any;
  if (vehicleId) where.vehicleId = vehicleId;
  if (tripId) where.tripId = tripId;
  if (isReimbursable !== undefined) where.isReimbursable = isReimbursable;
  if (isTaxDeductible !== undefined) where.isTaxDeductible = isTaxDeductible;

  if (startDate || endDate) {
    where.expenseDate = {};
    if (startDate) where.expenseDate.gte = new Date(startDate);
    if (endDate) where.expenseDate.lte = new Date(endDate);
  }

  if (minAmount || maxAmount) {
    where.amount = {};
    if (minAmount) where.amount.gte = minAmount;
    if (maxAmount) where.amount.lte = maxAmount;
  }

  const sortField = sort.startsWith('-') ? sort.slice(1) : sort;
  const sortOrder = sort.startsWith('-') ? 'desc' : 'asc';

  const orderBy: Prisma.ExpenseOrderByWithRelationInput = {};
  if (sortField === 'expenseDate') orderBy.expenseDate = sortOrder;
  else if (sortField === 'amount') orderBy.amount = sortOrder;
  else if (sortField === 'category') orderBy.category = sortOrder;
  else orderBy.expenseDate = 'desc';

  const [expenses, total] = await Promise.all([
    prisma.expense.findMany({
      where,
      orderBy,
      skip: offset,
      take: perPage,
      include: {
        vehicle: {
          select: { id: true, nickname: true },
        },
      },
    }),
    prisma.expense.count({ where }),
  ]);

  const totalPages = Math.ceil(total / perPage);

  return {
    data: expenses,
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

export async function createFuelPurchase(
  userId: string,
  input: CreateFuelPurchaseInput
): Promise<{ expense: Expense; fuelPurchase: FuelPurchase }> {
  // Verify vehicle ownership
  const vehicle = await prisma.vehicle.findFirst({
    where: { id: input.vehicleId, userId, deletedAt: null },
  });

  if (!vehicle) {
    throw new NotFoundError('Vehicle');
  }

  const totalCost = input.gallons * input.pricePerGallon;

  // Calculate MPG if we have previous fuel purchase with full tank
  let mpgCalculated: number | null = null;

  if (input.isFullTank && input.odometerReading) {
    const lastFill = await prisma.fuelPurchase.findFirst({
      where: {
        vehicleId: input.vehicleId,
        isFullTank: true,
        odometerReading: { not: null },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (lastFill && lastFill.odometerReading) {
      const milesDriven = input.odometerReading - lastFill.odometerReading;
      if (milesDriven > 0) {
        mpgCalculated = milesDriven / input.gallons;
      }
    }
  }

  // Create expense and fuel purchase in transaction
  const result = await prisma.$transaction(async (tx) => {
    const expense = await tx.expense.create({
      data: {
        userId,
        vehicleId: input.vehicleId,
        category: 'fuel',
        amount: totalCost,
        currency: 'USD',
        expenseDate: new Date(input.expenseDate),
        vendorName: input.stationName,
        vendorAddress: input.stationAddress,
        vendorLatitude: input.stationLatitude,
        vendorLongitude: input.stationLongitude,
        paymentMethod: input.paymentMethod ?? 'card',
        isTaxDeductible: true,
        taxCategory: 'Vehicle Fuel',
        notes: input.notes,
      },
    });

    const fuelPurchase = await tx.fuelPurchase.create({
      data: {
        expenseId: expense.id,
        vehicleId: input.vehicleId,
        fuelType: input.fuelType as any,
        gallons: input.gallons,
        pricePerGallon: input.pricePerGallon,
        totalCost,
        odometerReading: input.odometerReading,
        isFullTank: input.isFullTank ?? true,
        stationName: input.stationName,
        stationBrand: input.stationBrand,
        stationAddress: input.stationAddress,
        stationLatitude: input.stationLatitude,
        stationLongitude: input.stationLongitude,
        mpgCalculated,
      },
    });

    // Update vehicle odometer if needed
    if (input.odometerReading && input.odometerReading > vehicle.odometerReading) {
      await tx.vehicle.update({
        where: { id: input.vehicleId },
        data: {
          odometerReading: input.odometerReading,
          odometerUpdatedAt: new Date(),
        },
      });
    }

    return { expense, fuelPurchase };
  });

  expenseLogger.info('Fuel purchase created', {
    expenseId: result.expense.id,
    vehicleId: input.vehicleId,
    gallons: input.gallons,
    mpg: mpgCalculated,
  });

  return result;
}
