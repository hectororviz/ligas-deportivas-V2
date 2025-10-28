import { GameDay } from '@prisma/client';
import { IsEnum, IsHexColor, IsOptional, IsString, Matches } from 'class-validator';

export class UpdateLeagueDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @Matches(/^[a-z0-9-]+$/)
  slug?: string;

  @IsOptional()
  @IsHexColor()
  colorHex?: string;

  @IsOptional()
  @IsEnum(GameDay)
  gameDay?: GameDay;
}
