import { IsEnum, IsInt, IsOptional } from 'class-validator';
import { RoleKey } from '@prisma/client';

export class AssignRoleDto {
  @IsEnum(RoleKey)
  roleKey!: RoleKey;

  @IsOptional()
  @IsInt()
  leagueId?: number;

  @IsOptional()
  @IsInt()
  clubId?: number;

  @IsOptional()
  @IsInt()
  categoryId?: number;
}
