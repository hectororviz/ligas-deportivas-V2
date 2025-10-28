import { ArrayUnique, IsArray, IsInt } from 'class-validator';

export class UpdateClubTeamsDto {
  @IsArray()
  @ArrayUnique()
  @IsInt({ each: true })
  categoryIds!: number[];
}
