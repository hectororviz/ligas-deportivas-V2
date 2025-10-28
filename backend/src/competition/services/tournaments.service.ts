import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateTournamentDto } from '../dto/create-tournament.dto';
import { CreateZoneDto } from '../dto/create-zone.dto';
import { AddTournamentCategoryDto } from '../dto/add-tournament-category.dto';

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

    if (dto.enabled) {
      const clubAssignments = tournament.zones.flatMap((zone) => zone.clubZones);
      if (clubAssignments.length) {
        const clubIds = clubAssignments.map((assignment) => assignment.clubId);
        const teams = await this.prisma.team.findMany({
          where: {
            clubId: { in: clubIds },
            categoryId: dto.categoryId,
          },
          select: { clubId: true },
        });
        const clubIdsWithTeam = new Set(teams.map((team) => team.clubId));
        const missing = clubAssignments.filter(
          (assignment) => !clubIdsWithTeam.has(assignment.clubId),
        );
        if (missing.length) {
          const missingNames = missing
            .map((assignment) => assignment.club.name)
            .filter((value, index, array) => array.indexOf(value) === index)
            .join(', ');
          throw new BadRequestException(
            `Los siguientes clubes no tienen equipos en la categoría ${category.name}: ${missingNames}`,
          );
        }
      }
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
}
