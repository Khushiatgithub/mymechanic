import { Request, Response, NextFunction } from 'express';
import { OfferService } from '../services/offer.service';
import { sendSuccess } from '../utils/response.util';

export class OfferController {
  static async getOffers(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const category = typeof req.query.category === 'string' ? req.query.category : undefined;
      const offers = await OfferService.getActiveOffers(category);
      sendSuccess(res, offers, 200, 'Offers retrieved successfully');
    } catch (error) {
      next(error);
    }
  }

  static async validateCoupon(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { code, orderAmount, category, serviceId } = req.body;
      const result = await OfferService.validateCoupon(code, orderAmount, category, serviceId);
      sendSuccess(res, result, 200, 'Coupon is valid');
    } catch (error) {
      next(error);
    }
  }
}
