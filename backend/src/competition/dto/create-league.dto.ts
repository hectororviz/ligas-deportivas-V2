import { GameDay } from '@prisma/client';
import { IsEnum, IsHexColor, IsNotEmpty, IsOptional, Matches } from 'class-validator';

export class CreateLeagueDto {
  @IsNotEmpty()
  name!: string;

  @IsOptional()
  @Matches(/^[a-z0-9-]+$/)
  slug?: string;

  @IsHexColor()
  colorHex!: string;

  @IsEnum(GameDay)
  gameDay!: GameDay;
}
