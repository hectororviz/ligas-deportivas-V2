import {
  Body,
  Controller,
  Get,
  Post,
  Put,
  Res,
  UploadedFile,
  UploadedFiles,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileFieldsInterceptor, FileInterceptor } from '@nestjs/platform-express';
import { SiteIdentityService } from './site-identity.service';
import { UpdateSiteIdentityDto } from './dto/update-site-identity.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { PermissionsGuard } from '../rbac/permissions.guard';
import { Permissions } from '../common/decorators/permissions.decorator';
import { Action, Module } from '@prisma/client';
import { Response } from 'express';
import { UpdateFaviconDto } from './dto/update-favicon.dto';

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

  @Get('flyer')
  async getFlyer(@Res() res: Response) {
    const file = await this.siteIdentityService.getFlyerFile();
    res.setHeader('Cache-Control', 'public, max-age=300');
    res.type(file.mimeType);
    return res.sendFile(file.path);
  }

  @Put()
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.CONFIGURACION, action: Action.UPDATE })
  @UseInterceptors(FileFieldsInterceptor([
    { name: 'icon', maxCount: 1 },
    { name: 'flyer', maxCount: 1 },
  ]))
  updateIdentity(
    @Body() dto: UpdateSiteIdentityDto,
    @UploadedFiles()
    files?: {
      icon?: Express.Multer.File[];
      flyer?: Express.Multer.File[];
    },
  ) {
    const icon = files?.icon?.[0];
    const flyer = files?.flyer?.[0];
    return this.siteIdentityService.updateIdentity(dto, icon, flyer);
  }

  @Post('favicon')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.CONFIGURACION, action: Action.UPDATE })
  @UseInterceptors(FileInterceptor('file'))
  updateFavicon(
    @Body() dto: UpdateFaviconDto,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    return this.siteIdentityService.updateFavicon(file, dto.remove);
  }
}
