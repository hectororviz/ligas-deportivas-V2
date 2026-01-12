import { existsSync } from 'fs';
import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ConfigModule } from '@nestjs/config';
import { resolve } from 'path';
import configuration from './config/configuration';
import { validationSchema } from './config/validation.schema';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { AccessControlModule } from './rbac/access-control.module';
import { CompetitionModule } from './competition/competition.module';
import { StorageModule } from './storage/storage.module';
import { MailModule } from './mail/mail.module';
import { CaptchaModule } from './captcha/captcha.module';
import { MeModule } from './me/me.module';
import { SiteIdentityModule } from './site-identity/site-identity.module';
import { DatabaseReadyGuard } from './prisma/database-ready.guard';
import { HealthModule } from './health/health.module';

const envFileCandidates = [
  '.env.local',
  '.env',
  'backend/.env.local',
  'backend/.env',
  resolve(__dirname, '../.env.local'),
  resolve(__dirname, '../.env'),
  resolve(__dirname, '../../.env.local'),
  resolve(__dirname, '../../.env')
];

const envFilePath = envFileCandidates
  .map((filePath) => filePath.trim())
  .filter((filePath, index, self) => filePath.length > 0 && self.indexOf(filePath) === index && existsSync(filePath));

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath,
      load: [configuration],
      validationSchema,
    }),
    PrismaModule,
    MailModule,
    StorageModule,
    CaptchaModule,
    AccessControlModule,
    AuthModule,
    UsersModule,
    CompetitionModule,
    MeModule,
    SiteIdentityModule,
    HealthModule,
  ],
  providers: [
    {
      provide: APP_GUARD,
      useClass: DatabaseReadyGuard,
    },
  ],
})
export class AppModule {}
