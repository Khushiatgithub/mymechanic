import mongoose, { Schema, Types } from 'mongoose';

export interface IService {
  categoryId: Types.ObjectId;
  title: string;
  description: string;
  price: number;
  originalPrice?: number;
  durationText: string;
  rating: number;
  reviewCount: number;
  isActive: boolean;
  warrantyPeriod?: string;
  includedItems?: string[];
  excludedItems?: string[];
  createdAt: Date;
  updatedAt: Date;
}

const ServiceSchema = new Schema<IService>(
  {
    categoryId: {
      type: Schema.Types.ObjectId,
      ref: 'ServiceCategory',
      required: [true, 'Category ID is required'],
      index: true,
    },
    title: {
      type: String,
      required: [true, 'Service title is required'],
      trim: true,
    },
    description: {
      type: String,
      required: [true, 'Service description is required'],
      trim: true,
    },
    price: {
      type: Number,
      required: [true, 'Price is required'],
      min: [0, 'Price must be non-negative'],
    },
    originalPrice: {
      type: Number,
      min: [0, 'Original price must be non-negative'],
    },
    durationText: {
      type: String,
      required: [true, 'Duration text is required'],
      trim: true,
      default: '3-4 Hours',
    },
    rating: {
      type: Number,
      default: 4.8,
      min: 0,
      max: 5,
    },
    reviewCount: {
      type: Number,
      default: 0,
      min: 0,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    warrantyPeriod: {
      type: String,
      trim: true,
    },
    includedItems: {
      type: [String],
      default: [],
    },
    excludedItems: {
      type: [String],
      default: [],
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

// Indexes
ServiceSchema.index({ categoryId: 1, isActive: 1 });
ServiceSchema.index({ title: 'text', description: 'text' });

export const Service = mongoose.model<IService>('Service', ServiceSchema);
