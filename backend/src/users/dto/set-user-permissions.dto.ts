import { Type } from 'class-transformer';
import { ArrayMaxSize, IsArray, ValidateNested } from 'class-validator';
import { UserPermissionInput } from './create-user.dto';

export class SetUserPermissionsDto {
  @IsArray()
  @ArrayMaxSize(16)
  @ValidateNested({ each: true })
  @Type(() => UserPermissionInput)
  permissions!: UserPermissionInput[];
}
