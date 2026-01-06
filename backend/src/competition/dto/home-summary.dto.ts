import { MatchdayStatus } from '@prisma/client';

export interface StandingRowDto {
  clubId: number;
  clubName: string;
  points: number;
  goalsFor: number;
  goalsAgainst: number;
  goalDifference: number;
}

export interface NextRoundDto {
  matchday: number;
  date: string | null;
  status: MatchdayStatus;
  kickoffTime: string | null;
}

export interface ZoneHomeSummaryDto {
  id: number;
  name: string;
  top: StandingRowDto[];
  nextMatchday: NextRoundDto | null;
}

export interface TournamentHomeSummaryDto {
  id: number;
  leagueName: string;
  name: string;
  year: number;
  zones: ZoneHomeSummaryDto[];
}

export interface HomeSummaryDto {
  generatedAt: string;
  tournaments: TournamentHomeSummaryDto[];
}
