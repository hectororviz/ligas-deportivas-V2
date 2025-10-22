import { Injectable, Logger, OnApplicationBootstrap } from '@nestjs/common';
import { seedBaseData } from './base-seed';
import { PrismaService } from './prisma.service';

@Injectable()
export class DatabaseInitializerService implements OnApplicationBootstrap {
  private readonly logger = new Logger(DatabaseInitializerService.name);

  constructor(private readonly prisma: PrismaService) {}

  async onApplicationBootstrap(): Promise<void> {
    try {
      await seedBaseData(this.prisma);
      this.logger.log('Seed de datos base aplicado correctamente');
    } catch (error) {
      this.logger.error('Error al aplicar el seed inicial', error instanceof Error ? error.stack : undefined);
      throw error;
    }
  }
}
