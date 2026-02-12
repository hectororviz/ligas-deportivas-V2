import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Query,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { Action, Module } from '@prisma/client';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';

import { JwtAuthGuard } from '../../auth/jwt-auth.guard';
import { JwtOptionalAuthGuard } from '../../auth/jwt-optional.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { RequestUser } from '../../common/interfaces/request-user.interface';
import { Permissions } from '../../common/decorators/permissions.decorator';
import { PermissionsGuard } from '../../rbac/permissions.guard';
import { CreatePlayerDto } from '../dto/create-player.dto';
import { ListPlayersDto } from '../dto/list-players.dto';
import { UpdatePlayerDto } from '../dto/update-player.dto';
import { PlayersService } from '../services/players.service';
import { SearchPlayersDto } from '../dto/search-players.dto';

@Controller('players')
export class PlayersController {
  constructor(private readonly playersService: PlayersService) {}

  @Get()
  @UseGuards(JwtOptionalAuthGuard)
  findAll(@Query() query: ListPlayersDto, @CurrentUser() user?: RequestUser) {
    return this.playersService.findAll(query, user);
  }

  @Get('search')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.JUGADORES, action: Action.VIEW })
  search(@Query() query: SearchPlayersDto) {
    return this.playersService.searchByDniAndCategory(query);
  }

  @Get(':id')
  findById(@Param('id', ParseIntPipe) id: number) {
    return this.playersService.findById(id);
  }


  @Post('dni/scan')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @Permissions({ module: Module.JUGADORES, action: Action.CREATE })
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: 8 * 1024 * 1024 },
    }),
  )
  scanDni(@UploadedFile() file?: Express.Multer.File) {
    return this.playersService.scanDniFromImage(file);
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
