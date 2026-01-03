import type { Request, Response, NextFunction } from 'express';
import type { ZodSchema } from 'zod';

type ValidationTarget = 'body' | 'query' | 'params';

export function validate<T>(schema: ZodSchema<T>, target: ValidationTarget = 'body') {
  return (req: Request, _res: Response, next: NextFunction): void => {
    try {
      const data = req[target];
      const parsed = schema.parse(data);

      // Replace original data with parsed (and potentially transformed) data
      (req as Record<string, unknown>)[target] = parsed;

      next();
    } catch (error) {
      next(error);
    }
  };
}

export function validateBody<T>(schema: ZodSchema<T>) {
  return validate(schema, 'body');
}

export function validateQuery<T>(schema: ZodSchema<T>) {
  return validate(schema, 'query');
}

export function validateParams<T>(schema: ZodSchema<T>) {
  return validate(schema, 'params');
}

// Validate multiple targets at once
export function validateAll<
  TBody = unknown,
  TQuery = unknown,
  TParams = unknown
>(schemas: {
  body?: ZodSchema<TBody>;
  query?: ZodSchema<TQuery>;
  params?: ZodSchema<TParams>;
}) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    try {
      if (schemas.body) {
        req.body = schemas.body.parse(req.body);
      }
      if (schemas.query) {
        (req as unknown as { query: TQuery }).query = schemas.query.parse(req.query);
      }
      if (schemas.params) {
        (req as unknown as { params: TParams }).params = schemas.params.parse(req.params);
      }
      next();
    } catch (error) {
      next(error);
    }
  };
}
