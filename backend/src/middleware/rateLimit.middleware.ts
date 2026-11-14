import rateLimit from 'express-rate-limit';
import { env } from '../config/env';

/**
 * Development-friendly rate limiter for sensitive authentication endpoints.
 * Window: 15 minutes
 * Limit: 100 attempts in development, 1000 in test suites to prevent test flakiness.
 */
export const authRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: env.nodeEnv === 'test' ? 1000 : 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Too many authentication attempts. Please try again after 15 minutes.',
    error: {
      code: 'TOO_MANY_REQUESTS',
    },
  },
});
