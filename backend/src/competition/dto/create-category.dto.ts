import { Gender } from '@prisma/client';
import { IsBoolean, IsEnum, IsInt, IsNotEmpty, IsOptional, Max, Min } from 'class-validator';

export class CreateCategoryDto {
  @IsNotEmpty()
  name!: string;

  @IsInt()
  @Min(1900)
  @Max(2100)
  birthYearMin!: number;

  @IsInt()
  @Min(1900)
  @Max(2100)
  birthYearMax!: number;

  @IsEnum(Gender)
  gender!: Gender;

  @IsInt()
  @Min(1)
  minPlayers!: number;

  @IsBoolean()
  mandatory!: boolean;

  @IsOptional()
  @IsBoolean()
  active?: boolean;

  @IsOptional()
  @IsBoolean()
  promotional?: boolean;
}
