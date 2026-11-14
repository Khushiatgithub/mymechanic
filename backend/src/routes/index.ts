import { Router } from 'express';
import healthRoutes from './health.routes';
import authRoutes from './auth.routes';
import userRoutes from './user.routes';
import vehicleRoutes from './vehicle.routes';
import serviceCategoryRoutes from './serviceCategory.routes';
import serviceRoutes from './service.routes';
import bookingRoutes from './booking.routes';
import offerRoutes from './offer.routes';
import workshopRoutes from './workshop.routes';
import notificationRoutes from './notification.routes';
import { sendSuccess } from '../utils/response.util';

const apiRouter = Router();

// 1. Health check route
apiRouter.use(healthRoutes);

// 2. Authentication & Identity routes (Phase 3 Step 3)
apiRouter.use('/auth', authRoutes);

// 3. Core REST APIs
apiRouter.use('/users', userRoutes);
apiRouter.use('/vehicles', vehicleRoutes);
apiRouter.use('/service-categories', serviceCategoryRoutes);
apiRouter.use('/services', serviceRoutes);
apiRouter.use('/bookings', bookingRoutes);
apiRouter.use('/offers', offerRoutes);
apiRouter.use('/workshops', workshopRoutes);
apiRouter.use('/notifications', notificationRoutes);

export default apiRouter;
