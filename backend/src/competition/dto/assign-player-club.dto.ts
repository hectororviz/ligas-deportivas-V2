import { Type } from 'class-transformer';
import { IsInt } from 'class-validator';

export class AssignPlayerClubDto {
  @Type(() => Number)
  @IsInt()
  playerId!: number;

  @Type(() => Number)
  @IsInt()
  clubId!: number;

  @Type(() => Number)
  @IsInt()
  categoryId!: number;
}
