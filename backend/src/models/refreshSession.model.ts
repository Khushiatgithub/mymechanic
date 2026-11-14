import mongoose, { Schema, Types } from 'mongoose';

export interface IRefreshSession {
  userId: Types.ObjectId;
  tokenHash: string;
  expiresAt: Date;
  revokedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

const RefreshSessionSchema = new Schema<IRefreshSession>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User ID is required'],
      index: true,
    },
    tokenHash: {
      type: String,
      required: [true, 'Token hash is required'],
      index: true,
    },
    expiresAt: {
      type: Date,
      required: [true, 'Expiration date is required'],
      index: true,
    },
    revokedAt: {
      type: Date,
      index: true,
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

// Indexes for token lookup and cleanup
RefreshSessionSchema.index({ userId: 1, revokedAt: 1 });

export const RefreshSession = mongoose.model<IRefreshSession>(
  'RefreshSession',
  RefreshSessionSchema
);
