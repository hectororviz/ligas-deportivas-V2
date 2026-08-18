import { Module } from '@nestjs/common';
import { MeController } from './me.controller';
import { MeService } from './me.service';
import { PrismaModule } from '../prisma/prisma.module';
import { StorageModule } from '../storage/storage.module';
import { RateLimiterService } from '../common/services/rate-limiter.service';

@Module({
  imports: [PrismaModule, StorageModule],
  controllers: [MeController],
  providers: [MeService, RateLimiterService]
})
export class MeModule {}
