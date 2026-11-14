import mongoose, { Schema } from 'mongoose';

export interface IUser {
  name: string;
  email?: string;
  phone?: string;
  passwordHash?: string;
  isActive: boolean;
  lastLoginAt?: Date;
  profileImage?: string;
  createdAt: Date;
  updatedAt: Date;
}

const UserSchema = new Schema<IUser>(
  {
    name: {
      type: String,
      required: [true, 'User name is required'],
      trim: true,
      maxlength: [100, 'Name cannot exceed 100 characters'],
    },
    email: {
      type: String,
      trim: true,
      lowercase: true,
      match: [
        /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
        'Please provide a valid email address',
      ],
    },
    phone: {
      type: String,
      trim: true,
    },
    passwordHash: {
      type: String,
      select: false, // Hidden by default from all queries
    },
    isActive: {
      type: Boolean,
      default: true,
      index: true,
    },
    lastLoginAt: {
      type: Date,
    },
    profileImage: {
      type: String,
      trim: true,
    },
  },
  {
    timestamps: true,
    versionKey: false,
    toJSON: {
      transform(_doc, ret) {
        delete ret.passwordHash;
        return ret;
      },
    },
  }
);

// Indexes for high-frequency queries
UserSchema.index({ email: 1 }, { unique: true, sparse: true });
UserSchema.index({ phone: 1 }, { unique: true, sparse: true });

export const User = mongoose.model<IUser>('User', UserSchema);
