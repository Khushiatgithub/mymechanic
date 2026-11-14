import express, { Application, Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { env } from './config/env';
import apiRouter from './routes';
import { notFoundHandler } from './middleware/notFound.middleware';
import { errorHandler } from './middleware/error.middleware';
import { sendSuccess } from './utils/response.util';

export function createApp(): Application {
  const app: Application = express();

  // 1. Security baseline
  app.use(helmet());
  app.use(
    cors({
      origin: env.corsOrigin === '*' ? '*' : env.corsOrigin.split(','),
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
    })
  );

  // 2. Request parsing
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true, limit: '10mb' }));

  // 3. HTTP Request logging (suppressed in test environment)
  if (env.nodeEnv !== 'test') {
    app.use(morgan('dev'));
  }

  // 4. Root index route
  app.get('/', (_req: Request, res: Response) => {
    sendSuccess(
      res,
      {
        service: 'MyMechanic Backend API',
        version: 'v1',
        healthCheck: `${env.apiPrefix}/health`,
        documentation: '/README.md',
      },
      200,
      'Welcome to MyMechanic API'
    );
  });

  // 5. Mount API version router
  app.use(env.apiPrefix, apiRouter);

  // 6. Handle 404 for unknown endpoints
  app.use(notFoundHandler);

  // 7. Centralized error handling
  app.use(errorHandler);

  return app;
}

export const app = createApp();
export default app;
