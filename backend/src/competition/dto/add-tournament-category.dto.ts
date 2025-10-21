import { IsInt } from 'class-validator';

export class AddTournamentCategoryDto {
  @IsInt()
  categoryId!: number;
}
