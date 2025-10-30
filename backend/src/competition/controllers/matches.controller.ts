import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
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

@Controller()
export class MatchesController {
  constructor(private readonly matchesService: MatchesService) {}

  @Get('zones/:zoneId/matches')
  getByZone(@Param('zoneId', ParseIntPipe) zoneId: number) {
    return this.matchesService.listByZone(zoneId);
  }

  @Get('matches/:matchId/categories/:categoryId/result')
  getResult(
    @Param('matchId', ParseIntPipe) matchId: number,
    @Param('categoryId', ParseIntPipe) categoryId: number
  ) {
    return this.matchesService.getResult(matchId, categoryId);
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
