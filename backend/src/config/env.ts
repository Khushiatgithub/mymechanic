import dotenv from 'dotenv';
import path from 'path';

// Load .env file from backend root
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

export interface EnvironmentConfig {
  port: number;
  nodeEnv: string;
  mongodbUri: string;
  apiPrefix: string;
  corsOrigin: string;
  jwtAccessSecret: string;
  jwtAccessExpiresIn: string;
  jwtRefreshSecret: string;
  jwtRefreshExpiresIn: string;
  bcryptSaltRounds: number;
}

export const env: EnvironmentConfig = {
  port: parseInt(process.env.PORT || '5000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  mongodbUri: process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/mymechanic',
  apiPrefix: process.env.API_PREFIX || '/api/v1',
  corsOrigin: process.env.CORS_ORIGIN || '*',
  jwtAccessSecret:
    process.env.JWT_ACCESS_SECRET ||
    'mymechanic_dev_jwt_access_secret_long_and_secure_key_12345',
  jwtAccessExpiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '15m',
  jwtRefreshSecret:
    process.env.JWT_REFRESH_SECRET ||
    'mymechanic_dev_jwt_refresh_secret_distinct_and_secure_key_67890',
  jwtRefreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
  bcryptSaltRounds: parseInt(process.env.BCRYPT_SALT_ROUNDS || '12', 10),
};
