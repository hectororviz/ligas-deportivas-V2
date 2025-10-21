import { IsDateString, IsEnum, IsInt, IsNotEmpty, IsOptional } from 'class-validator';
import { TournamentChampionMode } from '@prisma/client';

export class CreateTournamentDto {
  @IsInt()
  leagueId!: number;

  @IsNotEmpty()
  name!: string;

  @IsInt()
  year!: number;

  @IsEnum(TournamentChampionMode)
  championMode!: TournamentChampionMode;

  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;
}
