import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
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

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [configuration],
      validationSchema
    }),
    PrismaModule,
    MailModule,
    StorageModule,
    CaptchaModule,
    AccessControlModule,
    AuthModule,
    UsersModule,
    CompetitionModule,
    MeModule
  ]
})
export class AppModule {}
