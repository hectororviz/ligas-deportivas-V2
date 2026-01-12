import { CanActivate, Injectable, ServiceUnavailableException } from '@nestjs/common';
import { DatabaseSchemaHealthService } from './database-schema-health.service';

@Injectable()
export class DatabaseReadyGuard implements CanActivate {
  constructor(private readonly schemaHealth: DatabaseSchemaHealthService) {}

  canActivate(): boolean {
    if (!this.schemaHealth.isReady()) {
      throw new ServiceUnavailableException('DB not migrated');
    }
    return true;
  }
}
