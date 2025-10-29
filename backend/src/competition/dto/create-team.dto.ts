import { Type } from 'class-transformer';
import { IsBoolean, IsInt, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class CreateTeamDto {
  @Type(() => Number)
  @IsInt()
  clubId!: number;

  @Type(() => Number)
  @IsInt()
  tournamentCategoryId!: number;

  @IsString()
  @MinLength(2)
  @MaxLength(120)
  publicName!: string;

  @IsOptional()
  @IsBoolean()
  active?: boolean;
}
