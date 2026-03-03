import { ArrayMinSize, IsArray, IsBoolean, IsIn, IsInt, IsOptional, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

class ManualFixtureMatchDto {
  @IsInt()
  homeClubId: number;

  @IsInt()
  awayClubId: number;
}

class ManualFixtureMatchdayDto {
  @IsInt()
  matchday: number;

  @IsIn(['FIRST', 'SECOND'])
  round: 'FIRST' | 'SECOND';

  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => ManualFixtureMatchDto)
  matches: ManualFixtureMatchDto[];

  @IsOptional()
  @IsInt()
  byeClubId?: number;
}

export class ManualZoneFixtureDto {
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => ManualFixtureMatchdayDto)
  matchdays: ManualFixtureMatchdayDto[];

  @IsOptional()
  @IsBoolean()
  doubleRound?: boolean;
}
