import { Request, Response, NextFunction } from 'express';
import { AuthService } from '../services/auth.service';
import { sendSuccess } from '../utils/response.util';
import { ApiError } from '../utils/errors';

export class AuthController {
  static async register(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { name, email, password, phone, profileImage } = req.body;
      const result = await AuthService.register({
        name,
        email,
        password,
        phone,
        profileImage,
      });

      sendSuccess(
        res,
        {
          user: result.user,
          accessToken: result.tokens.accessToken,
          refreshToken: result.tokens.refreshToken,
        },
        201,
        'Registration successful'
      );
    } catch (error) {
      next(error);
    }
  }

  static async login(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { email, password } = req.body;
      const result = await AuthService.login({ email, password });

      sendSuccess(
        res,
        {
          user: result.user,
          accessToken: result.tokens.accessToken,
          refreshToken: result.tokens.refreshToken,
        },
        200,
        'Login successful'
      );
    } catch (error) {
      next(error);
    }
  }

  static async refresh(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { refreshToken } = req.body;
      const tokens = await AuthService.refreshTokens(refreshToken);

      sendSuccess(res, tokens, 200, 'Tokens refreshed successfully');
    } catch (error) {
      next(error);
    }
  }

  static async logout(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw new ApiError('Authentication required', 401, 'UNAUTHORIZED');
      }

      const { refreshToken } = req.body;
      await AuthService.logout(req.user.id, refreshToken);

      sendSuccess(res, null, 200, 'Logged out successfully');
    } catch (error) {
      next(error);
    }
  }

  static async getMe(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw new ApiError('Authentication required', 401, 'UNAUTHORIZED');
      }

      const user = await AuthService.getMe(req.user.id);
      sendSuccess(res, user);
    } catch (error) {
      next(error);
    }
  }

  static async changePassword(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      if (!req.user) {
        throw new ApiError('Authentication required', 401, 'UNAUTHORIZED');
      }

      const { currentPassword, newPassword } = req.body;
      await AuthService.changePassword(req.user.id, currentPassword, newPassword);

      sendSuccess(
        res,
        null,
        200,
        'Password changed successfully. Please log in again.'
      );
    } catch (error) {
      next(error);
    }
  }
}
