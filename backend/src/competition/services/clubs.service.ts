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
      include: { category: true },
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
      const categoryIds = enabledCategories.map((tc) => tc.categoryId);
      const teams = await this.prisma.team.findMany({
        where: {
          clubId: dto.clubId,
          categoryId: { in: categoryIds },
        },
        select: { categoryId: true },
      });

      const teamCategoryIds = new Set(teams.map((team) => team.categoryId));
      const missing = enabledCategories.filter((tc) => !teamCategoryIds.has(tc.categoryId));

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

    if (!dto.categoryIds.length) {
      await this.prisma.team.deleteMany({ where: { clubId } });
      return this.prisma.team.findMany({
        where: { clubId },
        include: { category: true },
        orderBy: { category: { name: 'asc' } },
      });
    }

    const categories = await this.prisma.category.findMany({
      where: { id: { in: dto.categoryIds } },
    });

    if (categories.length !== dto.categoryIds.length) {
      throw new BadRequestException('Alguna de las categorías seleccionadas no existe');
    }

    const inactive = categories.filter((category) => !category.active);
    if (inactive.length) {
      const names = inactive.map((category) => category.name).join(', ');
      throw new BadRequestException(`No se pueden asignar categorías inactivas: ${names}`);
    }

    const existingTeams = await this.prisma.team.findMany({
      where: { clubId },
      select: { id: true, categoryId: true },
    });

    const targetCategoryIds = new Set(dto.categoryIds);
    const existingCategoryIds = new Set(existingTeams.map((team) => team.categoryId));

    const toCreate = dto.categoryIds.filter((id) => !existingCategoryIds.has(id));
    const toDelete = existingTeams
      .filter((team) => !targetCategoryIds.has(team.categoryId))
      .map((team) => team.id);

    if (toDelete.length) {
      await this.prisma.team.deleteMany({ where: { id: { in: toDelete } } });
    }

    if (toCreate.length) {
      await this.prisma.team.createMany({
        data: toCreate.map((categoryId) => ({ clubId, categoryId })),
      });
    }

    return this.prisma.team.findMany({
      where: { clubId },
      include: { category: true },
      orderBy: { category: { name: 'asc' } },
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
