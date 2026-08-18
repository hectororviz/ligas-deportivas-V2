import { Injectable, NotFoundException } from '@nestjs/common';
import {
  Action,
  Module,
  Permission,
  PermissionLevel,
  RoleKey,
  Scope
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { PermissionGrant } from '../common/interfaces/request-user.interface';

interface AssignRoleInput {
  leagueId?: number;
  clubId?: number;
  categoryId?: number;
}

export const MATRIX_MODULES: Module[] = [
  Module.LIGAS,
  Module.TORNEOS,
  Module.ZONAS,
  Module.CATEGORIAS,
  Module.JUGADORES,
  Module.CLUBES,
  Module.CONFIGURACION
];

const MODULE_EXPANSION: Partial<Record<Module, Module[]>> = {
  [Module.LIGAS]: [Module.LIGAS],
  [Module.TORNEOS]: [
    Module.TORNEOS,
    Module.FIXTURE,
    Module.PARTIDOS,
    Module.RESULTADOS
  ],
  [Module.ZONAS]: [Module.ZONAS, Module.FIXTURE],
  [Module.CATEGORIAS]: [Module.CATEGORIAS],
  [Module.JUGADORES]: [Module.JUGADORES, Module.PLANTELES],
  [Module.CLUBES]: [Module.CLUBES],
  [Module.CONFIGURACION]: [
    Module.CONFIGURACION,
    Module.USUARIOS,
    Module.ROLES,
    Module.PERMISOS
  ]
};

@Injectable()
export class AccessControlService {
  constructor(private readonly prisma: PrismaService) {}

  async listRoles() {
    return this.prisma.role.findMany({
      orderBy: { id: 'asc' },
      include: {
        permissions: {
          include: { permission: true }
        }
      }
    });
  }

  async listPermissions(): Promise<Permission[]> {
    return this.prisma.permission.findMany({ orderBy: [{ module: 'asc' }, { action: 'asc' }] });
  }

  async getRoleByKey(roleKey: RoleKey) {
    const role = await this.prisma.role.findUnique({ where: { key: roleKey } });
    if (!role) {
      throw new NotFoundException(`Rol ${roleKey} no encontrado`);
    }
    return role;
  }

  async assignRoleToUser(userId: number, roleKey: RoleKey, input: AssignRoleInput = {}) {
    const role = await this.getRoleByKey(roleKey);

    const existing = await this.prisma.userRole.findFirst({
      where: {
        userId,
        roleId: role.id,
        leagueId: input.leagueId ?? null,
        clubId: input.clubId ?? null,
        categoryId: input.categoryId ?? null
      }
    });

    if (existing) {
      return existing;
    }

    return this.prisma.userRole.create({
      data: {
        userId,
        roleId: role.id,
        leagueId: input.leagueId,
        clubId: input.clubId,
        categoryId: input.categoryId
      }
    });
  }

  async removeRoleFromUser(userRoleId: number) {
    return this.prisma.userRole.delete({ where: { id: userRoleId } });
  }

  async setRolePermissions(roleId: number, permissionIds: number[]) {
    await this.prisma.role.findUniqueOrThrow({ where: { id: roleId } });
    await this.prisma.rolePermission.deleteMany({ where: { roleId } });
    if (permissionIds.length) {
      await this.prisma.rolePermission.createMany({
        data: permissionIds.map((permissionId) => ({ roleId, permissionId })),
        skipDuplicates: true
      });
    }
    return this.prisma.role.findUnique({
      where: { id: roleId },
      include: {
        permissions: {
          include: { permission: true }
        }
      }
    });
  }

  async getUserGrants(userId: number): Promise<PermissionGrant[]> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        club: { select: { id: true } },
        permissions: true
      }
    });

    if (!user) {
      throw new NotFoundException('Usuario no encontrado');
    }

    return this.buildGrantsFromLevels(user.permissions, user.club?.id ?? null);
  }

  buildGrantsFromLevels(
    levels: Array<{ module: Module; level: PermissionLevel }>,
    clubId: number | null
  ): PermissionGrant[] {
    const grantsMap = new Map<string, PermissionGrant>();

    for (const entry of levels) {
      const internalModules = MODULE_EXPANSION[entry.module] ?? [entry.module];
      for (const module of internalModules) {
        const grants = this.levelToGrants(module, entry.level, clubId);
        for (const grant of grants) {
          const key = `${grant.module}:${grant.action}:${grant.scope}`;
          const existing = grantsMap.get(key);
          if (existing) {
            existing.leagues = this.mergeScopes(existing.leagues, grant.leagues);
            existing.clubs = this.mergeScopes(existing.clubs, grant.clubs);
            existing.categories = this.mergeScopes(existing.categories, grant.categories);
          } else {
            grantsMap.set(key, grant);
          }
        }
      }
    }

    return Array.from(grantsMap.values());
  }

  buildModuleLevels(
    permissions: Array<{ module: Module; level: PermissionLevel }>
  ): Record<string, PermissionLevel> {
    const levels: Record<string, PermissionLevel> = {};
    for (const module of MATRIX_MODULES) {
      levels[module] = PermissionLevel.NO;
    }
    for (const permission of permissions) {
      if (MATRIX_MODULES.includes(permission.module)) {
        levels[permission.module] = permission.level;
      }
    }
    return levels;
  }

  private levelToGrants(
    module: Module,
    level: PermissionLevel,
    clubId: number | null
  ): PermissionGrant[] {
    switch (level) {
      case PermissionLevel.TOTAL:
      case PermissionLevel.MODIFICACION:
        return [{ module, action: Action.MANAGE, scope: Scope.GLOBAL }];
      case PermissionLevel.LECTURA:
        return [{ module, action: Action.VIEW, scope: Scope.GLOBAL }];
      case PermissionLevel.LECTURA_CLUB:
        return clubId ? [{ module, action: Action.VIEW, scope: Scope.CLUB, clubs: [clubId] }] : [];
      case PermissionLevel.MODIFICACION_CLUB:
        return clubId
          ? [{ module, action: Action.MANAGE, scope: Scope.CLUB, clubs: [clubId] }]
          : [];
      case PermissionLevel.NO:
      default:
        return [];
    }
  }

  private mergeScopes(target: number[] | undefined, source: number[] | undefined) {
    if (!source || !source.length) {
      return target;
    }
    if (!target) {
      return [...new Set(source)];
    }
    const merged = new Set([...target, ...source]);
    return Array.from(merged);
  }
}
