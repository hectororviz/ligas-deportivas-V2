import {
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Put,
  Res,
  UploadedFiles,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileFieldsInterceptor } from '@nestjs/platform-express';
import { Action, Module } from '@prisma/client';
import { FlyerTemplatesService } from '../services/flyer-templates.service';
import { JwtAuthGuard } from '../../auth/jwt-auth.guard';
import { PermissionsGuard } from '../../rbac/permissions.guard';
import { Permissions } from '../../common/decorators/permissions.decorator';
import { Response } from 'express';

@Controller('competitions')
export class CompetitionController {
  constructor(private readonly flyerTemplatesService: FlyerTemplatesService) {}

  @Get(':competitionId/flyer-template')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.CONFIGURACION, action: Action.VIEW })
  getTemplate(@Param('competitionId', ParseIntPipe) competitionId: number) {
    return this.flyerTemplatesService.getForCompetition(competitionId);
  }

  @Put(':competitionId/flyer-template')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.CONFIGURACION, action: Action.UPDATE })
  @UseInterceptors(
    FileFieldsInterceptor([
      { name: 'background', maxCount: 1 },
      { name: 'layout', maxCount: 1 },
    ]),
  )
  updateTemplate(
    @Param('competitionId', ParseIntPipe) competitionId: number,
    @UploadedFiles()
    files: {
      background?: Express.Multer.File[];
      layout?: Express.Multer.File[];
    },
  ) {
    return this.flyerTemplatesService.upsertForCompetition(competitionId, {
      background: files?.background?.[0],
      layout: files?.layout?.[0],
    });
  }

  @Delete(':competitionId/flyer-template')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.CONFIGURACION, action: Action.DELETE })
  deleteTemplate(@Param('competitionId', ParseIntPipe) competitionId: number) {
    return this.flyerTemplatesService.deleteForCompetition(competitionId);
  }

  @Get(':competitionId/flyer-template/preview')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.CONFIGURACION, action: Action.VIEW })
  async previewTemplate(
    @Param('competitionId', ParseIntPipe) competitionId: number,
    @Res() res: Response,
  ) {
    const preview = await this.flyerTemplatesService.generatePreviewForCompetition(competitionId);
    res.setHeader('Content-Type', preview.contentType);
    return res.send(preview.buffer);
  }
}
