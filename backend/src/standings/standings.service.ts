import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

interface StandingAccumulator {
  clubId: number;
  played: number;
  wins: number;
  draws: number;
  losses: number;
  goalsFor: number;
  goalsAgainst: number;
}

@Injectable()
export class StandingsService {
  constructor(private readonly prisma: PrismaService) {}

  async recalculateForMatch(matchId: number) {
    const match = await this.prisma.match.findUnique({
      where: { id: matchId },
      include: {
        zone: true,
        categories: true
      }
    });
    if (!match) {
      return;
    }

    for (const category of match.categories) {
      await this.recalculateForCategory(match.zoneId, category.tournamentCategoryId);
    }
  }

  async recalculateForCategory(zoneId: number, tournamentCategoryId: number) {
    const clubAssignments = await this.prisma.clubZone.findMany({
      where: { zoneId },
      select: { clubId: true }
    });

    const clubIds = clubAssignments.map((assignment) => assignment.clubId);

    const matches = await this.prisma.matchCategory.findMany({
      where: {
        tournamentCategoryId,
        closedAt: { not: null },
        match: {
          zoneId
        }
      },
      include: {
        match: true
      }
    });

    const accumulator = new Map<number, StandingAccumulator>();

    for (const clubId of clubIds) {
      accumulator.set(clubId, {
        clubId,
        played: 0,
        wins: 0,
        draws: 0,
        losses: 0,
        goalsFor: 0,
        goalsAgainst: 0
      });
    }

    for (const entry of matches) {
      const homeClubId = entry.match.homeClubId;
      const awayClubId = entry.match.awayClubId;
      if (!homeClubId || !awayClubId) {
        continue;
      }

      const home = accumulator.get(homeClubId) ?? this.createAccumulator(homeClubId, accumulator);
      const away = accumulator.get(awayClubId) ?? this.createAccumulator(awayClubId, accumulator);

      home.played += 1;
      away.played += 1;

      home.goalsFor += entry.homeScore;
      home.goalsAgainst += entry.awayScore;
      away.goalsFor += entry.awayScore;
      away.goalsAgainst += entry.homeScore;

      if (entry.homeScore > entry.awayScore) {
        home.wins += 1;
        away.losses += 1;
      } else if (entry.homeScore < entry.awayScore) {
        away.wins += 1;
        home.losses += 1;
      } else {
        home.draws += 1;
        away.draws += 1;
      }
    }

    await this.prisma.categoryStanding.deleteMany({ where: { zoneId, tournamentCategoryId } });

    const standings = Array.from(accumulator.values()).map((row) => ({
      zoneId,
      tournamentCategoryId,
      clubId: row.clubId,
      played: row.played,
      wins: row.wins,
      draws: row.draws,
      losses: row.losses,
      goalsFor: row.goalsFor,
      goalsAgainst: row.goalsAgainst,
      points: row.wins * 3 + row.draws,
      goalDifference: row.goalsFor - row.goalsAgainst
    }));

    if (standings.length) {
      await this.prisma.categoryStanding.createMany({ data: standings });
    }
  }

  async getZoneStandings(zoneId: number, tournamentCategoryId: number) {
    return this.prisma.categoryStanding.findMany({
      where: { zoneId, tournamentCategoryId },
      orderBy: [
        { points: 'desc' },
        { goalDifference: 'desc' },
        { goalsFor: 'desc' }
      ],
      include: {
        club: true
      }
    });
  }

  async getTournamentStandings(tournamentId: number) {
    const entries = await this.prisma.categoryStanding.findMany({
      where: {
        zone: { tournamentId }
      },
      include: {
        club: true,
        zone: true,
        tournamentCategory: {
          include: { category: true }
        }
      }
    });

    const grouped = new Map<number, { category: string; categoryId: number; standings: any[] }>();

    for (const entry of entries) {
      const key = entry.tournamentCategoryId;
      if (!grouped.has(key)) {
        grouped.set(key, {
          category: entry.tournamentCategory.category.name,
          categoryId: entry.tournamentCategory.categoryId,
          standings: []
        });
      }
      grouped.get(key)?.standings.push(entry);
    }

    for (const [, group] of grouped) {
      group.standings.sort((a, b) => {
        if (b.points !== a.points) {
          return b.points - a.points;
        }
        if (b.goalDifference !== a.goalDifference) {
          return b.goalDifference - a.goalDifference;
        }
        return b.goalsFor - a.goalsFor;
      });
    }

    return Array.from(grouped.entries()).map(([tournamentCategoryId, data]) => ({
      tournamentCategoryId,
      categoryId: data.categoryId,
      categoryName: data.category,
      standings: data.standings
    }));
  }

  async getLeagueStandings(leagueId: number) {
    const entries = await this.prisma.categoryStanding.findMany({
      where: {
        zone: {
          tournament: {
            leagueId
          }
        }
      },
      include: {
        club: true,
        zone: {
          include: {
            tournament: true
          }
        },
        tournamentCategory: {
          include: { category: true }
        }
      }
    });

    const grouped = new Map<string, any>();

    for (const entry of entries) {
      const key = `${entry.tournamentCategory.categoryId}-${entry.clubId}`;
      const existing = grouped.get(key);
      if (!existing) {
        grouped.set(key, {
          categoryId: entry.tournamentCategory.categoryId,
          categoryName: entry.tournamentCategory.category.name,
          clubId: entry.clubId,
          club: entry.club,
          played: 0,
          wins: 0,
          draws: 0,
          losses: 0,
          goalsFor: 0,
          goalsAgainst: 0
        });
      }
      const row = grouped.get(key);
      row.played += entry.played;
      row.wins += entry.wins;
      row.draws += entry.draws;
      row.losses += entry.losses;
      row.goalsFor += entry.goalsFor;
      row.goalsAgainst += entry.goalsAgainst;
    }

    const result = new Map<number, any[]>();

    for (const [, row] of grouped) {
      const points = row.wins * 3 + row.draws;
      const goalDifference = row.goalsFor - row.goalsAgainst;
      const data = {
        ...row,
        points,
        goalDifference
      };
      if (!result.has(row.categoryId)) {
        result.set(row.categoryId, []);
      }
      result.get(row.categoryId)?.push(data);
    }

    for (const [, standings] of result) {
      standings.sort((a, b) => {
        if (b.points !== a.points) {
          return b.points - a.points;
        }
        if (b.goalDifference !== a.goalDifference) {
          return b.goalDifference - a.goalDifference;
        }
        return b.goalsFor - a.goalsFor;
      });
    }

    return Array.from(result.entries()).map(([categoryId, standings]) => ({
      categoryId,
      categoryName: standings[0]?.categoryName ?? '',
      standings
    }));
  }

  private createAccumulator(
    clubId: number,
    accumulator: Map<number, StandingAccumulator>
  ): StandingAccumulator {
    const row: StandingAccumulator = {
      clubId,
      played: 0,
      wins: 0,
      draws: 0,
      losses: 0,
      goalsFor: 0,
      goalsAgainst: 0
    };
    accumulator.set(clubId, row);
    return row;
  }
}
