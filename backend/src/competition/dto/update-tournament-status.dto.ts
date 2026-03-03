import { IsEnum } from 'class-validator';
import { TournamentStatus } from '@prisma/client';

export class UpdateTournamentStatusDto {
  @IsEnum(TournamentStatus)
  status!: TournamentStatus;
}
