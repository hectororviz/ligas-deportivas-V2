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
        championMode: dto.championMode,
        startDate: dto.startDate ? new Date(dto.startDate) : undefined,
        endDate: dto.endDate ? new Date(dto.endDate) : undefined
      }
    });
  }

  findAllByLeague(leagueId: number) {
    return this.prisma.tournament.findMany({
      where: { leagueId },
      include: {
        zones: true,
        categories: {
          include: { category: true }
        }
      },
      orderBy: [{ year: 'desc' }, { name: 'asc' }]
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
              include: { club: true }
            }
          }
        },
        categories: {
          include: { category: true }
        }
      }
    });
  }

  async addZone(tournamentId: number, dto: CreateZoneDto) {
    await this.prisma.tournament.findUniqueOrThrow({ where: { id: tournamentId } });
    return this.prisma.zone.create({
      data: {
        name: dto.name,
        tournamentId
      }
    });
  }

  async addCategory(tournamentId: number, dto: AddTournamentCategoryDto) {
    await this.prisma.tournament.findUniqueOrThrow({ where: { id: tournamentId } });
    const existing = await this.prisma.tournamentCategory.findUnique({
      where: {
        tournamentId_categoryId: {
          tournamentId,
          categoryId: dto.categoryId
        }
      }
    });
    if (existing) {
      throw new BadRequestException('La categoría ya está asignada al torneo');
    }
    return this.prisma.tournamentCategory.create({
      data: {
        tournamentId,
        categoryId: dto.categoryId
      }
    });
  }
}
