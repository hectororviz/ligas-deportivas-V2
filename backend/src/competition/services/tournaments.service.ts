import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateTournamentDto } from '../dto/create-tournament.dto';
import { CreateZoneDto } from '../dto/create-zone.dto';
import { AddTournamentCategoryDto } from '../dto/add-tournament-category.dto';
import { UpdateTournamentDto } from '../dto/update-tournament.dto';

@Injectable()
export class TournamentsService {
  constructor(private readonly prisma: PrismaService) {}

  create(dto: CreateTournamentDto) {
    return this.prisma.tournament.create({
      data: {
        leagueId: dto.leagueId,
        name: dto.name,
        year: dto.year,
        pointsWin: dto.pointsWin,
        pointsDraw: dto.pointsDraw,
        pointsLoss: dto.pointsLoss,
        championMode: dto.championMode,
        startDate: dto.startDate ? new Date(dto.startDate) : undefined,
        endDate: dto.endDate ? new Date(dto.endDate) : undefined,
      },
    });
  }

  findAllByLeague(leagueId: number) {
    return this.prisma.tournament.findMany({
      where: { leagueId },
      include: {
        zones: true,
        categories: {
          include: { category: true },
        },
      },
      orderBy: [{ year: 'desc' }, { name: 'asc' }],
    });
  }

  getTournament(id: number) {
    return this.prisma.tournament.findUnique({
      where: { id },
      include: {
        league: true,
        zones: {
          include: {
            clubZones: {
              include: { club: true },
            },
          },
        },
        categories: {
          include: { category: true },
        },
      },
    });
  }

  async addZone(tournamentId: number, dto: CreateZoneDto) {
    await this.prisma.tournament.findUniqueOrThrow({ where: { id: tournamentId } });
    return this.prisma.zone.create({
      data: {
        name: dto.name,
        tournamentId,
      },
    });
  }

  async addCategory(tournamentId: number, dto: AddTournamentCategoryDto) {
    const tournament = await this.prisma.tournament.findUnique({
      where: { id: tournamentId },
      include: {
        zones: {
          include: {
            clubZones: {
              include: { club: true },
            },
          },
        },
      },
    });

    if (!tournament) {
      throw new BadRequestException('Torneo inexistente');
    }

    const category = await this.prisma.category.findUnique({ where: { id: dto.categoryId } });

    if (!category) {
      throw new BadRequestException('Categoría inexistente');
    }

    if (!category.active) {
      throw new BadRequestException('Solo se pueden habilitar categorías activas');
    }

    const existing = await this.prisma.tournamentCategory.findUnique({
      where: {
        tournamentId_categoryId: {
          tournamentId,
          categoryId: dto.categoryId,
        },
      },
    });
    if (existing) {
      throw new BadRequestException('La categoría ya está asignada al torneo');
    }

    if (dto.enabled && !dto.gameTime) {
      throw new BadRequestException(
        'La hora de juego es obligatoria cuando la categoría está habilitada',
      );
    }

    return this.prisma.tournamentCategory.create({
      data: {
        tournamentId,
        categoryId: dto.categoryId,
        enabled: dto.enabled,
        gameTime: dto.enabled ? dto.gameTime : null,
      },
    });
  }

  async update(id: number, dto: UpdateTournamentDto) {
    if (!dto.categories || dto.categories.length === 0) {
      throw new BadRequestException('Selecciona al menos una categoría participante.');
    }

    const tournament = await this.prisma.tournament.findUnique({ where: { id } });

    if (!tournament) {
      throw new BadRequestException('Torneo inexistente');
    }

    const categoryIds = dto.categories.map((category) => category.categoryId);
    const categories = await this.prisma.category.findMany({
      where: { id: { in: categoryIds } },
    });
    const categoriesById = new Map(categories.map((category) => [category.id, category]));

    for (const assignment of dto.categories) {
      const category = categoriesById.get(assignment.categoryId);
      if (!category) {
        throw new BadRequestException('Categoría inexistente');
      }
      if (assignment.enabled) {
        if (!assignment.gameTime) {
          throw new BadRequestException(
            'La hora de juego es obligatoria cuando la categoría está habilitada',
          );
        }
        if (!category.active) {
          throw new BadRequestException('Solo se pueden habilitar categorías activas');
        }
      }
    }

    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.tournament.update({
        where: { id },
        data: {
          leagueId: dto.leagueId,
          name: dto.name,
          year: dto.year,
          pointsWin: dto.pointsWin,
          pointsDraw: dto.pointsDraw,
          pointsLoss: dto.pointsLoss,
          championMode: dto.championMode,
          startDate: dto.startDate ? new Date(dto.startDate) : undefined,
          endDate: dto.endDate ? new Date(dto.endDate) : undefined,
        },
      });

      const existing = await tx.tournamentCategory.findMany({
        where: { tournamentId: id },
      });
      const existingById = new Map(existing.map((item) => [item.categoryId, item]));

      for (const assignment of dto.categories) {
        const where = {
          tournamentId_categoryId: {
            tournamentId: id,
            categoryId: assignment.categoryId,
          },
        };
        const data = {
          enabled: assignment.enabled,
          gameTime: assignment.enabled ? assignment.gameTime : null,
        };

        if (existingById.has(assignment.categoryId)) {
          await tx.tournamentCategory.update({ where, data });
          existingById.delete(assignment.categoryId);
        } else if (assignment.enabled) {
          await tx.tournamentCategory.create({
            data: {
              tournamentId: id,
              categoryId: assignment.categoryId,
              enabled: true,
              gameTime: assignment.gameTime,
            },
          });
        }
      }

      for (const remaining of existingById.values()) {
        await tx.tournamentCategory.delete({
          where: {
            tournamentId_categoryId: {
              tournamentId: id,
              categoryId: remaining.categoryId,
            },
          },
        });
      }

      return updated;
    });
  }
}
