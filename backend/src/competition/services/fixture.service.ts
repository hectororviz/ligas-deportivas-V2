import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { FixtureAlreadyExistsException } from '../../common/exceptions/fixture-already-exists.exception';
import { FixtureGenerationException } from '../../common/exceptions/fixture-generation.exception';
import { Round } from '@prisma/client';
import { GenerateFixtureDto } from '../dto/generate-fixture.dto';

interface RoundMatch {
  matchday: number;
  homeClubId: number;
  awayClubId: number;
}

@Injectable()
export class FixtureService {
  constructor(private readonly prisma: PrismaService) {}

  async generateForTournament(tournamentId: number, options?: GenerateFixtureDto) {
    const { zones, doubleRound = true, shuffle = false, publish = false } = options ?? {};

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
                clubZones: true
              }
            },
            categories: {
              where: { enabled: true }
            }
          }
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

          if (shuffle) {
            this.shuffleClubIds(clubIds);
          }

          const { firstRound, secondRound, totalMatchdays } = this.buildRoundRobin(clubIds, doubleRound);
          const totalGenerated = doubleRound ? totalMatchdays * 2 : totalMatchdays;
          totalRoundsPerZone.push(totalGenerated);

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
                    tournamentCategoryId: category.id,
                    kickoffTime: category.kickoffTime,
                    isPromocional: !category.countsForGeneral,
                  }))
                }
              }
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
                    tournamentCategoryId: category.id,
                    kickoffTime: category.kickoffTime,
                    isPromocional: !category.countsForGeneral,
                  }))
                }
              }
            });
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
          roundsGenerated: totalRoundsPerZone
        };
      });
    } catch (error) {
      if (error instanceof FixtureAlreadyExistsException || error instanceof BadRequestException) {
        throw error;
      }
      throw new FixtureGenerationException();
    }
  }

  private buildRoundRobin(clubIds: number[], doubleRound: boolean) {
    const normalized = Array.from(new Set(clubIds));
    const arrangement: Array<number | null> = [...normalized];
    if (arrangement.length % 2 === 1) {
      arrangement.push(null);
    }

    const totalSlots = arrangement.length;
    const totalMatchdays = totalSlots - 1;
    const firstRound: RoundMatch[] = [];
    const working = [...arrangement];

    for (let roundIndex = 0; roundIndex < totalMatchdays; roundIndex += 1) {
      const isEvenRound = roundIndex % 2 === 0;
      for (let i = 0; i < totalSlots / 2; i += 1) {
        const home = working[i];
        const away = working[totalSlots - 1 - i];
        if (home === null || away === null) {
          continue;
        }
        const pairing: RoundMatch = {
          matchday: roundIndex + 1,
          homeClubId: isEvenRound ? home : away,
          awayClubId: isEvenRound ? away : home,
        };
        firstRound.push(pairing);
      }
      const last = working.pop();
      if (last !== undefined) {
        working.splice(1, 0, last);
      }
    }

    const secondRound: RoundMatch[] = doubleRound
      ? firstRound.map((match) => ({
          matchday: match.matchday + totalMatchdays,
          homeClubId: match.awayClubId,
          awayClubId: match.homeClubId,
        }))
      : [];

    return { firstRound, secondRound, totalMatchdays };
  }

  private shuffleClubIds(clubIds: number[]) {
    for (let i = clubIds.length - 1; i > 0; i -= 1) {
      const j = Math.floor(Math.random() * (i + 1));
      [clubIds[i], clubIds[j]] = [clubIds[j], clubIds[i]];
    }
  }
}
