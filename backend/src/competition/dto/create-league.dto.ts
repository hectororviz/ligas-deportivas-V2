import { IsHexColor, IsNotEmpty, IsOptional, Matches } from 'class-validator';

export class CreateLeagueDto {
  @IsNotEmpty()
  name!: string;

  @IsOptional()
  @Matches(/^[a-z0-9-]+$/)
  slug?: string;

  @IsHexColor()
  colorHex!: string;
}
