import { Module, PermissionLevel, PrismaClient } from '@prisma/client';
import * as argon2 from 'argon2';

const MATRIX_MODULES: Module[] = [
  Module.LIGAS,
  Module.TORNEOS,
  Module.ZONAS,
  Module.CATEGORIAS,
  Module.JUGADORES,
  Module.CLUBES,
  Module.CONFIGURACION,
];

export async function seedBaseData(prisma: PrismaClient) {
  const adminUsernameRaw = process.env.ADMIN_USERNAME?.trim();
  const adminUsername =
    adminUsernameRaw && adminUsernameRaw.length > 0 ? adminUsernameRaw.toLowerCase() : 'admin';
  const adminPasswordRaw = process.env.ADMIN_PASSWORD?.trim();
  const adminPassword =
    adminPasswordRaw && adminPasswordRaw.length > 0 ? adminPasswordRaw : 'Admin123';

  const existingAdmin = await prisma.user.findUnique({ where: { username: adminUsername } });

  let admin = existingAdmin;
  if (!existingAdmin) {
    admin = await prisma.user.create({
      data: {
        username: adminUsername,
        passwordHash: await argon2.hash(adminPassword, {
          type: argon2.argon2id,
        }),
        firstName: 'Admin',
        lastName: 'General',
        isAdmin: true,
      },
    });
  } else {
    const updateData: { isAdmin?: boolean } = {};
    if (!existingAdmin.isAdmin) {
      updateData.isAdmin = true;
    }
    if (Object.keys(updateData).length > 0) {
      admin = await prisma.user.update({
        where: { id: existingAdmin.id },
        data: updateData,
      });
    }
  }

  if (!admin) {
    throw new Error('No se pudo asegurar la creación del usuario administrador');
  }

  for (const module of MATRIX_MODULES) {
    await prisma.userPermission.upsert({
      where: {
        userId_module: {
          userId: admin.id,
          module,
        },
      },
      update: {
        level: PermissionLevel.TOTAL,
      },
      create: {
        userId: admin.id,
        module,
        level: PermissionLevel.TOTAL,
      },
    });
  }

  try {
    await prisma.siteIdentity.upsert({
      where: { id: 1 },
      update: {},
      create: {
        id: 1,
        title: 'Ligas Deportivas',
      },
    });
  } catch (error) {
    const prismaError = error as { code?: string };
    if (prismaError.code === 'P2022') {
      console.warn(
        'Seed de SiteIdentity omitido: el esquema de la base está desfasado (columna faltante).',
      );
    } else {
      throw error;
    }
  }
}
