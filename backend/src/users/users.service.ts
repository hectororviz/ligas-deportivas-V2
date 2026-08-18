import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateUserDto } from './dto/update-user.dto';
import { AccessControlService } from '../rbac/access-control.service';
import { Module, PermissionLevel } from '@prisma/client';
import { ListUsersQueryDto } from './dto/list-users-query.dto';
import { CreateUserDto, UserPermissionInput } from './dto/create-user.dto';
import * as argon2 from 'argon2';

interface UserWithRelations {
  id: number;
  username: string;
  firstName: string;
  lastName: string;
  isAdmin: boolean;
  club: { id: number; name: string } | null;
  permissions: Array<{ module: Module; level: PermissionLevel }>;
}

@Injectable()
export class UsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly accessControlService: AccessControlService,
  ) {}

  async findAll(query: ListUsersQueryDto) {
    const page = query.page ?? 1;
    const pageSize = query.pageSize ?? 20;
    const skip = (page - 1) * pageSize;
    const search = query.search?.trim();
    const searchFilter = search
      ? {
          OR: [
            { username: { contains: search, mode: 'insensitive' as const } },
            { firstName: { contains: search, mode: 'insensitive' as const } },
            { lastName: { contains: search, mode: 'insensitive' as const } },
          ],
        }
      : undefined;
    const where = searchFilter ? { AND: [searchFilter] } : {};

    const [total, users] = await this.prisma.$transaction([
      this.prisma.user.count({ where }),
      this.prisma.user.findMany({
        where,
        skip,
        take: pageSize,
        orderBy: { createdAt: 'asc' },
        include: {
          club: {
            select: {
              id: true,
              name: true,
            },
          },
          permissions: true,
        },
      }),
    ]);

    return {
      data: users.map((user) => this.mapUser(user)),
      meta: {
        total,
        page,
        pageSize,
      },
    };
  }

  async findById(userId: number) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        club: { select: { id: true, name: true } },
        permissions: true,
      },
    });
    if (!user) {
      throw new NotFoundException('Usuario no encontrado');
    }
    return this.mapUser(user);
  }

  async createUser(dto: CreateUserDto) {
    const username = dto.username.trim().toLowerCase();
    const existing = await this.prisma.user.findUnique({ where: { username } });
    if (existing) {
      throw new BadRequestException('El nombre de usuario ya está en uso.');
    }

    const passwordHash = await argon2.hash(dto.password, { type: argon2.argon2id });
    const permissions = this.dedupePermissions(dto.permissions);

    const user = await this.prisma.user.create({
      data: {
        username,
        passwordHash,
        firstName: dto.firstName.trim(),
        lastName: dto.lastName.trim(),
        clubId: dto.clubId ?? null,
        permissions: {
          create: permissions.map((permission) => ({
            module: permission.module,
            level: permission.level,
          })),
        },
      },
      include: {
        club: { select: { id: true, name: true } },
        permissions: true,
      },
    });

    return this.mapUser(user);
  }

  async updateUser(id: number, dto: UpdateUserDto) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) {
      throw new NotFoundException('Usuario no encontrado');
    }

    const data: Record<string, unknown> = {};
    if (dto.firstName !== undefined) data.firstName = dto.firstName.trim();
    if (dto.lastName !== undefined) data.lastName = dto.lastName.trim();
    if (dto.clubId !== undefined) data.clubId = dto.clubId;

    const updated = await this.prisma.user.update({
      where: { id },
      data,
      include: {
        club: { select: { id: true, name: true } },
        permissions: true,
      },
    });

    return this.mapUser(updated);
  }

  async setUserPermissions(userId: number, permissions: UserPermissionInput[]) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('Usuario no encontrado');
    }
    if (user.isAdmin) {
      throw new BadRequestException('No se pueden modificar los permisos del administrador.');
    }

    const deduped = this.dedupePermissions(permissions);

    await this.prisma.$transaction([
      this.prisma.userPermission.deleteMany({ where: { userId } }),
      ...(deduped.length
        ? [
            this.prisma.userPermission.createMany({
              data: deduped.map((permission) => ({
                userId,
                module: permission.module,
                level: permission.level,
              })),
            }),
          ]
        : []),
    ]);

    return this.findById(userId);
  }

  async setUserPassword(userId: number, password: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('Usuario no encontrado');
    }

    const passwordHash = await argon2.hash(password, { type: argon2.argon2id });

    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: userId },
        data: { passwordHash },
      }),
      this.prisma.userToken.deleteMany({ where: { userId } }),
    ]);

    return { success: true };
  }

  async deleteUser(userId: number) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });

    if (!user) {
      throw new NotFoundException('Usuario no encontrado');
    }

    if (user.isAdmin) {
      throw new BadRequestException('No se puede eliminar al administrador.');
    }

    await this.prisma.$transaction([
      this.prisma.matchCategory.updateMany({
        where: { closedById: userId },
        data: { closedById: null },
      }),
      this.prisma.matchLog.updateMany({
        where: { userId },
        data: { userId: null },
      }),
      this.prisma.auditLog.updateMany({
        where: { userId },
        data: { userId: null },
      }),
      this.prisma.matchAttachment.deleteMany({
        where: { uploadedById: userId },
      }),
      this.prisma.userPermission.deleteMany({ where: { userId } }),
      this.prisma.userRole.deleteMany({ where: { userId } }),
      this.prisma.userToken.deleteMany({ where: { userId } }),
      this.prisma.user.delete({ where: { id: userId } }),
    ]);

    return { success: true };
  }

  private dedupePermissions(permissions: UserPermissionInput[]): UserPermissionInput[] {
    const map = new Map<Module, PermissionLevel>();
    for (const permission of permissions) {
      map.set(permission.module, permission.level);
    }
    return Array.from(map.entries()).map(([module, level]) => ({ module, level }));
  }

  private mapUser(user: UserWithRelations) {
    return {
      id: user.id,
      username: user.username,
      firstName: user.firstName,
      lastName: user.lastName,
      isAdmin: user.isAdmin,
      club: user.club ? { id: user.club.id, name: user.club.name } : null,
      moduleLevels: this.accessControlService.buildModuleLevels(user.permissions),
    };
  }
}
