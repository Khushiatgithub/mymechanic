import mongoose, { Schema } from 'mongoose';

export interface IServiceCategory {
  name: string;
  description?: string;
  icon?: string;
  isActive: boolean;
  sortOrder: number;
  createdAt: Date;
  updatedAt: Date;
}

const ServiceCategorySchema = new Schema<IServiceCategory>(
  {
    name: {
      type: String,
      required: [true, 'Category name is required'],
      unique: true,
      trim: true,
    },
    description: {
      type: String,
      trim: true,
    },
    icon: {
      type: String,
      trim: true,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    sortOrder: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

// Indexes
ServiceCategorySchema.index({ isActive: 1, sortOrder: 1 });

export const ServiceCategory = mongoose.model<IServiceCategory>(
  'ServiceCategory',
  ServiceCategorySchema
);
