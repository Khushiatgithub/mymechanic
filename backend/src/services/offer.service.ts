import { Offer, IOffer } from '../models/offer.model';
import { BadRequestError, NotFoundError, ValidationError } from '../utils/errors';

export interface CouponValidationResponse {
  valid: boolean;
  code: string;
  title: string;
  description: string;
  discountType: 'flat' | 'percentage';
  discountValue: number;
  discountAmount: number;
  finalAmount: number;
  terms: string[];
}

export class OfferService {
  /**
   * Returns list of currently active and valid offers.
   */
  static async getActiveOffers(category?: string): Promise<IOffer[]> {
    const query: Record<string, unknown> = {
      isActive: true,
      expiryDate: { $gt: new Date() },
    };

    if (category && category.trim() !== '' && category.toLowerCase() !== 'all deals') {
      query.eligibleCategory = new RegExp(category.trim(), 'i');
    }

    return Offer.find(query).sort({ discountValue: -1, createdAt: -1 });
  }

  /**
   * Validates a coupon code against an order amount and category.
   */
  static async validateCoupon(
    code: string,
    orderAmount: number,
    category?: string,
    serviceId?: string
  ): Promise<CouponValidationResponse> {
    if (!code || typeof code !== 'string' || code.trim() === '') {
      throw new ValidationError('Coupon code is required.');
    }

    const numericAmount = Number(orderAmount);
    if (isNaN(numericAmount) || numericAmount < 0) {
      throw new ValidationError('Valid order amount is required.');
    }

    const cleanCode = code.trim().toUpperCase();
    const offer = await Offer.findOne({ code: cleanCode });

    if (!offer) {
      throw new NotFoundError(`Coupon code '${cleanCode}' is invalid.`);
    }

    if (!offer.isActive) {
      throw new BadRequestError('This coupon is currently inactive.', 'COUPON_INACTIVE');
    }

    if (new Date() > offer.expiryDate) {
      throw new BadRequestError('This coupon has expired.', 'COUPON_EXPIRED');
    }

    if (numericAmount < offer.minOrderValue) {
      throw new BadRequestError(
        `Minimum order value for this coupon is ₹${offer.minOrderValue.toFixed(0)}.`,
        'MIN_ORDER_VALUE_NOT_MET'
      );
    }

    if (offer.eligibleCategory && offer.eligibleCategory.trim().length > 0) {
      if (
        !category ||
        !category.toLowerCase().includes(offer.eligibleCategory.toLowerCase())
      ) {
        throw new BadRequestError(
          `This coupon is valid only for '${offer.eligibleCategory}' services.`,
          'CATEGORY_NOT_ELIGIBLE'
        );
      }
    }

    if (offer.eligibleServiceIds && offer.eligibleServiceIds.length > 0) {
      if (!serviceId || !offer.eligibleServiceIds.includes(serviceId)) {
        throw new BadRequestError(
          'This coupon is not valid for the selected service package.',
          'SERVICE_NOT_ELIGIBLE'
        );
      }
    }

    // Calculate discount amount
    let discountAmount = 0;
    if (offer.discountType === 'flat') {
      discountAmount = offer.discountValue;
    } else {
      discountAmount = (numericAmount * offer.discountValue) / 100.0;
      if (offer.maxDiscount !== undefined && offer.maxDiscount !== null) {
        discountAmount = Math.min(discountAmount, offer.maxDiscount);
      }
    }

    // Cannot discount more than order subtotal
    discountAmount = Math.min(discountAmount, numericAmount);
    discountAmount = Math.round(discountAmount * 100) / 100;
    const finalAmount = Math.max(0, Math.round((numericAmount - discountAmount) * 100) / 100);

    return {
      valid: true,
      code: offer.code,
      title: offer.title,
      description: offer.description,
      discountType: offer.discountType,
      discountValue: offer.discountValue,
      discountAmount,
      finalAmount,
      terms: offer.terms,
    };
  }
}
