import { IsDateString, IsOptional } from 'class-validator';

export class UpdateMatchdayDto {
  @IsOptional()
  @IsDateString()
  date?: string | null;
}
