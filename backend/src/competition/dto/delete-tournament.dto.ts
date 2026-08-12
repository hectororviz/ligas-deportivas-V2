import { IsEmail, IsNotEmpty, IsString } from 'class-validator';

export class DeleteTournamentDto {
  @IsEmail()
  email!: string;

  @IsString()
  @IsNotEmpty()
  password!: string;
}
