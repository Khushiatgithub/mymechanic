import { Request, Response, NextFunction } from 'express';
import { NotificationService } from '../services/notification.service';
import { sendSuccess } from '../utils/response.util';
import { ApiError } from '../utils/errors';

export class NotificationController {
  static async getNotifications(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw new ApiError('Authentication required', 401, 'UNAUTHORIZED');
      }
      const category = typeof req.query.category === 'string' ? req.query.category : undefined;
      const notifications = await NotificationService.getNotifications(req.user.id, category);
      sendSuccess(res, notifications, 200, 'Notifications retrieved successfully');
    } catch (error) {
      next(error);
    }
  }

  static async markAsRead(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw new ApiError('Authentication required', 401, 'UNAUTHORIZED');
      }
      const notification = await NotificationService.markAsRead(req.user.id, req.params.id as string);
      sendSuccess(res, notification, 200, 'Notification marked as read');
    } catch (error) {
      next(error);
    }
  }

  static async markAllAsRead(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw new ApiError('Authentication required', 401, 'UNAUTHORIZED');
      }
      const count = await NotificationService.markAllAsRead(req.user.id);
      sendSuccess(res, { count }, 200, 'All notifications marked as read');
    } catch (error) {
      next(error);
    }
  }

  static async deleteNotification(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw new ApiError('Authentication required', 401, 'UNAUTHORIZED');
      }
      await NotificationService.deleteNotification(req.user.id, req.params.id as string);
      sendSuccess(res, null, 200, 'Notification deleted successfully');
    } catch (error) {
      next(error);
    }
  }
}
