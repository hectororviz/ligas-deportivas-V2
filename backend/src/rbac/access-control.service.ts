import { Injectable, NotFoundException } from '@nestjs/common';
import { Permission, RoleKey, Scope } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { PermissionGrant } from '../common/interfaces/request-user.interface';

interface AssignRoleInput {
  leagueId?: number;
  clubId?: number;
  categoryId?: number;
}

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
        roles: {
          include: {
            league: true,
            club: true,
            category: true,
            role: {
              include: {
                permissions: {
                  include: { permission: true }
                }
              }
            }
          }
        }
      }
    });

    if (!user) {
      throw new NotFoundException('Usuario no encontrado');
    }

    return this.buildGrants(user.roles);
  }

  buildGrants(
    roles: Array<
      {
        leagueId: number | null;
        clubId: number | null;
        categoryId: number | null;
      } & {
        role: {
          permissions: Array<{ permission: Permission }>;
        };
      }
    >
  ): PermissionGrant[] {
    const grantsMap = new Map<string, PermissionGrant>();

    for (const assignment of roles) {
      for (const rolePermission of assignment.role.permissions) {
        const permission = rolePermission.permission;
        const key = `${permission.module}:${permission.action}:${permission.scope}`;
        const existing = grantsMap.get(key);
        const scopedGrant = this.createScopedGrant(permission, assignment);
        if (existing) {
          existing.leagues = this.mergeScopes(existing.leagues, scopedGrant.leagues);
          existing.clubs = this.mergeScopes(existing.clubs, scopedGrant.clubs);
          existing.categories = this.mergeScopes(existing.categories, scopedGrant.categories);
        } else {
          grantsMap.set(key, scopedGrant);
        }
      }
    }

    return Array.from(grantsMap.values());
  }

  private createScopedGrant(
    permission: Permission,
    assignment: { leagueId: number | null; clubId: number | null; categoryId: number | null }
  ): PermissionGrant {
    const grant: PermissionGrant = {
      module: permission.module,
      action: permission.action,
      scope: permission.scope
    };

    if (permission.scope === Scope.LIGA && assignment.leagueId) {
      grant.leagues = [assignment.leagueId];
    }
    if (permission.scope === Scope.CLUB && assignment.clubId) {
      grant.clubs = [assignment.clubId];
    }
    if (permission.scope === Scope.CATEGORIA && assignment.categoryId) {
      grant.categories = [assignment.categoryId];
    }

    return grant;
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
