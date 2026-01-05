import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Put,
  Query,
  Res,
  UploadedFiles,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileFieldsInterceptor } from '@nestjs/platform-express';
import { Action, Module } from '@prisma/client';
import { FlyerTemplatesService } from '../services/flyer-templates.service';
import { PosterTemplatesService } from '../services/poster-templates.service';
import { JwtAuthGuard } from '../../auth/jwt-auth.guard';
import { PermissionsGuard } from '../../rbac/permissions.guard';
import { Permissions } from '../../common/decorators/permissions.decorator';
import { Response } from 'express';

@Controller('competitions')
export class CompetitionController {
  constructor(
    private readonly flyerTemplatesService: FlyerTemplatesService,
    private readonly posterTemplatesService: PosterTemplatesService,
  ) {}

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

  @Get(':competitionId/poster-template')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.CONFIGURACION, action: Action.VIEW })
  getPosterTemplate(@Param('competitionId', ParseIntPipe) competitionId: number) {
    return this.posterTemplatesService.getForTournament(competitionId);
  }

  @Put(':competitionId/poster-template')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.CONFIGURACION, action: Action.UPDATE })
  @UseInterceptors(
    FileFieldsInterceptor([
      { name: 'background', maxCount: 1 },
    ]),
  )
  updatePosterTemplate(
    @Param('competitionId', ParseIntPipe) competitionId: number,
    @Body('template') template: string,
    @UploadedFiles()
    files: {
      background?: Express.Multer.File[];
    },
  ) {
    if (!template) {
      throw new BadRequestException('La plantilla es obligatoria.');
    }
    return this.posterTemplatesService.upsertForTournament(competitionId, {
      template: JSON.parse(template),
      background: files?.background?.[0],
    });
  }

  @Get(':competitionId/poster-template/preview')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.CONFIGURACION, action: Action.VIEW })
  async previewPosterTemplate(
    @Param('competitionId', ParseIntPipe) competitionId: number,
    @Query('matchId', ParseIntPipe) matchId: number,
    @Res() res: Response,
  ) {
    const preview = await this.posterTemplatesService.generatePreviewForTournament(competitionId, matchId);
    res.setHeader('Content-Type', preview.contentType);
    return res.send(preview.buffer);
  }
}
