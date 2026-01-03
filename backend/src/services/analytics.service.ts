import { prisma } from '../config/database.js';
import type { DashboardData, TaxSummary, AnalyticsQueryInput, TaxSummaryQueryInput } from '../types/index.js';

const METERS_TO_MILES = 0.000621371;

// IRS Standard Mileage Rates
const IRS_RATES: Record<number, { business: number; medical: number; charity: number }> = {
  2024: { business: 0.67, medical: 0.21, charity: 0.14 },
  2025: { business: 0.70, medical: 0.22, charity: 0.14 },
  2026: { business: 0.70, medical: 0.22, charity: 0.14 },
};

function getDateRange(period: string): { start: Date; end: Date } {
  const now = new Date();
  const end = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);
  let start: Date;

  switch (period) {
    case 'today':
      start = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0);
      break;
    case 'week':
      start = new Date(now);
      start.setDate(now.getDate() - 7);
      start.setHours(0, 0, 0, 0);
      break;
    case 'month':
      start = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0, 0);
      break;
    case 'year':
      start = new Date(now.getFullYear(), 0, 1, 0, 0, 0, 0);
      break;
    case 'all_time':
    default:
      start = new Date(2000, 0, 1);
      break;
  }

  return { start, end };
}

export async function getDashboardData(
  userId: string,
  query: AnalyticsQueryInput
): Promise<DashboardData> {
  const { start, end } = getDateRange(query.period ?? 'month');

  // Get trip statistics
  const tripStats = await prisma.trip.groupBy({
    by: ['category'],
    where: {
      userId,
      deletedAt: null,
      startTime: { gte: start, lte: end },
      status: { in: ['completed', 'verified'] },
    },
    _count: true,
    _sum: { distanceMeters: true },
  });

  let totalTrips = 0;
  let totalMeters = 0;
  let businessMeters = 0;
  let personalMeters = 0;
  const tripsByCategory: Record<string, number> = {};

  for (const stat of tripStats) {
    totalTrips += stat._count;
    totalMeters += stat._sum.distanceMeters ?? 0;
    tripsByCategory[stat.category] = (stat._sum.distanceMeters ?? 0) * METERS_TO_MILES;

    if (stat.category === 'business') {
      businessMeters = stat._sum.distanceMeters ?? 0;
    } else if (stat.category === 'personal') {
      personalMeters = stat._sum.distanceMeters ?? 0;
    }
  }

  // Get expense statistics
  const expenseStats = await prisma.expense.aggregate({
    where: {
      userId,
      deletedAt: null,
      expenseDate: { gte: start, lte: end },
    },
    _sum: { amount: true },
  });

  const fuelStats = await prisma.expense.aggregate({
    where: {
      userId,
      deletedAt: null,
      category: 'fuel',
      expenseDate: { gte: start, lte: end },
    },
    _sum: { amount: true },
  });

  // Get most used vehicle
  const vehicleUsage = await prisma.trip.groupBy({
    by: ['vehicleId'],
    where: {
      userId,
      deletedAt: null,
      vehicleId: { not: null },
      startTime: { gte: start, lte: end },
    },
    _count: true,
    orderBy: { _count: { vehicleId: 'desc' } },
    take: 1,
  });

  let mostUsedVehicle: DashboardData['mostUsedVehicle'] = null;
  if (vehicleUsage[0]?.vehicleId) {
    const vehicle = await prisma.vehicle.findUnique({
      where: { id: vehicleUsage[0].vehicleId },
      select: { id: true, nickname: true },
    });
    if (vehicle) {
      mostUsedVehicle = {
        id: vehicle.id,
        nickname: vehicle.nickname,
        tripCount: vehicleUsage[0]._count,
      };
    }
  }

  // Calculate weekly trend
  const weeklyTrend: Array<{ date: string; trips: number; miles: number }> = [];
  const daysToShow = query.period === 'week' ? 7 : query.period === 'month' ? 4 : 12;

  for (let i = daysToShow - 1; i >= 0; i--) {
    const periodStart = new Date(end);
    const periodEnd = new Date(end);

    if (query.period === 'week') {
      periodStart.setDate(end.getDate() - i);
      periodEnd.setDate(end.getDate() - i);
    } else if (query.period === 'month') {
      periodStart.setDate(end.getDate() - i * 7);
      periodEnd.setDate(end.getDate() - (i - 1) * 7);
    } else {
      periodStart.setMonth(end.getMonth() - i);
      periodEnd.setMonth(end.getMonth() - i + 1);
    }

    periodStart.setHours(0, 0, 0, 0);
    periodEnd.setHours(23, 59, 59, 999);

    const periodTrips = await prisma.trip.aggregate({
      where: {
        userId,
        deletedAt: null,
        startTime: { gte: periodStart, lte: periodEnd },
        status: { in: ['completed', 'verified'] },
      },
      _count: true,
      _sum: { distanceMeters: true },
    });

    weeklyTrend.push({
      date: periodStart.toISOString().split('T')[0]!,
      trips: periodTrips._count,
      miles: (periodTrips._sum.distanceMeters ?? 0) * METERS_TO_MILES,
    });
  }

  const totalMiles = totalMeters * METERS_TO_MILES;
  const businessMiles = businessMeters * METERS_TO_MILES;
  const personalMiles = personalMeters * METERS_TO_MILES;
  const daysDiff = Math.max(1, Math.ceil((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24)));

  // Get current year IRS rate
  const currentYear = new Date().getFullYear();
  const rates = IRS_RATES[currentYear] ?? IRS_RATES[2026]!;

  return {
    period: query.period ?? 'month',
    totalTrips,
    totalMiles,
    businessMiles,
    personalMiles,
    totalExpenses: Number(expenseStats._sum.amount ?? 0),
    fuelCosts: Number(fuelStats._sum.amount ?? 0),
    estimatedDeduction: businessMiles * rates.business,
    avgDailyMiles: totalMiles / daysDiff,
    mostUsedVehicle,
    tripsByCategory,
    weeklyTrend,
  };
}

export async function getTaxSummary(
  userId: string,
  query: TaxSummaryQueryInput
): Promise<TaxSummary> {
  const taxYear = query.year ?? new Date().getFullYear();
  const startOfYear = new Date(taxYear, 0, 1, 0, 0, 0, 0);
  const endOfYear = new Date(taxYear, 11, 31, 23, 59, 59, 999);

  // Get or create tax year record
  let taxYearRecord = await prisma.taxYear.findUnique({
    where: { userId_taxYear: { userId, taxYear } },
  });

  const rates = IRS_RATES[taxYear] ?? IRS_RATES[2026]!;

  if (!taxYearRecord) {
    taxYearRecord = await prisma.taxYear.create({
      data: {
        userId,
        taxYear,
        irsStandardRate: rates.business,
        irsMedicalRate: rates.medical,
        irsCharityRate: rates.charity,
      },
    });
  }

  // Get mileage by category
  const mileageByCategory = await prisma.trip.groupBy({
    by: ['category'],
    where: {
      userId,
      deletedAt: null,
      startTime: { gte: startOfYear, lte: endOfYear },
      status: { in: ['completed', 'verified'] },
    },
    _sum: { distanceMeters: true },
  });

  let businessMiles = 0;
  let medicalMiles = 0;
  let charityMiles = 0;

  for (const item of mileageByCategory) {
    const miles = (item._sum.distanceMeters ?? 0) * METERS_TO_MILES;
    if (item.category === 'business') businessMiles = miles;
    else if (item.category === 'medical') medicalMiles = miles;
    else if (item.category === 'charity') charityMiles = miles;
  }

  // Get actual expenses
  const actualExpenses = await prisma.expense.aggregate({
    where: {
      userId,
      deletedAt: null,
      isTaxDeductible: true,
      expenseDate: { gte: startOfYear, lte: endOfYear },
    },
    _sum: { amount: true },
  });

  const totalActualExpenses = Number(actualExpenses._sum.amount ?? 0);

  // Calculate standard deduction
  const standardDeduction =
    businessMiles * rates.business +
    medicalMiles * rates.medical +
    charityMiles * rates.charity;

  // Determine recommended method
  const recommendedMethod = standardDeduction >= totalActualExpenses ? 'standard' : 'actual';
  const savingsAmount = Math.abs(standardDeduction - totalActualExpenses);

  // Update tax year record
  await prisma.taxYear.update({
    where: { id: taxYearRecord.id },
    data: {
      totalBusinessMiles: businessMiles,
      totalMedicalMiles: medicalMiles,
      totalCharityMiles: charityMiles,
      actualExpenses: totalActualExpenses,
      recommendedMethod,
    },
  });

  return {
    taxYear,
    businessMiles,
    medicalMiles,
    charityMiles,
    irsBusinessRate: rates.business,
    irsMedicalRate: rates.medical,
    irsCharityRate: rates.charity,
    standardDeduction,
    actualExpenses: totalActualExpenses,
    recommendedMethod,
    savingsAmount,
  };
}
