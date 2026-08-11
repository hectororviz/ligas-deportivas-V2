import { Type } from 'class-transformer';
import { IsArray, ValidateNested } from 'class-validator';

import { CreateTournamentDto } from './create-tournament.dto';
import { AddTournamentCategoryDto } from './add-tournament-category.dto';

export class UpdateTournamentCategoryDto extends AddTournamentCategoryDto {}

export class UpdateTournamentDto extends CreateTournamentDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => UpdateTournamentCategoryDto)
  categories!: UpdateTournamentCategoryDto[];
}
