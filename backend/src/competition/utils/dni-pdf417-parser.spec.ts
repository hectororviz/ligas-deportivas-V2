import { UnprocessableEntityException } from '@nestjs/common';

import { parseDniPdf417Payload } from './dni-pdf417-parser';

describe('parseDniPdf417Payload', () => {
  it('parsea un payload estándar del DNI', () => {
    const result = parseDniPdf417Payload(
      '00123456789@PEREZ@JUAN CARLOS@M@30111222@A@01/02/2001@123456',
    );

    expect(result).toEqual({
      lastName: 'Perez',
      firstName: 'Juan Carlos',
      sex: 'M',
      dni: '30111222',
      birthDate: '2001-02-01',
    });
  });

  it('soporta variantes con espacios y sexo extendido', () => {
    const result = parseDniPdf417Payload(
      'ABCD@  GOMEZ   @ MARIA ELENA @ Femenino @  33444555 @A@15/11/1997@',
    );

    expect(result).toEqual({
      lastName: 'Gomez',
      firstName: 'Maria Elena',
      sex: 'F',
      dni: '33444555',
      birthDate: '1997-11-15',
    });
  });

  it('falla con payload incompleto', () => {
    expect(() => parseDniPdf417Payload('A@B@C')).toThrow(UnprocessableEntityException);
  });

  it('falla con fecha inválida', () => {
    expect(() =>
      parseDniPdf417Payload('ABCD@PEREZ@ANA@F@33444555@A@31/02/1997@123'),
    ).toThrow(UnprocessableEntityException);
  });
});
