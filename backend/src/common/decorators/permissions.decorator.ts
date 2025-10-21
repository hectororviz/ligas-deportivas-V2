import { SetMetadata } from '@nestjs/common';
import { Action, Module, Scope } from '@prisma/client';

export const PERMISSIONS_KEY = 'permissions';

export interface PermissionRequirement {
  module: Module;
  action: Action;
  scope?: Scope;
}

export const Permissions = (...permissions: PermissionRequirement[]) =>
  SetMetadata(PERMISSIONS_KEY, permissions);
