import { Module } from '@nestjs/common';
import { SanctionsService } from './sanctions.service';
import { SanctionsController } from './sanctions.controller';

@Module({
  controllers: [SanctionsController],
  providers: [SanctionsService],
  exports: [SanctionsService],
})
export class SanctionsModule {}
