import { Body, Controller, Delete, Get, Param, ParseIntPipe, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { PermissionsGuard } from '../rbac/permissions.guard';
import { Permissions } from '../common/decorators/permissions.decorator';
import { Action, Module } from '@prisma/client';
import { PaginationQueryDto } from '../common/dto/pagination.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { AssignRoleDto } from './dto/assign-role.dto';

@Controller('users')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  @Permissions({ module: Module.USUARIOS, action: Action.VIEW })
  findAll(@Query() pagination: PaginationQueryDto) {
    return this.usersService.findAll(pagination);
  }

  @Patch(':id')
  @Permissions({ module: Module.USUARIOS, action: Action.UPDATE })
  update(@Param('id', ParseIntPipe) id: number, @Body() dto: UpdateUserDto) {
    return this.usersService.updateUser(id, dto);
  }

  @Post(':id/roles')
  @Permissions({ module: Module.ROLES, action: Action.MANAGE })
  assignRole(@Param('id', ParseIntPipe) id: number, @Body() dto: AssignRoleDto) {
    return this.usersService.assignRole(id, dto);
  }

  @Delete('roles/:assignmentId')
  @Permissions({ module: Module.ROLES, action: Action.MANAGE })
  removeRole(@Param('assignmentId', ParseIntPipe) assignmentId: number) {
    return this.usersService.removeRole(assignmentId);
  }
}
