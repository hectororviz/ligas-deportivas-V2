import { Type } from 'class-transformer';
import { IsArray, IsBoolean, IsInt, IsString, MaxLength, MinLength, ValidateNested } from 'class-validator';

class ClubTeamInputDto {
  @IsInt()
  tournamentCategoryId!: number;

  @IsString()
  @MinLength(2)
  @MaxLength(120)
  publicName!: string;

  @IsBoolean()
  active!: boolean;
}

export class UpdateClubTeamsDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ClubTeamInputDto)
  teams!: ClubTeamInputDto[];
}

export { ClubTeamInputDto };
