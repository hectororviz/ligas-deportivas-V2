import { Type } from 'class-transformer';
import { ArrayNotEmpty, IsArray, IsInt, Min } from 'class-validator';

export class JoinTournamentDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  tournamentId!: number;

  @IsArray()
  @ArrayNotEmpty()
  @IsInt({ each: true })
  @Min(1, { each: true })
  @Type(() => Number)
  tournamentCategoryIds!: number[];
}
