import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ClubsService } from '../services/clubs.service';
import { CreateClubDto } from '../dto/create-club.dto';
import { JwtAuthGuard } from '../../auth/jwt-auth.guard';
import { PermissionsGuard } from '../../rbac/permissions.guard';
import { Permissions } from '../../common/decorators/permissions.decorator';
import { Action, Module } from '@prisma/client';
import { AssignClubZoneDto } from '../dto/assign-club-zone.dto';
import { UpdateClubTeamsDto } from '../dto/update-club-teams.dto';
import { ListClubsDto } from '../dto/list-clubs.dto';
import { UpdateClubDto } from '../dto/update-club.dto';

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

  @Post('zones/:zoneId/clubs')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.ZONAS, action: Action.UPDATE })
  assignToZone(@Param('zoneId', ParseIntPipe) zoneId: number, @Body() dto: AssignClubZoneDto) {
    return this.clubsService.assignToZone(zoneId, dto);
  }

  @Put('clubs/:id/teams')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.CLUBES, action: Action.UPDATE })
  updateTeams(@Param('id', ParseIntPipe) clubId: number, @Body() dto: UpdateClubTeamsDto) {
    return this.clubsService.updateTeams(clubId, dto);
  }
}
