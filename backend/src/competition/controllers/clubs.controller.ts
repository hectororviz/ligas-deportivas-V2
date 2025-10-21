import { Body, Controller, Get, Param, ParseIntPipe, Post, UseGuards } from '@nestjs/common';
import { ClubsService } from '../services/clubs.service';
import { CreateClubDto } from '../dto/create-club.dto';
import { JwtAuthGuard } from '../../auth/jwt-auth.guard';
import { PermissionsGuard } from '../../rbac/permissions.guard';
import { Permissions } from '../../common/decorators/permissions.decorator';
import { Action, Module } from '@prisma/client';
import { AssignClubZoneDto } from '../dto/assign-club-zone.dto';

@Controller()
export class ClubsController {
  constructor(private readonly clubsService: ClubsService) {}

  @Get('clubs')
  findAll() {
    return this.clubsService.findAll();
  }

  @Post('clubs')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.CLUBES, action: Action.CREATE })
  create(@Body() dto: CreateClubDto) {
    return this.clubsService.create(dto);
  }

  @Post('zones/:zoneId/clubs')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.ZONAS, action: Action.UPDATE })
  assignToZone(@Param('zoneId', ParseIntPipe) zoneId: number, @Body() dto: AssignClubZoneDto) {
    return this.clubsService.assignToZone(zoneId, dto);
  }
}
