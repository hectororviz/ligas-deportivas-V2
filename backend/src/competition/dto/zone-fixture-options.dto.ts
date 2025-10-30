import { IsBoolean, IsInt, IsOptional } from 'class-validator';

export class ZoneFixtureOptionsDto {
  @IsOptional()
  @IsBoolean()
  doubleRound?: boolean;

  @IsOptional()
  @IsBoolean()
  shuffle?: boolean;

  @IsOptional()
  @IsInt()
  seed?: number;
}
