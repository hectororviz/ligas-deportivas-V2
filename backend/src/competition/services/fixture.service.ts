import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { FixtureAlreadyExistsException } from '../../common/exceptions/fixture-already-exists.exception';
import { FixtureGenerationException } from '../../common/exceptions/fixture-generation.exception';
import { Round } from '@prisma/client';

interface RoundMatch {
  matchday: number;
  homeClubId: number;
  awayClubId: number;
}

@Injectable()
export class FixtureService {
  constructor(private readonly prisma: PrismaService) {}

  async generateForTournament(tournamentId: number) {
    try {
      return await this.prisma.$transaction(async (tx) => {
        const existing = await tx.match.count({ where: { tournamentId } });
        if (existing > 0) {
          throw new FixtureAlreadyExistsException();
        }

        const tournament = await tx.tournament.findUnique({
          where: { id: tournamentId },
          include: {
            zones: {
              include: {
                clubZones: {
                  include: { club: true }
                }
              }
            },
            categories: true
          }
        });

        if (!tournament) {
          throw new NotFoundException('Torneo no encontrado');
        }

        if (tournament.categories.length === 0) {
          throw new BadRequestException('El torneo debe tener categorías asignadas antes de generar el fixture');
        }

        const totalRoundsPerZone: number[] = [];

        for (const zone of tournament.zones) {
          const clubIds = Array.from(new Set(zone.clubZones.map((cz) => cz.clubId)));
          if (clubIds.length < 2) {
            throw new BadRequestException(`La zona ${zone.name} debe tener al menos dos clubes`);
          }

          const { firstRound, secondRound, totalMatchdays } = this.buildRoundRobin(clubIds);
          totalRoundsPerZone.push(totalMatchdays * 2);

          const categories = tournament.categories;

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
                    tournamentCategoryId: category.id
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
                    tournamentCategoryId: category.id
                  }))
                }
              }
            });
          }
        }

        await tx.tournament.update({
          where: { id: tournamentId },
          data: { fixtureLockedAt: new Date() },
        });

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

  private buildRoundRobin(clubIds: number[]) {
    const normalized = Array.from(new Set(clubIds));
    const arrangement: Array<number | null> = [...normalized];
    if (arrangement.length % 2 === 1) {
      arrangement.push(null);
    }

    const totalSlots = arrangement.length;
    const totalMatchdays = totalSlots - 1;
    const firstRound: RoundMatch[] = [];

    for (let roundIndex = 0; roundIndex < totalMatchdays; roundIndex += 1) {
      for (let i = 0; i < totalSlots / 2; i += 1) {
        const home = arrangement[i];
        const away = arrangement[totalSlots - 1 - i];
        if (home === null || away === null) {
          continue;
        }
        const isOddRound = (roundIndex + 1) % 2 === 1;
        const pairing: RoundMatch = {
          matchday: roundIndex + 1,
          homeClubId: isOddRound ? home : away,
          awayClubId: isOddRound ? away : home
        };
        firstRound.push(pairing);
      }
      const last = arrangement.pop();
      if (last !== undefined) {
        arrangement.splice(1, 0, last);
      }
    }

    const secondRound: RoundMatch[] = firstRound.map((match) => ({
      matchday: match.matchday + totalMatchdays,
      homeClubId: match.awayClubId,
      awayClubId: match.homeClubId
    }));

    return { firstRound, secondRound, totalMatchdays };
  }
}
