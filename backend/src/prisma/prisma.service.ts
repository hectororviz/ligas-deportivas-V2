import { INestApplication, Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { Prisma, PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService
  extends PrismaClient<Prisma.PrismaClientOptions, 'beforeExit'>
  implements OnModuleInit
{
  private readonly logger = new Logger(PrismaService.name);

  async onModuleInit(): Promise<void> {
    await this.connectWithRetry();
  }

  private async connectWithRetry(): Promise<void> {
    const maxAttempts = 5;
    const backoffMs = 2000;
    const databaseLocation = this.describeDatabaseLocation(process.env.DATABASE_URL);

    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await this.$connect();
        if (attempt > 1) {
          this.log(`Connected to the database on attempt ${attempt}.`);
        }
        return;
      } catch (error) {
        if (attempt < maxAttempts && this.isInitializationError(error)) {
          const wait = backoffMs * attempt;
          this.warn(
            `Unable to reach the database${databaseLocation ? ` at ${databaseLocation}` : ''} (attempt ${attempt}/${maxAttempts}). Retrying in ${wait}ms...`
          );
          await new Promise((resolve) => setTimeout(resolve, wait));
          continue;
        }

        this.logInitializationFailure(error, databaseLocation);
        throw error;
      }
    }
  }

  private describeDatabaseLocation(databaseUrl?: string): string | undefined {
    if (!databaseUrl) {
      return undefined;
    }

    try {
      const { hostname, port } = new URL(databaseUrl);
      return port ? `${hostname}:${port}` : hostname;
    } catch (error) {
      this.debug(`Unable to parse DATABASE_URL: ${(error as Error).message}`);
      return undefined;
    }
  }

  private isInitializationError(error: unknown): error is Prisma.PrismaClientInitializationError {
    if (error instanceof Prisma.PrismaClientInitializationError) {
      return true;
    }

    if (typeof error === 'object' && error !== null && 'code' in error) {
      const code = (error as { code?: unknown }).code;
      return typeof code === 'string' && code.startsWith('P1');
    }

    return false;
  }

  private logInitializationFailure(error: unknown, databaseLocation?: string): void {
    if (this.isInitializationError(error)) {
      const hint = databaseLocation
        ? `Check that the database server at ${databaseLocation} is running and that your DATABASE_URL is correct.`
        : 'Check that your database server is running and that the DATABASE_URL environment variable is correct.';

      this.error(`Failed to establish a database connection. ${hint}`);
    } else {
      this.error('Failed to establish a database connection.', error);
    }
  }

  private log(message: string): void {
    this.logger.log(message);
    console.log(`[Prisma] ${message}`);
  }

  private warn(message: string): void {
    this.logger.warn(message);
    console.warn(`[Prisma] ${message}`);
  }

  private error(message: string, error?: unknown): void {
    if (error instanceof Error && error.stack) {
      this.logger.error(message, error.stack);
      console.error(`[Prisma] ${message}`);
      console.error(error.stack);
    } else {
      this.logger.error(message);
      console.error(`[Prisma] ${message}`);
      if (error) {
        console.error(error);
      }
    }
  }

  private debug(message: string): void {
    this.logger.debug(message);
    console.debug(`[Prisma] ${message}`);
  }

  async enableShutdownHooks(app: INestApplication): Promise<void> {
    this.$on('beforeExit', async () => {
      await app.close();
    });
  }
}
