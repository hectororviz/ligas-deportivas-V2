import { IsBoolean, IsInt, IsOptional, Min } from 'class-validator';

export class UpdateDisciplinaryRulesDto {
  @IsOptional()
  @IsInt()
  @Min(1)
  yellowCardLimit?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  yellowLimitSuspensionMatches?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  directRedSuspensionMatches?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  doubleYellowSuspensionMatches?: number;

  @IsOptional()
  @IsBoolean()
  resetYellowsOnPhaseChange?: boolean;
}

export class DisciplinaryRulesResponseDto {
  id: number;
  tournamentId: number;
  yellowCardLimit: number;
  yellowLimitSuspensionMatches: number;
  directRedSuspensionMatches: number;
  doubleYellowSuspensionMatches: number;
  resetYellowsOnPhaseChange: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export class DefaultDisciplinaryRules {
  static readonly yellowCardLimit = 3;
  static readonly yellowLimitSuspensionMatches = 1;
  static readonly directRedSuspensionMatches = 2;
  static readonly doubleYellowSuspensionMatches = 1;
  static readonly resetYellowsOnPhaseChange = false;
}
