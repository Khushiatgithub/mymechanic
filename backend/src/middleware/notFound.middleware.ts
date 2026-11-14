import { Request, Response, NextFunction } from 'express';
import { sendError } from '../utils/response.util';

export function notFoundHandler(req: Request, res: Response, _next: NextFunction): void {
  sendError(
    res,
    `Cannot ${req.method} ${req.originalUrl} - Endpoint not found`,
    404,
    'NOT_FOUND'
  );
}
