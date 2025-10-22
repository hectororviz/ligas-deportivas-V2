import { Global, Module } from '@nestjs/common';
import { PrismaService } from './prisma.service';
import { DatabaseInitializerService } from './database-initializer.service';

@Global()
@Module({
  providers: [PrismaService, DatabaseInitializerService],
  exports: [PrismaService]
})
export class PrismaModule {}
