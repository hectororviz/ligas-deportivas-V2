import { PrismaClient, Action, Module, RoleKey, Scope } from '@prisma/client';
import * as bcrypt from 'bcrypt';

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

export async function seedBaseData(prisma: PrismaClient) {
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
    if (!keys.length) {
      return;
    }
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

  const adminEmail = 'admin@ligas.local';
  const adminPassword = 'Admin123';
  const existingAdmin = await prisma.user.findUnique({ where: { email: adminEmail } });

  let admin = existingAdmin;
  if (!existingAdmin) {
    admin = await prisma.user.create({
      data: {
        email: adminEmail,
        passwordHash: await bcrypt.hash(adminPassword, 12),
        firstName: 'Admin',
        lastName: 'General',
        emailVerifiedAt: new Date()
      }
    });
  } else if (!existingAdmin.emailVerifiedAt) {
    admin = await prisma.user.update({
      where: { id: existingAdmin.id },
      data: { emailVerifiedAt: new Date() }
    });
  }

  if (!admin) {
    throw new Error('No se pudo asegurar la creación del usuario administrador');
  }

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
