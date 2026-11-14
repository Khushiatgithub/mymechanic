import { Router } from 'express';
import { OfferController } from '../controllers/offer.controller';

const router = Router();

// Public routes for guest and authenticated customers
router.get('/', OfferController.getOffers);
router.post('/validate', OfferController.validateCoupon);

export default router;
