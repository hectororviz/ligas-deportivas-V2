import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Action, Gender, Module, Prisma, Scope } from '@prisma/client';

import { PrismaService } from '../../prisma/prisma.service';
import { RequestUser } from '../../common/interfaces/request-user.interface';
import { CreatePlayerDto } from '../dto/create-player.dto';
import { ListPlayersDto } from '../dto/list-players.dto';
import { SearchPlayersDto } from '../dto/search-players.dto';
import { UpdatePlayerDto } from '../dto/update-player.dto';

type PlayerWithMemberships = Prisma.PlayerGetPayload<{
  include: {
    playerTournamentClubs: {
      select: {
        tournamentId: true;
        club: { select: { id: true; name: true } };
      };
    };
  };
}>;

@Injectable()
export class PlayersService {
  constructor(private readonly prisma: PrismaService) {}

  private readonly include = {
    playerTournamentClubs: {
      select: {
        tournamentId: true,
        club: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    },
  } satisfies Prisma.PlayerInclude;

  async create(dto: CreatePlayerDto) {
    await this.ensureUniqueDni(dto.dni);

    try {
      const player = await this.prisma.player.create({
        data: {
          firstName: dto.firstName.trim(),
          lastName: dto.lastName.trim(),
          dni: dto.dni.trim(),
          birthDate: new Date(dto.birthDate),
          gender: dto.gender,
          active: dto.active ?? true,
          addressStreet: this.normalizeNullable(dto.address?.street),
          addressNumber: this.normalizeNullable(dto.address?.number),
          addressCity: this.normalizeNullable(dto.address?.city),
          emergencyName: this.normalizeNullable(dto.emergencyContact?.name),
          emergencyRelationship: this.normalizeNullable(dto.emergencyContact?.relationship),
          emergencyPhone: this.normalizeNullable(dto.emergencyContact?.phone),
        },
        include: this.include,
      });

      return this.mapPlayer(player);
    } catch (error) {
      throw this.handlePrismaError(error);
    }
  }

  async findAll(query: ListPlayersDto, user?: RequestUser) {
    const {
      search,
      status,
      dni,
      page,
      pageSize,
      clubId,
      tournamentId,
      gender,
      birthYear,
      birthYearMin,
      birthYearMax,
    } = query;

    const where: Prisma.PlayerWhereInput = {};

    if (clubId !== undefined && clubId !== null && tournamentId === undefined) {
      throw new BadRequestException('El filtro por club requiere un torneo.');
    }

    const trimmedDni = dni?.trim();
    if (trimmedDni) {
      where.dni = trimmedDni;
    } else if (search?.trim()) {
      const term = search.trim();
      where.OR = [
        { firstName: { contains: term, mode: 'insensitive' } },
        { lastName: { contains: term, mode: 'insensitive' } },
        { dni: { contains: term, mode: 'insensitive' } },
      ];
    }

    if (status === 'active') {
      where.active = true;
    } else if (status === 'inactive') {
      where.active = false;
    }

    if (gender) {
      where.gender = gender;
    }

    if (
      birthYear !== undefined &&
      (birthYearMin !== undefined || birthYearMax !== undefined)
    ) {
      throw new BadRequestException(
        'No se puede combinar el filtro por año de nacimiento único con un rango.',
      );
    }

    if (
      birthYearMin !== undefined &&
      birthYearMax !== undefined &&
      birthYearMin > birthYearMax
    ) {
      throw new BadRequestException(
        'El año mínimo no puede ser mayor al año máximo.',
      );
    }

    if (birthYear !== undefined) {
      const start = new Date(Date.UTC(birthYear, 0, 1));
      const end = new Date(Date.UTC(birthYear + 1, 0, 1));
      const existingBirthDateFilter =
        where.birthDate &&
        typeof where.birthDate === 'object' &&
        !(where.birthDate instanceof Date)
          ? (where.birthDate as Prisma.DateTimeFilter)
          : undefined;
      where.birthDate = {
        ...(existingBirthDateFilter ?? {}),
        gte: start,
        lt: end,
      };
    }

    if (birthYearMin !== undefined || birthYearMax !== undefined) {
      const existingBirthDateFilter =
        where.birthDate &&
        typeof where.birthDate === 'object' &&
        !(where.birthDate instanceof Date)
          ? (where.birthDate as Prisma.DateTimeFilter)
          : undefined;
      const filter: Prisma.DateTimeFilter = {
        ...(existingBirthDateFilter ?? {}),
      };
      if (birthYearMin !== undefined) {
        filter.gte = new Date(Date.UTC(birthYearMin, 0, 1));
      }
      if (birthYearMax !== undefined) {
        filter.lt = new Date(Date.UTC(birthYearMax + 1, 0, 1));
      }
      where.birthDate = filter;
    }

    const restrictedClubIds = this.getRestrictedClubIds(user);
    const membershipFilters: Prisma.PlayerTournamentClubWhereInput[] = [];
    const buildMembershipCriteria = (
      filters: Prisma.PlayerTournamentClubWhereInput[],
    ): Prisma.PlayerTournamentClubWhereInput => (filters.length ? { AND: filters } : {});

    if (tournamentId !== undefined) {
      membershipFilters.push({ tournamentId });
    }

    if (restrictedClubIds !== null) {
      if (clubId !== undefined) {
        if (clubId === null) {
          where.playerTournamentClubs = { none: buildMembershipCriteria(membershipFilters) };
        } else if (restrictedClubIds.includes(clubId)) {
          membershipFilters.push({ clubId });
          where.playerTournamentClubs = { some: buildMembershipCriteria(membershipFilters) };
        } else {
          where.playerTournamentClubs = {
            some: { AND: [...membershipFilters, { clubId: { in: [] } }] },
          };
        }
      } else {
        membershipFilters.push({ clubId: { in: restrictedClubIds } });
        where.playerTournamentClubs = { some: buildMembershipCriteria(membershipFilters) };
      }
    } else if (clubId !== undefined) {
      if (clubId === null) {
        where.playerTournamentClubs = { none: buildMembershipCriteria(membershipFilters) };
      } else {
        membershipFilters.push({ clubId });
        where.playerTournamentClubs = { some: buildMembershipCriteria(membershipFilters) };
      }
    } else if (membershipFilters.length) {
      where.playerTournamentClubs = { some: buildMembershipCriteria(membershipFilters) };
    }

    const skip = (page - 1) * pageSize;

    const [total, players] = await this.prisma.$transaction([
      this.prisma.player.count({ where }),
      this.prisma.player.findMany({
        where,
        include: this.include,
        orderBy: [{ lastName: 'asc' }, { firstName: 'asc' }],
        skip,
        take: pageSize,
      }),
    ]);

    return {
      data: players.map((player) => this.mapPlayer(player, tournamentId)),
      total,
      page,
      pageSize,
    };
  }

  async searchByDniAndCategory(query: SearchPlayersDto) {
    const trimmedDni = query.dni?.trim();
    const [category, tournamentCategory] = await Promise.all([
      this.prisma.category.findUnique({
        where: { id: query.categoryId },
      }),
      this.prisma.tournamentCategory.findFirst({
        where: {
          tournamentId: query.tournamentId,
          categoryId: query.categoryId,
          enabled: true,
        },
        select: { id: true },
      }),
    ]);

    if (!category || !category.active) {
      throw new BadRequestException('Categoría inválida o inactiva.');
    }
    if (!tournamentCategory) {
      throw new BadRequestException('La categoría no está habilitada en el torneo.');
    }

    const startDate = new Date(Date.UTC(category.birthYearMin, 0, 1));
    const endDate = new Date(Date.UTC(category.birthYearMax, 11, 31, 23, 59, 59, 999));

    const where: Prisma.PlayerWhereInput = {
      active: true,
      birthDate: {
        gte: startDate,
        lte: endDate,
      },
    };

    if (trimmedDni) {
      where.dni = trimmedDni;
    }

    if (category.gender !== Gender.MIXTO) {
      where.gender = category.gender;
    }

    const players = await this.prisma.player.findMany({
      where,
      include: {
        playerTournamentClubs: {
          where: { tournamentId: query.tournamentId },
          select: {
            clubId: true,
            club: { select: { id: true, name: true } },
            tournamentId: true,
          },
        },
      },
      orderBy: [{ lastName: 'asc' }, { firstName: 'asc' }],
    });

    return players.map((player) => {
      const assignment = player.playerTournamentClubs[0];
      return {
        id: player.id,
        firstName: player.firstName,
        lastName: player.lastName,
        dni: player.dni,
        birthDate: player.birthDate.toISOString(),
        assignedClubId: assignment?.clubId ?? null,
        assignedClubName: assignment?.club?.name ?? null,
      };
    });
  }

  private getRestrictedClubIds(user?: RequestUser): number[] | null {
    if (!user) {
      return null;
    }

    const relevantGrants = user.permissions.filter(
      (grant) =>
        grant.module === Module.JUGADORES &&
        (grant.action === Action.VIEW || grant.action === Action.MANAGE)
    );

    if (relevantGrants.length === 0) {
      return this.getFallbackClubRestriction(user);
    }

    if (relevantGrants.some((grant) => grant.scope === Scope.GLOBAL)) {
      return null;
    }

    const clubIds = new Set<number>();
    for (const grant of relevantGrants) {
      if (grant.scope === Scope.CLUB && grant.clubs) {
        for (const clubId of grant.clubs) {
          clubIds.add(clubId);
        }
      }
    }

    if (clubIds.size > 0) {
      return Array.from(clubIds);
    }

    return this.getFallbackClubRestriction(user);
  }

  private getFallbackClubRestriction(user: RequestUser): number[] | null {
    if (!user.club) {
      return null;
    }

    const limitedRoles = new Set(['DELEGATE', 'COACH']);
    const hasLimitedRole = user.roles.some((role) => limitedRoles.has(role));

    if (!hasLimitedRole) {
      return null;
    }

    return [user.club.id];
  }

  async findById(id: number) {
    const player = await this.prisma.player.findUnique({
      where: { id },
      include: this.include,
    });
    if (!player) {
      throw new NotFoundException('Jugador no encontrado');
    }
    return this.mapPlayer(player);
  }

  async update(id: number, dto: UpdatePlayerDto) {
    const existing = await this.prisma.player.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundException('Jugador no encontrado');
    }

    if (dto.dni && dto.dni.trim() !== existing.dni) {
      await this.ensureUniqueDni(dto.dni, id);
    }

    const data: Prisma.PlayerUpdateInput = {};

    if (dto.firstName !== undefined) {
      data.firstName = dto.firstName.trim();
    }
    if (dto.lastName !== undefined) {
      data.lastName = dto.lastName.trim();
    }
    if (dto.dni !== undefined) {
      data.dni = dto.dni.trim();
    }
    if (dto.birthDate !== undefined) {
      data.birthDate = new Date(dto.birthDate);
    }
    if (dto.gender !== undefined) {
      data.gender = dto.gender;
    }
    if (dto.active !== undefined) {
      data.active = dto.active;
    }
    if (dto.address !== undefined) {
      data.addressStreet = this.normalizeNullable(dto.address?.street);
      data.addressNumber = this.normalizeNullable(dto.address?.number);
      data.addressCity = this.normalizeNullable(dto.address?.city);
    }
    if (dto.emergencyContact !== undefined) {
      data.emergencyName = this.normalizeNullable(dto.emergencyContact?.name);
      data.emergencyRelationship = this.normalizeNullable(dto.emergencyContact?.relationship);
      data.emergencyPhone = this.normalizeNullable(dto.emergencyContact?.phone);
    }

    try {
      const player = await this.prisma.player.update({
        where: { id },
        data,
        include: this.include,
      });
      return this.mapPlayer(player);
    } catch (error) {
      throw this.handlePrismaError(error);
    }
  }

  private mapPlayer(player: PlayerWithMemberships, tournamentId?: number) {
    const addressFields = [player.addressStreet, player.addressNumber, player.addressCity];
    const hasAddress = addressFields.some((value) => value && value.trim().length > 0);
    const emergencyFields = [
      player.emergencyName,
      player.emergencyRelationship,
      player.emergencyPhone,
    ];
    const hasEmergency = emergencyFields.some((value) => value && value.trim().length > 0);
    const memberships = player.playerTournamentClubs ?? [];
    const membership =
      tournamentId !== undefined
        ? memberships.find((entry) => entry.tournamentId === tournamentId)
        : memberships.length === 1
          ? memberships[0]
          : undefined;
    const club = membership?.club ?? null;

    return {
      id: player.id,
      firstName: player.firstName,
      lastName: player.lastName,
      dni: player.dni,
      birthDate: player.birthDate.toISOString(),
      gender: player.gender,
      active: player.active,
      club: club ? { id: club.id, name: club.name } : null,
      address: hasAddress
        ? {
            street: player.addressStreet,
            number: player.addressNumber,
            city: player.addressCity,
          }
        : null,
      emergencyContact: hasEmergency
        ? {
            name: player.emergencyName,
            relationship: player.emergencyRelationship,
            phone: player.emergencyPhone,
          }
        : null,
    };
  }

  private normalizeNullable(value?: string | null) {
    if (value === undefined) {
      return undefined;
    }
    if (value === null) {
      return null;
    }
    const trimmed = value.trim();
    return trimmed.length ? trimmed : null;
  }

  private async ensureUniqueDni(dni: string, excludeId?: number) {
    const existing = await this.prisma.player.findFirst({
      where: {
        dni: dni.trim(),
        NOT: excludeId ? { id: excludeId } : undefined,
      },
    });

    if (existing) {
      throw new BadRequestException('El DNI ingresado ya está en uso.');
    }
  }

  private handlePrismaError(error: unknown): never {
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
      if (Array.isArray(error.meta?.target) && error.meta?.target.includes('dni')) {
        throw new BadRequestException('El DNI ingresado ya está en uso.');
      }
    }
    throw error;
  }
}
