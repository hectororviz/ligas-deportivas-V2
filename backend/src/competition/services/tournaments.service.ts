import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Gender, TournamentStatus, ZoneStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { AssignPlayerClubDto } from '../dto/assign-player-club.dto';
import { CreateTournamentDto } from '../dto/create-tournament.dto';
import { CreateZoneDto } from '../dto/create-zone.dto';
import { AddTournamentCategoryDto } from '../dto/add-tournament-category.dto';
import { UpdateTournamentDto } from '../dto/update-tournament.dto';

@Injectable()
export class TournamentsService {
  constructor(private readonly prisma: PrismaService) {}

  findAll(includeInactive = false) {
    return this.prisma.tournament.findMany({
      where: includeInactive ? undefined : { status: TournamentStatus.ACTIVE },
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
        status: dto.status ?? TournamentStatus.ACTIVE,
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

  findAllByLeague(leagueId: number, includeInactive = false) {
    return this.prisma.tournament.findMany({
      where: includeInactive
        ? { leagueId }
        : { leagueId, status: TournamentStatus.ACTIVE },
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

    const [player, category, tournamentCategory] = await Promise.all([
      this.prisma.player.findUnique({ where: { id: dto.playerId } }),
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
    if (!category || !category.active) {
      throw new BadRequestException('Categoría inválida o inactiva.');
    }
    if (!tournamentCategory) {
      throw new BadRequestException('La categoría no está habilitada en el torneo.');
    }

    if (dto.clubId == null) {
      await this.prisma.playerTournamentClub.deleteMany({
        where: {
          playerId: dto.playerId,
          tournamentId,
        },
      });

      return {
        playerId: dto.playerId,
        clubId: null,
        tournamentId,
      };
    }

    const club = await this.prisma.club.findUnique({ where: { id: dto.clubId } });
    if (!club) {
      throw new NotFoundException('Club inexistente');
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
          where: { enabled: true, category: { active: true } },
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
    const players = await this.prisma.player.findMany({
      where: {
        active: true,
        playerTournamentClubs: {
          some: {
            tournamentId,
            clubId: { in: clubIds },
          },
        },
      },
      select: {
        birthDate: true,
        gender: true,
        playerTournamentClubs: {
          where: { tournamentId },
          select: { clubId: true },
        },
      },
    });

    const playersByClub = new Map<number, Array<{ birthDate: Date; gender: Gender }>>();
    for (const player of players) {
      const clubId = player.playerTournamentClubs[0]?.clubId;
      if (!clubId) {
        continue;
      }
      if (!playersByClub.has(clubId)) {
        playersByClub.set(clubId, []);
      }
      playersByClub.get(clubId)!.push({ birthDate: player.birthDate, gender: player.gender });
    }

    const sortedClubs = clubIds
      .map((id) => clubData.get(id)!)
      .filter((club) => !assignedClubIds.has(club.id))
      .sort((a, b) => a.name.localeCompare(b.name, 'es', { sensitivity: 'base' }));

    return sortedClubs.map((club) => {
      const teamSet = clubTeams.get(club.id) ?? new Set<number>();
      const categories = assignments.map((assignment) => {
        const hasTeam = teamSet.has(assignment.id);
        const clubPlayers = playersByClub.get(club.id) ?? [];
        const playersCount = clubPlayers.filter((player) =>
          this.isPlayerEligibleForCategory(player, assignment.category),
        ).length;
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

  private isPlayerEligibleForCategory(
    player: { birthDate: Date; gender: Gender },
    category: { birthYearMin: number; birthYearMax: number; gender: Gender },
  ) {
    if (category.gender !== Gender.MIXTO && player.gender !== category.gender) {
      return false;
    }
    const birthYear = player.birthDate.getUTCFullYear();
    return birthYear >= category.birthYearMin && birthYear <= category.birthYearMax;
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

    const tournament = await this.prisma.tournament.findUnique({
      where: { id },
      include: {
        zones: {
          select: { status: true },
        },
      },
    });

    if (!tournament) {
      throw new BadRequestException('Torneo inexistente');
    }
    if (tournament.zones.some((zone) => zone.status !== ZoneStatus.OPEN)) {
      throw new BadRequestException(
        'No se puede editar el torneo mientras alguna de sus zonas no esté abierta.',
      );
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
          status: dto.status,
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

  async updateStatus(id: number, status: TournamentStatus) {
    await this.prisma.tournament.findUniqueOrThrow({ where: { id } });
    return this.prisma.tournament.update({
      where: { id },
      data: { status },
    });
  }
}
