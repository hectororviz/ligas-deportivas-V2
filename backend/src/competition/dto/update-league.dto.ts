import { IsHexColor, IsOptional, IsString, Matches } from 'class-validator';

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
}
