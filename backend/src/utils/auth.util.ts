import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import { env } from '../config/env';
import { ApiError } from './errors';

export interface TokenPayload {
  sub: string;
  type: 'access' | 'refresh';
  iat?: number;
  exp?: number;
}

/**
 * Hash plaintext password using bcrypt with configured salt rounds.
 */
export async function hashPassword(password: string): Promise<string> {
  return await bcrypt.hash(password, env.bcryptSaltRounds);
}

/**
 * Compare candidate password against stored bcrypt hash.
 */
export async function comparePassword(
  password: string,
  storedHash: string
): Promise<boolean> {
  return await bcrypt.compare(password, storedHash);
}

/**
 * Creates SHA-256 hash of a token for secure database storage.
 */
export function hashToken(token: string): string {
  return crypto.createHash('sha256').update(token).digest('hex');
}

/**
 * Generates short-lived JWT access token.
 */
export function generateAccessToken(userId: string): string {
  const payload: TokenPayload = {
    sub: userId,
    type: 'access',
  };

  return jwt.sign(payload, env.jwtAccessSecret, {
    expiresIn: env.jwtAccessExpiresIn as jwt.SignOptions['expiresIn'],
  });
}

/**
 * Generates long-lived refresh token and calculates its secure SHA-256 storage hash.
 */
export function generateRefreshToken(userId: string): {
  token: string;
  tokenHash: string;
  expiresAt: Date;
} {
  const payload: TokenPayload = {
    sub: userId,
    type: 'refresh',
  };

  const token = jwt.sign(payload, env.jwtRefreshSecret, {
    expiresIn: env.jwtRefreshExpiresIn as jwt.SignOptions['expiresIn'],
  });

  const tokenHash = hashToken(token);

  // Parse expiration: default 7 days from now
  const decoded = jwt.decode(token) as { exp?: number };
  const expiresAt = decoded?.exp
    ? new Date(decoded.exp * 1000)
    : new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

  return { token, tokenHash, expiresAt };
}

/**
 * Verifies JWT access token signature, type, and expiration.
 */
export function verifyAccessToken(token: string): TokenPayload {
  try {
    const decoded = jwt.verify(token, env.jwtAccessSecret) as TokenPayload;
    if (decoded.type !== 'access') {
      throw new ApiError('Invalid token type. Access token expected.', 401, 'INVALID_TOKEN');
    }
    return decoded;
  } catch (error) {
    if (error instanceof ApiError) throw error;
    if (error instanceof jwt.TokenExpiredError) {
      throw new ApiError('Access token has expired. Please refresh your session.', 401, 'TOKEN_EXPIRED');
    }
    throw new ApiError('Invalid authentication token.', 401, 'INVALID_TOKEN');
  }
}

/**
 * Verifies JWT refresh token signature, type, and expiration.
 */
export function verifyRefreshToken(token: string): TokenPayload {
  try {
    const decoded = jwt.verify(token, env.jwtRefreshSecret) as TokenPayload;
    if (decoded.type !== 'refresh') {
      throw new ApiError('Invalid token type. Refresh token expected.', 401, 'INVALID_REFRESH_TOKEN');
    }
    return decoded;
  } catch (error) {
    if (error instanceof ApiError) throw error;
    if (error instanceof jwt.TokenExpiredError) {
      throw new ApiError('Refresh token has expired. Please log in again.', 401, 'REFRESH_TOKEN_EXPIRED');
    }
    throw new ApiError('Invalid refresh token.', 401, 'INVALID_REFRESH_TOKEN');
  }
}
