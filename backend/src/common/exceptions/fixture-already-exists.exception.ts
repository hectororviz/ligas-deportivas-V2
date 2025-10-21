import { BadRequestException } from '@nestjs/common';

export class FixtureAlreadyExistsException extends BadRequestException {
  constructor() {
    super('El torneo ya cuenta con un fixture generado.');
  }
}
