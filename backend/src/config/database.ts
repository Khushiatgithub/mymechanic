import mongoose from 'mongoose';
import { env } from './env';
import { logger } from '../utils/logger.util';

const connectionStates: Record<number, string> = {
  0: 'disconnected',
  1: 'connected',
  2: 'connecting',
  3: 'disconnecting',
};

export async function connectDatabase(customUri?: string): Promise<void> {
  if (mongoose.connection.readyState === 1) {
    logger.info('MongoDB is already connected.');
    return;
  }

  const targetUri =
    customUri ||
    (process.env.NODE_ENV === 'test'
      ? process.env.MONGODB_TEST_URI || 'mongodb://127.0.0.1:27017/mymechanic_test'
      : env.mongodbUri);

  try {
    logger.info(`Connecting to MongoDB (${process.env.NODE_ENV === 'test' ? 'isolated test db' : 'dev db'})...`);
    await mongoose.connect(targetUri, {
      serverSelectionTimeoutMS: 5000,
    });
    logger.info(`MongoDB connected successfully [State: ${connectionStates[mongoose.connection.readyState]}]`);
  } catch (error) {
    logger.error('Failed to connect to MongoDB:', error instanceof Error ? error.message : error);
    throw error;
  }
}

export async function disconnectDatabase(): Promise<void> {
  if (mongoose.connection.readyState !== 0) {
    await mongoose.disconnect();
    logger.info('MongoDB disconnected gracefully.');
  }
}

export function getDatabaseHealth(): { isConnected: boolean; state: string } {
  const readyState = mongoose.connection.readyState;
  return {
    isConnected: readyState === 1,
    state: connectionStates[readyState] || 'unknown',
  };
}
