import { Body, Controller, Get, Param, ParseIntPipe, Patch, UseGuards } from '@nestjs/common';
import { AccessControlService } from './access-control.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { PermissionsGuard } from './permissions.guard';
import { Permissions } from '../common/decorators/permissions.decorator';
import { Action, Module } from '@prisma/client';
import { SetRolePermissionsDto } from './dto/set-role-permissions.dto';

@Controller('roles')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class RolesController {
  constructor(private readonly accessControlService: AccessControlService) {}

  @Get()
  @Permissions({ module: Module.ROLES, action: Action.VIEW })
  listRoles() {
    return this.accessControlService.listRoles();
  }

  @Get('permissions')
  @Permissions({ module: Module.PERMISOS, action: Action.VIEW })
  listPermissions() {
    return this.accessControlService.listPermissions();
  }

  @Patch(':roleId/permissions')
  @Permissions({ module: Module.PERMISOS, action: Action.MANAGE })
  updateRolePermissions(
    @Param('roleId', ParseIntPipe) roleId: number,
    @Body() dto: SetRolePermissionsDto
  ) {
    return this.accessControlService.setRolePermissions(roleId, dto.permissionIds);
  }
}
