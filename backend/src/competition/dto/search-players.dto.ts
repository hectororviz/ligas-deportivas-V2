import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class SearchPlayersDto {
  @IsOptional()
  @IsString()
  @MinLength(6)
  @MaxLength(20)
  dni?: string;

  @Type(() => Number)
  @IsInt()
  categoryId!: number;

  @Type(() => Number)
  @IsInt()
  tournamentId!: number;
}
