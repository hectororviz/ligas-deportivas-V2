import { IsInt, IsNotEmpty } from 'class-validator';

export class CreateCategoryDto {
  @IsNotEmpty()
  name!: string;

  @IsInt()
  birthYear!: number;
}
