import { IsBoolean, IsInt, IsOptional, Matches } from 'class-validator';

export class AddTournamentCategoryDto {
  @IsInt()
  categoryId!: number;

  @IsBoolean()
  enabled!: boolean;

  @IsOptional()
  @Matches(/^(?:[01]\d|2[0-3]):[0-5]\d$/)
  gameTime?: string;
}
