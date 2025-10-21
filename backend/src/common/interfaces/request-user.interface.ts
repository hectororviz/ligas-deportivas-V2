import { Action, Module, Scope } from '@prisma/client';

export interface PermissionGrant {
  module: Module;
  action: Action;
  scope: Scope;
  leagues?: number[];
  clubs?: number[];
  categories?: number[];
}

export interface RequestUser {
  id: number;
  email: string;
  firstName: string;
  lastName: string;
  roles: string[];
  permissions: PermissionGrant[];
}
