import { Injectable } from '@nestjs/common';
import { MatchdayStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { LeaderboardsDto } from '../dto/leaderboards.dto';

interface LeaderboardsFilters {
  tournamentId: number;
  zoneId?: number | null;
  categoryId?: number | null;
}

interface PlayerEntryAccumulator {
  playerId: number;
  playerName: string;
  clubId: number;
  clubName: string;
  goals: number;
  matchesWithGoals: Set<number>;
  matchGoals: Map<number, number>;
}

interface TeamEntryAccumulator {
  clubId: number;
  clubName: string;
  goalsFor: number;
  goalsAgainst: number;
  cleanSheets: number;
  wins: number;
}

@Injectable()
export class LeaderboardsService {
  constructor(private readonly prisma: PrismaService) {}

  async getLeaderboards(filters: LeaderboardsFilters): Promise<LeaderboardsDto> {
    const playedMatchdays = await this.prisma.zoneMatchday.findMany({
      where: {
        status: MatchdayStatus.PLAYED,
        zone: {
          tournamentId: filters.tournamentId,
          ...(filters.zoneId ? { id: filters.zoneId } : {}),
        },
      },
      select: {
        zoneId: true,
        matchday: true,
      },
    });

    const playedMatchdaysByZone = new Map<number, Set<number>>();
    for (const matchday of playedMatchdays) {
      const existing = playedMatchdaysByZone.get(matchday.zoneId) ?? new Set<number>();
      existing.add(matchday.matchday);
      playedMatchdaysByZone.set(matchday.zoneId, existing);
    }

    const matchCategories = await this.prisma.matchCategory.findMany({
      where: {
        match: {
          tournamentId: filters.tournamentId,
          ...(filters.zoneId ? { zoneId: filters.zoneId } : {}),
        },
        ...(filters.categoryId
          ? { tournamentCategory: { categoryId: filters.categoryId } }
          : {}),
      },
      include: {
        match: {
          include: {
            zone: {
              select: {
                name: true,
              },
            },
            homeClub: {
              select: {
                id: true,
                name: true,
                shortName: true,
              },
            },
            awayClub: {
              select: {
                id: true,
                name: true,
                shortName: true,
              },
            },
          },
        },
        tournamentCategory: {
          include: {
            category: {
              select: {
                name: true,
              },
            },
          },
        },
      },
    });

    const playedMatchCategories = matchCategories.filter((matchCategory) => {
      const matchdaySet = playedMatchdaysByZone.get(matchCategory.match.zoneId);
      return matchdaySet?.has(matchCategory.match.matchday) ?? false;
    });

    const matchCategoryIds = playedMatchCategories.map((entry) => entry.id);

    const goals = await this.prisma.goal.findMany({
      where: {
        matchCategoryId: {
          in: matchCategoryIds,
        },
      },
      include: {
        player: {
          select: {
            firstName: true,
            lastName: true,
          },
        },
        club: {
          select: {
            id: true,
            name: true,
            shortName: true,
          },
        },
      },
    });

    const playerEntries = new Map<string, PlayerEntryAccumulator>();
    for (const goal of goals) {
      const key = `${goal.playerId}-${goal.clubId}`;
      const playerName = this.formatPlayerName(
        goal.player.firstName,
        goal.player.lastName
      );
      const clubName = goal.club.shortName ?? goal.club.name;
      const entry = playerEntries.get(key) ?? {
        playerId: goal.playerId,
        playerName,
        clubId: goal.clubId,
        clubName,
        goals: 0,
        matchesWithGoals: new Set<number>(),
        matchGoals: new Map<number, number>(),
      };
      entry.goals += 1;
      entry.matchesWithGoals.add(goal.matchCategoryId);
      entry.matchGoals.set(
        goal.matchCategoryId,
        (entry.matchGoals.get(goal.matchCategoryId) ?? 0) + 1
      );
      playerEntries.set(key, entry);
    }

    const topScorersPlayers = this.sortByPlayerName(
      Array.from(playerEntries.values()).map((entry) => ({
        playerId: entry.playerId,
        playerName: entry.playerName,
        clubId: entry.clubId,
        clubName: entry.clubName,
        goals: entry.goals,
      })),
      (entry) => entry.goals,
      'desc',
    ).slice(0, 10);

    const mostMatchesScoringPlayers = this.sortByPlayerName(
      Array.from(playerEntries.values()).map((entry) => ({
        playerId: entry.playerId,
        playerName: entry.playerName,
        clubId: entry.clubId,
        clubName: entry.clubName,
        matchesWithGoal: entry.matchesWithGoals.size,
      })),
      (entry) => entry.matchesWithGoal,
      'desc',
    ).slice(0, 10);

    const mostBracesPlayers = this.sortByPlayerName(
      Array.from(playerEntries.values()).map((entry) => ({
        playerId: entry.playerId,
        playerName: entry.playerName,
        clubId: entry.clubId,
        clubName: entry.clubName,
        bracesCount: Array.from(entry.matchGoals.values()).filter(
          (count) => count === 2
        ).length,
      })),
      (entry) => entry.bracesCount,
      'desc',
    ).slice(0, 10);

    const mostHatTricksPlayers = this.sortByPlayerName(
      Array.from(playerEntries.values()).map((entry) => ({
        playerId: entry.playerId,
        playerName: entry.playerName,
        clubId: entry.clubId,
        clubName: entry.clubName,
        hatTricksCount: Array.from(entry.matchGoals.values()).filter(
          (count) => count >= 3
        ).length,
      })),
      (entry) => entry.hatTricksCount,
      'desc',
    ).slice(0, 10);

    const teamEntries = new Map<number, TeamEntryAccumulator>();
    const matchEntries = [];
    const biggestWinsEntries = [];

    for (const matchCategory of playedMatchCategories) {
      const homeClub = matchCategory.match.homeClub;
      const awayClub = matchCategory.match.awayClub;
      if (!homeClub || !awayClub) {
        continue;
      }
      const homeClubName = homeClub.shortName ?? homeClub.name;
      const awayClubName = awayClub.shortName ?? awayClub.name;
      const homeEntry = this.getTeamEntry(teamEntries, homeClub.id, homeClubName);
      const awayEntry = this.getTeamEntry(teamEntries, awayClub.id, awayClubName);

      homeEntry.goalsFor += matchCategory.homeScore;
      homeEntry.goalsAgainst += matchCategory.awayScore;
      awayEntry.goalsFor += matchCategory.awayScore;
      awayEntry.goalsAgainst += matchCategory.homeScore;

      if (matchCategory.awayScore === 0) {
        homeEntry.cleanSheets += 1;
      }
      if (matchCategory.homeScore === 0) {
        awayEntry.cleanSheets += 1;
      }

      if (matchCategory.homeScore > matchCategory.awayScore) {
        homeEntry.wins += 1;
      } else if (matchCategory.awayScore > matchCategory.homeScore) {
        awayEntry.wins += 1;
      }

      const categoryName = matchCategory.tournamentCategory.category.name;
      const zoneName = matchCategory.match.zone?.name ?? null;
      const totalGoals = matchCategory.homeScore + matchCategory.awayScore;
      const goalDiff = Math.abs(matchCategory.homeScore - matchCategory.awayScore);

      matchEntries.push({
        matchCategoryId: matchCategory.id,
        matchId: matchCategory.matchId,
        zoneName,
        categoryName,
        homeClubName,
        awayClubName,
        homeScore: matchCategory.homeScore,
        awayScore: matchCategory.awayScore,
        totalGoals,
      });

      biggestWinsEntries.push({
        matchCategoryId: matchCategory.id,
        matchId: matchCategory.matchId,
        zoneName,
        categoryName,
        homeClubName,
        awayClubName,
        homeScore: matchCategory.homeScore,
        awayScore: matchCategory.awayScore,
        goalDiff,
      });
    }

    const teamValues = Array.from(teamEntries.values());
    const topScoringTeams = this.sortTeams(
      teamValues.map((entry) => ({
        clubId: entry.clubId,
        clubName: entry.clubName,
        goalsFor: entry.goalsFor,
      })),
      (entry) => entry.goalsFor,
      'desc',
    ).slice(0, 10);

    const bestDefenseTeams = this.sortTeams(
      teamValues.map((entry) => ({
        clubId: entry.clubId,
        clubName: entry.clubName,
        goalsAgainst: entry.goalsAgainst,
      })),
      (entry) => entry.goalsAgainst,
      'asc',
    ).slice(0, 10);

    const mostCleanSheetsTeams = this.sortTeams(
      teamValues.map((entry) => ({
        clubId: entry.clubId,
        clubName: entry.clubName,
        cleanSheets: entry.cleanSheets,
      })),
      (entry) => entry.cleanSheets,
      'desc',
    ).slice(0, 10);

    const mostWinsTeams = this.sortTeams(
      teamValues.map((entry) => ({
        clubId: entry.clubId,
        clubName: entry.clubName,
        wins: entry.wins,
      })),
      (entry) => entry.wins,
      'desc',
    ).slice(0, 10);

    const mostGoalsMatches = matchEntries
      .sort((a, b) => {
        if (b.totalGoals !== a.totalGoals) {
          return b.totalGoals - a.totalGoals;
        }
        return a.matchCategoryId - b.matchCategoryId;
      })
      .slice(0, 10);

    const biggestWinsMatches = biggestWinsEntries
      .sort((a, b) => {
        if (b.goalDiff !== a.goalDiff) {
          return b.goalDiff - a.goalDiff;
        }
        return a.matchCategoryId - b.matchCategoryId;
      })
      .slice(0, 10);

    return {
      filtersApplied: {
        tournamentId: filters.tournamentId,
        zoneId: filters.zoneId ?? null,
        categoryId: filters.categoryId ?? null,
      },
      leaderboards: {
        topScorersPlayers,
        mostMatchesScoringPlayers,
        mostBracesPlayers,
        mostHatTricksPlayers,
        topScoringTeams,
        bestDefenseTeams,
        mostCleanSheetsTeams,
        mostWinsTeams,
        mostGoalsMatches,
        biggestWinsMatches,
      },
    };
  }

  private formatPlayerName(firstName?: string | null, lastName?: string | null) {
    const parts = [firstName?.trim(), lastName?.trim()].filter(
      (value): value is string => Boolean(value)
    );
    return parts.length ? parts.join(' ') : 'Jugador';
  }

  private sortByPlayerName<T extends { playerName: string }>(
    entries: T[],
    metric: (entry: T) => number,
    direction: 'asc' | 'desc',
  ) {
    return entries.sort((a, b) => {
      const metricDiff = metric(a) - metric(b);
      if (metricDiff !== 0) {
        return direction === 'asc' ? metricDiff : -metricDiff;
      }
      return a.playerName.localeCompare(b.playerName, 'es', { sensitivity: 'base' });
    });
  }

  private sortTeams<T extends { clubName: string }>(
    entries: T[],
    metric: (entry: T) => number,
    direction: 'asc' | 'desc',
  ) {
    return entries.sort((a, b) => {
      const metricDiff = metric(a) - metric(b);
      if (metricDiff !== 0) {
        return direction === 'asc' ? metricDiff : -metricDiff;
      }
      return a.clubName.localeCompare(b.clubName, 'es', { sensitivity: 'base' });
    });
  }

  private getTeamEntry(
    entries: Map<number, TeamEntryAccumulator>,
    clubId: number,
    clubName: string,
  ) {
    const existing = entries.get(clubId);
    if (existing) {
      return existing;
    }
    const created = {
      clubId,
      clubName,
      goalsFor: 0,
      goalsAgainst: 0,
      cleanSheets: 0,
      wins: 0,
    };
    entries.set(clubId, created);
    return created;
  }
}
