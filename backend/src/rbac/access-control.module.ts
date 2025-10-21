import { Global, Module } from '@nestjs/common';
import { AccessControlService } from './access-control.service';
import { PermissionsGuard } from './permissions.guard';
import { RolesController } from './roles.controller';
import { PrismaModule } from '../prisma/prisma.module';

@Global()
@Module({
  imports: [PrismaModule],
  providers: [AccessControlService, PermissionsGuard],
  controllers: [RolesController],
  exports: [AccessControlService, PermissionsGuard]
})
export class AccessControlModule {}
