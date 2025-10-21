import { ArrayUnique, IsArray, IsInt } from 'class-validator';

export class SetRolePermissionsDto {
  @IsArray()
  @ArrayUnique()
  @IsInt({ each: true })
  permissionIds!: number[];
}
