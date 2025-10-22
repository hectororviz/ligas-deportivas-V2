import { PrismaClient, Action, Module, RoleKey, Scope } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

const baseModules: Module[] = [
  Module.LIGAS,
  Module.TORNEOS,
  Module.ZONAS,
  Module.FIXTURE,
  Module.PARTIDOS,
  Module.RESULTADOS,
  Module.TABLAS,
  Module.CLUBES,
  Module.CATEGORIAS,
  Module.JUGADORES,
  Module.PLANTELES,
  Module.CONFIGURACION,
  Module.USUARIOS,
  Module.ROLES,
  Module.PERMISOS,
  Module.REPORTES
];

async function main() {
  const permissionsData = new Map<string, { module: Module; action: Action; scope: Scope }>();

  const ensurePermission = (module: Module, action: Action, scope: Scope) => {
    const key = `${module}-${action}-${scope}`;
    if (!permissionsData.has(key)) {
      permissionsData.set(key, { module, action, scope });
    }
  };

  baseModules.forEach((module) => ensurePermission(module, Action.VIEW, Scope.GLOBAL));
  baseModules.forEach((module) => ensurePermission(module, Action.MANAGE, Scope.GLOBAL));

  [Module.FIXTURE, Module.RESULTADOS, Module.PARTIDOS, Module.TABLAS].forEach((module) => {
    ensurePermission(module, Action.VIEW, Scope.LIGA);
    ensurePermission(module, Action.VIEW, Scope.CLUB);
    ensurePermission(module, Action.VIEW, Scope.CATEGORIA);
  });

  [Module.JUGADORES, Module.PLANTELES].forEach((module) => {
    ensurePermission(module, Action.VIEW, Scope.CATEGORIA);
  });

  const permissions = await Promise.all(
    Array.from(permissionsData.values()).map((permission) =>
      prisma.permission.upsert({
        where: {
          module_action_scope: {
            module: permission.module,
            action: permission.action,
            scope: permission.scope
          }
        },
        update: {},
        create: {
          module: permission.module,
          action: permission.action,
          scope: permission.scope
        }
      })
    )
  );

  const roleEntries = await Promise.all([
    prisma.role.upsert({
      where: { key: RoleKey.ADMIN },
      update: {},
      create: { key: RoleKey.ADMIN, name: 'Administrador' }
    }),
    prisma.role.upsert({
      where: { key: RoleKey.COLLABORATOR },
      update: {},
      create: { key: RoleKey.COLLABORATOR, name: 'Colaborador' }
    }),
    prisma.role.upsert({
      where: { key: RoleKey.DELEGATE },
      update: {},
      create: { key: RoleKey.DELEGATE, name: 'Delegado' }
    }),
    prisma.role.upsert({
      where: { key: RoleKey.COACH },
      update: {},
      create: { key: RoleKey.COACH, name: 'DT' }
    }),
    prisma.role.upsert({
      where: { key: RoleKey.USER },
      update: {},
      create: { key: RoleKey.USER, name: 'Usuario' }
    })
  ]);

  const roleMap = new Map<RoleKey, number>();
  roleEntries.forEach((role) => roleMap.set(role.key, role.id));

  const permissionMap = new Map<string, number>();
  permissions.forEach((permission) => {
    permissionMap.set(`${permission.module}-${permission.action}-${permission.scope}`, permission.id);
  });

  const assignPermissions = async (roleKey: RoleKey, keys: Array<{ module: Module; action: Action; scope: Scope }>) => {
    const roleId = roleMap.get(roleKey);
    if (!roleId) {
      return;
    }
    await prisma.rolePermission.deleteMany({ where: { roleId } });
    await prisma.rolePermission.createMany({
      data: keys.map((key) => ({
        roleId,
        permissionId: permissionMap.get(`${key.module}-${key.action}-${key.scope}`)!
      }))
    });
  };

  await assignPermissions(
    RoleKey.ADMIN,
    Array.from(permissionsData.values()).map((permission) => ({
      module: permission.module,
      action: permission.action,
      scope: permission.scope
    }))
  );

  await assignPermissions(RoleKey.COLLABORATOR, [
    { module: Module.RESULTADOS, action: Action.MANAGE, scope: Scope.GLOBAL },
    { module: Module.PARTIDOS, action: Action.MANAGE, scope: Scope.GLOBAL },
    { module: Module.FIXTURE, action: Action.MANAGE, scope: Scope.GLOBAL },
    { module: Module.PLANTELES, action: Action.MANAGE, scope: Scope.GLOBAL },
    { module: Module.TABLAS, action: Action.VIEW, scope: Scope.GLOBAL },
    { module: Module.CLUBES, action: Action.VIEW, scope: Scope.GLOBAL },
    { module: Module.CATEGORIAS, action: Action.VIEW, scope: Scope.GLOBAL }
  ]);

  await assignPermissions(RoleKey.DELEGATE, [
    { module: Module.RESULTADOS, action: Action.VIEW, scope: Scope.CLUB },
    { module: Module.PARTIDOS, action: Action.VIEW, scope: Scope.CLUB },
    { module: Module.FIXTURE, action: Action.VIEW, scope: Scope.CLUB },
    { module: Module.TABLAS, action: Action.VIEW, scope: Scope.GLOBAL }
  ]);

  await assignPermissions(RoleKey.COACH, [
    { module: Module.JUGADORES, action: Action.VIEW, scope: Scope.CATEGORIA },
    { module: Module.PLANTELES, action: Action.VIEW, scope: Scope.CATEGORIA },
    { module: Module.RESULTADOS, action: Action.VIEW, scope: Scope.CATEGORIA },
    { module: Module.FIXTURE, action: Action.VIEW, scope: Scope.CATEGORIA }
  ]);

  await assignPermissions(RoleKey.USER, [
    { module: Module.RESULTADOS, action: Action.VIEW, scope: Scope.GLOBAL },
    { module: Module.FIXTURE, action: Action.VIEW, scope: Scope.GLOBAL },
    { module: Module.TABLAS, action: Action.VIEW, scope: Scope.GLOBAL }
  ]);

  const adminPassword = await bcrypt.hash('Admin123', 12);
  const admin = await prisma.user.upsert({
    where: { email: 'admin@ligas.local' },
    update: {},
    create: {
      email: 'admin@ligas.local',
      passwordHash: adminPassword,
      firstName: 'Admin',
      lastName: 'General',
      emailVerifiedAt: new Date()
    }
  });

  const existingAdminRole = await prisma.userRole.findFirst({
    where: {
      userId: admin.id,
      roleId: roleMap.get(RoleKey.ADMIN)!,
      leagueId: null,
      clubId: null,
      categoryId: null
    }
  });

  if (!existingAdminRole) {
    await prisma.userRole.create({
      data: {
        userId: admin.id,
        roleId: roleMap.get(RoleKey.ADMIN)!
      }
    });
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
