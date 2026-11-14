import { Types } from 'mongoose';
import { Notification, INotification, NotificationCategoryType } from '../models/notification.model';
import { validateObjectId } from '../utils/validation.util';
import { NotFoundError } from '../utils/errors';

export interface CreateNotificationInput {
  userId: string | Types.ObjectId;
  title: string;
  message: string;
  category?: NotificationCategoryType;
  actionRoute?: string;
  relatedId?: string;
}

export class NotificationService {
  /**
   * Creates and stores a new in-app notification for a user.
   */
  static async createNotification(input: CreateNotificationInput): Promise<INotification> {
    const notification = new Notification({
      userId: typeof input.userId === 'string' ? new Types.ObjectId(input.userId) : input.userId,
      title: input.title.trim(),
      message: input.message.trim(),
      category: input.category || 'booking',
      ...(input.actionRoute ? { actionRoute: input.actionRoute.trim() } : {}),
      ...(input.relatedId ? { relatedId: input.relatedId.trim() } : {}),
    });

    return notification.save();
  }

  /**
   * Retrieves all notifications for an authenticated user, optionally filtered by category.
   */
  static async getNotifications(userId: string, category?: string): Promise<INotification[]> {
    validateObjectId(userId, 'User ID');
    const query: Record<string, unknown> = { userId };
    if (category && category.toLowerCase() !== 'all') {
      query.category = category.toLowerCase();
    }
    return Notification.find(query).sort({ createdAt: -1 }).limit(50);
  }

  /**
   * Marks a specific notification as read.
   */
  static async markAsRead(userId: string, notificationId: string): Promise<INotification> {
    validateObjectId(userId, 'User ID');
    validateObjectId(notificationId, 'Notification ID');

    const notification = await Notification.findOneAndUpdate(
      { _id: notificationId, userId },
      { isRead: true },
      { new: true }
    );

    if (!notification) {
      throw new NotFoundError('Notification not found.');
    }
    return notification;
  }

  /**
   * Marks all notifications as read for a user.
   */
  static async markAllAsRead(userId: string): Promise<number> {
    validateObjectId(userId, 'User ID');
    const result = await Notification.updateMany(
      { userId, isRead: false },
      { isRead: true }
    );
    return result.modifiedCount;
  }

  /**
   * Deletes a notification by ID.
   */
  static async deleteNotification(userId: string, notificationId: string): Promise<void> {
    validateObjectId(userId, 'User ID');
    validateObjectId(notificationId, 'Notification ID');

    const result = await Notification.deleteOne({ _id: notificationId, userId });
    if (result.deletedCount === 0) {
      throw new NotFoundError('Notification not found.');
    }
  }
}
