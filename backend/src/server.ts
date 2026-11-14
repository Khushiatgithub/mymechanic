import { app } from './app';
import { env } from './config/env';
import { connectDatabase, disconnectDatabase } from './config/database';
import { logger } from './utils/logger.util';

async function startServer(): Promise<void> {
  try {
    // 1. Establish MongoDB connection (logs warning if offline, does not crash process)
    try {
      await connectDatabase();
    } catch (dbError) {
      logger.warn(
        'Database connection failed during startup. Server will continue in detached mode.',
        dbError instanceof Error ? dbError.message : dbError
      );
    }

    // 2. Start HTTP server
    const server = app.listen(env.port, () => {
      logger.info('==================================================');
      logger.info(`  MyMechanic Backend API Server Started`);
      logger.info(`  Port:        ${env.port}`);
      logger.info(`  Environment: ${env.nodeEnv}`);
      logger.info(`  Prefix:      ${env.apiPrefix}`);
      logger.info(`  Health:      http://localhost:${env.port}${env.apiPrefix}/health`);
      logger.info('==================================================');
    });

    // 3. Graceful shutdown handler
    const shutdown = async (signal: string) => {
      logger.info(`Received ${signal}. Shutting down gracefully...`);
      server.close(async () => {
        logger.info('HTTP server closed.');
        await disconnectDatabase();
        process.exit(0);
      });

      // Force close if graceful shutdown takes longer than 10 seconds
      setTimeout(() => {
        logger.error('Forced shutdown due to timeout.');
        process.exit(1);
      }, 10000);
    };

    process.on('SIGINT', () => shutdown('SIGINT'));
    process.on('SIGTERM', () => shutdown('SIGTERM'));
  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
}

// Only start when invoked directly (not during test suites)
if (require.main === module) {
  startServer();
}

export { startServer };
