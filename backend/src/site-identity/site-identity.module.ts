import { Module } from '@nestjs/common';
import { SiteIdentityController } from './site-identity.controller';
import { SiteIdentityService } from './site-identity.service';
import { StorageModule } from '../storage/storage.module';

@Module({
  imports: [StorageModule],
  controllers: [SiteIdentityController],
  providers: [SiteIdentityService],
})
export class SiteIdentityModule {}
