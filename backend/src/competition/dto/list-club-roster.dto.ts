import { Transform } from 'class-transformer';
import { IsInt, IsOptional, Min } from 'class-validator';

export class ListClubRosterDto {
  @Transform(({ value }) => {
    if (value === undefined || value === null || value === '') {
      return undefined;
    }
    return Number(value);
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  tournamentId?: number;

  @Transform(({ value }) => {
    if (value === undefined || value === null || value === '') {
      return undefined;
    }
    return Number(value);
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  categoryId?: number;
}
