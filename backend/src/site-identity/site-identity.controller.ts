import {
  Body,
  Controller,
  Get,
  Put,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { SiteIdentityService } from './site-identity.service';
import { UpdateSiteIdentityDto } from './dto/update-site-identity.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { PermissionsGuard } from '../rbac/permissions.guard';
import { Permissions } from '../common/decorators/permissions.decorator';
import { Action, Module } from '@prisma/client';

@Controller('site-identity')
export class SiteIdentityController {
  constructor(private readonly siteIdentityService: SiteIdentityService) {}

  @Get()
  getIdentity() {
    return this.siteIdentityService.getIdentity();
  }

  @Put()
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.CONFIGURACION, action: Action.UPDATE })
  @UseInterceptors(FileInterceptor('icon'))
  updateIdentity(@Body() dto: UpdateSiteIdentityDto, @UploadedFile() icon?: Express.Multer.File) {
    return this.siteIdentityService.updateIdentity(dto, icon);
  }
}
