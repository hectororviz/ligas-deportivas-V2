import { Transform } from 'class-transformer';
import { IsBoolean, IsInt, IsOptional, IsString, Length, Max, Min } from 'class-validator';

export class UpdateSiteIdentityDto {
  @IsString()
  @Length(3, 80)
  title!: string;

  @IsOptional()
  @IsString()
  @Length(0, 160)
  slogan?: string;

  @IsOptional()
  @IsBoolean()
  @Transform(({ value }) => {
    if (typeof value === 'boolean') {
      return value;
    }
    if (typeof value === 'string') {
      return value.toLowerCase() === 'true';
    }
    return false;
  })
  removeIcon?: boolean;

  @IsOptional()
  @IsBoolean()
  @Transform(({ value }) => {
    if (typeof value === 'boolean') {
      return value;
    }
    if (typeof value === 'string') {
      return value.toLowerCase() === 'true';
    }
    return false;
  })
  removeFlyer?: boolean;

  @IsOptional()
  @IsBoolean()
  @Transform(({ value }) => {
    if (typeof value === 'boolean') {
      return value;
    }
    if (typeof value === 'string') {
      return value.toLowerCase() === 'true';
    }
    return false;
  })
  removeLoadingAnimation?: boolean;

  @IsOptional()
  @IsString()
  paletteId?: string;

  @IsOptional()
  @Transform(({ value }) => {
    if (value === '' || value === undefined || value === null) {
      return undefined;
    }
    return Number(value);
  })
  @IsInt()
  @Min(0)
  @Max(60000)
  loadingAnimationDuration?: number;

  @IsOptional()
  @IsString()
  homeBackground?: string;
}
