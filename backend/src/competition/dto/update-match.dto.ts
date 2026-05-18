import { IsBoolean, IsDateString, IsEnum, IsOptional } from 'class-validator';
import { MatchStatus } from '@prisma/client';
import { Type } from 'class-transformer';

export class UpdateMatchDto {
  @IsOptional()
  @IsEnum(MatchStatus)
  status?: MatchStatus;

  @IsOptional()
  @IsDateString()
  date?: string;

  @IsOptional()
  @IsBoolean()
  @Type(() => Boolean)
  suspended?: boolean;
}
