import { Body, Controller, Get, Param, ParseIntPipe, Post, Put, UseGuards } from '@nestjs/common';
import { TournamentsService } from '../services/tournaments.service';
import { CreateTournamentDto } from '../dto/create-tournament.dto';
import { JwtAuthGuard } from '../../auth/jwt-auth.guard';
import { PermissionsGuard } from '../../rbac/permissions.guard';
import { Permissions } from '../../common/decorators/permissions.decorator';
import { Action, Module } from '@prisma/client';
import { CreateZoneDto } from '../dto/create-zone.dto';
import { AddTournamentCategoryDto } from '../dto/add-tournament-category.dto';
import { UpdateTournamentDto } from '../dto/update-tournament.dto';

@Controller()
export class TournamentsController {
  constructor(private readonly tournamentsService: TournamentsService) {}

  @Get('tournaments')
  listAll() {
    return this.tournamentsService.findAll();
  }

  @Get('leagues/:leagueId/tournaments')
  listByLeague(@Param('leagueId', ParseIntPipe) leagueId: number) {
    return this.tournamentsService.findAllByLeague(leagueId);
  }

  @Get('tournaments/:id')
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.tournamentsService.getTournament(id);
  }

  @Get('tournaments/:id/zones/clubs')
  listClubsForZones(@Param('id', ParseIntPipe) id: number) {
    return this.tournamentsService.listClubsForZones(id);
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
