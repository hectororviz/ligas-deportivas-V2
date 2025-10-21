import { IsInt } from 'class-validator';

export class AssignClubZoneDto {
  @IsInt()
  clubId!: number;
}
