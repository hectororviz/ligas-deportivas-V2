import { Type } from 'class-transformer';
import { IsArray, IsBoolean, IsInt, IsOptional, ValidateNested } from 'class-validator';

class PlayerGoalDto {
  @IsInt()
  playerId!: number;

  @IsInt()
  clubId!: number;

  @IsInt()
  goals!: number;
}

class OtherGoalDto {
  @IsInt()
  clubId!: number;

  @IsInt()
  goals!: number;
}

export class RecordMatchResultDto {
  @IsInt()
  homeScore!: number;

  @IsInt()
  awayScore!: number;

  @IsOptional()
  @IsBoolean()
  confirm?: boolean = true;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PlayerGoalDto)
  playerGoals: PlayerGoalDto[] = [];

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OtherGoalDto)
  otherGoals: OtherGoalDto[] = [];
}

export { PlayerGoalDto, OtherGoalDto };
