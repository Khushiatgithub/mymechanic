import { Response } from 'express';

export interface ApiResponse<T = unknown> {
  success: boolean;
  message?: string;
  data?: T;
  error?: {
    code: string;
    details?: unknown;
  };
}

export interface PaginationMeta {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

export interface PaginatedData<T> {
  items: T[];
  pagination: PaginationMeta;
}

export function sendSuccess<T>(
  res: Response,
  data?: T,
  statusCode = 200,
  message?: string
): Response {
  const response: ApiResponse<T> = {
    success: true,
  };

  if (message) {
    response.message = message;
  }

  if (data !== undefined) {
    response.data = data;
  }

  return res.status(statusCode).json(response);
}

export function sendPaginated<T>(
  res: Response,
  items: T[],
  pagination: PaginationMeta,
  statusCode = 200,
  message?: string
): Response {
  return sendSuccess<PaginatedData<T>>(
    res,
    {
      items,
      pagination,
    },
    statusCode,
    message
  );
}

export function sendError(
  res: Response,
  message: string,
  statusCode = 500,
  errorCode = 'INTERNAL_SERVER_ERROR',
  details?: unknown
): Response {
  const response: ApiResponse = {
    success: false,
    message,
    error: {
      code: errorCode,
      ...(details !== undefined && { details }),
    },
  };

  return res.status(statusCode).json(response);
}
