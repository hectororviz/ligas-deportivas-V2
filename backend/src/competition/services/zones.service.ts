import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Gender, Prisma, ZoneStatus } from '@prisma/client';

import { PrismaService } from '../../prisma/prisma.service';

type ZoneContext = Prisma.ZoneGetPayload<{
  include: {
    tournament: {
      include: {
        categories: {
          where: { enabled: true };
          include: { category: true };
        };
        zones: { include: { clubZones: true } };
      };
    };
    clubZones: { include: { club: true } };
  };
}>;

type ZoneDetail = Prisma.ZoneGetPayload<{
  include: {
    tournament: {
      include: {
        league: true;
        categories: {
          where: { enabled: true };
          include: { category: true };
        };
      };
    };
    clubZones: { include: { club: true } };
  };
}>;

@Injectable()
export class ZonesService {
  constructor(private readonly prisma: PrismaService) {}

  list() {
    return this.prisma.zone.findMany({
      include: {
        tournament: {
          include: { league: true },
        },
        _count: {
          select: { clubZones: true, matches: true },
        },
      },
      orderBy: [
        { tournament: { year: 'desc' } },
        { tournament: { name: 'asc' } },
        { name: 'asc' },
      ],
    });
  }

  findById(id: number) {
    return this.prisma.zone.findUnique({
      where: { id },
      include: {
        tournament: {
          include: {
            league: true,
            categories: {
              where: { enabled: true },
              include: { category: true },
            },
          },
        },
        clubZones: {
          include: { club: true },
          orderBy: { club: { name: 'asc' } },
        },
      },
    });
  }

  async assignClub(zoneId: number, clubId: number) {
    return this.prisma.$transaction(async (tx) => {
      const zone = await this.getZoneContext(tx, zoneId);
      if (!zone) {
        throw new NotFoundException('Zona inexistente');
      }

      this.ensureZoneEditable(zone);

      const existingAssignment = this.findExistingAssignment(zone, clubId);
      if (existingAssignment?.zoneId === zone.id) {
        throw new BadRequestException('El club ya está asignado a esta zona');
      }

      await this.ensureClubEligibility(tx, zone, clubId, false);

      if (existingAssignment) {
        await tx.clubZone.delete({
          where: {
            zoneId_clubId: {
              zoneId: existingAssignment.zoneId,
              clubId,
            },
          },
        });
      }

      await tx.clubZone.create({
        data: {
          clubId,
          zoneId: zone.id,
        },
      });

      return this.getZoneDetail(tx, zone.id);
    });
  }

  async removeClub(zoneId: number, clubId: number) {
    return this.prisma.$transaction(async (tx) => {
      const zone = await this.getZoneContext(tx, zoneId);
      if (!zone) {
        throw new NotFoundException('Zona inexistente');
      }

      this.ensureZoneEditable(zone);

      const existingAssignment = zone.clubZones.find((assignment) => assignment.clubId === clubId);
      if (!existingAssignment) {
        throw new BadRequestException('El club no está asignado a esta zona');
      }

      await tx.clubZone.delete({
        where: {
          zoneId_clubId: {
            zoneId,
            clubId,
          },
        },
      });

      return this.getZoneDetail(tx, zone.id);
    });
  }

  async finalize(zoneId: number) {
    return this.prisma.$transaction(async (tx) => {
      const zone = await this.getZoneContext(tx, zoneId);
      if (!zone) {
        throw new NotFoundException('Zona inexistente');
      }

      this.ensureZoneEditable(zone);

      if (!zone.clubZones.length) {
        throw new BadRequestException('La zona debe tener al menos un club asignado antes de finalizar');
      }

      for (const assignment of zone.clubZones) {
        await this.ensureClubEligibility(tx, zone, assignment.clubId);
      }

      await tx.zone.update({
        where: { id: zone.id },
        data: {
          status: ZoneStatus.IN_PROGRESS,
          lockedAt: new Date(),
        },
      });

      return this.getZoneDetail(tx, zone.id);
    });
  }

  private async getZoneContext(tx: Prisma.TransactionClient, zoneId: number): Promise<ZoneContext | null> {
    return tx.zone.findUnique({
      where: { id: zoneId },
      include: {
        tournament: {
          include: {
            categories: {
              where: { enabled: true },
              include: { category: true },
            },
            zones: {
              include: { clubZones: true },
            },
          },
        },
        clubZones: {
          include: { club: true },
        },
      },
    });
  }

  private async getZoneDetail(tx: Prisma.TransactionClient, zoneId: number): Promise<ZoneDetail> {
    const zone = await tx.zone.findUnique({
      where: { id: zoneId },
      include: {
        tournament: {
          include: {
            league: true,
            categories: {
              where: { enabled: true },
              include: { category: true },
            },
          },
        },
        clubZones: {
          include: { club: true },
          orderBy: { club: { name: 'asc' } },
        },
      },
    });

    if (!zone) {
      throw new NotFoundException('Zona inexistente');
    }

    return zone;
  }

  private ensureZoneEditable(zone: ZoneContext) {
    if (zone.status !== ZoneStatus.OPEN) {
      throw new BadRequestException('La zona está bloqueada para edición');
    }
    if (zone.tournament.fixtureLockedAt) {
      throw new BadRequestException('El torneo está bloqueado para la generación de fixture');
    }
  }

  private findExistingAssignment(zone: ZoneContext, clubId: number) {
    for (const zoneItem of zone.tournament.zones) {
      for (const assignment of zoneItem.clubZones) {
        if (assignment.clubId === clubId) {
          return { zoneId: zoneItem.id, clubId };
        }
      }
    }
    return null;
  }

  private async ensureClubEligibility(
    tx: Prisma.TransactionClient,
    zone: ZoneContext,
    clubId: number,
    strict = true,
  ) {
    const enabledCategories = zone.tournament.categories;
    if (!enabledCategories.length) {
      return;
    }

    const tournamentCategoryIds = enabledCategories.map((category) => category.id);
    const teams = await tx.team.findMany({
      where: {
        clubId,
        tournamentCategoryId: { in: tournamentCategoryIds },
        active: true,
      },
      select: { tournamentCategoryId: true },
    });

    if (!teams.length) {
      throw new BadRequestException('El club no participa en este torneo');
    }

    const teamCategoryIds = new Set(teams.map((team) => team.tournamentCategoryId));

    if (!strict) {
      return;
    }

    const missingRequired = enabledCategories.filter(
      (assignment) => assignment.category.mandatory && !teamCategoryIds.has(assignment.id),
    );

    if (missingRequired.length) {
      const names = missingRequired.map((assignment) => assignment.category.name).join(', ');
      throw new BadRequestException(
        `El club no tiene equipos cargados para las categorías obligatorias: ${names}`,
      );
    }

    const players = await tx.player.findMany({
      where: {
        active: true,
        playerTournamentClubs: {
          some: {
            clubId,
            tournamentId: zone.tournamentId,
          },
        },
      },
      select: {
        birthDate: true,
        gender: true,
      },
    });

    const eligibleCounts = new Map<number, number>();
    for (const assignment of enabledCategories) {
      const count = players.filter((player) =>
        this.isPlayerEligibleForCategory(player, assignment.category),
      ).length;
      eligibleCounts.set(assignment.id, count);
    }

    const insufficient = enabledCategories.filter((assignment) => {
      if (!teamCategoryIds.has(assignment.id)) {
        return false;
      }
      const playersCount = eligibleCounts.get(assignment.id) ?? 0;
      return playersCount < assignment.category.minPlayers;
    });

    if (insufficient.length) {
      const details = insufficient
        .map((assignment) => {
          const playersCount = eligibleCounts.get(assignment.id) ?? 0;
          return `${assignment.category.name} (${playersCount}/${assignment.category.minPlayers})`;
        })
        .join(', ');
      throw new BadRequestException(
        `El club no cumple con el mínimo de jugadores requerido en: ${details}`,
      );
    }
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
}
