import { Request, Response, NextFunction } from 'express';
import { verifyAccessToken } from '../utils/auth.util';
import { User } from '../models/user.model';
import { ApiError } from '../utils/errors';
import { validateObjectId } from '../utils/validation.util';

export async function authenticate(
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader) {
      throw new ApiError(
        'Authentication required. Missing Authorization header.',
        401,
        'UNAUTHORIZED'
      );
    }

    const parts = authHeader.split(' ');
    if (parts.length !== 2 || parts[0] !== 'Bearer') {
      throw new ApiError(
        'Invalid Authorization format. Expected "Bearer <token>".',
        401,
        'INVALID_TOKEN'
      );
    }

    const token = parts[1];
    const payload = verifyAccessToken(token);

    validateObjectId(payload.sub, 'User ID in token');

    const user = await User.findById(payload.sub).select('+isActive');
    if (!user) {
      throw new ApiError(
        'User account associated with this token no longer exists.',
        401,
        'USER_NOT_FOUND'
      );
    }

    if (!user.isActive) {
      throw new ApiError(
        'User account is disabled. Please contact support.',
        403,
        'ACCOUNT_DISABLED'
      );
    }

    req.user = {
      id: user._id.toString(),
      email: user.email,
      name: user.name,
    };

    next();
  } catch (error) {
    next(error);
  }
}
