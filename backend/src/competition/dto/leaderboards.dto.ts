export interface PlayerGoalsLeaderboardEntry {
  playerId: number;
  playerName: string;
  clubId: number;
  clubName: string;
  goals: number;
}

export interface PlayerMatchesScoringLeaderboardEntry {
  playerId: number;
  playerName: string;
  clubId: number;
  clubName: string;
  matchesWithGoal: number;
}

export interface PlayerBracesLeaderboardEntry {
  playerId: number;
  playerName: string;
  clubId: number;
  clubName: string;
  bracesCount: number;
}

export interface PlayerHatTricksLeaderboardEntry {
  playerId: number;
  playerName: string;
  clubId: number;
  clubName: string;
  hatTricksCount: number;
}

export interface TeamGoalsForLeaderboardEntry {
  clubId: number;
  clubName: string;
  goalsFor: number;
}

export interface TeamGoalsAgainstLeaderboardEntry {
  clubId: number;
  clubName: string;
  goalsAgainst: number;
}

export interface TeamCleanSheetsLeaderboardEntry {
  clubId: number;
  clubName: string;
  cleanSheets: number;
}

export interface TeamWinsLeaderboardEntry {
  clubId: number;
  clubName: string;
  wins: number;
}

export interface MatchGoalsLeaderboardEntry {
  matchCategoryId: number;
  matchId: number;
  zoneName?: string | null;
  categoryName: string;
  homeClubName: string;
  awayClubName: string;
  homeScore: number;
  awayScore: number;
  totalGoals: number;
}

export interface MatchBiggestWinLeaderboardEntry {
  matchCategoryId: number;
  matchId: number;
  zoneName?: string | null;
  categoryName: string;
  homeClubName: string;
  awayClubName: string;
  homeScore: number;
  awayScore: number;
  goalDiff: number;
}

export interface LeaderboardsDto {
  filtersApplied: {
    tournamentId: number;
    zoneId: number | null;
    categoryId: number | null;
  };
  leaderboards: {
    topScorersPlayers: PlayerGoalsLeaderboardEntry[];
    mostMatchesScoringPlayers: PlayerMatchesScoringLeaderboardEntry[];
    mostBracesPlayers: PlayerBracesLeaderboardEntry[];
    mostHatTricksPlayers: PlayerHatTricksLeaderboardEntry[];
    topScoringTeams: TeamGoalsForLeaderboardEntry[];
    bestDefenseTeams: TeamGoalsAgainstLeaderboardEntry[];
    mostCleanSheetsTeams: TeamCleanSheetsLeaderboardEntry[];
    mostWinsTeams: TeamWinsLeaderboardEntry[];
    mostGoalsMatches: MatchGoalsLeaderboardEntry[];
    biggestWinsMatches: MatchBiggestWinLeaderboardEntry[];
  };
}
