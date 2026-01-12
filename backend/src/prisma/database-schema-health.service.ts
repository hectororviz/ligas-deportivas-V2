import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { PrismaService } from './prisma.service';
import * as fs from 'fs';
import * as path from 'path';

type MigrationRow = {
  migration_name: string;
  finished_at: Date | null;
  rolled_back_at: Date | null;
};

@Injectable()
export class DatabaseSchemaHealthService implements OnModuleInit {
  private readonly logger = new Logger(DatabaseSchemaHealthService.name);
  private dbReady = true;

  constructor(private readonly prisma: PrismaService) {}

  async onModuleInit(): Promise<void> {
    this.logDatabaseTarget();
    const errors = await this.checkSchema();
    if (errors.length === 0) {
      return;
    }

    this.dbReady = false;
    this.logger.error('El esquema de la base de datos no está listo:');
    errors.forEach((error) => this.logger.error(`- ${error}`));

    if (process.env.ALLOW_UNMIGRATED_DB === '1') {
      this.logger.warn(
        'ALLOW_UNMIGRATED_DB=1 activo: la aplicación continuará sin migraciones completas.',
      );
      return;
    }

    this.logger.error('Abortando inicio. Ejecuta el job de migraciones antes del backend.');
    process.exit(1);
  }

  isReady(): boolean {
    return this.dbReady;
  }

  private logDatabaseTarget(): void {
    const databaseUrl = process.env.DATABASE_URL;
    if (!databaseUrl) {
      this.logger.warn('DATABASE_URL no está definido.');
      return;
    }

    try {
      const url = new URL(databaseUrl);
      const schema = url.searchParams.get('schema') ?? 'public';
      const database = url.pathname.replace('/', '') || '(unknown)';
      const port = url.port || '5432';
      this.logger.log(
        `Database target: host=${url.hostname} port=${port} db=${database} schema=${schema}`,
      );
    } catch (error) {
      this.logger.warn('DATABASE_URL no se pudo parsear.');
    }
  }

  private getMigrationNames(): { names: string[]; error?: string } {
    const migrationsPath = path.join(process.cwd(), 'prisma', 'migrations');
    if (!fs.existsSync(migrationsPath)) {
      return {
        names: [],
        error: `No se encontró el directorio de migraciones en ${migrationsPath}.`,
      };
    }

    const entries = fs.readdirSync(migrationsPath, { withFileTypes: true });
    const names = entries
      .filter((entry) => entry.isDirectory())
      .map((entry) => entry.name)
      .sort();

    return { names };
  }

  private async checkSchema(): Promise<string[]> {
    const errors: string[] = [];

    const migrationsTable = await this.prisma.$queryRaw<{ name: string | null }[]>`
      SELECT to_regclass('public._prisma_migrations') as name;
    `;
    if (!migrationsTable[0]?.name) {
      errors.push('La tabla _prisma_migrations no existe.');
      return errors;
    }

    const appliedMigrations = await this.prisma.$queryRaw<MigrationRow[]>`
      SELECT migration_name, finished_at, rolled_back_at
      FROM _prisma_migrations
    `;
    const failed = appliedMigrations.filter(
      (row) => row.finished_at === null && row.rolled_back_at === null,
    );
    if (failed.length > 0) {
      errors.push(`Hay ${failed.length} migraciones fallidas en _prisma_migrations.`);
    }

    const { names: migrationNames, error: migrationDirError } = this.getMigrationNames();
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
          errors.push(`Migraciones pendientes: ${pending.join(', ')}.`);
        }
      }
    }

    const coreTables = [
      { name: 'tournament', ref: 'public.tournament' },
      { name: 'SiteIdentity', ref: 'public."SiteIdentity"' },
    ];
    for (const table of coreTables) {
      const tableResult = await this.prisma.$queryRaw<{ name: string | null }[]>`
        SELECT to_regclass(${table.ref}) as name;
      `;
      if (!tableResult[0]?.name) {
        errors.push(`La tabla ${table.name} no existe.`);
      }
    }

    const columnResult = await this.prisma.$queryRaw<{ exists: number }[]>`
      SELECT 1 as exists
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'SiteIdentity'
        AND column_name = 'faviconHash'
      LIMIT 1
    `;
    if (columnResult.length === 0) {
      errors.push('La columna SiteIdentity.faviconHash no existe.');
    }

    return errors;
  }
}
