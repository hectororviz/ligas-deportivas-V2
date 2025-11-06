import { Module } from '@nestjs/common';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { AccessControlModule } from '../rbac/access-control.module';
import { MailModule } from '../mail/mail.module';

@Module({
  imports: [PrismaModule, AccessControlModule, MailModule],
  providers: [UsersService],
  controllers: [UsersController],
  exports: [UsersService],
})
export class UsersModule {}
