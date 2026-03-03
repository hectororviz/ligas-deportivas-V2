import { IsDateString, IsEnum, IsInt, IsNotEmpty, IsOptional } from 'class-validator';
import { Gender, TournamentChampionMode, TournamentStatus } from '@prisma/client';

export class CreateTournamentDto {
  @IsInt()
  leagueId!: number;

  @IsNotEmpty()
  name!: string;

  @IsInt()
  year!: number;

  @IsEnum(Gender)
  gender!: Gender;

  @IsEnum(TournamentChampionMode)
  championMode!: TournamentChampionMode;

  @IsOptional()
  @IsEnum(TournamentStatus)
  status?: TournamentStatus;

  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;

  @IsInt()
  pointsWin!: number;

  @IsInt()
  pointsDraw!: number;

  @IsInt()
  pointsLoss!: number;
}
