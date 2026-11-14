import { Request, Response, NextFunction } from 'express';
import { sendError } from '../utils/response.util';
import { logger } from '../utils/logger.util';
import { ApiError } from '../utils/errors';

export function errorHandler(
  err: Error,
  req: Request,
  res: Response,
  _next: NextFunction
): void {
  // 1. Handled ApiError instances
  if (err instanceof ApiError) {
    logger.warn(`[${req.method}] ${req.originalUrl} - ${err.code}: ${err.message}`);
    sendError(res, err.message, err.statusCode, err.code, err.details);
    return;
  }

  // 2. Mongoose CastError (e.g. invalid ObjectId cast)
  if (err.name === 'CastError' && 'path' in (err as unknown as { path: string })) {
    const castErr = err as unknown as { path: string };
    const message = `Invalid format for field '${castErr.path}'`;
    logger.warn(`[${req.method}] ${req.originalUrl} - INVALID_ID: ${message}`);
    sendError(res, message, 400, 'INVALID_ID');
    return;
  }

  // 3. Mongoose Schema ValidationError
  if (err.name === 'ValidationError' && 'errors' in (err as unknown as { errors: Record<string, { message: string }> })) {
    const validationErr = err as unknown as { errors: Record<string, { message: string }> };
    const firstMessage = Object.values(validationErr.errors)[0]?.message || 'Validation failed';
    logger.warn(`[${req.method}] ${req.originalUrl} - VALIDATION_ERROR: ${firstMessage}`);
    sendError(res, firstMessage, 400, 'VALIDATION_ERROR');
    return;
  }

  // 4. MongoServerError: Duplicate Key (11000)
  if ('code' in err && (err as unknown as { code: number }).code === 11000) {
    const mongoErr = err as unknown as { keyValue?: Record<string, unknown> };
    const duplicateField = mongoErr.keyValue ? Object.keys(mongoErr.keyValue)[0] : 'field';
    const message = `Duplicate value for ${duplicateField}. Must be unique.`;
    logger.warn(`[${req.method}] ${req.originalUrl} - CONFLICT: ${message}`);
    sendError(res, message, 409, 'DUPLICATE_KEY_ERROR');
    return;
  }

  // 5. Unhandled / Unexpected Errors (500)
  logger.error(`[${req.method}] ${req.originalUrl} - Unhandled Exception:`, err);
  sendError(
    res,
    'An unexpected error occurred. Please try again later.',
    500,
    'INTERNAL_SERVER_ERROR'
  );
}
