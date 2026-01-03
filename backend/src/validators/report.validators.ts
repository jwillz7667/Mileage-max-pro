import { z } from 'zod';

const reportTypeSchema = z.enum([
  'weekly',
  'monthly',
  'quarterly',
  'annual',
  'custom',
  'irs_log',
]);

const exportFormatSchema = z.enum(['pdf', 'csv', 'both']);

export const createReportSchema = z.object({
  reportType: reportTypeSchema,
  dateRangeStart: z.string().datetime(),
  dateRangeEnd: z.string().datetime(),
  vehicleIds: z.array(z.string().uuid()).optional(),
  categories: z.array(z.string()).optional(),
  includeExpenses: z.boolean().optional().default(true),
  includeEarnings: z.boolean().optional().default(false),
  format: exportFormatSchema.optional().default('pdf'),
}).refine(
  (data) => new Date(data.dateRangeStart) <= new Date(data.dateRangeEnd),
  { message: 'Start date must be before or equal to end date' }
);

export const reportIdParamSchema = z.object({
  reportId: z.string().uuid(),
});

export const reportFilterSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  perPage: z.coerce.number().int().min(1).max(100).default(20),
  reportType: reportTypeSchema.optional(),
  status: z.enum(['generating', 'ready', 'failed']).optional(),
  sort: z.string().optional().default('-createdAt'),
});

export const analyticsQuerySchema = z.object({
  period: z.enum(['today', 'week', 'month', 'year', 'all_time']).optional().default('month'),
});

export const taxSummaryQuerySchema = z.object({
  year: z.coerce.number().int().min(2000).max(2100).optional(),
});

export type CreateReportInput = z.infer<typeof createReportSchema>;
export type ReportFilterInput = z.infer<typeof reportFilterSchema>;
export type AnalyticsQueryInput = z.infer<typeof analyticsQuerySchema>;
export type TaxSummaryQueryInput = z.infer<typeof taxSummaryQuerySchema>;
