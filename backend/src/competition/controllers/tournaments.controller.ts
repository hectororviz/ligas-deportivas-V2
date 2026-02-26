import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { TournamentsService } from '../services/tournaments.service';
import { CreateTournamentDto } from '../dto/create-tournament.dto';
import { JwtAuthGuard } from '../../auth/jwt-auth.guard';
import { PermissionsGuard } from '../../rbac/permissions.guard';
import { Permissions } from '../../common/decorators/permissions.decorator';
import { Action, Module } from '@prisma/client';
import { CreateZoneDto } from '../dto/create-zone.dto';
import { AddTournamentCategoryDto } from '../dto/add-tournament-category.dto';
import { UpdateTournamentDto } from '../dto/update-tournament.dto';
import { AssignPlayerClubDto } from '../dto/assign-player-club.dto';
import { UpdateTournamentStatusDto } from '../dto/update-tournament-status.dto';

const parseIncludeInactive = (value?: string) =>
  value === 'true' || value === '1';

@Controller()
export class TournamentsController {
  constructor(private readonly tournamentsService: TournamentsService) {}

  @Get('tournaments')
  listAll(@Query('includeInactive') includeInactive?: string) {
    return this.tournamentsService.findAll(parseIncludeInactive(includeInactive));
  }

  @Get('tournaments/active')
  listActive() {
    return this.tournamentsService.findAll(false);
  }

  @Get('leagues/:leagueId/tournaments')
  listByLeague(
    @Param('leagueId', ParseIntPipe) leagueId: number,
    @Query('includeInactive') includeInactive?: string,
  ) {
    return this.tournamentsService.findAllByLeague(
      leagueId,
      parseIncludeInactive(includeInactive),
    );
  }

  @Get('tournaments/:id')
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.tournamentsService.getTournament(id);
  }

  @Get('tournaments/:id/categories')
  listCategories(@Param('id', ParseIntPipe) id: number) {
    return this.tournamentsService.listCategories(id);
  }

  @Get('tournaments/:id/participating-clubs')
  listParticipatingClubs(@Param('id', ParseIntPipe) id: number) {
    return this.tournamentsService.listParticipatingClubs(id);
  }

  @Get('tournaments/:id/zones/clubs')
  listClubsForZones(
    @Param('id', ParseIntPipe) id: number,
    @Query('zoneId') zoneId?: string,
  ) {
    const parsedZoneId =
      typeof zoneId === 'string' && zoneId.trim().length
        ? Number.parseInt(zoneId, 10)
        : undefined;
    return this.tournamentsService.listClubsForZones(
      id,
      Number.isNaN(parsedZoneId) ? undefined : parsedZoneId,
    );
  }

  @Post('tournaments')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.TORNEOS, action: Action.CREATE })
  create(@Body() dto: CreateTournamentDto) {
    return this.tournamentsService.create(dto);
  }

  @Put('tournaments/:id')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.TORNEOS, action: Action.UPDATE })
  update(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateTournamentDto,
  ) {
    return this.tournamentsService.update(id, dto);
  }

  @Put('tournaments/:id/status')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.TORNEOS, action: Action.UPDATE })
  updateStatus(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateTournamentStatusDto,
  ) {
    return this.tournamentsService.updateStatus(id, dto.status);
  }

  @Put('tournaments/:id/player-club')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.JUGADORES, action: Action.UPDATE })
  assignPlayerClub(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: AssignPlayerClubDto,
  ) {
    return this.tournamentsService.assignPlayerClub(id, dto);
  }

  @Post('tournaments/:id/zones')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.ZONAS, action: Action.CREATE })
  addZone(@Param('id', ParseIntPipe) id: number, @Body() dto: CreateZoneDto) {
    return this.tournamentsService.addZone(id, dto);
  }

  @Post('tournaments/:id/categories')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.CATEGORIAS, action: Action.CREATE })
  addCategory(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: AddTournamentCategoryDto
  ) {
    return this.tournamentsService.addCategory(id, dto);
  }
}
