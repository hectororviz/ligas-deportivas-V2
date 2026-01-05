import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Res,
  UploadedFile,
  UseGuards,
  UseInterceptors
} from '@nestjs/common';
import { MatchesService } from '../services/matches.service';
import { JwtAuthGuard } from '../../auth/jwt-auth.guard';
import { PermissionsGuard } from '../../rbac/permissions.guard';
import { Permissions } from '../../common/decorators/permissions.decorator';
import { Action, Module } from '@prisma/client';
import { UpdateMatchDto } from '../dto/update-match.dto';
import { RecordMatchResultDto } from '../dto/record-match-result.dto';
import { FileInterceptor } from '@nestjs/platform-express';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { RequestUser } from '../../common/interfaces/request-user.interface';
import { UpdateMatchdayDto } from '../dto/update-matchday.dto';
import { MatchFlyerService } from '../services/match-flyer.service';
import { MatchPosterService } from '../services/match-poster.service';
import { Response } from 'express';
import { MATCH_FLYER_TOKEN_DEFINITIONS } from '../dto/match-flyer-token.dto';
import { MATCH_POSTER_TOKEN_DEFINITIONS } from '../dto/match-poster-token.dto';

@Controller()
export class MatchesController {
  constructor(
    private readonly matchesService: MatchesService,
    private readonly matchFlyerService: MatchFlyerService,
    private readonly matchPosterService: MatchPosterService,
  ) {}

  @Get('zones/:zoneId/matches')
  getByZone(@Param('zoneId', ParseIntPipe) zoneId: number) {
    return this.matchesService.listByZone(zoneId);
  }

  @Post('zones/:zoneId/matchdays/:matchday/finalize')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.FIXTURE, action: Action.UPDATE })
  finalizeMatchday(
    @Param('zoneId', ParseIntPipe) zoneId: number,
    @Param('matchday', ParseIntPipe) matchday: number
  ) {
    return this.matchesService.finalizeMatchday(zoneId, matchday);
  }

  @Get('zones/:zoneId/matchdays/:matchday/summary')
  getMatchdaySummary(
    @Param('zoneId', ParseIntPipe) zoneId: number,
    @Param('matchday', ParseIntPipe) matchday: number
  ) {
    return this.matchesService.getMatchdaySummary(zoneId, matchday);
  }

  @Patch('zones/:zoneId/matchdays/:matchday')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.FIXTURE, action: Action.UPDATE })
  updateMatchday(
    @Param('zoneId', ParseIntPipe) zoneId: number,
    @Param('matchday', ParseIntPipe) matchday: number,
    @Body() dto: UpdateMatchdayDto
  ) {
    return this.matchesService.updateMatchdayDate(zoneId, matchday, dto);
  }

  @Get('matches/:matchId/categories/:categoryId/result')
  getResult(
    @Param('matchId', ParseIntPipe) matchId: number,
    @Param('categoryId', ParseIntPipe) categoryId: number
  ) {
    return this.matchesService.getResult(matchId, categoryId);
  }

  @Get('matches/flyer/tokens')
  listFlyerTokens() {
    return MATCH_FLYER_TOKEN_DEFINITIONS;
  }

  @Get('matches/poster/tokens')
  listPosterTokens() {
    return MATCH_POSTER_TOKEN_DEFINITIONS;
  }

  @Get('matches/:matchId/flyer')
  async downloadFlyer(
    @Param('matchId', ParseIntPipe) matchId: number,
    @Res() res: Response,
  ) {
    const flyer = await this.matchFlyerService.generate(matchId);
    res.setHeader('Content-Type', flyer.contentType);
    res.setHeader('Content-Disposition', `attachment; filename="flyer-${matchId}.${flyer.fileExtension}"`);
    return res.send(flyer.buffer);
  }

  @Get('matches/:matchId/poster')
  async downloadPoster(
    @Param('matchId', ParseIntPipe) matchId: number,
    @Res() res: Response,
  ) {
    const poster = await this.matchPosterService.generate(matchId);
    res.setHeader('Content-Type', poster.contentType);
    res.setHeader('Content-Disposition', `attachment; filename=\"poster-${matchId}.${poster.fileExtension}\"`);
    return res.send(poster.buffer);
  }

  @Patch('matches/:matchId')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.PARTIDOS, action: Action.UPDATE })
  updateMatch(@Param('matchId', ParseIntPipe) matchId: number, @Body() dto: UpdateMatchDto) {
    return this.matchesService.updateMatch(matchId, dto);
  }

  @Post('matches/:matchId/categories/:categoryId/result')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @UseInterceptors(FileInterceptor('attachment'))
  @Permissions({ module: Module.RESULTADOS, action: Action.UPDATE })
  recordResult(
    @Param('matchId', ParseIntPipe) matchId: number,
    @Param('categoryId', ParseIntPipe) categoryId: number,
    @Body() dto: RecordMatchResultDto,
    @CurrentUser() user: RequestUser,
    @UploadedFile() attachment?: Express.Multer.File
  ) {
    return this.matchesService.recordResult(matchId, categoryId, dto, user.id, attachment);
  }
}
