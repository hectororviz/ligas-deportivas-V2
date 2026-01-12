import { Type } from 'class-transformer';
import { IsInt, IsNotEmpty, IsString, MaxLength, MinLength } from 'class-validator';

export class SearchPlayersDto {
  @IsString()
  @IsNotEmpty()
  @MinLength(6)
  @MaxLength(20)
  dni!: string;

  @Type(() => Number)
  @IsInt()
  categoryId!: number;

  @Type(() => Number)
  @IsInt()
  tournamentId!: number;
}
