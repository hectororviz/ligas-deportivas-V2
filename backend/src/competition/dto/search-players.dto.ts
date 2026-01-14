import { Transform, Type } from 'class-transformer';
import { IsBoolean, IsInt, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

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

  @IsOptional()
  @Transform(({ value }) => {
    if (value === undefined) {
      return undefined;
    }
    if (typeof value === 'boolean') {
      return value;
    }
    if (typeof value === 'string') {
      const normalized = value.trim().toLowerCase();
      if (normalized === 'true' || normalized === '1') {
        return true;
      }
      if (normalized === 'false' || normalized === '0') {
        return false;
      }
    }
    return Boolean(value);
  })
  @IsBoolean()
  onlyFree?: boolean;
}
