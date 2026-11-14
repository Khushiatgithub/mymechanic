import { Request, Response, NextFunction } from 'express';
import { BookingService } from '../services/booking.service';
import { sendSuccess, sendPaginated } from '../utils/response.util';
import { parsePagination } from '../utils/pagination.util';
import { ValidationError, ApiError } from '../utils/errors';

export class BookingController {
  static async createBooking(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw new ApiError('Authentication required', 401, 'UNAUTHORIZED');
      }

      // Security: Prevent User ID Spoofing
      if (req.body.userId && req.body.userId !== req.user.id) {
        throw new ApiError('Cannot create a booking for another user.', 403, 'FORBIDDEN');
      }

      const booking = await BookingService.createBooking(
        {
          ...req.body,
          userId: req.user.id,
        },
        req.user.id
      );
      sendSuccess(res, booking, 201, 'Booking created successfully');
    } catch (error) {
      next(error);
    }
  }

  static async getBookings(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw new ApiError('Authentication required', 401, 'UNAUTHORIZED');
      }

      const pagination = parsePagination(req.query);
      const vehicleId = typeof req.query.vehicleId === 'string' ? req.query.vehicleId : undefined;
      const status = typeof req.query.status === 'string' ? req.query.status : undefined;

      // Security: Scoped to req.user.id
      const result = await BookingService.getBookings(
        pagination,
        {
          vehicleId,
          status,
        },
        req.user.id
      );

      sendPaginated(res, result.items, result.pagination);
    } catch (error) {
      next(error);
    }
  }

  static async getBookingById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw new ApiError('Authentication required', 401, 'UNAUTHORIZED');
      }

      const booking = await BookingService.getBookingById(
        req.params.id as string,
        req.user.id
      );
      sendSuccess(res, booking);
    } catch (error) {
      next(error);
    }
  }

  static async updateBooking(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw new ApiError('Authentication required', 401, 'UNAUTHORIZED');
      }

      const updated = await BookingService.updateBooking(
        req.params.id as string,
        req.body,
        req.user.id
      );
      sendSuccess(res, updated, 200, 'Booking details updated successfully');
    } catch (error) {
      next(error);
    }
  }

  static async updateBookingStatus(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      if (!req.user) {
        throw new ApiError('Authentication required', 401, 'UNAUTHORIZED');
      }

      const { status } = req.body;
      if (!status || typeof status !== 'string') {
        throw new ValidationError("Body field 'status' is required.");
      }
      const updated = await BookingService.updateBookingStatus(
        req.params.id as string,
        status,
        req.user.id
      );
      sendSuccess(res, updated, 200, `Booking status updated to '${status}'`);
    } catch (error) {
      next(error);
    }
  }

  static async deleteBooking(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw new ApiError('Authentication required', 401, 'UNAUTHORIZED');
      }

      await BookingService.deleteBooking(req.params.id as string, req.user.id);
      sendSuccess(res, null, 200, 'Booking deleted successfully');
    } catch (error) {
      next(error);
    }
  }

  static async rateBooking(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw new ApiError('Authentication required', 401, 'UNAUTHORIZED');
      }

      const { rating, ratingCategories, ratingFeedback } = req.body;
      const updated = await BookingService.submitRating(
        req.params.id as string,
        { rating, ratingCategories, ratingFeedback },
        req.user.id
      );
      sendSuccess(res, updated, 200, 'Rating submitted successfully');
    } catch (error) {
      next(error);
    }
  }

  static async updatePayment(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw new ApiError('Authentication required', 401, 'UNAUTHORIZED');
      }

      const { paymentMethod, paymentStatus, paymentReference } = req.body;
      const updated = await BookingService.updatePayment(
        req.params.id as string,
        { paymentMethod, paymentStatus, paymentReference },
        req.user.id
      );
      sendSuccess(res, updated, 200, 'Payment status updated successfully');
    } catch (error) {
      next(error);
    }
  }
}
