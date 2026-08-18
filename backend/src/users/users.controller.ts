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
  UseGuards,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { PermissionsGuard } from '../rbac/permissions.guard';
import { Permissions } from '../common/decorators/permissions.decorator';
import { Action, Module } from '@prisma/client';
import { UpdateUserDto } from './dto/update-user.dto';
import { ListUsersQueryDto } from './dto/list-users-query.dto';
import { CreateUserDto } from './dto/create-user.dto';
import { SetUserPermissionsDto } from './dto/set-user-permissions.dto';
import { SetUserPasswordDto } from './dto/set-user-password.dto';

@Controller('users')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  @Permissions({ module: Module.USUARIOS, action: Action.VIEW })
  findAll(@Query() query: ListUsersQueryDto) {
    return this.usersService.findAll(query);
  }

  @Post()
  @Permissions({ module: Module.USUARIOS, action: Action.CREATE })
  create(@Body() dto: CreateUserDto) {
    return this.usersService.createUser(dto);
  }

  @Patch(':id')
  @Permissions({ module: Module.USUARIOS, action: Action.UPDATE })
  update(@Param('id', ParseIntPipe) id: number, @Body() dto: UpdateUserDto) {
    return this.usersService.updateUser(id, dto);
  }

  @Put(':id/permissions')
  @Permissions({ module: Module.PERMISOS, action: Action.MANAGE })
  setPermissions(@Param('id', ParseIntPipe) id: number, @Body() dto: SetUserPermissionsDto) {
    return this.usersService.setUserPermissions(id, dto.permissions);
  }

  @Post(':id/password')
  @Permissions({ module: Module.USUARIOS, action: Action.UPDATE })
  setPassword(@Param('id', ParseIntPipe) id: number, @Body() dto: SetUserPasswordDto) {
    return this.usersService.setUserPassword(id, dto.password);
  }

  @Delete(':id')
  @Permissions({ module: Module.USUARIOS, action: Action.DELETE })
  delete(@Param('id', ParseIntPipe) id: number) {
    return this.usersService.deleteUser(id);
  }
}
