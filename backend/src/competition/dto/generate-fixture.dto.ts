import {
  ArrayNotEmpty,
  IsArray,
  IsBoolean,
  IsInt,
  IsOptional
} from 'class-validator';

export class GenerateFixtureDto {
  @IsOptional()
  @IsArray()
  @ArrayNotEmpty()
  @IsInt({ each: true })
  zones?: number[];

  @IsOptional()
  @IsBoolean()
  doubleRound?: boolean;

  @IsOptional()
  @IsBoolean()
  shuffle?: boolean;

  @IsOptional()
  @IsBoolean()
  publish?: boolean;
}
