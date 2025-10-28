import { Transform } from 'class-transformer';
import { IsIn, IsInt, IsOptional, Min } from 'class-validator';

export class ListClubsDto {
  @IsOptional()
  search?: string;

  @IsOptional()
  @IsIn(['active', 'inactive'])
  status?: 'active' | 'inactive';

  @IsOptional()
  @Transform(({ value }) => {
    const parsed = Number.parseInt(value, 10);
    if (Number.isNaN(parsed)) {
      return 1;
    }
    return parsed;
  })
  @IsInt()
  @Min(1)
  page: number = 1;

  @IsOptional()
  @Transform(({ value }) => {
    const parsed = Number.parseInt(value, 10);
    if (parsed === 50) {
      return 50;
    }
    return 25;
  })
  @IsInt()
  @IsIn([25, 50])
  pageSize: number = 25;
}
