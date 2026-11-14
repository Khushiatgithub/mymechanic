import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller';
import { authenticate } from '../middleware/auth.middleware';
import { authRateLimiter } from '../middleware/rateLimit.middleware';

const router = Router();

// Public auth endpoints with rate limiting
router.post('/register', authRateLimiter, AuthController.register);
router.post('/login', authRateLimiter, AuthController.login);
router.post('/refresh', authRateLimiter, AuthController.refresh);

// Protected auth endpoints
router.get('/me', authenticate, AuthController.getMe);
router.post('/logout', authenticate, AuthController.logout);
router.patch('/password', authenticate, authRateLimiter, AuthController.changePassword);

export default router;
