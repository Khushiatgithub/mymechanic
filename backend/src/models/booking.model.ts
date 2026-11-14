import mongoose, { Schema, Types } from 'mongoose';

export type BookingStatus =
  | 'confirmed'
  | 'vehicle_received'
  | 'inspection'
  | 'service_in_progress'
  | 'quality_check'
  | 'ready_for_delivery'
  | 'completed'
  | 'cancelled';

export type PaymentMethod =
  | 'pay_on_delivery'
  | 'online_upi'
  | 'online_card'
  | 'online_netbanking';

export type PaymentStatus = 'pending' | 'paid' | 'failed' | 'refunded';

export interface IBooking {
  userId: Types.ObjectId;
  vehicleId: Types.ObjectId;
  serviceId: Types.ObjectId;
  bookingNumber: string;
  scheduledDate: Date;
  scheduledTime: string;
  serviceMode: 'doorstep' | 'workshop';
  workshopId?: Types.ObjectId;
  workshopName?: string;
  assignedMechanic?: string;
  address?: string;
  couponCode?: string;
  subtotal: number;
  discount: number;
  pickupFee: number;
  gst: number;
  totalAmount: number;
  status: BookingStatus;
  notes?: string;
  paymentMethod: PaymentMethod;
  paymentStatus: PaymentStatus;
  paymentReference?: string;
  paidAt?: Date;
  rating?: number;
  ratingCategories?: string[];
  ratingFeedback?: string;
  ratedAt?: Date;
  isRated?: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const BookingSchema = new Schema<IBooking>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User ID is required'],
      index: true,
    },
    vehicleId: {
      type: Schema.Types.ObjectId,
      ref: 'Vehicle',
      required: [true, 'Vehicle ID is required'],
      index: true,
    },
    serviceId: {
      type: Schema.Types.ObjectId,
      ref: 'Service',
      required: [true, 'Service ID is required'],
      index: true,
    },
    bookingNumber: {
      type: String,
      required: [true, 'Booking number is required'],
      unique: true,
      trim: true,
    },
    scheduledDate: {
      type: Date,
      required: [true, 'Scheduled date is required'],
      index: true,
    },
    scheduledTime: {
      type: String,
      required: [true, 'Scheduled time slot is required'],
    },
    serviceMode: {
      type: String,
      enum: ['doorstep', 'workshop'],
      default: 'doorstep',
    },
    workshopId: {
      type: Schema.Types.ObjectId,
      ref: 'Workshop',
    },
    workshopName: {
      type: String,
      trim: true,
      default: 'My Mechanic Premium Car Service',
    },
    assignedMechanic: {
      type: String,
      trim: true,
      default: 'Assigned upon arrival',
    },
    address: {
      type: String,
      trim: true,
    },
    couponCode: {
      type: String,
      trim: true,
      uppercase: true,
    },
    subtotal: {
      type: Number,
      required: true,
      min: 0,
    },
    discount: {
      type: Number,
      default: 0,
      min: 0,
    },
    pickupFee: {
      type: Number,
      default: 0,
      min: 0,
    },
    gst: {
      type: Number,
      default: 0,
      min: 0,
    },
    totalAmount: {
      type: Number,
      required: true,
      min: 0,
    },
    status: {
      type: String,
      enum: [
        'confirmed',
        'vehicle_received',
        'inspection',
        'service_in_progress',
        'quality_check',
        'ready_for_delivery',
        'completed',
        'cancelled',
      ],
      default: 'confirmed',
      index: true,
    },
    notes: {
      type: String,
      trim: true,
    },
    paymentMethod: {
      type: String,
      enum: ['pay_on_delivery', 'online_upi', 'online_card', 'online_netbanking'],
      default: 'pay_on_delivery',
    },
    paymentStatus: {
      type: String,
      enum: ['pending', 'paid', 'failed', 'refunded'],
      default: 'pending',
      index: true,
    },
    paymentReference: {
      type: String,
      trim: true,
    },
    paidAt: {
      type: Date,
    },
    rating: {
      type: Number,
      min: 1,
      max: 5,
    },
    ratingCategories: {
      type: [String],
      default: [],
    },
    ratingFeedback: {
      type: String,
      trim: true,
      maxlength: 1000,
    },
    ratedAt: {
      type: Date,
    },
    isRated: {
      type: Boolean,
      default: false,
      index: true,
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

// Indexes
BookingSchema.index({ userId: 1, status: 1 });
BookingSchema.index({ scheduledDate: 1, status: 1 });

export const Booking = mongoose.model<IBooking>('Booking', BookingSchema);
