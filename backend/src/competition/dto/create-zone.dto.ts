import { IsNotEmpty } from 'class-validator';

export class CreateZoneDto {
  @IsNotEmpty()
  name!: string;
}
