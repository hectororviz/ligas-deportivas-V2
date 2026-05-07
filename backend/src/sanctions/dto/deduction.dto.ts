import { IsInt, IsOptional, IsString, Min, MaxLength } from 'class-validator';

export class CreateDeductionDto {
  @IsInt()
  clubId: number;

  @IsOptional()
  @IsInt()
  tournamentCategoryId?: number;

  @IsInt()
  @Min(1)
  points: number;

  @IsString()
  @MaxLength(500)
  reason: string;
}

export class DeductionResponseDto {
  id: number;
  clubId: number;
  tournamentId: number;
  tournamentCategoryId: number | null;
  points: number;
  reason: string;
  createdById: number;
  createdAt: Date;
  updatedAt: Date;
  club?: {
    id: number;
    name: string;
  };
  tournamentCategory?: {
    id: number;
    category: {
      name: string;
    };
  } | null;
}
