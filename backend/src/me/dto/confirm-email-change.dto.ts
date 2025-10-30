import { IsString, Length } from 'class-validator';

export class ConfirmEmailChangeDto {
  @IsString()
  @Length(16, 128)
  token!: string;
}
