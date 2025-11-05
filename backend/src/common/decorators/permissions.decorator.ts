import { SetMetadata } from '@nestjs/common';
import { Action, Module, Scope } from '@prisma/client';

export const PERMISSIONS_KEY = 'permissions';

export interface PermissionRequirement {
  module: Module;
  action: Action;
  scope?: Scope;
}

export type PermissionCondition = PermissionRequirement | PermissionRequirement[];

export const Permissions = (...permissions: PermissionCondition[]) =>
  SetMetadata(PERMISSIONS_KEY, permissions);
