import { Controller, Get, ServiceUnavailableException } from '@nestjs/common';
import { DatabaseSchemaHealthService } from '../prisma/database-schema-health.service';

@Controller('health')
export class HealthController {
  constructor(private readonly schemaHealth: DatabaseSchemaHealthService) {}

  @Get('db')
  getDatabaseHealth(): { status: string } {
    if (!this.schemaHealth.isReady()) {
      throw new ServiceUnavailableException('DB not migrated');
    }
    return { status: 'ok' };
  }
}
