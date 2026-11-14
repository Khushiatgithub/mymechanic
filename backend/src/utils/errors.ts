/**
 * Standardized API Error Classes for MyMechanic Backend.
 */

export class ApiError extends Error {
  public readonly statusCode: number;
  public readonly code: string;
  public readonly details?: unknown;

  constructor(
    message: string,
    statusCode = 400,
    code = 'BAD_REQUEST',
    details?: unknown
  ) {
    super(message);
    this.name = this.constructor.name;
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
    Error.captureStackTrace(this, this.constructor);
  }
}

export class NotFoundError extends ApiError {
  constructor(message = 'Resource not found', code = 'NOT_FOUND') {
    super(message, 404, code);
  }
}

export class ValidationError extends ApiError {
  constructor(
    message = 'Validation failed',
    code = 'VALIDATION_ERROR',
    details?: unknown
  ) {
    super(message, 400, code, details);
  }
}

export class ConflictError extends ApiError {
  constructor(message = 'Resource conflict', code = 'CONFLICT') {
    super(message, 409, code);
  }
}

export class BadRequestError extends ApiError {
  constructor(message = 'Bad request', code = 'BAD_REQUEST') {
    super(message, 400, code);
  }
}
