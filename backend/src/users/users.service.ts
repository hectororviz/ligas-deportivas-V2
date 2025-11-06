import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { PaginationQueryDto } from '../common/dto/pagination.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { AssignRoleDto } from './dto/assign-role.dto';
import { AccessControlService } from '../rbac/access-control.service';
import { RoleKey } from '@prisma/client';

@Injectable()
export class UsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly accessControlService: AccessControlService
  ) {}

  async findAll(pagination: PaginationQueryDto) {
    const page = pagination.page ?? 1;
    const pageSize = pagination.pageSize ?? 20;
    const skip = (page - 1) * pageSize;

    const [total, users] = await this.prisma.$transaction([
      this.prisma.user.count(),
      this.prisma.user.findMany({
        skip,
        take: pageSize,
        orderBy: { createdAt: 'desc' },
        include: {
          club: {
            select: {
              id: true,
              name: true
            }
          },
          roles: {
            include: {
              role: true,
              league: true,
              club: true,
              category: true
            }
          }
        }
      })
    ]);

    return {
      data: users,
      meta: {
        total,
        page,
        pageSize
      }
    };
  }

  async updateUser(id: number, dto: UpdateUserDto) {
    await this.prisma.user.findUniqueOrThrow({ where: { id } });
    return this.prisma.user.update({
      where: { id },
      data: dto,
      include: {
        club: {
          select: {
            id: true,
            name: true
          }
        }
      }
    });
  }

  async assignRole(userId: number, dto: AssignRoleDto) {
    await this.prisma.user.findUniqueOrThrow({ where: { id: userId } });
    return this.accessControlService.assignRoleToUser(userId, dto.roleKey as RoleKey, {
      leagueId: dto.leagueId,
      clubId: dto.clubId,
      categoryId: dto.categoryId
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
}
