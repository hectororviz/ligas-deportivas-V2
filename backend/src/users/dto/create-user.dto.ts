import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  MinLength,
  ValidateNested
} from 'class-validator';
import { Module, PermissionLevel } from '@prisma/client';

export class UserPermissionInput {
  @IsEnum(Module)
  module!: Module;

  @IsEnum(PermissionLevel)
  level!: PermissionLevel;
}

export class CreateUserDto {
  @IsString()
  @Matches(/^[a-zA-Z0-9._-]{3,32}$/, {
    message: 'El nombre de usuario debe tener entre 3 y 32 caracteres (letras, números, punto, guion).'
  })
  username!: string;

  @IsString()
  @MinLength(8)
  password!: string;

  @IsString()
  firstName!: string;

  @IsString()
  lastName!: string;

  @IsOptional()
  @Transform(({ value }) => {
    if (value === null || value === undefined || value === '') {
      return null;
    }
    const parsed = Number.parseInt(value, 10);
    return Number.isNaN(parsed) ? value : parsed;
  })
  @IsInt()
  clubId?: number | null;

  @IsArray()
  @ArrayMaxSize(16)
  @ValidateNested({ each: true })
  @Type(() => UserPermissionInput)
  permissions!: UserPermissionInput[];
}
