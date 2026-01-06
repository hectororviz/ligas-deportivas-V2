import { Injectable } from '@nestjs/common';
import { MatchdayStatus, ZoneStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

interface StandingRow {
  clubId: number;
  clubName: string;
  points: number;
  goalsFor: number;
  goalsAgainst: number;
  goalDifference: number;
}

@Injectable()
export class HomeSummaryService {
  constructor(private readonly prisma: PrismaService) {}

  async getSummary() {
    const tournaments = await this.prisma.tournament.findMany({
      where: {
        zones: {
          some: {
            status: { not: ZoneStatus.FINISHED }
          }
        }
      },
      include: {
        zones: {
          where: { status: { not: ZoneStatus.FINISHED } },
          include: {
            matchdays: true
          }
        }
      }
    });

    const zoneIds = tournaments.flatMap((tournament) =>
      tournament.zones.map((zone) => zone.id)
    );

    const standings =
      zoneIds.length === 0
        ? []
        : await this.prisma.categoryStanding.findMany({
            where: { zoneId: { in: zoneIds } },
            include: {
              club: true,
              tournamentCategory: {
                select: {
                  countsForGeneral: true
                }
              }
            }
          });

    const standingsByZone = new Map<number, Map<number, StandingRow>>();

    for (const entry of standings) {
      if (!entry.tournamentCategory.countsForGeneral) {
        continue;
      }
      const zoneStandings =
        standingsByZone.get(entry.zoneId) ?? new Map<number, StandingRow>();
      if (!standingsByZone.has(entry.zoneId)) {
        standingsByZone.set(entry.zoneId, zoneStandings);
      }

      const row = zoneStandings.get(entry.clubId) ?? {
        clubId: entry.clubId,
        clubName: entry.club.name,
        points: 0,
        goalsFor: 0,
        goalsAgainst: 0,
        goalDifference: 0
      };

      row.points += entry.points;
      row.goalsFor += entry.goalsFor;
      row.goalsAgainst += entry.goalsAgainst;
      row.goalDifference = row.goalsFor - row.goalsAgainst;
      zoneStandings.set(entry.clubId, row);
    }

    const sortedTournaments = tournaments.sort((a, b) => {
      if (b.year !== a.year) {
        return b.year - a.year;
      }
      return a.name.toLowerCase().localeCompare(b.name.toLowerCase());
    });

    const tournamentsSummary = sortedTournaments
      .map((tournament) => {
        const zones = [...tournament.zones].sort((a, b) =>
          a.name.toLowerCase().localeCompare(b.name.toLowerCase())
        );
        return {
          id: tournament.id,
          name: tournament.name,
          year: tournament.year,
          zones: zones.map((zone) => {
            const standingsMap = standingsByZone.get(zone.id);
            const top =
              standingsMap == null
                ? []
                : this.sortStandings(Array.from(standingsMap.values())).slice(
                    0,
                    3
                  );
            const upcomingMatchday = zone.matchdays
              .filter((matchday) => matchday.status !== MatchdayStatus.PLAYED)
              .sort((a, b) => a.matchday - b.matchday)[0];

            return {
              id: zone.id,
              name: zone.name,
              top,
              nextMatchday: upcomingMatchday
                ? {
                    matchday: upcomingMatchday.matchday,
                    date: upcomingMatchday.date
                      ? upcomingMatchday.date.toISOString()
                      : null,
                    status: upcomingMatchday.status
                  }
                : null
            };
          })
        };
      })
      .filter((tournament) => tournament.zones.length > 0);

    return {
      generatedAt: new Date().toISOString(),
      tournaments: tournamentsSummary
    };
  }

  private sortStandings(rows: StandingRow[]) {
    return rows.sort((a, b) => {
      if (b.points !== a.points) {
        return b.points - a.points;
      }
      if (b.goalDifference !== a.goalDifference) {
        return b.goalDifference - a.goalDifference;
      }
      if (b.goalsFor !== a.goalsFor) {
        return b.goalsFor - a.goalsFor;
      }
      return a.goalsAgainst - b.goalsAgainst;
    });
  }
}
