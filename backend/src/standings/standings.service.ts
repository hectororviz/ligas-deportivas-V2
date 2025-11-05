import { Injectable, NotFoundException } from '@nestjs/common';
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
        categories: true,
      },
    });
    if (!match) {
      return;
    }

    for (const category of match.categories) {
      await this.recalculateForCategory(match.zoneId, category.tournamentCategoryId);
    }
  }

  async recalculateForCategory(zoneId: number, tournamentCategoryId: number) {
    const tournamentCategory = await this.prisma.tournamentCategory.findUnique({
      where: { id: tournamentCategoryId },
      include: {
        tournament: true,
        category: true,
      },
    });

    if (!tournamentCategory) {
      return;
    }

    const { tournament } = tournamentCategory;

    const clubAssignments = await this.prisma.clubZone.findMany({
      where: { zoneId },
      select: { clubId: true },
    });

    const clubIds = clubAssignments.map((assignment) => assignment.clubId);

    const matches = await this.prisma.matchCategory.findMany({
      where: {
        tournamentCategoryId,
        closedAt: { not: null },
        match: {
          zoneId,
        },
      },
      include: {
        match: true,
      },
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
        goalsAgainst: 0,
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
      points:
        row.wins * tournament.pointsWin +
        row.draws * tournament.pointsDraw +
        row.losses * tournament.pointsLoss,
      goalDifference: row.goalsFor - row.goalsAgainst,
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
        { goalsFor: 'desc' },
        { goalsAgainst: 'asc' },
      ],
      include: {
        club: true,
      },
    });
  }

  async getTournamentStandings(tournamentId: number) {
    const entries = await this.prisma.categoryStanding.findMany({
      where: {
        zone: { tournamentId },
      },
      include: {
        club: true,
        zone: true,
        tournamentCategory: {
          include: { category: true },
        },
      },
    });

    const grouped = new Map<number, { category: string; categoryId: number; standings: any[] }>();

    for (const entry of entries) {
      const key = entry.tournamentCategoryId;
      if (!grouped.has(key)) {
        grouped.set(key, {
          category: entry.tournamentCategory.category.name,
          categoryId: entry.tournamentCategory.categoryId,
          standings: [],
        });
      }
      grouped.get(key)?.standings.push(entry);
    }

    for (const [, group] of grouped) {
      this.sortStandings(group.standings);
    }

    return Array.from(grouped.entries()).map(([tournamentCategoryId, data]) => ({
      tournamentCategoryId,
      categoryId: data.categoryId,
      categoryName: data.category,
      standings: data.standings,
    }));
  }

  async getLeagueStandings(leagueId: number) {
    const entries = await this.prisma.categoryStanding.findMany({
      where: {
        zone: {
          tournament: {
            leagueId,
          },
        },
      },
      include: {
        club: true,
        zone: {
          include: {
            tournament: true,
          },
        },
        tournamentCategory: {
          include: { category: true },
        },
      },
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
          goalsAgainst: 0,
          points: 0,
        });
      }
      const row = grouped.get(key);
      row.played += entry.played;
      row.wins += entry.wins;
      row.draws += entry.draws;
      row.losses += entry.losses;
      row.goalsFor += entry.goalsFor;
      row.goalsAgainst += entry.goalsAgainst;
      row.points += entry.points;
    }

    const result = new Map<number, any[]>();

    for (const [, row] of grouped) {
      const points = row.points;
      const goalDifference = row.goalsFor - row.goalsAgainst;
      const data = {
        ...row,
        points,
        goalDifference,
      };
      if (!result.has(row.categoryId)) {
        result.set(row.categoryId, []);
      }
      result.get(row.categoryId)?.push(data);
    }

    for (const [, standings] of result) {
      this.sortStandings(standings);
    }

    return Array.from(result.entries()).map(([categoryId, standings]) => ({
      categoryId,
      categoryName: standings[0]?.categoryName ?? '',
      standings,
    }));
  }

  async getZoneStandingsSummary(zoneId: number) {
    const zone = await this.prisma.zone.findUnique({
      where: { id: zoneId },
      include: {
        tournament: {
          include: {
            league: true,
          },
        },
      },
    });

    if (!zone) {
      throw new NotFoundException('Zona no encontrada');
    }

    const entries = await this.prisma.categoryStanding.findMany({
      where: { zoneId },
      include: {
        club: true,
        tournamentCategory: {
          include: {
            category: true,
          },
        },
      },
    });

    const general = new Map<
      number,
      {
        clubId: number;
        clubName: string;
        played: number;
        wins: number;
        draws: number;
        losses: number;
        goalsFor: number;
        goalsAgainst: number;
        goalDifference: number;
        points: number;
      }
    >();

    const categories = new Map<
      number,
      {
        tournamentCategoryId: number;
        categoryId: number;
        categoryName: string;
        countsForGeneral: boolean;
        standings: any[];
      }
    >();

    for (const entry of entries) {
      const category = entry.tournamentCategory;
      const clubName = entry.club.name;

      if (!categories.has(entry.tournamentCategoryId)) {
        categories.set(entry.tournamentCategoryId, {
          tournamentCategoryId: entry.tournamentCategoryId,
          categoryId: category.categoryId,
          categoryName: category.category.name,
          countsForGeneral: category.countsForGeneral,
          standings: [],
        });
      }

      categories.get(entry.tournamentCategoryId)?.standings.push({
        clubId: entry.clubId,
        clubName,
        played: entry.played,
        wins: entry.wins,
        draws: entry.draws,
        losses: entry.losses,
        goalsFor: entry.goalsFor,
        goalsAgainst: entry.goalsAgainst,
        goalDifference: entry.goalDifference,
        points: entry.points,
      });

      if (!general.has(entry.clubId)) {
        general.set(entry.clubId, {
          clubId: entry.clubId,
          clubName,
          played: 0,
          wins: 0,
          draws: 0,
          losses: 0,
          goalsFor: 0,
          goalsAgainst: 0,
          goalDifference: 0,
          points: 0,
        });
      }

      if (!category.countsForGeneral) {
        continue;
      }

      const row = general.get(entry.clubId)!;
      row.played += entry.played;
      row.wins += entry.wins;
      row.draws += entry.draws;
      row.losses += entry.losses;
      row.goalsFor += entry.goalsFor;
      row.goalsAgainst += entry.goalsAgainst;
      row.points += entry.points;
      row.goalDifference = row.goalsFor - row.goalsAgainst;
    }

    const generalRows = Array.from(general.values());
    this.sortStandings(generalRows);

    const categoryRows = Array.from(categories.values()).map((group) => {
      this.sortStandings(group.standings);
      return group;
    });

    categoryRows.sort((a, b) =>
      a.categoryName.toLowerCase().localeCompare(b.categoryName.toLowerCase()),
    );

    return {
      zone: {
        id: zone.id,
        name: zone.name,
        tournamentId: zone.tournamentId,
        tournamentName: zone.tournament.name,
        tournamentYear: zone.tournament.year,
        leagueId: zone.tournament.leagueId,
        leagueName: zone.tournament.league?.name ?? '',
      },
      general: generalRows,
      categories: categoryRows,
    };
  }

  private createAccumulator(
    clubId: number,
    accumulator: Map<number, StandingAccumulator>,
  ): StandingAccumulator {
    const row: StandingAccumulator = {
      clubId,
      played: 0,
      wins: 0,
      draws: 0,
      losses: 0,
      goalsFor: 0,
      goalsAgainst: 0,
    };
    accumulator.set(clubId, row);
    return row;
  }

  private sortStandings<
    T extends {
      points: number;
      goalDifference: number;
      goalsFor: number;
      goalsAgainst: number;
    }
  >(rows: T[]) {
    rows.sort((a, b) => {
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
