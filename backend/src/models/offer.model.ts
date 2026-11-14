import mongoose, { Schema, Document } from 'mongoose';

export type DiscountType = 'flat' | 'percentage';

export interface IOffer extends Document {
  code: string;
  title: string;
  description: string;
  discountType: DiscountType;
  discountValue: number;
  maxDiscount?: number;
  minOrderValue: number;
  expiryDate: Date;
  eligibleCategory?: string;
  eligibleServiceIds: string[];
  terms: string[];
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const OfferSchema = new Schema<IOffer>(
  {
    code: {
      type: String,
      required: [true, 'Coupon code is required'],
      unique: true,
      uppercase: true,
      trim: true,
      index: true,
    },
    title: {
      type: String,
      required: [true, 'Offer title is required'],
      trim: true,
    },
    description: {
      type: String,
      required: [true, 'Offer description is required'],
      trim: true,
    },
    discountType: {
      type: String,
      enum: ['flat', 'percentage'],
      required: true,
      default: 'flat',
    },
    discountValue: {
      type: Number,
      required: [true, 'Discount value is required'],
      min: [0, 'Discount value cannot be negative'],
    },
    maxDiscount: {
      type: Number,
      min: [0, 'Max discount cannot be negative'],
    },
    minOrderValue: {
      type: Number,
      default: 0,
      min: [0, 'Minimum order value cannot be negative'],
    },
    expiryDate: {
      type: Date,
      required: [true, 'Expiry date is required'],
      index: true,
    },
    eligibleCategory: {
      type: String,
      trim: true,
    },
    eligibleServiceIds: {
      type: [String],
      default: [],
    },
    terms: {
      type: [String],
      default: [],
    },
    isActive: {
      type: Boolean,
      default: true,
      index: true,
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

OfferSchema.index({ isActive: 1, expiryDate: 1 });

export const Offer = mongoose.model<IOffer>('Offer', OfferSchema);
