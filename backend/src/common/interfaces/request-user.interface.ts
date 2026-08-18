import { Action, Module, PermissionLevel, Scope } from '@prisma/client';

export interface PermissionGrant {
  module: Module;
  action: Action;
  scope: Scope;
  leagues?: number[];
  clubs?: number[];
  categories?: number[];
}

export interface RequestUserClub {
  id: number;
  name: string;
}

export interface RequestUser {
  id: number;
  username: string;
  firstName: string;
  lastName: string;
  isAdmin: boolean;
  language?: string | null;
  avatarHash?: string | null;
  avatarUpdatedAt?: Date | null;
  avatarMime?: string | null;
  roles: string[];
  permissions: PermissionGrant[];
  moduleLevels: Record<string, PermissionLevel>;
  club?: RequestUserClub | null;
}
