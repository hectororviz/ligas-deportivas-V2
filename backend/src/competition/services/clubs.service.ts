import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateClubDto } from '../dto/create-club.dto';
import { slugify } from '../../common/utils/slugify';
import { AssignClubZoneDto } from '../dto/assign-club-zone.dto';
import { UpdateClubTeamsDto } from '../dto/update-club-teams.dto';

@Injectable()
export class ClubsService {
  constructor(private readonly prisma: PrismaService) {}

  create(dto: CreateClubDto) {
    return this.prisma.club.create({
      data: {
        name: dto.name,
        shortName: dto.shortName,
        slug: dto.slug ?? slugify(dto.name),
        leagueId: dto.leagueId,
        primaryColor: dto.primaryColor,
        secondaryColor: dto.secondaryColor,
      },
    });
  }

  findAll() {
    return this.prisma.club.findMany({
      include: {
        teams: {
          include: { category: true },
        },
      },
      orderBy: { name: 'asc' },
    });
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
}
