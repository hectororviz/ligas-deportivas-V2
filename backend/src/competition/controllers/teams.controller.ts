import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { Action, Module } from '@prisma/client';

import { JwtAuthGuard } from '../../auth/jwt-auth.guard';
import { Permissions } from '../../common/decorators/permissions.decorator';
import { PermissionsGuard } from '../../rbac/permissions.guard';
import { CreateTeamDto } from '../dto/create-team.dto';
import { TeamsService } from '../services/teams.service';

@Controller('teams')
export class TeamsController {
  constructor(private readonly teamsService: TeamsService) {}

  @Post()
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.PLANTELES, action: Action.CREATE })
  create(@Body() dto: CreateTeamDto) {
    return this.teamsService.create(dto);
  }
}
