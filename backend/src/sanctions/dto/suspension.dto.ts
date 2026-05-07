import { IsEnum, IsInt, IsOptional, IsString, Min, IsArray } from 'class-validator';
import { SuspensionStatus } from '@prisma/client';

export class CreateSuspensionDto {
  @IsInt()
  playerId: number;

  @IsInt()
  @Min(1)
  originalMatches: number;

  @IsOptional()
  @IsString()
  reason?: string;

  @IsOptional()
  @IsArray()
  @IsInt({ each: true })
  cardIds?: number[];
}

export class UpdateSuspensionDto {
  @IsOptional()
  @IsEnum(SuspensionStatus)
  status?: SuspensionStatus;

  @IsOptional()
  @IsInt()
  @Min(0)
  remainingMatches?: number;

  @IsOptional()
  @IsString()
  reason?: string;
}

export class SuspensionResponseDto {
  id: number;
  playerId: number;
  tournamentId: number;
  originalMatches: number;
  remainingMatches: number;
  status: SuspensionStatus;
  reason: string | null;
  createdById: number;
  createdAt: Date;
  updatedAt: Date;
  player?: {
    id: number;
    firstName: string;
    lastName: string;
    dni: string;
  };
  originCards?: {
    id: number;
    cardType: string;
    matchCategoryId: number;
  }[];
  servedMatches?: {
    id: number;
    matchCategoryId: number;
    servedAt: Date;
  }[];
}
