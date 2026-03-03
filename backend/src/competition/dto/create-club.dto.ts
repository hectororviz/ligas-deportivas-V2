import { Transform } from 'class-transformer';
import {
  IsBoolean,
  IsHexColor,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  IsUrl,
  Matches,
  MaxLength,
} from 'class-validator';

export class CreateClubDto {
  @IsNotEmpty()
  name!: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
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

  @IsOptional()
  @Transform(({ value }) => {
    if (value === undefined || value === null || value === '') {
      return undefined;
    }
    if (typeof value === 'boolean') {
      return value;
    }
    if (typeof value === 'string') {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return Boolean(value);
  })
  @IsBoolean()
  active?: boolean;

  @IsOptional()
  @IsUrl({}, { message: 'Ingresa una URL válida para el escudo.' })
  logoUrl?: string;

  @IsOptional()
  @MaxLength(120)
  instagram?: string;

  @IsOptional()
  @MaxLength(120)
  facebook?: string;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  homeAddress?: string;

  @IsOptional()
  @Transform(({ value }) => {
    if (value === undefined || value === null || value === '') {
      return undefined;
    }
    return typeof value === 'number' ? value : Number(value);
  })
  @IsNumber({ allowNaN: false, allowInfinity: false }, { message: 'Latitud inválida.' })
  latitude?: number;

  @IsOptional()
  @Transform(({ value }) => {
    if (value === undefined || value === null || value === '') {
      return undefined;
    }
    return typeof value === 'number' ? value : Number(value);
  })
  @IsNumber({ allowNaN: false, allowInfinity: false }, { message: 'Longitud inválida.' })
  longitude?: number;
}
