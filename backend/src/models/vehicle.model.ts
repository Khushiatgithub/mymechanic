import mongoose, { Schema, Types } from 'mongoose';

export interface IVehicle {
  userId: Types.ObjectId;
  make: string;
  model: string;
  variant?: string;
  registrationNumber: string;
  fuelType: 'Petrol' | 'Diesel' | 'Electric' | 'CNG' | 'Hybrid';
  year: number;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const VehicleSchema = new Schema<IVehicle>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User ID is required'],
      index: true,
    },
    make: {
      type: String,
      required: [true, 'Vehicle make is required'],
      trim: true,
    },
    model: {
      type: String,
      required: [true, 'Vehicle model is required'],
      trim: true,
    },
    variant: {
      type: String,
      trim: true,
    },
    registrationNumber: {
      type: String,
      required: [true, 'Registration number is required'],
      trim: true,
      uppercase: true,
    },
    fuelType: {
      type: String,
      enum: ['Petrol', 'Diesel', 'Electric', 'CNG', 'Hybrid'],
      required: [true, 'Fuel type is required'],
      default: 'Petrol',
    },
    year: {
      type: Number,
      required: [true, 'Manufacturing year is required'],
      min: [1990, 'Year must be after 1990'],
      max: [new Date().getFullYear() + 1, 'Year cannot be in the future'],
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

// Indexes
VehicleSchema.index({ userId: 1, registrationNumber: 1 });
VehicleSchema.index({ registrationNumber: 1 });

export const Vehicle = mongoose.model<IVehicle>('Vehicle', VehicleSchema);
