import { IsNotEmpty, Matches, MinLength } from 'class-validator';

export class ResetPasswordDto {
  @IsNotEmpty()
  token!: string;

  @MinLength(8)
  @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$/)
  password!: string;
}
