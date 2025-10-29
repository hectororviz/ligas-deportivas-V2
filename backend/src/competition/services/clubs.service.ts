import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';

import { slugify } from '../../common/utils/slugify';
import { PrismaService } from '../../prisma/prisma.service';
import { AssignClubZoneDto } from '../dto/assign-club-zone.dto';
import { CreateClubDto } from '../dto/create-club.dto';
import { ListClubsDto } from '../dto/list-clubs.dto';
import { UpdateClubDto } from '../dto/update-club.dto';
import { UpdateClubTeamsDto } from '../dto/update-club-teams.dto';

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

  async assignToZone(zoneId: number, dto: AssignClubZoneDto) {
    const zone = await this.prisma.zone.findUnique({
      where: { id: zoneId },
      include: {
        tournament: {
          include: {
            zones: {
              include: {
                clubZones: true,
              },
            },
            categories: {
              where: { enabled: true },
              include: { category: true },
            },
          },
        },
      },
    });

    if (!zone) {
      throw new BadRequestException('Zona inexistente');
    }

    const alreadyAssigned = zone.tournament.zones.some((zoneItem) =>
      zoneItem.clubZones.some((assignment) => assignment.clubId === dto.clubId),
    );

    if (alreadyAssigned) {
      throw new BadRequestException('El club ya está asignado a una zona en este torneo');
    }

    const enabledCategories = zone.tournament.categories;

    if (enabledCategories.length) {
      const tournamentCategoryIds = enabledCategories.map((tc) => tc.id);
      const teams = await this.prisma.team.findMany({
        where: {
          clubId: dto.clubId,
          tournamentCategoryId: { in: tournamentCategoryIds },
          active: true,
        },
        select: { tournamentCategoryId: true },
      });

      const activeTeamCategoryIds = new Set(teams.map((team) => team.tournamentCategoryId));
      const missing = enabledCategories.filter((tc) => !activeTeamCategoryIds.has(tc.id));

      if (missing.length) {
        const missingNames = missing.map((tc) => tc.category.name).join(', ');
        throw new BadRequestException(
          `El club no tiene equipos cargados para las categorías habilitadas: ${missingNames}`,
        );
      }
    }

    await this.prisma.clubZone.create({
      data: {
        clubId: dto.clubId,
        zoneId: zone.id,
      },
    });

    return this.prisma.zone.findUnique({
      where: { id: zoneId },
      include: {
        clubZones: {
          include: { club: true },
        },
      },
    });
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
