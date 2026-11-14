import { Router } from 'express';
import { UserController } from '../controllers/user.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

// Authenticated current-user self profile routes
router.get('/me', authenticate, UserController.getMe);
router.patch('/me', authenticate, UserController.updateMe);

// General User routes
router.get('/', UserController.getUsers);
router.post('/', UserController.createUser);
router.get('/:id', UserController.getUserById);
router.patch('/:id', UserController.updateUser);
router.delete('/:id', UserController.deleteUser);

export default router;
