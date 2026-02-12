import { Transform, Type } from 'class-transformer';
import { IsInt, IsOptional, ValidateIf } from 'class-validator';

export class AssignPlayerClubDto {
  @Type(() => Number)
  @IsInt()
  playerId!: number;

  @Transform(({ value }) => (value === null || value === undefined || value === '' ? null : Number(value)))
  @ValidateIf((_, value) => value !== null && value !== undefined)
  @IsInt()
  clubId!: number | null;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  categoryId?: number;
}
