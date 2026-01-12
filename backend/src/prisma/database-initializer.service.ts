import { Injectable, Logger, OnApplicationBootstrap } from '@nestjs/common';
import { seedBaseData } from './base-seed';
import { PrismaService } from './prisma.service';
import { DatabaseSchemaHealthService } from './database-schema-health.service';

@Injectable()
export class DatabaseInitializerService implements OnApplicationBootstrap {
  private readonly logger = new Logger(DatabaseInitializerService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly schemaHealth: DatabaseSchemaHealthService,
  ) {}

  async onApplicationBootstrap(): Promise<void> {
    if (!this.schemaHealth.isReady()) {
      this.logger.warn(
        'Seed inicial omitido: el esquema de la base no está listo antes del arranque.',
      );
      return;
    }
    try {
      await seedBaseData(this.prisma);
      this.logger.log('Seed de datos base aplicado correctamente');
    } catch (error) {
      this.logger.error('Error al aplicar el seed inicial', error instanceof Error ? error.stack : undefined);
      throw error;
    }
  }
}
