import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Action, Scope } from '@prisma/client';
import {
  PERMISSIONS_KEY,
  PermissionCondition,
  PermissionRequirement
} from '../common/decorators/permissions.decorator';
import { RequestUser } from '../common/interfaces/request-user.interface';

@Injectable()
export class PermissionsGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requirements = this.reflector.getAllAndOverride<PermissionCondition[]>(PERMISSIONS_KEY, [
      context.getHandler(),
      context.getClass()
    ]);

    if (!requirements || requirements.length === 0) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const user: RequestUser | undefined = request.user;

    if (!user) {
      throw new ForbiddenException('Usuario no autenticado');
    }

    const hasAllPermissions = requirements.every((requirement) =>
      this.satisfiesRequirement(user, requirement)
    );

    if (!hasAllPermissions) {
      throw new ForbiddenException('Permisos insuficientes');
    }

    return true;
  }

  private satisfiesRequirement(user: RequestUser, requirement: PermissionCondition): boolean {
    if (Array.isArray(requirement)) {
      return requirement.some((option) => this.hasPermission(user, option));
    }
    return this.hasPermission(user, requirement);
  }

  private hasPermission(user: RequestUser, requirement: PermissionRequirement): boolean {
    return user.permissions.some((grant) => {
      if (grant.module !== requirement.module) {
        return false;
      }

      if (grant.action !== requirement.action && grant.action !== Action.MANAGE) {
        return false;
      }

      if (!requirement.scope) {
        return true;
      }

      if (grant.scope === Scope.GLOBAL) {
        return true;
      }

      return grant.scope === requirement.scope;
    });
  }
}
