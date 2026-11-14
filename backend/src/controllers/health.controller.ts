import { Request, Response } from 'express';
import { env } from '../config/env';
import { getDatabaseHealth } from '../config/database';
import { sendSuccess } from '../utils/response.util';

export function getHealth(_req: Request, res: Response): void {
  const dbHealth = getDatabaseHealth();

  sendSuccess(
    res,
    {
      environment: env.nodeEnv,
      timestamp: new Date().toISOString(),
      uptimeSeconds: Math.floor(process.uptime()),
      database: dbHealth,
    },
    200,
    'MyMechanic API is healthy'
  );
}
