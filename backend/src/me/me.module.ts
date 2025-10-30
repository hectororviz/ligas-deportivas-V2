import { Module } from '@nestjs/common';
import { MeController } from './me.controller';
import { MeService } from './me.service';
import { PrismaModule } from '../prisma/prisma.module';
import { MailModule } from '../mail/mail.module';
import { StorageModule } from '../storage/storage.module';
import { RateLimiterService } from '../common/services/rate-limiter.service';

@Module({
  imports: [PrismaModule, MailModule, StorageModule],
  controllers: [MeController],
  providers: [MeService, RateLimiterService]
})
export class MeModule {}
