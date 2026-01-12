const fs = require('fs');
const path = require('path');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

function describeDatabaseUrl(databaseUrl) {
  if (!databaseUrl) {
    return null;
  }

  try {
    const url = new URL(databaseUrl);
    const schema = url.searchParams.get('schema') || 'public';
    const database = url.pathname.replace('/', '') || '(unknown)';
    const port = url.port || '5432';
    return {
      host: url.hostname,
      port,
      database,
      schema,
      maskedUrl: `${url.protocol}//${url.username ? `${url.username}:***@` : ''}${url.host}${url.pathname}${url.search}`,
    };
  } catch (error) {
    return {
      host: '(invalid)',
      port: '(invalid)',
      database: '(invalid)',
      schema: '(invalid)',
      maskedUrl: '(invalid DATABASE_URL)',
    };
  }
}

function readMigrationNames() {
  const migrationsPath = path.join(process.cwd(), 'prisma', 'migrations');
  if (!fs.existsSync(migrationsPath)) {
    return { names: [], error: `No se encontró el directorio de migraciones en ${migrationsPath}.` };
  }

  const entries = fs.readdirSync(migrationsPath, { withFileTypes: true });
  const names = entries
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .sort();
  return { names };
}

async function checkSchema() {
  const errors = [];
  const migrationsTableResult = await prisma.$queryRaw`
    SELECT EXISTS (
      SELECT 1
      FROM information_schema.tables
      WHERE table_schema = 'public'
        AND table_name = '_prisma_migrations'
    ) AS "exists";
  `;
  const migrationsTableExists = Array.isArray(migrationsTableResult)
    ? migrationsTableResult[0]?.exists
    : false;
  if (!migrationsTableExists) {
    errors.push('La tabla _prisma_migrations no existe. Ejecuta el job de migraciones.');
  }

  let appliedMigrations = [];
  if (migrationsTableExists) {
    appliedMigrations = await prisma.$queryRaw`
      SELECT migration_name, finished_at, rolled_back_at
      FROM _prisma_migrations
    `;
    const failed = appliedMigrations.filter(
      (row) => row.finished_at === null && row.rolled_back_at === null,
    );
    if (failed.length > 0) {
      errors.push(`Hay ${failed.length} migraciones fallidas pendientes en _prisma_migrations.`);
    }
  }

  const { names: migrationNames, error: migrationDirError } = readMigrationNames();
  if (migrationDirError) {
    errors.push(migrationDirError);
  }

  if (migrationNames.length === 0) {
    errors.push('No se encontraron migraciones locales en prisma/migrations.');
  }

  if (migrationNames.length > 0) {
    if (appliedMigrations.length === 0) {
      errors.push('No hay migraciones aplicadas en _prisma_migrations.');
    } else {
      const applied = new Set(
        appliedMigrations
          .filter((row) => row.finished_at !== null && row.rolled_back_at === null)
          .map((row) => row.migration_name),
      );
      const pending = migrationNames.filter((name) => !applied.has(name));
      if (pending.length > 0) {
        errors.push(
          `Migraciones pendientes: ${pending.join(', ')}. Ejecuta "prisma migrate deploy".`,
        );
      }
    }
  }

  const coreTables = [
    { name: 'tournament', schema: 'public', tableName: 'tournament' },
    { name: 'SiteIdentity', schema: 'public', tableName: 'SiteIdentity' },
  ];
  for (const table of coreTables) {
    const result = await prisma.$queryRaw`
      SELECT EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = ${table.schema}
          AND table_name = ${table.tableName}
      ) AS "exists";
    `;
    const exists = Array.isArray(result) ? result[0]?.exists : false;
    if (!exists) {
      errors.push(`La tabla ${table.name} no existe en la base.`);
    }
  }

  const columnResult = await prisma.$queryRaw`
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'SiteIdentity'
      AND column_name = 'faviconHash'
    LIMIT 1
  `;
  if (!Array.isArray(columnResult) || columnResult.length === 0) {
    errors.push('La columna SiteIdentity.faviconHash no existe en la base.');
  }

  return errors;
}

async function main() {
  const args = new Set(process.argv.slice(2));
  const info = describeDatabaseUrl(process.env.DATABASE_URL);
  if (!info) {
    console.error('DATABASE_URL no está definido.');
    process.exit(1);
  }

  console.log(
    `Database target: host=${info.host} port=${info.port} db=${info.database} schema=${info.schema}`,
  );

  if (args.has('--log-only')) {
    return;
  }

  try {
    const errors = await checkSchema();
    if (errors.length > 0) {
      console.error('El esquema de la base no está listo:');
      for (const error of errors) {
        console.error(`- ${error}`);
      }
      process.exitCode = 2;
      return;
    }
  } catch (error) {
    console.error('No se pudo validar el esquema de la base.', error);
    process.exitCode = 1;
  } finally {
    await prisma.$disconnect();
  }
}

main();
