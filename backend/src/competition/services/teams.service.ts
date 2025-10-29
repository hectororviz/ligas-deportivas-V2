import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';

import { PrismaService } from '../../prisma/prisma.service';
import { CreateTeamDto } from '../dto/create-team.dto';

@Injectable()
export class TeamsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreateTeamDto) {
    const [club, tournamentCategory] = await Promise.all([
      this.prisma.club.findUnique({ where: { id: dto.clubId } }),
      this.prisma.tournamentCategory.findUnique({
        where: { id: dto.tournamentCategoryId },
        include: { category: true, tournament: true },
      }),
    ]);

    if (!club) {
      throw new NotFoundException('Club no encontrado');
    }

    if (!tournamentCategory) {
      throw new NotFoundException('Categoría de torneo no encontrada');
    }

    if (!tournamentCategory.enabled) {
      throw new BadRequestException('La categoría seleccionada no está habilitada en el torneo.');
    }

    if (!tournamentCategory.category.active) {
      throw new BadRequestException('No se pueden crear planteles para categorías inactivas.');
    }

    try {
      return await this.prisma.team.create({
        data: {
          clubId: dto.clubId,
          tournamentCategoryId: dto.tournamentCategoryId,
          publicName: dto.publicName.trim(),
          active: dto.active ?? true,
        },
        include: {
          club: true,
          tournamentCategory: {
            include: { category: true, tournament: true },
          },
        },
      });
    } catch (error) {
      throw this.handlePrismaError(error);
    }
  }

  private handlePrismaError(error: unknown): never {
    if (error instanceof Prisma.PrismaClientKnownRequestError) {
      if (error.code === 'P2002') {
        throw new BadRequestException('Ya existe un plantel con ese nombre para la categoría seleccionada.');
      }
    }
    throw error;
  }
}
