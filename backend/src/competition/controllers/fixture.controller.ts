import { Body, Controller, Param, ParseIntPipe, Post, UseGuards } from '@nestjs/common';
import { FixtureService } from '../services/fixture.service';
import { JwtAuthGuard } from '../../auth/jwt-auth.guard';
import { PermissionsGuard } from '../../rbac/permissions.guard';
import { Permissions } from '../../common/decorators/permissions.decorator';
import { Action, Module } from '@prisma/client';
import { GenerateFixtureDto } from '../dto/generate-fixture.dto';

@Controller('tournaments')
export class FixtureController {
  constructor(private readonly fixtureService: FixtureService) {}

  @Post(':id/fixtures/generate')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.FIXTURE, action: Action.CREATE })
  generate(@Param('id', ParseIntPipe) id: number, @Body() dto: GenerateFixtureDto) {
    return this.fixtureService.generateForTournament(id, dto);
  }
}
