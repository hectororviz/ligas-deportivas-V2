const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function main() {
  try {
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
      console.log('Tabla _prisma_migrations inexistente, se asumirá base vacía.');
      return;
    }

    const failedMigrations = await prisma.$queryRaw`
      SELECT migration_name
      FROM _prisma_migrations
      WHERE finished_at IS NULL
        AND rolled_back_at IS NULL
      ORDER BY migration_name ASC
    `;

    if (Array.isArray(failedMigrations) && failedMigrations.length > 0) {
      const names = failedMigrations.map((row) => row.migration_name).join(', ');
      console.error('Migraciones fallidas detectadas en _prisma_migrations:');
      console.error(`- ${names}`);
      console.error('');
      console.error('Resuelve el estado con los siguientes comandos:');
      failedMigrations.forEach((row) => {
        console.error(
          `docker compose run --rm --entrypoint sh migrate -lc 'npx prisma migrate resolve --rolled-back ${row.migration_name}'`,
        );
      });
      console.error('');
      console.error('Luego vuelve a ejecutar deploy.sh.');
      process.exitCode = 2;
    }
  } catch (error) {
    console.error('No se pudo validar el estado de migraciones.', error);
    process.exitCode = 1;
  } finally {
    await prisma.$disconnect();
  }
}

main();
