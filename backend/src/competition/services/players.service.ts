import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';

import { PrismaService } from '../../prisma/prisma.service';
import { CreatePlayerDto } from '../dto/create-player.dto';
import { ListPlayersDto } from '../dto/list-players.dto';
import { UpdatePlayerDto } from '../dto/update-player.dto';

type PlayerWithClub = Prisma.PlayerGetPayload<{
  include: { club: { select: { id: true; name: true } } };
}>;

@Injectable()
export class PlayersService {
  constructor(private readonly prisma: PrismaService) {}

  private readonly include = {
    club: {
      select: {
        id: true,
        name: true,
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
          clubId: dto.clubId ?? null,
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

  async findAll(query: ListPlayersDto) {
    const { search, status, dni, page, pageSize, clubId, gender, birthYear } = query;

    const where: Prisma.PlayerWhereInput = {};

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

    if (clubId !== undefined) {
      where.clubId = clubId;
    }

    if (gender) {
      where.gender = gender;
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
      data: players.map((player) => this.mapPlayer(player)),
      total,
      page,
      pageSize,
    };
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
    if (dto.clubId !== undefined) {
      data.club = dto.clubId === null ? { disconnect: true } : { connect: { id: dto.clubId } };
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

  private mapPlayer(player: PlayerWithClub) {
    const addressFields = [player.addressStreet, player.addressNumber, player.addressCity];
    const hasAddress = addressFields.some((value) => value && value.trim().length > 0);
    const emergencyFields = [
      player.emergencyName,
      player.emergencyRelationship,
      player.emergencyPhone,
    ];
    const hasEmergency = emergencyFields.some((value) => value && value.trim().length > 0);

    return {
      id: player.id,
      firstName: player.firstName,
      lastName: player.lastName,
      dni: player.dni,
      birthDate: player.birthDate.toISOString(),
      gender: player.gender,
      active: player.active,
      club: player.club ? { id: player.club.id, name: player.club.name } : null,
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
