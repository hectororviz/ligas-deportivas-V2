import { IsDateString, IsIn, Matches, MaxLength, MinLength } from 'class-validator';

export class ScanDniResultDto {
  @MinLength(1)
  @MaxLength(120)
  lastName!: string;

  @MinLength(1)
  @MaxLength(120)
  firstName!: string;

  @IsIn(['M', 'F', 'X'])
  sex!: 'M' | 'F' | 'X';

  @Matches(/^\d{6,9}$/)
  dni!: string;

  @IsDateString()
  birthDate!: string;
}
