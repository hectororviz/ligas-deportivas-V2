import { IsHexColor, IsNotEmpty, IsOptional, Matches } from 'class-validator';

export class CreateClubDto {
  @IsNotEmpty()
  name!: string;

  @IsOptional()
  shortName?: string;

  @IsOptional()
  @Matches(/^[a-z0-9-]+$/)
  slug?: string;

  @IsOptional()
  leagueId?: number;

  @IsOptional()
  @IsHexColor()
  primaryColor?: string;

  @IsOptional()
  @IsHexColor()
  secondaryColor?: string;
}
