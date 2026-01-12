import { Global, Module } from '@nestjs/common';
import { PrismaService } from './prisma.service';
import { DatabaseInitializerService } from './database-initializer.service';
import { DatabaseSchemaHealthService } from './database-schema-health.service';

@Global()
@Module({
  providers: [PrismaService, DatabaseSchemaHealthService, DatabaseInitializerService],
  exports: [PrismaService, DatabaseSchemaHealthService]
})
export class PrismaModule {}
