import mongoose, { Schema, Document } from 'mongoose';

export interface IWorkshop extends Document {
  name: string;
  city: string;
  area: string;
  address: string;
  pincode: string;
  rating: number;
  reviewsCount: number;
  leadMechanic: string;
  phone: string;
  operatingHours: string;
  isDemoSeedData: boolean;
  disclaimer: string;
  latitude: number;
  longitude: number;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const WorkshopSchema = new Schema<IWorkshop>(
  {
    name: {
      type: String,
      required: [true, 'Workshop name is required'],
      trim: true,
    },
    city: {
      type: String,
      required: [true, 'City is required'],
      trim: true,
      default: 'Gurugram',
    },
    area: {
      type: String,
      required: [true, 'Area is required'],
      trim: true,
    },
    address: {
      type: String,
      required: [true, 'Address is required'],
      trim: true,
    },
    pincode: {
      type: String,
      required: [true, 'Pincode is required'],
      trim: true,
      default: '122015',
    },
    rating: {
      type: Number,
      required: true,
      min: 1,
      max: 5,
      default: 4.8,
    },
    reviewsCount: {
      type: Number,
      default: 150,
    },
    leadMechanic: {
      type: String,
      required: [true, 'Lead mechanic name is required'],
      trim: true,
      default: 'Assigned upon arrival',
    },
    phone: {
      type: String,
      required: [true, 'Phone number is required'],
      trim: true,
      default: '+91 88269 91028',
    },
    operatingHours: {
      type: String,
      default: '24x7',
    },
    isDemoSeedData: {
      type: Boolean,
      default: false,
      required: true,
    },
    disclaimer: {
      type: String,
      default: 'Official verified workshop location.',
      required: true,
    },
    latitude: {
      type: Number,
      default: 28.491111,
    },
    longitude: {
      type: Number,
      default: 77.0562498,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

WorkshopSchema.index({ city: 1, area: 1 });
WorkshopSchema.index({ isActive: 1 });

export const Workshop = mongoose.model<IWorkshop>('Workshop', WorkshopSchema);
