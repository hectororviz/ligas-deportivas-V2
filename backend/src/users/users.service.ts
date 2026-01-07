import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateUserDto } from './dto/update-user.dto';
import { AssignRoleDto } from './dto/assign-role.dto';
import { AccessControlService } from '../rbac/access-control.service';
import { RoleKey } from '@prisma/client';
import { ListUsersQueryDto } from './dto/list-users-query.dto';
import { MailService } from '../mail/mail.service';
import { randomBytes } from 'crypto';

@Injectable()
export class UsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly accessControlService: AccessControlService,
    private readonly mailService: MailService,
  ) {}

  async findAll(query: ListUsersQueryDto) {
    const page = query.page ?? 1;
    const pageSize = query.pageSize ?? 20;
    const skip = (page - 1) * pageSize;
    const search = query.search?.trim();
    const where = search
      ? {
          OR: [
            { email: { contains: search, mode: 'insensitive' as const } },
            { firstName: { contains: search, mode: 'insensitive' as const } },
            { lastName: { contains: search, mode: 'insensitive' as const } },
          ],
        }
      : undefined;

    const [total, users] = await this.prisma.$transaction([
      this.prisma.user.count({ where }),
      this.prisma.user.findMany({
        where,
        skip,
        take: pageSize,
        orderBy: { createdAt: 'desc' },
        include: {
          club: {
            select: {
              id: true,
              name: true,
            },
          },
          roles: {
            include: {
              role: true,
              league: true,
              club: true,
              category: true,
            },
          },
        },
      }),
    ]);

    return {
      data: users,
      meta: {
        total,
        page,
        pageSize,
      },
    };
  }

  async updateUser(id: number, dto: UpdateUserDto) {
    await this.prisma.user.findUniqueOrThrow({ where: { id } });
    return this.prisma.user.update({
      where: { id },
      data: dto,
    });
  }

  async assignRole(userId: number, dto: AssignRoleDto) {
    await this.prisma.user.findUniqueOrThrow({ where: { id: userId } });
    return this.accessControlService.assignRoleToUser(userId, dto.roleKey as RoleKey, {
      leagueId: dto.leagueId,
      clubId: dto.clubId,
      categoryId: dto.categoryId,
    });
  }

  async removeRole(assignmentId: number) {
    const assignment = await this.prisma.userRole.findUnique({ where: { id: assignmentId } });
    if (!assignment) {
      throw new NotFoundException('Asignación no encontrada');
    }
    await this.accessControlService.removeRoleFromUser(assignmentId);
    return { success: true };
  }

  async sendPasswordReset(userId: number) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('Usuario no encontrado');
    }

    const token = randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 1000 * 60 * 60);

    await this.prisma.passwordResetToken.create({
      data: {
        userId,
        token,
        expiresAt,
      },
    });

    await this.mailService.sendPasswordReset(user.email, token, user.firstName);
    return { success: true };
  }

  async deleteUser(userId: number) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        roles: {
          include: {
            role: true,
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('Usuario no encontrado');
    }

    const isAdmin = user.roles.some((role) => role.role.key === RoleKey.ADMIN);
    if (isAdmin) {
      const adminCount = await this.prisma.userRole.count({
        where: {
          role: {
            key: RoleKey.ADMIN,
          },
        },
      });
      if (adminCount <= 1) {
        throw new BadRequestException('Debe quedar al menos un usuario con rol administrador.');
      }
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
      this.prisma.userRole.deleteMany({ where: { userId } }),
      this.prisma.userToken.deleteMany({ where: { userId } }),
      this.prisma.emailVerificationToken.deleteMany({ where: { userId } }),
      this.prisma.passwordResetToken.deleteMany({ where: { userId } }),
      this.prisma.passwordChangeRequest.deleteMany({ where: { userId } }),
      this.prisma.emailChangeRequest.deleteMany({ where: { userId } }),
      this.prisma.user.delete({ where: { id: userId } }),
    ]);

    return { success: true };
  }
}
