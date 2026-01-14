import { Transform } from 'class-transformer';
import { IsInt, Min } from 'class-validator';

export class ListAssignedPlayersDto {
  @Transform(({ value }) => (value != null ? Number(value) : 1))
  @IsInt()
  @Min(1)
  page = 1;

  @Transform(({ value }) => (value != null ? Number(value) : 20))
  @IsInt()
  @Min(1)
  pageSize = 20;
}
