import { Router } from 'express';
import { BookingController } from '../controllers/booking.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

// Protect all booking routes with authentication
router.use(authenticate);

router.get('/', BookingController.getBookings);
router.post('/', BookingController.createBooking);
router.get('/:id', BookingController.getBookingById);
router.patch('/:id/status', BookingController.updateBookingStatus);
router.patch('/:id', BookingController.updateBooking);
router.post('/:id/rating', BookingController.rateBooking);
router.post('/:id/payment', BookingController.updatePayment);
router.delete('/:id', BookingController.deleteBooking);

export default router;
