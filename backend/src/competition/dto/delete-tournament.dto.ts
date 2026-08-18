import { IsNotEmpty, IsString } from 'class-validator';

export class DeleteTournamentDto {
  @IsString()
  @IsNotEmpty()
  username!: string;

  @IsString()
  @IsNotEmpty()
  password!: string;
}
