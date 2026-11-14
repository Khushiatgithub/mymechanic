import { Router } from 'express';
import { NotificationController } from '../controllers/notification.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

// Protect all notification routes with authentication
router.use(authenticate);

router.get('/', NotificationController.getNotifications);
router.patch('/read-all', NotificationController.markAllAsRead);
router.patch('/:id/read', NotificationController.markAsRead);
router.delete('/:id', NotificationController.deleteNotification);

export default router;
