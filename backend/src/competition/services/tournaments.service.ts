import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Gender } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { AssignPlayerClubDto } from '../dto/assign-player-club.dto';
import { CreateTournamentDto } from '../dto/create-tournament.dto';
import { CreateZoneDto } from '../dto/create-zone.dto';
import { AddTournamentCategoryDto } from '../dto/add-tournament-category.dto';
import { UpdateTournamentDto } from '../dto/update-tournament.dto';

@Injectable()
export class TournamentsService {
  constructor(private readonly prisma: PrismaService) {}

  findAll() {
    return this.prisma.tournament.findMany({
      include: {
        league: true,
      },
      orderBy: [
        { year: 'desc' },
        { name: 'asc' },
      ],
    });
  }

  create(dto: CreateTournamentDto) {
    return this.prisma.tournament.create({
      data: {
        leagueId: dto.leagueId,
        name: dto.name,
        year: dto.year,
        gender: dto.gender,
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

  async listCategories(tournamentId: number) {
    const tournament = await this.prisma.tournament.findUnique({
      where: { id: tournamentId },
    });
    if (!tournament) {
      throw new NotFoundException('Torneo inexistente');
    }

    const categories = await this.prisma.tournamentCategory.findMany({
      where: {
        tournamentId,
        enabled: true,
        category: { active: true },
      },
      include: {
        category: true,
      },
      orderBy: { category: { name: 'asc' } },
    });

    return categories.map((assignment) => ({
      tournamentCategoryId: assignment.id,
      categoryId: assignment.categoryId,
      name: assignment.category.name,
      birthYearMin: assignment.category.birthYearMin,
      birthYearMax: assignment.category.birthYearMax,
      gender: assignment.category.gender,
    }));
  }

  async listParticipatingClubs(tournamentId: number) {
    const tournament = await this.prisma.tournament.findUnique({
      where: { id: tournamentId },
    });
    if (!tournament) {
      throw new NotFoundException('Torneo inexistente');
    }

    return this.prisma.club.findMany({
      where: {
        teams: {
          some: {
            tournamentCategory: {
              tournamentId,
            },
          },
        },
      },
      select: {
        id: true,
        name: true,
        shortName: true,
      },
      distinct: ['id'],
      orderBy: { name: 'asc' },
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

  async assignPlayerClub(tournamentId: number, dto: AssignPlayerClubDto) {
    const tournament = await this.prisma.tournament.findUnique({
      where: { id: tournamentId },
    });
    if (!tournament) {
      throw new NotFoundException('Torneo inexistente');
    }

    const [player, club, category, tournamentCategory] = await Promise.all([
      this.prisma.player.findUnique({ where: { id: dto.playerId } }),
      this.prisma.club.findUnique({ where: { id: dto.clubId } }),
      this.prisma.category.findUnique({ where: { id: dto.categoryId } }),
      this.prisma.tournamentCategory.findFirst({
        where: {
          tournamentId,
          categoryId: dto.categoryId,
          enabled: true,
        },
        select: { id: true },
      }),
    ]);

    if (!player) {
      throw new NotFoundException('Jugador inexistente');
    }
    if (!club) {
      throw new NotFoundException('Club inexistente');
    }
    if (!category || !category.active) {
      throw new BadRequestException('Categoría inválida o inactiva.');
    }
    if (!tournamentCategory) {
      throw new BadRequestException('La categoría no está habilitada en el torneo.');
    }

    const startDate = new Date(Date.UTC(category.birthYearMin, 0, 1));
    const endDate = new Date(Date.UTC(category.birthYearMax, 11, 31, 23, 59, 59, 999));
    if (player.birthDate < startDate || player.birthDate > endDate) {
      throw new BadRequestException('El jugador no pertenece a la categoría seleccionada.');
    }
    if (category.gender !== Gender.MIXTO && player.gender !== category.gender) {
      throw new BadRequestException('El jugador no pertenece a la categoría seleccionada.');
    }

    const clubParticipates = await this.prisma.team.findFirst({
      where: {
        clubId: dto.clubId,
        tournamentCategory: { tournamentId },
      },
      select: { id: true },
    });
    if (!clubParticipates) {
      throw new BadRequestException('El club no participa en este torneo.');
    }

    const assignment = await this.prisma.playerTournamentClub.upsert({
      where: {
        playerId_tournamentId: {
          playerId: dto.playerId,
          tournamentId,
        },
      },
      create: {
        playerId: dto.playerId,
        clubId: dto.clubId,
        tournamentId,
      },
      update: {
        clubId: dto.clubId,
      },
    });

    return {
      id: assignment.id,
      playerId: assignment.playerId,
      clubId: assignment.clubId,
      tournamentId: assignment.tournamentId,
    };
  }

  async listClubsForZones(tournamentId: number, zoneId?: number) {
    const tournament = await this.prisma.tournament.findUnique({
      where: { id: tournamentId },
      include: {
        categories: {
          where: { enabled: true },
          orderBy: { category: { name: 'asc' } },
          include: {
            category: true,
            teams: {
              where: { active: true },
              include: {
                club: {
                  select: {
                    id: true,
                    name: true,
                    shortName: true,
                  },
                },
              },
            },
          },
        },
        zones: {
          include: {
            clubZones: true,
          },
        },
      },
    });

    if (!tournament) {
      throw new NotFoundException('Torneo inexistente');
    }

    const assignments = tournament.categories;
    if (!assignments.length) {
      return [];
    }

    const assignedClubIds = new Set<number>();
    for (const zone of tournament.zones) {
      if (zoneId != null && zone.id === zoneId) {
        continue;
      }
      for (const assignment of zone.clubZones) {
        assignedClubIds.add(assignment.clubId);
      }
    }

    const clubData = new Map<
      number,
      {
        id: number;
        name: string;
        shortName: string | null;
      }
    >();
    const clubTeams = new Map<number, Set<number>>();

    for (const assignment of assignments) {
      for (const team of assignment.teams) {
        const club = team.club;
        if (!club) {
          continue;
        }
        clubData.set(club.id, {
          id: club.id,
          name: club.name,
          shortName: club.shortName ?? null,
        });
        if (!clubTeams.has(club.id)) {
          clubTeams.set(club.id, new Set<number>());
        }
        clubTeams.get(club.id)!.add(assignment.id);
      }
    }

    const clubIds = Array.from(clubData.keys());
    if (!clubIds.length) {
      return [];
    }

    const tournamentCategoryIds = assignments.map((assignment) => assignment.id);
    const rosters = await this.prisma.roster.findMany({
      where: {
        clubId: { in: clubIds },
        tournamentCategoryId: { in: tournamentCategoryIds },
      },
      include: {
        players: {
          select: { playerId: true },
        },
      },
    });

    const rosterCounts = new Map<string, number>();
    for (const roster of rosters) {
      const key = this.buildRosterKey(roster.clubId, roster.tournamentCategoryId);
      rosterCounts.set(key, roster.players.length);
    }

    const sortedClubs = clubIds
      .map((id) => clubData.get(id)!)
      .filter((club) => !assignedClubIds.has(club.id))
      .sort((a, b) => a.name.localeCompare(b.name, 'es', { sensitivity: 'base' }));

    return sortedClubs.map((club) => {
      const teamSet = clubTeams.get(club.id) ?? new Set<number>();
      const categories = assignments.map((assignment) => {
        const hasTeam = teamSet.has(assignment.id);
        const rosterKey = this.buildRosterKey(club.id, assignment.id);
        const playersCount = rosterCounts.get(rosterKey) ?? 0;
        const meetsMinPlayers = hasTeam
          ? playersCount >= assignment.category.minPlayers
          : !assignment.category.mandatory;
        return {
          tournamentCategoryId: assignment.id,
          categoryId: assignment.categoryId,
          categoryName: assignment.category.name,
          mandatory: assignment.category.mandatory,
          minPlayers: assignment.category.minPlayers,
          hasTeam,
          playersCount,
          meetsMinPlayers,
        };
      });

      const eligible = categories.every((category) => {
        if (category.mandatory) {
          return category.hasTeam && category.playersCount >= category.minPlayers;
        }
        if (!category.hasTeam) {
          return true;
        }
        return category.playersCount >= category.minPlayers;
      });

      return {
        id: club.id,
        name: club.name,
        shortName: club.shortName,
        eligible,
        categories,
      };
    });
  }

  private buildRosterKey(clubId: number, tournamentCategoryId: number) {
    return `${clubId}-${tournamentCategoryId}`;
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

    if (dto.enabled && !dto.kickoffTime) {
      throw new BadRequestException(
        'La hora de juego es obligatoria cuando la categoría está habilitada',
      );
    }

    return this.prisma.tournamentCategory.create({
      data: {
        tournamentId,
        categoryId: dto.categoryId,
        enabled: dto.enabled,
        kickoffTime: dto.enabled ? dto.kickoffTime : null,
        countsForGeneral: dto.countsForGeneral,
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
        if (!assignment.kickoffTime) {
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
          gender: dto.gender,
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
          kickoffTime: assignment.enabled ? assignment.kickoffTime : null,
          countsForGeneral: assignment.countsForGeneral,
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
              kickoffTime: assignment.kickoffTime,
              countsForGeneral: assignment.countsForGeneral,
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
