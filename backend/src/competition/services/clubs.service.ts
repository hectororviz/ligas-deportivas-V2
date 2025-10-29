import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Gender, Prisma } from '@prisma/client';

import { slugify } from '../../common/utils/slugify';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateClubDto } from '../dto/create-club.dto';
import { ListClubsDto } from '../dto/list-clubs.dto';
import { UpdateClubDto } from '../dto/update-club.dto';
import { UpdateClubTeamsDto } from '../dto/update-club-teams.dto';
import { ListRosterPlayersDto } from '../dto/list-roster-players.dto';
import { UpdateRosterPlayersDto } from '../dto/update-roster-players.dto';
import { JoinTournamentDto } from '../dto/join-tournament.dto';

interface FindClubsInput extends ListClubsDto {}

@Injectable()
export class ClubsService {
  constructor(private readonly prisma: PrismaService) {}

  private readonly defaultInclude: Prisma.ClubInclude = {
    league: true,
    teams: {
      include: {
        tournamentCategory: {
          include: { category: true, tournament: true },
        },
      },
    },
  };

  async create(dto: CreateClubDto) {
    await this.ensureUniqueName(dto.name, dto.leagueId);
    const slug = await this.resolveSlug(dto.slug, dto.name);

    try {
      return await this.prisma.club.create({
        data: {
          name: dto.name.trim(),
          shortName: dto.shortName?.trim(),
          slug,
          leagueId: dto.leagueId,
          primaryColor: dto.primaryColor?.toUpperCase(),
          secondaryColor: dto.secondaryColor?.toUpperCase(),
          active: dto.active ?? true,
          logoUrl: dto.logoUrl?.trim(),
          instagramUrl: this.normalizeSocial(dto.instagram, 'instagram'),
          facebookUrl: this.normalizeSocial(dto.facebook, 'facebook'),
          latitude: dto.latitude,
          longitude: dto.longitude,
        },
        include: this.defaultInclude,
      });
    } catch (error) {
      throw this.handlePrismaError(error);
    }
  }

  async findAll(input: FindClubsInput) {
    const { search, status, page, pageSize } = input;
    const where: Prisma.ClubWhereInput = {};
    if (search) {
      where.name = {
        contains: search.trim(),
        mode: 'insensitive',
      };
    }
    if (status === 'active') {
      where.active = true;
    } else if (status === 'inactive') {
      where.active = false;
    }

    const skip = (page - 1) * pageSize;

    const [total, clubs] = await this.prisma.$transaction([
      this.prisma.club.count({ where }),
      this.prisma.club.findMany({
        where,
        include: this.defaultInclude,
        orderBy: {
          name: 'asc',
        },
        skip,
        take: pageSize,
      }),
    ]);

    return {
      data: clubs,
      total,
      page,
      pageSize,
    };
  }

  async findById(id: number) {
    const club = await this.prisma.club.findUnique({
      where: { id },
      include: this.defaultInclude,
    });
    if (!club) {
      throw new NotFoundException('Club no encontrado');
    }
    return club;
  }

  async findAdminOverviewBySlug(slug: string) {
    const club = await this.prisma.club.findUnique({
      where: { slug },
    });
    if (!club) {
      throw new NotFoundException('Club no encontrado');
    }

    const teams = await this.prisma.team.findMany({
      where: { clubId: club.id },
      include: {
        tournamentCategory: {
          include: {
            category: true,
            tournament: { include: { league: true } },
          },
        },
      },
      orderBy: [
        { tournamentCategory: { tournament: { year: 'desc' } } },
        { tournamentCategory: { tournament: { name: 'asc' } } },
        { tournamentCategory: { category: { name: 'asc' } } },
      ],
    });

    const rosterList = await this.prisma.roster.findMany({
      where: { clubId: club.id },
      include: {
        _count: {
          select: { players: true },
        },
      },
    });

    const rosterMap = new Map<number, { id: number; playerCount: number }>();
    rosterList.forEach((roster) => {
      rosterMap.set(roster.tournamentCategoryId, {
        id: roster.id,
        playerCount: roster._count.players,
      });
    });

    const processedCategories = new Set<number>();
    const tournamentsMap = new Map<
      number,
      {
        id: number;
        name: string;
        year: number;
        leagueId: number;
        leagueName: string;
        categories: Array<{
          tournamentCategoryId: number;
          categoryId: number;
          categoryName: string;
          birthYearMin: number;
          birthYearMax: number;
          gender: string;
          minPlayers: number;
          mandatory: boolean;
          enabledCount: number;
        }>;
      }
    >();

    for (const team of teams) {
      const tournamentCategory = team.tournamentCategory;
      if (!tournamentCategory) {
        continue;
      }
      if (processedCategories.has(tournamentCategory.id)) {
        continue;
      }
      processedCategories.add(tournamentCategory.id);

      const tournament = tournamentCategory.tournament;
      if (!tournament) {
        continue;
      }

      let tournamentEntry = tournamentsMap.get(tournament.id);
      if (!tournamentEntry) {
        tournamentEntry = {
          id: tournament.id,
          name: tournament.name,
          year: tournament.year,
          leagueId: tournament.leagueId,
          leagueName: tournament.league?.name ?? '—',
          categories: [],
        };
        tournamentsMap.set(tournament.id, tournamentEntry);
      }

      const category = tournamentCategory.category;
      const rosterInfo = rosterMap.get(tournamentCategory.id);
      tournamentEntry.categories.push({
        tournamentCategoryId: tournamentCategory.id,
        categoryId: category.id,
        categoryName: category.name,
        birthYearMin: category.birthYearMin,
        birthYearMax: category.birthYearMax,
        gender: category.gender,
        minPlayers: category.minPlayers,
        mandatory: category.mandatory,
        enabledCount: rosterInfo?.playerCount ?? 0,
      });
    }

    const tournaments = Array.from(tournamentsMap.values()).map((tournament) => ({
      ...tournament,
      categories: tournament.categories.sort((a, b) => a.categoryName.localeCompare(b.categoryName)),
    }));

    tournaments.sort((a, b) => {
      if (a.year !== b.year) {
        return b.year - a.year;
      }
      return a.name.localeCompare(b.name);
    });

    return {
      club: {
        id: club.id,
        name: club.name,
        slug: club.slug,
        active: club.active,
        primaryColor: club.primaryColor,
        secondaryColor: club.secondaryColor,
        logoUrl: club.logoUrl,
        instagramUrl: club.instagramUrl,
        facebookUrl: club.facebookUrl,
      },
      tournaments,
    };
  }

  async listEligibleRosterPlayers(
    clubId: number,
    tournamentCategoryId: number,
    query: ListRosterPlayersDto,
  ) {
    await this.prisma.club.findUniqueOrThrow({ where: { id: clubId } });

    const tournamentCategory = await this.prisma.tournamentCategory.findUnique({
      where: { id: tournamentCategoryId },
      include: {
        category: true,
        teams: {
          where: { clubId },
          select: { id: true },
        },
      },
    });

    if (!tournamentCategory) {
      throw new NotFoundException('Categoría del torneo no encontrada');
    }

    if (!tournamentCategory.teams.length) {
      throw new BadRequestException('El club no participa en esta categoría del torneo.');
    }

    const roster = await this.prisma.roster.findUnique({
      where: {
        clubId_tournamentCategoryId: {
          clubId,
          tournamentCategoryId,
        },
      },
      select: {
        id: true,
        players: {
          select: { playerId: true },
        },
      },
    });

    const enabledIds = new Set<number>(roster?.players.map((player) => player.playerId) ?? []);

    const { page = 1, pageSize = 20, onlyEnabled } = query;
    const skip = (page - 1) * pageSize;

    const category = tournamentCategory.category;
    const startDate = new Date(category.birthYearMin, 0, 1);
    const endDate = new Date(category.birthYearMax, 11, 31, 23, 59, 59, 999);

    const where: Prisma.PlayerWhereInput = {
      clubId,
      active: true,
      birthDate: {
        gte: startDate,
        lte: endDate,
      },
    };

    if (category.gender !== Gender.MIXTO) {
      where.gender = category.gender;
    }

    if (onlyEnabled) {
      if (enabledIds.size === 0) {
        return {
          page,
          pageSize,
          total: 0,
          enabledCount: enabledIds.size,
          minPlayers: category.minPlayers,
          mandatory: category.mandatory,
          players: [],
        };
      }
      where.id = { in: Array.from(enabledIds.values()) };
    }

    const [total, players] = await this.prisma.$transaction([
      this.prisma.player.count({ where }),
      this.prisma.player.findMany({
        where,
        orderBy: [
          { lastName: 'asc' },
          { firstName: 'asc' },
        ],
        skip,
        take: pageSize,
      }),
    ]);

    return {
      page,
      pageSize,
      total,
      enabledCount: enabledIds.size,
      minPlayers: category.minPlayers,
      mandatory: category.mandatory,
      players: players.map((player) => ({
        id: player.id,
        firstName: player.firstName,
        lastName: player.lastName,
        birthDate: player.birthDate,
        gender: player.gender,
        enabled: enabledIds.has(player.id),
      })),
    };
  }

  async updateRosterPlayers(
    clubId: number,
    tournamentCategoryId: number,
    dto: UpdateRosterPlayersDto,
  ) {
    await this.prisma.club.findUniqueOrThrow({ where: { id: clubId } });

    const tournamentCategory = await this.prisma.tournamentCategory.findUnique({
      where: { id: tournamentCategoryId },
      include: {
        category: true,
        teams: {
          where: { clubId },
          select: { id: true },
        },
      },
    });

    if (!tournamentCategory) {
      throw new NotFoundException('Categoría del torneo no encontrada');
    }

    if (!tournamentCategory.teams.length) {
      throw new BadRequestException('El club no participa en esta categoría del torneo.');
    }

    const category = tournamentCategory.category;
    const startDate = new Date(category.birthYearMin, 0, 1);
    const endDate = new Date(category.birthYearMax, 11, 31, 23, 59, 59, 999);

    const uniquePlayerIds = Array.from(new Set(dto.playerIds ?? []));

    if (uniquePlayerIds.length) {
      const players = await this.prisma.player.findMany({
        where: {
          id: { in: uniquePlayerIds },
          clubId,
          active: true,
          birthDate: {
            gte: startDate,
            lte: endDate,
          },
          ...(category.gender !== Gender.MIXTO ? { gender: category.gender } : {}),
        },
      });

      if (players.length !== uniquePlayerIds.length) {
        const foundIds = new Set(players.map((player) => player.id));
        const missing = uniquePlayerIds.filter((id) => !foundIds.has(id));
        throw new BadRequestException(
          `Algunos jugadores no son elegibles para esta categoría: ${missing.join(', ')}`,
        );
      }
    }

    const roster = await this.prisma.roster.upsert({
      where: {
        clubId_tournamentCategoryId: {
          clubId,
          tournamentCategoryId,
        },
      },
      update: {},
      create: {
        clubId,
        tournamentCategoryId,
      },
    });

    await this.prisma.$transaction(async (tx) => {
      await tx.rosterPlayer.deleteMany({ where: { rosterId: roster.id } });
      if (uniquePlayerIds.length) {
        await tx.rosterPlayer.createMany({
          data: uniquePlayerIds.map((playerId) => ({ rosterId: roster.id, playerId })),
        });
      }
    });

    return {
      enabledCount: uniquePlayerIds.length,
      minPlayers: category.minPlayers,
      mandatory: category.mandatory,
    };
  }

  async listAvailableTournaments(clubId: number) {
    const club = await this.prisma.club.findUnique({ where: { id: clubId } });
    if (!club) {
      throw new NotFoundException('Club no encontrado');
    }

    const tournaments = await this.prisma.tournament.findMany({
      where: {
        categories: {
          some: {
            enabled: true,
            category: { active: true },
          },
        },
        NOT: {
          categories: {
            some: {
              teams: {
                some: { clubId },
              },
            },
          },
        },
      },
      include: {
        categories: {
          where: {
            enabled: true,
            category: { active: true },
          },
          include: {
            category: true,
          },
        },
        league: true,
      },
      orderBy: [
        { year: 'desc' },
        { name: 'asc' },
      ],
    });

    return tournaments
      .map((tournament) => ({
        id: tournament.id,
        name: tournament.name,
        year: tournament.year,
        leagueId: tournament.leagueId,
        leagueName: tournament.league?.name ?? '—',
        categories: tournament.categories.map((assignment) => ({
          tournamentCategoryId: assignment.id,
          categoryId: assignment.categoryId,
          categoryName: assignment.category.name,
          birthYearMin: assignment.category.birthYearMin,
          birthYearMax: assignment.category.birthYearMax,
          gender: assignment.category.gender,
          minPlayers: assignment.category.minPlayers,
          mandatory: assignment.category.mandatory,
        })),
      }))
      .filter((tournament) => tournament.categories.length > 0);
  }

  async joinTournament(clubId: number, dto: JoinTournamentDto) {
    const club = await this.prisma.club.findUnique({ where: { id: clubId } });
    if (!club) {
      throw new NotFoundException('Club no encontrado');
    }

    const tournament = await this.prisma.tournament.findUnique({
      where: { id: dto.tournamentId },
      include: {
        categories: {
          where: {
            enabled: true,
            category: { active: true },
          },
          include: {
            category: true,
            teams: {
              where: { clubId },
              select: { id: true },
            },
          },
        },
      },
    });

    if (!tournament) {
      throw new NotFoundException('Torneo no encontrado');
    }

    const alreadyParticipates = tournament.categories.some((assignment) => assignment.teams.length > 0);
    if (alreadyParticipates) {
      throw new BadRequestException('El club ya participa en este torneo.');
    }

    const uniqueCategoryIds = Array.from(new Set(dto.tournamentCategoryIds ?? []));
    if (!uniqueCategoryIds.length) {
      throw new BadRequestException('Debe seleccionar al menos una categoría.');
    }

    const validCategoryIds = new Set(tournament.categories.map((assignment) => assignment.id));
    const invalid = uniqueCategoryIds.filter((id) => !validCategoryIds.has(id));
    if (invalid.length) {
      throw new BadRequestException('Alguna de las categorías seleccionadas no pertenece al torneo.');
    }

    const assignments = tournament.categories.filter((assignment) => uniqueCategoryIds.includes(assignment.id));

    if (!assignments.length) {
      throw new BadRequestException('Debe seleccionar al menos una categoría habilitada.');
    }

    const shortName = club.shortName ? club.shortName.trim() : '';
    const publicNameBase = shortName.length > 0 ? shortName : club.name;

    await this.prisma.team.createMany({
      data: assignments.map((assignment) => ({
        clubId,
        tournamentCategoryId: assignment.id,
        publicName: publicNameBase,
        active: true,
      })),
    });

    return {
      tournamentId: tournament.id,
      categories: assignments.map((assignment) => assignment.id),
    };
  }

  async update(id: number, dto: UpdateClubDto) {
    const existing = await this.prisma.club.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundException('Club no encontrado');
    }

    if (dto.name && dto.name.trim().toLowerCase() !== existing.name.toLowerCase()) {
      await this.ensureUniqueName(dto.name, dto.leagueId ?? existing.leagueId, id);
    }

    let newSlug: string | undefined;
    if (dto.slug !== undefined) {
      const trimmed = dto.slug.trim();
      const base = trimmed.length === 0 ? dto.name ?? existing.name : dto.slug;
      newSlug = await this.resolveSlug(base, dto.name ?? existing.name, id);
    }

    try {
      const data: Prisma.ClubUpdateInput = {};

      if (dto.name !== undefined) {
        data.name = dto.name.trim();
      }
      if (dto.shortName !== undefined) {
        data.shortName = dto.shortName ? dto.shortName.trim() : null;
      }
      if (dto.leagueId !== undefined) {
        data.league = { connect: { id: dto.leagueId } };
      }
      if (dto.primaryColor !== undefined) {
        data.primaryColor = dto.primaryColor?.toUpperCase() ?? null;
      }
      if (dto.secondaryColor !== undefined) {
        data.secondaryColor = dto.secondaryColor?.toUpperCase() ?? null;
      }
      if (dto.active !== undefined) {
        data.active = dto.active;
      }
      if (Object.prototype.hasOwnProperty.call(dto, 'logoUrl')) {
        data.logoUrl = dto.logoUrl?.trim() ?? null;
      }
      if (Object.prototype.hasOwnProperty.call(dto, 'instagram')) {
        data.instagramUrl = this.normalizeSocial(dto.instagram, 'instagram');
      }
      if (Object.prototype.hasOwnProperty.call(dto, 'facebook')) {
        data.facebookUrl = this.normalizeSocial(dto.facebook, 'facebook');
      }
      if (Object.prototype.hasOwnProperty.call(dto, 'latitude')) {
        data.latitude = dto.latitude ?? null;
      }
      if (Object.prototype.hasOwnProperty.call(dto, 'longitude')) {
        data.longitude = dto.longitude ?? null;
      }
      if (newSlug !== undefined) {
        data.slug = newSlug;
      }

      return await this.prisma.club.update({
        where: { id },
        data,
        include: this.defaultInclude,
      });
    } catch (error) {
      throw this.handlePrismaError(error);
    }
  }

  async updateTeams(clubId: number, dto: UpdateClubTeamsDto) {
    await this.prisma.club.findUniqueOrThrow({ where: { id: clubId } });

    const payload = dto.teams ?? [];

    const uniqueKeys = new Set<string>();
    for (const team of payload) {
      const key = `${team.tournamentCategoryId}-${team.publicName.trim().toLowerCase()}`;
      if (uniqueKeys.has(key)) {
        throw new BadRequestException(
          'No se pueden repetir planteles con el mismo nombre dentro de la misma categoría del torneo.',
        );
      }
      uniqueKeys.add(key);
    }

    if (!payload.length) {
      await this.prisma.team.deleteMany({ where: { clubId } });
      return [];
    }

    const tournamentCategoryIds = Array.from(
      new Set(payload.map((team) => team.tournamentCategoryId)),
    );

    const tournamentCategories = await this.prisma.tournamentCategory.findMany({
      where: { id: { in: tournamentCategoryIds } },
      include: { category: true },
    });

    if (tournamentCategories.length !== tournamentCategoryIds.length) {
      throw new BadRequestException('Alguna de las categorías seleccionadas no existe.');
    }

    const disabled = tournamentCategories.filter((tc) => !tc.enabled || !tc.category.active);
    if (disabled.length) {
      const names = disabled.map((tc) => tc.category.name).join(', ');
      throw new BadRequestException(
        `No se pueden asignar planteles a categorías inactivas o deshabilitadas: ${names}`,
      );
    }

    await this.prisma.team.deleteMany({ where: { clubId } });

    await this.prisma.team.createMany({
      data: payload.map((team) => ({
        clubId,
        tournamentCategoryId: team.tournamentCategoryId,
        publicName: team.publicName.trim(),
        active: team.active,
      })),
    });

    return this.prisma.team.findMany({
      where: { clubId },
      include: {
        tournamentCategory: {
          include: { category: true, tournament: true },
        },
      },
      orderBy: [
        { tournamentCategory: { tournament: { year: 'desc' } } },
        { tournamentCategory: { category: { name: 'asc' } } },
        { publicName: 'asc' },
      ],
    });
  }

  private async ensureUniqueName(name: string, leagueId?: number | null, excludeId?: number) {
    const normalized = name.trim();
    const where: Prisma.ClubWhereInput = {
      name: { equals: normalized, mode: 'insensitive' },
      NOT: excludeId ? { id: excludeId } : undefined,
    };
    if (leagueId !== undefined) {
      where.leagueId = leagueId;
    }

    const existing = await this.prisma.club.findFirst({ where });

    if (existing) {
      throw new BadRequestException(`Ya existe un club con el nombre "${normalized}".`);
    }
  }

  private async resolveSlug(slug: string | undefined, name: string, excludeId?: number) {
    const trimmed = slug?.trim();
    const baseInput = trimmed && trimmed.length > 0 ? trimmed : name;
    const base = slugify(baseInput);
    if (!base) {
      throw new BadRequestException('No se pudo generar un identificador único para el club.');
    }
    return this.ensureUniqueSlug(base, excludeId);
  }

  private async ensureUniqueSlug(base: string, excludeId?: number) {
    let candidate = base;
    let suffix = 1;
    while (true) {
      const existing = await this.prisma.club.findFirst({
        where: {
          slug: candidate,
          NOT: excludeId ? { id: excludeId } : undefined,
        },
      });
      if (!existing) {
        return candidate;
      }
      candidate = `${base}-${suffix++}`;
    }
  }

  private normalizeSocial(value: string | null | undefined, network: 'instagram' | 'facebook') {
    if (value === undefined) {
      return undefined;
    }
    if (value === null) {
      return null;
    }
    let input = value.trim();
    if (!input) {
      return null;
    }
    const host = network === 'instagram' ? 'instagram.com' : 'facebook.com';
    if (input.startsWith('@')) {
      input = input.substring(1);
    }
    if (input.startsWith('http://') || input.startsWith('https://')) {
      try {
        const url = new URL(input);
        if (!url.hostname.includes(host)) {
          throw new BadRequestException(`La URL de ${network} no es válida.`);
        }
        input = url.pathname;
      } catch (error) {
        throw new BadRequestException(`La URL de ${network} no es válida.`);
      }
    }
    input = input
      .replace(/^\//, '')
      .replace(/\?.*$/, '')
      .replace(/#.*/, '');
    const segments = input.split('/').filter(Boolean);
    const username = segments.length ? segments[0] : input;
    if (!username) {
      throw new BadRequestException(`El usuario de ${network} es inválido.`);
    }
    return `https://${host}/${username}`;
  }

  private handlePrismaError(error: unknown): never {
    if (error instanceof Prisma.PrismaClientKnownRequestError) {
      if (error.code === 'P2002') {
        const target = Array.isArray(error.meta?.target) ? (error.meta?.target[0] as string) : undefined;
        if (target === 'slug') {
          throw new BadRequestException('El identificador indicado ya está en uso.');
        }
      }
    }
    throw error;
  }
}
