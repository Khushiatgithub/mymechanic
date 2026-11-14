import mongoose, { Types } from 'mongoose';
import { Booking, IBooking, BookingStatus } from '../models/booking.model';
import { User } from '../models/user.model';
import { Vehicle } from '../models/vehicle.model';
import { Service } from '../models/service.model';
import { NotificationService } from './notification.service';
import { NotFoundError, ValidationError, BadRequestError } from '../utils/errors';
import { validateObjectId, generateBookingNumber } from '../utils/validation.util';
import { PaginationOptions, buildPaginationMeta } from '../utils/pagination.util';
import { PaginatedData } from '../utils/response.util';

export const VALID_BOOKING_STATUSES: BookingStatus[] = [
  'confirmed',
  'vehicle_received',
  'inspection',
  'service_in_progress',
  'quality_check',
  'ready_for_delivery',
  'completed',
  'cancelled',
];

export interface CreateBookingInput {
  userId: string;
  vehicleId: string;
  serviceId: string;
  bookingNumber?: string;
  scheduledDate: string | Date;
  scheduledTime: string;
  serviceMode?: 'doorstep' | 'workshop';
  address?: string;
  couponCode?: string;
  subtotal: number;
  discount?: number;
  pickupFee?: number;
  gst?: number;
  totalAmount: number;
  notes?: string;
  paymentMethod?: 'pay_on_delivery' | 'online_upi' | 'online_card' | 'online_netbanking';
  paymentStatus?: 'pending' | 'paid' | 'failed' | 'refunded';
  paymentReference?: string;
  workshopId?: string;
  workshopName?: string;
  assignedMechanic?: string;
}

export interface UpdateBookingInput {
  scheduledDate?: string | Date;
  scheduledTime?: string;
  address?: string;
  notes?: string;
}

export interface SubmitRatingInput {
  rating: number;
  ratingCategories?: string[];
  ratingFeedback?: string;
}

export interface BookingFilterOptions {
  userId?: string;
  vehicleId?: string;
  status?: string;
}

export class BookingService {
  static async createBooking(
    input: CreateBookingInput,
    ownerUserId?: string
  ): Promise<IBooking> {
    const effectiveUserId = ownerUserId || input.userId;
    const userId = validateObjectId(effectiveUserId, 'User ID');
    const vehicleId = validateObjectId(input.vehicleId, 'Vehicle ID');
    const serviceId = validateObjectId(input.serviceId, 'Service ID');

    // 1. Verify User exists
    const userExists = await User.exists({ _id: userId });
    if (!userExists) {
      throw new NotFoundError(`User with ID '${effectiveUserId}' not found.`);
    }

    // 2. Verify Vehicle exists and belongs to this user
    const vehicle = await Vehicle.findById(vehicleId);
    if (!vehicle) {
      throw new NotFoundError(`Vehicle with ID '${input.vehicleId}' not found.`);
    }
    if (vehicle.userId.toString() !== userId) {
      throw new BadRequestError(
        'Vehicle does not belong to the booking user.',
        'VEHICLE_OWNERSHIP_MISMATCH'
      );
    }

    // 3. Verify Service exists
    const service = await Service.findById(serviceId);
    if (!service) {
      throw new NotFoundError(`Service with ID '${input.serviceId}' not found.`);
    }

    // 4. Validate scheduled date
    if (!input.scheduledDate) {
      throw new ValidationError('Scheduled date is required.');
    }
    const scheduledDateObj = new Date(input.scheduledDate);
    if (isNaN(scheduledDateObj.getTime())) {
      throw new ValidationError('Scheduled date must be a valid date.');
    }

    // 5. Validate scheduled time
    if (
      !input.scheduledTime ||
      typeof input.scheduledTime !== 'string' ||
      input.scheduledTime.trim() === ''
    ) {
      throw new ValidationError('Scheduled time slot is required.');
    }

    // 6. Validate service mode
    const mode = input.serviceMode || 'doorstep';
    if (mode !== 'doorstep' && mode !== 'workshop') {
      throw new ValidationError("Service mode must be either 'doorstep' or 'workshop'.");
    }

    if (mode === 'doorstep' && (!input.address || input.address.trim() === '')) {
      throw new ValidationError('Service address is required for doorstep service.');
    }

    // 7. Validate monetary fields
    const subtotal = Number(input.subtotal);
    const discount = input.discount !== undefined ? Number(input.discount) : 0;
    const pickupFee = input.pickupFee !== undefined ? Number(input.pickupFee) : 0;
    const gst = input.gst !== undefined ? Number(input.gst) : 0;
    const totalAmount = Number(input.totalAmount);

    if (isNaN(subtotal) || subtotal < 0) {
      throw new ValidationError('Subtotal must be a non-negative number.');
    }
    if (isNaN(discount) || discount < 0) {
      throw new ValidationError('Discount must be a non-negative number.');
    }
    if (isNaN(pickupFee) || pickupFee < 0) {
      throw new ValidationError('Pickup fee must be a non-negative number.');
    }
    if (isNaN(gst) || gst < 0) {
      throw new ValidationError('GST must be a non-negative number.');
    }
    if (isNaN(totalAmount) || totalAmount < 0) {
      throw new ValidationError('Total amount must be a non-negative number.');
    }

    // 8. Generate unique booking reference
    let bookingNumber = input.bookingNumber?.trim();
    if (!bookingNumber) {
      let isUnique = false;
      let attempts = 0;
      while (!isUnique && attempts < 5) {
        const candidate = generateBookingNumber(scheduledDateObj.getFullYear());
        const exists = await Booking.exists({ bookingNumber: candidate });
        if (!exists) {
          bookingNumber = candidate;
          isUnique = true;
        }
        attempts++;
      }
      if (!bookingNumber) {
        bookingNumber = `MM-${Date.now()}`;
      }
    } else {
      const exists = await Booking.exists({ bookingNumber });
      if (exists) {
        throw new BadRequestError(
          `Booking number '${bookingNumber}' already exists.`,
          'DUPLICATE_BOOKING_NUMBER'
        );
      }
    }

    const booking = new Booking({
      userId,
      vehicleId,
      serviceId,
      bookingNumber,
      scheduledDate: scheduledDateObj,
      scheduledTime: input.scheduledTime.trim(),
      serviceMode: mode,
      ...(input.address ? { address: input.address.trim() } : {}),
      ...(input.couponCode ? { couponCode: input.couponCode.trim().toUpperCase() } : {}),
      subtotal,
      discount,
      pickupFee,
      gst,
      totalAmount,
      status: 'confirmed',
      ...(input.notes ? { notes: input.notes.trim() } : {}),
      ...(input.workshopId ? { workshopId: new Types.ObjectId(input.workshopId) } : {}),
      workshopName: input.workshopName?.trim() || 'My Mechanic Premium Car Service',
      assignedMechanic: input.assignedMechanic?.trim() || 'Assigned upon arrival',
      paymentMethod: input.paymentMethod || 'pay_on_delivery',
      paymentStatus: input.paymentStatus || 'pending',
      ...(input.paymentReference ? { paymentReference: input.paymentReference.trim() } : {}),
      ...(input.paymentStatus === 'paid' ? { paidAt: new Date() } : {}),
    });

    const saved = await booking.save();
    try {
      await NotificationService.createNotification({
        userId: saved.userId,
        title: 'Booking Confirmed!',
        message: `Your booking #${saved.bookingNumber} has been confirmed for ${saved.scheduledTime}.`,
        category: 'booking',
        actionRoute: '/bookings',
        relatedId: saved._id.toString(),
      });
    } catch (_) {}

    return (await saved.populate([
      { path: 'userId', select: 'name email phone' },
      { path: 'vehicleId', select: 'make model variant registrationNumber fuelType year' },
      { path: 'serviceId', select: 'title price durationText' },
    ])) as IBooking;
  }

  static async getBookings(
    pagination: PaginationOptions,
    filters: BookingFilterOptions,
    ownerUserId?: string
  ): Promise<PaginatedData<IBooking>> {
    const query: Record<string, unknown> = {};

    const effectiveUserId = ownerUserId || filters.userId;
    if (effectiveUserId) {
      validateObjectId(effectiveUserId, 'User ID');
      query.userId = effectiveUserId;
    }

    if (filters.vehicleId) {
      validateObjectId(filters.vehicleId, 'Vehicle ID');
      query.vehicleId = filters.vehicleId;
    }

    if (filters.status) {
      if (!VALID_BOOKING_STATUSES.includes(filters.status as BookingStatus)) {
        throw new ValidationError(
          `Invalid status filter. Allowed values: ${VALID_BOOKING_STATUSES.join(', ')}.`
        );
      }
      query.status = filters.status;
    }

    const total = await Booking.countDocuments(query);
    const items = await Booking.find(query)
      .populate('userId', 'name email phone')
      .populate('vehicleId', 'make model variant registrationNumber fuelType year')
      .populate('serviceId', 'title price durationText')
      .sort({ createdAt: -1 })
      .skip(pagination.skip)
      .limit(pagination.limit);

    return {
      items,
      pagination: buildPaginationMeta(total, pagination.page, pagination.limit),
    };
  }

  static async getBookingById(id: string, ownerUserId?: string): Promise<IBooking> {
    validateObjectId(id, 'Booking ID');
    const filter: Record<string, unknown> = { _id: id };
    if (ownerUserId) {
      validateObjectId(ownerUserId, 'Owner User ID');
      filter.userId = ownerUserId;
    }

    const booking = await Booking.findOne(filter)
      .populate('userId', 'name email phone')
      .populate('vehicleId', 'make model variant registrationNumber fuelType year')
      .populate('serviceId', 'title description price durationText includedItems');

    if (!booking) {
      throw new NotFoundError(`Booking with ID '${id}' not found.`);
    }
    return booking;
  }

  static async updateBooking(
    id: string,
    input: UpdateBookingInput,
    ownerUserId?: string
  ): Promise<IBooking> {
    validateObjectId(id, 'Booking ID');
    const filter: Record<string, unknown> = { _id: id };
    if (ownerUserId) {
      validateObjectId(ownerUserId, 'Owner User ID');
      filter.userId = ownerUserId;
    }

    const booking = await Booking.findOne(filter);
    if (!booking) {
      throw new NotFoundError(`Booking with ID '${id}' not found.`);
    }

    if (booking.status === 'completed' || booking.status === 'cancelled') {
      throw new BadRequestError(
        `Cannot update booking details when status is '${booking.status}'.`,
        'BOOKING_NOT_MODIFIABLE'
      );
    }

    const updatePayload: Record<string, unknown> = {};

    if (input.scheduledDate !== undefined) {
      const dateObj = new Date(input.scheduledDate);
      if (isNaN(dateObj.getTime())) {
        throw new ValidationError('Invalid scheduled date.');
      }
      updatePayload.scheduledDate = dateObj;
    }

    if (input.scheduledTime !== undefined) {
      if (typeof input.scheduledTime !== 'string' || input.scheduledTime.trim() === '') {
        throw new ValidationError('Scheduled time cannot be empty.');
      }
      updatePayload.scheduledTime = input.scheduledTime.trim();
    }

    if (input.address !== undefined) {
      updatePayload.address = input.address ? input.address.trim() : undefined;
    }

    if (input.notes !== undefined) {
      updatePayload.notes = input.notes ? input.notes.trim() : undefined;
    }

    const updated = await Booking.findByIdAndUpdate(id, updatePayload, {
      new: true,
      runValidators: true,
    })
      .populate('userId', 'name email phone')
      .populate('vehicleId', 'make model registrationNumber')
      .populate('serviceId', 'title price');

    return updated!;
  }

  static async updateBookingStatus(
    id: string,
    newStatus: string,
    ownerUserId?: string
  ): Promise<IBooking> {
    validateObjectId(id, 'Booking ID');

    if (!VALID_BOOKING_STATUSES.includes(newStatus as BookingStatus)) {
      throw new ValidationError(
        `Invalid status '${newStatus}'. Allowed: ${VALID_BOOKING_STATUSES.join(', ')}.`,
        'INVALID_STATUS'
      );
    }

    const targetStatus = newStatus as BookingStatus;
    const filter: Record<string, unknown> = { _id: id };
    if (ownerUserId) {
      validateObjectId(ownerUserId, 'Owner User ID');
      filter.userId = ownerUserId;
    }

    const booking = await Booking.findOne(filter);
    if (!booking) {
      throw new NotFoundError(`Booking with ID '${id}' not found.`);
    }

    const currentStatus = booking.status;

    // Transition Validation Rules:
    // 1. Completed bookings are strictly terminal
    if (currentStatus === 'completed') {
      throw new BadRequestError(
        'A completed booking cannot be modified or cancelled.',
        'INVALID_STATUS_TRANSITION'
      );
    }

    // 2. Cancelled bookings are strictly terminal
    if (currentStatus === 'cancelled') {
      throw new BadRequestError(
        'A cancelled booking cannot be modified or reopened.',
        'INVALID_STATUS_TRANSITION'
      );
    }

    // 3. Same status no-op check
    if (currentStatus === targetStatus) {
      return booking;
    }

    booking.status = targetStatus;
    await booking.save();
    try {
      const statusTitles: Record<string, string> = {
        vehicle_received: 'Vehicle Received at Workshop',
        inspection: 'Vehicle Inspection in Progress',
        service_in_progress: 'Service Underway',
        quality_check: 'Quality Check in Progress',
        ready_for_delivery: 'Ready for Handover',
        completed: 'Service Completed!',
        cancelled: 'Booking Cancelled',
      };
      const label = statusTitles[targetStatus] || targetStatus;
      await NotificationService.createNotification({
        userId: booking.userId,
        title: `Service Update: ${label}`,
        message: `Booking #${booking.bookingNumber} has transitioned to: ${label}.`,
        category: 'service',
        actionRoute: '/bookings',
        relatedId: booking._id.toString(),
      });
    } catch (_) {}

    return (await booking.populate([
      { path: 'userId', select: 'name email phone' },
      { path: 'vehicleId', select: 'make model registrationNumber' },
      { path: 'serviceId', select: 'title price' },
    ])) as IBooking;
  }

  static async deleteBooking(id: string, ownerUserId?: string): Promise<void> {
    validateObjectId(id, 'Booking ID');
    const filter: Record<string, unknown> = { _id: id };
    if (ownerUserId) {
      validateObjectId(ownerUserId, 'Owner User ID');
      filter.userId = ownerUserId;
    }

    const booking = await Booking.findOne(filter);
    if (!booking) {
      throw new NotFoundError(`Booking with ID '${id}' not found.`);
    }

    // Cannot delete an in-progress active service without cancelling first
    if (booking.status !== 'completed' && booking.status !== 'cancelled') {
      throw new BadRequestError(
        `Cannot delete active booking. Please cancel the booking first or wait for completion.`,
        'CANNOT_DELETE_ACTIVE_BOOKING'
      );
    }

    await Booking.findByIdAndDelete(id);
  }

  static async submitRating(
    id: string,
    input: SubmitRatingInput,
    ownerUserId?: string
  ): Promise<IBooking> {
    validateObjectId(id, 'Booking ID');
    const filter: Record<string, unknown> = { _id: id };
    if (ownerUserId) {
      validateObjectId(ownerUserId, 'Owner User ID');
      filter.userId = ownerUserId;
    }

    const booking = await Booking.findOne(filter);
    if (!booking) {
      throw new NotFoundError(`Booking with ID '${id}' not found.`);
    }

    if (booking.status !== 'completed') {
      throw new BadRequestError(
        'Ratings can only be submitted for completed bookings.',
        'BOOKING_NOT_COMPLETED'
      );
    }

    if (booking.isRated || booking.rating !== undefined) {
      throw new BadRequestError(
        'This booking has already been rated.',
        'ALREADY_RATED'
      );
    }

    const ratingVal = Number(input.rating);
    if (isNaN(ratingVal) || ratingVal < 1 || ratingVal > 5 || !Number.isInteger(ratingVal)) {
      throw new ValidationError('Rating must be an integer between 1 and 5.');
    }

    booking.rating = ratingVal;
    booking.ratingCategories = Array.isArray(input.ratingCategories)
      ? input.ratingCategories.map((c) => String(c).trim()).filter(Boolean)
      : [];
    booking.ratingFeedback = input.ratingFeedback ? String(input.ratingFeedback).trim() : undefined;
    booking.isRated = true;
    booking.ratedAt = new Date();

    await booking.save();
    try {
      await NotificationService.createNotification({
        userId: booking.userId,
        title: 'Thank You for Your Feedback!',
        message: `Your ${ratingVal}-star rating for booking #${booking.bookingNumber} was submitted.`,
        category: 'service',
        actionRoute: '/bookings',
        relatedId: booking._id.toString(),
      });
    } catch (_) {}

    return (await booking.populate([
      { path: 'userId', select: 'name email phone' },
      { path: 'vehicleId', select: 'make model registrationNumber' },
      { path: 'serviceId', select: 'title price' },
    ])) as IBooking;
  }

  static async updatePayment(
    id: string,
    input: {
      paymentMethod?: string;
      paymentStatus: string;
      paymentReference?: string;
    },
    ownerUserId?: string
  ): Promise<IBooking> {
    validateObjectId(id, 'Booking ID');
    const filter: Record<string, unknown> = { _id: id };
    if (ownerUserId) {
      validateObjectId(ownerUserId, 'Owner User ID');
      filter.userId = ownerUserId;
    }

    const booking = await Booking.findOne(filter);
    if (!booking) {
      throw new NotFoundError(`Booking with ID '${id}' not found.`);
    }

    const validStatuses = ['pending', 'paid', 'failed', 'refunded'];
    if (!validStatuses.includes(input.paymentStatus)) {
      throw new ValidationError(`Invalid payment status '${input.paymentStatus}'.`);
    }

    booking.paymentStatus = input.paymentStatus as any;
    if (input.paymentMethod) {
      booking.paymentMethod = input.paymentMethod as any;
    }
    if (input.paymentReference) {
      booking.paymentReference = input.paymentReference.trim();
    }
    if (input.paymentStatus === 'paid') {
      booking.paidAt = new Date();
    }

    await booking.save();
    try {
      await NotificationService.createNotification({
        userId: booking.userId,
        title: input.paymentStatus === 'paid' ? 'Payment Successful' : 'Payment Status Updated',
        message: `Payment of ₹${booking.totalAmount} for booking #${booking.bookingNumber} is ${input.paymentStatus}.`,
        category: 'booking',
        actionRoute: '/bookings',
        relatedId: booking._id.toString(),
      });
    } catch (_) {}

    return (await booking.populate([
      { path: 'userId', select: 'name email phone' },
      { path: 'vehicleId', select: 'make model variant registrationNumber fuelType year' },
      { path: 'serviceId', select: 'title price durationText' },
    ])) as IBooking;
  }
}
