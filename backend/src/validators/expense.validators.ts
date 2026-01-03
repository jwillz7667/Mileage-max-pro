import { z } from 'zod';

const expenseCategorySchema = z.enum([
  'fuel',
  'parking',
  'tolls',
  'maintenance',
  'repairs',
  'insurance',
  'registration',
  'car_wash',
  'supplies',
  'phone',
  'equipment',
  'meals',
  'lodging',
  'other',
]);

const paymentMethodSchema = z.enum(['cash', 'card', 'check', 'app', 'other']);

const fuelTypeSchema = z.enum([
  'gasoline',
  'diesel',
  'electric',
  'hybrid',
  'plugin_hybrid',
]);

const reimbursementStatusSchema = z.enum([
  'not_applicable',
  'pending',
  'submitted',
  'approved',
  'paid',
  'rejected',
]);

export const createExpenseSchema = z.object({
  vehicleId: z.string().uuid().optional().nullable(),
  tripId: z.string().uuid().optional().nullable(),
  category: expenseCategorySchema,
  subcategory: z.string().max(100).optional().nullable(),
  amount: z.number().positive().max(1000000),
  currency: z.string().length(3).optional().default('USD'),
  expenseDate: z.string().datetime(),
  vendorName: z.string().max(255).optional().nullable(),
  vendorAddress: z.string().max(500).optional().nullable(),
  vendorLatitude: z.number().min(-90).max(90).optional().nullable(),
  vendorLongitude: z.number().min(-180).max(180).optional().nullable(),
  description: z.string().max(2000).optional().nullable(),
  paymentMethod: paymentMethodSchema.optional().default('card'),
  isReimbursable: z.boolean().optional().default(false),
  isTaxDeductible: z.boolean().optional().default(false),
  taxCategory: z.string().max(100).optional().nullable(),
  notes: z.string().max(2000).optional().nullable(),
});

export const updateExpenseSchema = createExpenseSchema.partial().extend({
  reimbursementStatus: reimbursementStatusSchema.optional(),
  receiptUrl: z.string().url().optional().nullable(),
});

export const createFuelPurchaseSchema = z.object({
  vehicleId: z.string().uuid(),
  fuelType: fuelTypeSchema,
  gallons: z.number().positive().max(500),
  pricePerGallon: z.number().positive().max(100),
  expenseDate: z.string().datetime(),
  odometerReading: z.number().int().min(0).max(10000000).optional().nullable(),
  isFullTank: z.boolean().optional().default(true),
  stationName: z.string().max(255).optional().nullable(),
  stationBrand: z.string().max(100).optional().nullable(),
  stationAddress: z.string().max(500).optional().nullable(),
  stationLatitude: z.number().min(-90).max(90).optional().nullable(),
  stationLongitude: z.number().min(-180).max(180).optional().nullable(),
  paymentMethod: paymentMethodSchema.optional().default('card'),
  notes: z.string().max(2000).optional().nullable(),
});

export const expenseIdParamSchema = z.object({
  expenseId: z.string().uuid(),
});

export const expenseFilterSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  perPage: z.coerce.number().int().min(1).max(100).default(20),
  category: expenseCategorySchema.optional(),
  vehicleId: z.string().uuid().optional(),
  tripId: z.string().uuid().optional(),
  startDate: z.string().datetime().optional(),
  endDate: z.string().datetime().optional(),
  minAmount: z.coerce.number().positive().optional(),
  maxAmount: z.coerce.number().positive().optional(),
  isReimbursable: z.coerce.boolean().optional(),
  isTaxDeductible: z.coerce.boolean().optional(),
  sort: z.string().optional().default('-expenseDate'),
});

export type CreateExpenseInput = z.infer<typeof createExpenseSchema>;
export type UpdateExpenseInput = z.infer<typeof updateExpenseSchema>;
export type CreateFuelPurchaseInput = z.infer<typeof createFuelPurchaseSchema>;
export type ExpenseFilterInput = z.infer<typeof expenseFilterSchema>;
