import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Put,
  Query,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { ClubsService } from '../services/clubs.service';
import { CreateClubDto } from '../dto/create-club.dto';
import { JwtAuthGuard } from '../../auth/jwt-auth.guard';
import { PermissionsGuard } from '../../rbac/permissions.guard';
import { Permissions } from '../../common/decorators/permissions.decorator';
import { Action, Module } from '@prisma/client';
import { UpdateClubTeamsDto } from '../dto/update-club-teams.dto';
import { ListClubsDto } from '../dto/list-clubs.dto';
import { UpdateClubDto } from '../dto/update-club.dto';
import { ListAssignedPlayersDto } from '../dto/list-assigned-players.dto';
import { ListRosterPlayersDto } from '../dto/list-roster-players.dto';
import { UpdateRosterPlayersDto } from '../dto/update-roster-players.dto';
import { JoinTournamentDto } from '../dto/join-tournament.dto';
import { FileInterceptor } from '@nestjs/platform-express';
import { Express } from 'express';

@Controller()
export class ClubsController {
  constructor(private readonly clubsService: ClubsService) {}

  @Get('clubs')
  findAll(@Query() query: ListClubsDto) {
    return this.clubsService.findAll(query);
  }

  @Get('clubs/:id')
  findOne(@Param('id', ParseIntPipe) clubId: number) {
    return this.clubsService.findById(clubId);
  }

  @Get('clubs/:slug/admin')
  findAdminOverview(@Param('slug') slug: string) {
    return this.clubsService.findAdminOverviewBySlug(slug);
  }

  @Get('clubs/:clubId/tournament-categories/:tournamentCategoryId/eligible-players')
  listEligibleRosterPlayers(
    @Param('clubId', ParseIntPipe) clubId: number,
    @Param('tournamentCategoryId', ParseIntPipe) tournamentCategoryId: number,
    @Query() query: ListRosterPlayersDto,
  ) {
    return this.clubsService.listEligibleRosterPlayers(clubId, tournamentCategoryId, query);
  }

  @Get('clubs/:clubId/tournament-categories/:tournamentCategoryId/assigned-players')
  listAssignedPlayers(
    @Param('clubId', ParseIntPipe) clubId: number,
    @Param('tournamentCategoryId', ParseIntPipe) tournamentCategoryId: number,
    @Query() query: ListAssignedPlayersDto,
  ) {
    return this.clubsService.listAssignedPlayers(clubId, tournamentCategoryId, query);
  }

  @Put('clubs/:clubId/tournament-categories/:tournamentCategoryId/eligible-players')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.CLUBES, action: Action.UPDATE })
  updateRosterPlayers(
    @Param('clubId', ParseIntPipe) clubId: number,
    @Param('tournamentCategoryId', ParseIntPipe) tournamentCategoryId: number,
    @Body() dto: UpdateRosterPlayersDto,
  ) {
    return this.clubsService.updateRosterPlayers(clubId, tournamentCategoryId, dto);
  }

  @Get('clubs/:clubId/available-tournaments')
  listAvailableTournaments(@Param('clubId', ParseIntPipe) clubId: number) {
    return this.clubsService.listAvailableTournaments(clubId);
  }

  @Post('clubs/:clubId/available-tournaments')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.CLUBES, action: Action.UPDATE })
  joinTournament(
    @Param('clubId', ParseIntPipe) clubId: number,
    @Body() dto: JoinTournamentDto,
  ) {
    return this.clubsService.joinTournament(clubId, dto);
  }

  @Delete('clubs/:clubId/tournaments/:tournamentId')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.CLUBES, action: Action.UPDATE })
  leaveTournament(
    @Param('clubId', ParseIntPipe) clubId: number,
    @Param('tournamentId', ParseIntPipe) tournamentId: number,
  ) {
    return this.clubsService.leaveTournament(clubId, tournamentId);
  }

  @Post('clubs')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.CLUBES, action: Action.CREATE })
  create(@Body() dto: CreateClubDto) {
    return this.clubsService.create(dto);
  }

  @Patch('clubs/:id')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.CLUBES, action: Action.UPDATE })
  update(@Param('id', ParseIntPipe) clubId: number, @Body() dto: UpdateClubDto) {
    return this.clubsService.update(clubId, dto);
  }

  @Put('clubs/:id/teams')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.CLUBES, action: Action.UPDATE })
  updateTeams(@Param('id', ParseIntPipe) clubId: number, @Body() dto: UpdateClubTeamsDto) {
    return this.clubsService.updateTeams(clubId, dto);
  }

  @Put('clubs/:id/logo')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.CLUBES, action: Action.UPDATE })
  @UseInterceptors(FileInterceptor('logo'))
  uploadLogo(
    @Param('id', ParseIntPipe) clubId: number,
    @UploadedFile() logo?: Express.Multer.File,
  ) {
    return this.clubsService.updateLogo(clubId, logo);
  }

  @Delete('clubs/:id/logo')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.CLUBES, action: Action.UPDATE })
  removeLogo(@Param('id', ParseIntPipe) clubId: number) {
    return this.clubsService.removeLogo(clubId);
  }
}
