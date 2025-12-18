import { randomInt } from 'crypto';

import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { MatchdayStatus, Prisma, Round, ZoneStatus } from '@prisma/client';

import { PrismaService } from '../../prisma/prisma.service';
import { FixtureAlreadyExistsException } from '../../common/exceptions/fixture-already-exists.exception';
import { FixtureGenerationException } from '../../common/exceptions/fixture-generation.exception';
import { GenerateFixtureDto } from '../dto/generate-fixture.dto';
import { ZoneFixtureOptionsDto } from '../dto/zone-fixture-options.dto';

interface RoundMatch {
  matchday: number;
  homeClubId: number;
  awayClubId: number;
}

interface RoundBye {
  matchday: number;
  clubId: number;
}

export interface MatchdaySchedule {
  matchday: number;
  round: Round;
  matches: RoundMatch[];
  byeClubId?: number;
}

interface ZoneFixtureContext {
  zoneId: number;
  tournamentId: number;
  categories: Array<{
    id: number;
    kickoffTime: string;
    countsForGeneral: boolean;
  }>;
  clubs: { id: number; name: string; shortName: string | null }[];
  clubIds: number[];
}

@Injectable()
export class FixtureService {
  constructor(private readonly prisma: PrismaService) {}

  async generateForTournament(tournamentId: number, options?: GenerateFixtureDto) {
    const { zones, doubleRound = true, shuffle = true, publish = false, seed } = options ?? {};

    try {
      return await this.prisma.$transaction(async (tx) => {
        if (zones && zones.length) {
          const matches = await tx.match.findFirst({
            where: { tournamentId, zoneId: { in: zones } },
            select: { id: true },
          });
          if (matches) {
            throw new FixtureAlreadyExistsException();
          }
        } else {
          const existing = await tx.match.count({ where: { tournamentId } });
          if (existing > 0) {
            throw new FixtureAlreadyExistsException();
          }
        }

        const tournament = await tx.tournament.findUnique({
          where: { id: tournamentId },
          include: {
            zones: {
              include: {
                clubZones: true,
              },
            },
            categories: {
              where: { enabled: true },
            },
          },
        });

        if (!tournament) {
          throw new NotFoundException('Torneo no encontrado');
        }

        if (tournament.categories.length === 0) {
          throw new BadRequestException('El torneo debe tener categorías asignadas antes de generar el fixture');
        }

        const zoneIdSet = zones && zones.length ? new Set(zones) : null;
        const zonesToProcess = tournament.zones.filter((zone) =>
          zoneIdSet ? zoneIdSet.has(zone.id) : true
        );

        if (zoneIdSet && zonesToProcess.length !== zoneIdSet.size) {
          throw new BadRequestException('Alguna de las zonas seleccionadas no pertenece al torneo');
        }

        if (zonesToProcess.length === 0) {
          throw new BadRequestException('No hay zonas disponibles para generar el fixture');
        }

        const categories = tournament.categories;
        for (const category of categories) {
          if (!category.kickoffTime) {
            throw new BadRequestException('Todas las categorías habilitadas deben tener horario definido');
          }
        }

        const totalRoundsPerZone: number[] = [];

        for (const zone of zonesToProcess) {
          const clubIds = Array.from(new Set(zone.clubZones.map((cz) => cz.clubId)));
          if (clubIds.length < 2) {
            throw new BadRequestException(`La zona ${zone.name} debe tener al menos dos clubes`);
          }

          const { firstRound, secondRound, totalMatchdays } = this.buildRoundRobin(clubIds, {
            doubleRound,
            shuffle,
            seed,
          });
          const totalGenerated = doubleRound ? totalMatchdays * 2 : totalMatchdays;
          totalRoundsPerZone.push(totalGenerated);

          await tx.zoneMatchday.deleteMany({ where: { zoneId: zone.id } });

          for (const match of firstRound) {
            await tx.match.create({
              data: {
                tournamentId,
                zoneId: zone.id,
                matchday: match.matchday,
                round: Round.FIRST,
                homeClubId: match.homeClubId,
                awayClubId: match.awayClubId,
                categories: {
                  create: categories.map((category) => ({
                    kickoffTime: category.kickoffTime,
                    isPromocional: !category.countsForGeneral,
                    tournamentCategory: {
                      connect: { id: category.id },
                    },
                  })),
                },
              },
            });
          }

          for (const match of secondRound) {
            await tx.match.create({
              data: {
                tournamentId,
                zoneId: zone.id,
                matchday: match.matchday,
                round: Round.SECOND,
                homeClubId: match.homeClubId,
                awayClubId: match.awayClubId,
                categories: {
                  create: categories.map((category) => ({
                    kickoffTime: category.kickoffTime,
                    isPromocional: !category.countsForGeneral,
                    tournamentCategory: {
                      connect: { id: category.id },
                    },
                  })),
                },
              },
            });
          }

          if (totalGenerated > 0) {
            const matchdayEntries = Array.from({ length: totalGenerated }, (_, index) => ({
              zoneId: zone.id,
              matchday: index + 1,
              status: index === 0 ? MatchdayStatus.IN_PROGRESS : MatchdayStatus.PENDING,
            }));
            await tx.zoneMatchday.createMany({ data: matchdayEntries });
          }
        }

        if (publish) {
          await tx.tournament.update({
            where: { id: tournamentId },
            data: { fixtureLockedAt: new Date() },
          });
        }

        return {
          success: true,
          roundsGenerated: totalRoundsPerZone,
        };
      });
    } catch (error) {
      if (
        error instanceof FixtureAlreadyExistsException ||
        error instanceof BadRequestException ||
        error instanceof NotFoundException
      ) {
        throw error;
      }
      throw new FixtureGenerationException();
    }
  }

  async previewForZone(zoneId: number, options: ZoneFixtureOptionsDto = {}) {
    const doubleRound = options.doubleRound ?? true;
    const shuffle = options.shuffle ?? true;

    try {
      return await this.prisma.$transaction(async (tx) => {
        const existingMatches = await tx.match.count({ where: { zoneId } });
        if (existingMatches > 0) {
          throw new FixtureAlreadyExistsException();
        }

        const context = await this.getZoneFixtureContext(tx, zoneId, { allowOpen: true });

        const { firstRound, secondRound, totalMatchdays, byes, secondRoundByes, seed } =
          this.buildRoundRobin(context.clubIds, {
            doubleRound,
            shuffle,
            seed: options.seed,
          });

        const matchdays = this.buildMatchdays(firstRound, secondRound, byes, secondRoundByes);

        return {
          zoneId,
          doubleRound,
          totalMatchdays,
          seed: seed ?? null,
          matchdays,
        };
      });
    } catch (error) {
      if (
        error instanceof FixtureAlreadyExistsException ||
        error instanceof BadRequestException ||
        error instanceof NotFoundException
      ) {
        throw error;
      }
      throw new FixtureGenerationException();
    }
  }

  async generateForZone(zoneId: number, options: ZoneFixtureOptionsDto = {}) {
    const doubleRound = options.doubleRound ?? true;
    const shuffle = options.shuffle ?? true;

    try {
      return await this.prisma.$transaction(async (tx) => {
        const existingMatches = await tx.match.count({ where: { zoneId } });
        if (existingMatches > 0) {
          throw new FixtureAlreadyExistsException();
        }

        const context = await this.getZoneFixtureContext(tx, zoneId);

        const { firstRound, secondRound, totalMatchdays, seed } = this.buildRoundRobin(context.clubIds, {
          doubleRound,
          shuffle,
          seed: options.seed,
        });

        for (const match of firstRound) {
          await tx.match.create({
            data: {
              tournamentId: context.tournamentId,
              zoneId: context.zoneId,
              matchday: match.matchday,
              round: Round.FIRST,
              homeClubId: match.homeClubId,
              awayClubId: match.awayClubId,
              categories: {
                create: context.categories.map((category) => ({
                  kickoffTime: category.kickoffTime,
                  isPromocional: !category.countsForGeneral,
                  tournamentCategory: {
                    connect: { id: category.id },
                  },
                })),
              },
            },
          });
        }

        for (const match of secondRound) {
          await tx.match.create({
            data: {
              tournamentId: context.tournamentId,
              zoneId: context.zoneId,
              matchday: match.matchday,
              round: Round.SECOND,
              homeClubId: match.homeClubId,
              awayClubId: match.awayClubId,
              categories: {
                create: context.categories.map((category) => ({
                  tournamentCategoryId: category.id,
                  kickoffTime: category.kickoffTime,
                  isPromocional: !category.countsForGeneral,
                })),
              },
            },
          });
        }

        const totalGenerated = doubleRound ? totalMatchdays * 2 : totalMatchdays;

        await tx.zoneMatchday.deleteMany({ where: { zoneId } });

        if (totalGenerated > 0) {
          const matchdayEntries = Array.from({ length: totalGenerated }, (_, index) => ({
            zoneId,
            matchday: index + 1,
            status: index === 0 ? MatchdayStatus.IN_PROGRESS : MatchdayStatus.PENDING,
          }));
          await tx.zoneMatchday.createMany({ data: matchdayEntries });
        }

        await tx.zone.update({
          where: { id: zoneId },
          data: {
            status: ZoneStatus.PLAYING,
            fixtureSeed: seed ?? null,
          },
        });

        return {
          success: true,
          totalMatchdays: doubleRound ? totalMatchdays * 2 : totalMatchdays,
          seed: seed ?? null,
        };
      });
    } catch (error) {
      if (
        error instanceof FixtureAlreadyExistsException ||
        error instanceof BadRequestException ||
        error instanceof NotFoundException
      ) {
        throw error;
      }
      throw new FixtureGenerationException();
    }
  }

  private async getZoneFixtureContext(
    tx: Prisma.TransactionClient,
    zoneId: number,
    options: { allowOpen?: boolean } = {},
  ): Promise<ZoneFixtureContext> {
    const zone = await tx.zone.findUnique({
      where: { id: zoneId },
      include: {
        tournament: {
          include: {
            categories: {
              where: { enabled: true },
            },
          },
        },
        clubZones: {
          include: { club: true },
        },
      },
    });

    if (!zone) {
      throw new NotFoundException('Zona inexistente');
    }

    const allowedStatuses: ZoneStatus[] = options.allowOpen
      ? [ZoneStatus.OPEN, ZoneStatus.IN_PROGRESS]
      : [ZoneStatus.IN_PROGRESS];

    if (!allowedStatuses.includes(zone.status)) {
      throw new BadRequestException('La zona debe estar en curso para generar el fixture');
    }

    if (!zone.clubZones.length) {
      throw new BadRequestException('La zona debe tener clubes asignados');
    }

    const categories = zone.tournament.categories.map((category) => {
      if (!category.kickoffTime) {
        throw new BadRequestException('Todas las categorías habilitadas deben tener horario definido');
      }

      return {
        id: category.id,
        kickoffTime: category.kickoffTime,
        countsForGeneral: category.countsForGeneral,
      };
    });
    if (!categories.length) {
      throw new BadRequestException('El torneo debe tener categorías habilitadas');
    }

    const clubsMap = new Map<number, { id: number; name: string; shortName: string | null }>();
    for (const assignment of zone.clubZones) {
      if (assignment.club) {
        clubsMap.set(assignment.club.id, {
          id: assignment.club.id,
          name: assignment.club.name,
          shortName: assignment.club.shortName ?? null,
        });
      }
    }

    const clubs = Array.from(clubsMap.values()).sort((a, b) => a.name.localeCompare(b.name));

    if (clubs.length < 2) {
      throw new BadRequestException(`La zona ${zone.name} debe tener al menos dos clubes`);
    }

    const clubIds = clubs.map((club) => club.id);

    return {
      zoneId: zone.id,
      tournamentId: zone.tournamentId,
      categories,
      clubs,
      clubIds,
    };
  }

  private buildRoundRobin(
    clubIds: number[],
    options: { doubleRound: boolean; shuffle: boolean; seed?: number | null } | boolean
  ) {
    const normalizedOptions =
      typeof options === 'boolean'
        ? { doubleRound: options, shuffle: false, seed: null }
        : options;
    const normalized = Array.from(new Set(clubIds));
    let working = [...normalized];

    let seed = normalizedOptions.seed ?? null;
    const shouldShuffle = normalizedOptions.shuffle || seed != null;
    if (shouldShuffle) {
      seed = seed ?? this.generateSeed();
      const random = this.createSeededRandom(seed);
      this.shuffleClubIds(working, random);
    }

    const arrangement: Array<number | null> = [...working];
    if (arrangement.length % 2 === 1) {
      arrangement.push(null);
    }

    const totalSlots = arrangement.length;
    const totalMatchdays = totalSlots - 1;
    const firstRound: RoundMatch[] = [];
    const byes: RoundBye[] = [];
    const workingArrangement = [...arrangement];

    for (let roundIndex = 0; roundIndex < totalMatchdays; roundIndex += 1) {
      const isEvenRound = roundIndex % 2 === 0;
      for (let i = 0; i < totalSlots / 2; i += 1) {
        const home = workingArrangement[i];
        const away = workingArrangement[totalSlots - 1 - i];
        if (home === null || away === null) {
          const byeClub = home ?? away;
          if (byeClub !== null) {
            byes.push({ matchday: roundIndex + 1, clubId: byeClub });
          }
          continue;
        }
        const pairing: RoundMatch = {
          matchday: roundIndex + 1,
          homeClubId: isEvenRound ? home : away,
          awayClubId: isEvenRound ? away : home,
        };
        firstRound.push(pairing);
      }
      const last = workingArrangement.pop();
      if (last !== undefined) {
        workingArrangement.splice(1, 0, last);
      }
    }

    const secondRound: RoundMatch[] = normalizedOptions.doubleRound
      ? firstRound.map((match) => ({
          matchday: match.matchday + totalMatchdays,
          homeClubId: match.awayClubId,
          awayClubId: match.homeClubId,
        }))
      : [];

    const secondRoundByes: RoundBye[] = normalizedOptions.doubleRound
      ? byes.map((bye) => ({
          matchday: bye.matchday + totalMatchdays,
          clubId: bye.clubId,
        }))
      : [];

    return { firstRound, secondRound, totalMatchdays, byes, secondRoundByes, seed };
  }

  private buildMatchdays(
    firstRound: RoundMatch[],
    secondRound: RoundMatch[],
    firstRoundByes: RoundBye[],
    secondRoundByes: RoundBye[]
  ): MatchdaySchedule[] {
    const matchdayMap = new Map<number, MatchdaySchedule>();

    const ensureEntry = (matchday: number, round: Round) => {
      let entry = matchdayMap.get(matchday);
      if (!entry) {
        entry = { matchday, round, matches: [] };
        matchdayMap.set(matchday, entry);
      }
      entry.round = round;
      return entry;
    };

    for (const match of firstRound) {
      ensureEntry(match.matchday, Round.FIRST).matches.push(match);
    }

    for (const match of secondRound) {
      ensureEntry(match.matchday, Round.SECOND).matches.push(match);
    }

    for (const bye of firstRoundByes) {
      if (bye.clubId !== null) {
        ensureEntry(bye.matchday, Round.FIRST).byeClubId = bye.clubId;
      }
    }

    for (const bye of secondRoundByes) {
      if (bye.clubId !== null) {
        ensureEntry(bye.matchday, Round.SECOND).byeClubId = bye.clubId;
      }
    }

    return Array.from(matchdayMap.values()).sort((a, b) => a.matchday - b.matchday);
  }

  private shuffleClubIds(clubIds: number[], random: () => number) {
    for (let i = clubIds.length - 1; i > 0; i -= 1) {
      const j = Math.floor(random() * (i + 1));
      [clubIds[i], clubIds[j]] = [clubIds[j], clubIds[i]];
    }
  }

  private createSeededRandom(seed: number) {
    let value = seed % 2147483647;
    if (value <= 0) {
      value += 2147483646;
    }
    return () => {
      value = (value * 16807) % 2147483647;
      return (value - 1) / 2147483646;
    };
  }

  private generateSeed() {
    return randomInt(1, 2147483647);
  }
}
