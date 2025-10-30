import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Post,
  UseGuards,
} from '@nestjs/common';

import { ZonesService } from '../services/zones.service';
import { AssignClubZoneDto } from '../dto/assign-club-zone.dto';
import { JwtAuthGuard } from '../../auth/jwt-auth.guard';
import { PermissionsGuard } from '../../rbac/permissions.guard';
import { Permissions } from '../../common/decorators/permissions.decorator';
import { Action, Module } from '@prisma/client';
import { FixtureService } from '../services/fixture.service';
import { ZoneFixtureOptionsDto } from '../dto/zone-fixture-options.dto';

@Controller('zones')
export class ZonesController {
  constructor(
    private readonly zonesService: ZonesService,
    private readonly fixtureService: FixtureService
  ) {}

  @Get()
  list() {
    return this.zonesService.list();
  }

  @Get(':id')
  findById(@Param('id', ParseIntPipe) id: number) {
    return this.zonesService.findById(id);
  }

  @Post(':zoneId/clubs')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.ZONAS, action: Action.UPDATE })
  assignClub(
    @Param('zoneId', ParseIntPipe) zoneId: number,
    @Body() dto: AssignClubZoneDto,
  ) {
    return this.zonesService.assignClub(zoneId, dto.clubId);
  }

  @Delete(':zoneId/clubs/:clubId')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.ZONAS, action: Action.UPDATE })
  removeClub(
    @Param('zoneId', ParseIntPipe) zoneId: number,
    @Param('clubId', ParseIntPipe) clubId: number,
  ) {
    return this.zonesService.removeClub(zoneId, clubId);
  }

  @Post(':zoneId/finalize')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.ZONAS, action: Action.UPDATE })
  finalize(@Param('zoneId', ParseIntPipe) zoneId: number) {
    return this.zonesService.finalize(zoneId);
  }

  @Post(':zoneId/fixture/preview')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.FIXTURE, action: Action.CREATE })
  previewFixture(
    @Param('zoneId', ParseIntPipe) zoneId: number,
    @Body() options: ZoneFixtureOptionsDto
  ) {
    return this.fixtureService.previewForZone(zoneId, options);
  }

  @Post(':zoneId/fixture')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.FIXTURE, action: Action.CREATE })
  generateFixture(
    @Param('zoneId', ParseIntPipe) zoneId: number,
    @Body() options: ZoneFixtureOptionsDto
  ) {
    return this.fixtureService.generateForZone(zoneId, options);
  }
}
