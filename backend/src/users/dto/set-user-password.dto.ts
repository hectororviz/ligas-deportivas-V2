import { IsString, MinLength } from 'class-validator';

export class SetUserPasswordDto {
  @IsString()
  @MinLength(8)
  password!: string;
}
