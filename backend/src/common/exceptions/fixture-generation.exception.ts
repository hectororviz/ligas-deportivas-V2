import { InternalServerErrorException } from '@nestjs/common';

export class FixtureGenerationException extends InternalServerErrorException {
  constructor(message = 'No se pudo generar el fixture. Revise las migraciones y los datos asociados.') {
    super(message);
  }
}
