import { Request, Response, NextFunction } from 'express';
import { UserService } from '../services/user.service';
import { sendSuccess, sendPaginated } from '../utils/response.util';
import { parsePagination } from '../utils/pagination.util';
import { ApiError } from '../utils/errors';

export class UserController {
  static async createUser(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { name, email, phone, profileImage } = req.body;
      const user = await UserService.createUser({ name, email, phone, profileImage });
      sendSuccess(res, user, 201, 'User created successfully');
    } catch (error) {
      next(error);
    }
  }

  static async getUsers(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const pagination = parsePagination(req.query);
      const result = await UserService.getUsers(pagination);
      sendPaginated(res, result.items, result.pagination);
    } catch (error) {
      next(error);
    }
  }

  static async getMe(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw new ApiError('Authentication required', 401, 'UNAUTHORIZED');
      }
      const user = await UserService.getUserById(req.user.id);
      sendSuccess(res, user);
    } catch (error) {
      next(error);
    }
  }

  static async updateMe(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw new ApiError('Authentication required', 401, 'UNAUTHORIZED');
      }
      const { name, email, phone, profileImage } = req.body;
      const updatedUser = await UserService.updateUser(req.user.id, {
        name,
        email,
        phone,
        profileImage,
      });
      sendSuccess(res, updatedUser, 200, 'Profile updated successfully');
    } catch (error) {
      next(error);
    }
  }

  static async getUserById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = await UserService.getUserById(req.params.id as string);
      sendSuccess(res, user);
    } catch (error) {
      next(error);
    }
  }

  static async updateUser(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { name, email, phone, profileImage } = req.body;
      const updatedUser = await UserService.updateUser(req.params.id as string, {
        name,
        email,
        phone,
        profileImage,
      });
      sendSuccess(res, updatedUser, 200, 'User updated successfully');
    } catch (error) {
      next(error);
    }
  }

  static async deleteUser(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await UserService.deleteUser(req.params.id as string);
      sendSuccess(res, null, 200, 'User and dependent records deleted successfully');
    } catch (error) {
      next(error);
    }
  }
}
