import mongoose, { Schema, Document, Types } from 'mongoose';

export type NotificationCategoryType = 'booking' | 'service' | 'offers';

export interface INotification extends Document {
  userId: Types.ObjectId;
  title: string;
  message: string;
  category: NotificationCategoryType;
  isRead: boolean;
  actionRoute?: string;
  relatedId?: string;
  createdAt: Date;
  updatedAt: Date;
}

const NotificationSchema = new Schema<INotification>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User ID is required'],
      index: true,
    },
    title: {
      type: String,
      required: [true, 'Title is required'],
      trim: true,
    },
    message: {
      type: String,
      required: [true, 'Message is required'],
      trim: true,
    },
    category: {
      type: String,
      enum: ['booking', 'service', 'offers'],
      default: 'booking',
      index: true,
    },
    isRead: {
      type: Boolean,
      default: false,
      index: true,
    },
    actionRoute: {
      type: String,
      trim: true,
    },
    relatedId: {
      type: String,
      trim: true,
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

NotificationSchema.index({ userId: 1, createdAt: -1 });

export const Notification = mongoose.model<INotification>('Notification', NotificationSchema);
