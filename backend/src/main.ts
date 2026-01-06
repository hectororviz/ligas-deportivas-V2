import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import helmet from 'helmet';
import * as cookieParser from 'cookie-parser';
import { extname, join, sep } from 'path';
import { NestExpressApplication } from '@nestjs/platform-express';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule, { bufferLogs: true });

  // Allow frontend (Flutter web) to call the API during development
  const configService = app.get(ConfigService);
  const frontendUrl = configService.get<string>('app.frontendUrl') ?? 'http://localhost:8080';
  const localhostRegex = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/;
  app.enableCors({
    origin: (origin, callback) => {
      // Allow same-origin or non-browser requests
      if (!origin) return callback(null, true);
      if (origin === frontendUrl || localhostRegex.test(origin)) {
        return callback(null, true);
      }
      // Do not throw on preflight; respond as not allowed
      return callback(null, false);
    },
    methods: ['GET', 'HEAD', 'PUT', 'PATCH', 'POST', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true,
    optionsSuccessStatus: 204
  });

  app.setGlobalPrefix('api/v1');
  app.use(helmet());
  app.use(cookieParser());
  const uploadsDir = join(process.cwd(), 'storage', 'uploads');
  const publicDir = join(process.cwd(), 'public');

  // Serve uploaded files both with and without the API prefix so that
  // absolute URLs stored as "/storage/..." still work when the HTTP client
  // applies the global `/api/v1` prefix.
  app.useStaticAssets(uploadsDir, { prefix: '/storage/uploads/' });
  app.useStaticAssets(uploadsDir, { prefix: '/api/v1/storage/uploads/' });
  app.useStaticAssets(publicDir, {
    prefix: '/',
    setHeaders: (res, filePath) => {
      if (filePath.includes(`${sep}site-identity${sep}icons${sep}`)) {
        res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
      }
      if (extname(filePath) === '.webmanifest') {
        res.setHeader('Content-Type', 'application/manifest+json');
      }
    },
  });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true
    })
  );

  const port = process.env.PORT || 3000;
  await app.listen(port);
}

bootstrap().catch((error) => {
  if (isPrismaConnectionError(error)) {
    const databaseLocation = describeDatabaseLocation(process.env.DATABASE_URL);
    const locationMessage = databaseLocation ? ` at ${databaseLocation}` : '';
    console.error(
      `Failed to connect to the database${locationMessage}. Ensure your database is running and that the DATABASE_URL environment variable matches your local setup.`
    );
  } else {
    console.error(error);
  }
  process.exit(1);
});

function isPrismaConnectionError(error: unknown): error is { code?: string } {
  if (typeof error === 'object' && error !== null && 'code' in error) {
    const code = (error as { code?: unknown }).code;
    return typeof code === 'string' && code.startsWith('P1');
  }
  return false;
}

function describeDatabaseLocation(databaseUrl?: string): string | undefined {
  if (!databaseUrl) {
    return undefined;
  }

  try {
    const { hostname, port } = new URL(databaseUrl);
    return port ? `${hostname}:${port}` : hostname;
  } catch {
    return undefined;
  }
}
