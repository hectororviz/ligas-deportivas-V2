import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Query,
  UseGuards
} from '@nestjs/common';
import { Action, Module } from '@prisma/client';

import { JwtAuthGuard } from '../../auth/jwt-auth.guard';
import { Permissions } from '../../common/decorators/permissions.decorator';
import { PermissionsGuard } from '../../rbac/permissions.guard';
import { CreatePlayerDto } from '../dto/create-player.dto';
import { ListPlayersDto } from '../dto/list-players.dto';
import { UpdatePlayerDto } from '../dto/update-player.dto';
import { PlayersService } from '../services/players.service';

@Controller('players')
export class PlayersController {
  constructor(private readonly playersService: PlayersService) {}

  @Get()
  findAll(@Query() query: ListPlayersDto) {
    return this.playersService.findAll(query);
  }

  @Get(':id')
  findById(@Param('id', ParseIntPipe) id: number) {
    return this.playersService.findById(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.JUGADORES, action: Action.CREATE })
  create(@Body() dto: CreatePlayerDto) {
    return this.playersService.create(dto);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.JUGADORES, action: Action.UPDATE })
  update(@Param('id', ParseIntPipe) id: number, @Body() dto: UpdatePlayerDto) {
    return this.playersService.update(id, dto);
  }
}
