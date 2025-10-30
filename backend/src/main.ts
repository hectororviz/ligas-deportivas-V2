import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import helmet from 'helmet';
import * as cookieParser from 'cookie-parser';
import { join } from 'path';
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
  app.useStaticAssets(join(process.cwd(), 'storage', 'uploads'), {
    prefix: '/storage/uploads/'
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

bootstrap();
