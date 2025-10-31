import {
  Body,
  Controller,
  Get,
  Put,
  Res,
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
import { Response } from 'express';

@Controller('site-identity')
export class SiteIdentityController {
  constructor(private readonly siteIdentityService: SiteIdentityService) {}

  @Get()
  getIdentity() {
    return this.siteIdentityService.getIdentity();
  }

  @Get('icon')
  async getIcon(@Res() res: Response) {
    const file = await this.siteIdentityService.getIconFile();
    res.setHeader('Cache-Control', 'public, max-age=300');
    res.type(file.mimeType);
    return res.sendFile(file.path);
  }

  @Put()
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.CONFIGURACION, action: Action.UPDATE })
  @UseInterceptors(FileInterceptor('icon'))
  updateIdentity(@Body() dto: UpdateSiteIdentityDto, @UploadedFile() icon?: Express.Multer.File) {
    return this.siteIdentityService.updateIdentity(dto, icon);
  }
}
