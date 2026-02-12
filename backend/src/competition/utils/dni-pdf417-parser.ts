import { UnprocessableEntityException } from '@nestjs/common';

import { ScanDniResultDto } from '../dto/scan-dni-result.dto';

const DATE_PATTERN = /^(\d{2})\/(\d{2})\/(\d{4})$/;

function normalizeText(value: string): string {
  return value
    .replace(/\s+/g, ' ')
    .trim()
    .toLowerCase()
    .replace(/\b\p{L}/gu, (char) => char.toUpperCase());
}

function normalizeDni(value: string): string {
  return value.replace(/\D/g, '').trim();
}

function normalizeSex(value: string): 'M' | 'F' | 'X' {
  const normalized = value.trim().toUpperCase();
  if (normalized === 'M' || normalized === 'MASCULINO') {
    return 'M';
  }
  if (normalized === 'F' || normalized === 'FEMENINO') {
    return 'F';
  }
  if (normalized === 'X' || normalized === 'NO BINARIO') {
    return 'X';
  }
  throw new UnprocessableEntityException('Sexo inválido en el PDF417.');
}

function normalizeBirthDate(value: string): string {
  const cleaned = value.trim();
  const parsed = DATE_PATTERN.exec(cleaned);
  if (!parsed) {
    throw new UnprocessableEntityException('Fecha de nacimiento inválida en el PDF417.');
  }

  const [, dayString, monthString, yearString] = parsed;
  const day = Number.parseInt(dayString, 10);
  const month = Number.parseInt(monthString, 10);
  const year = Number.parseInt(yearString, 10);
  const date = new Date(Date.UTC(year, month - 1, day));

  if (
    date.getUTCFullYear() !== year ||
    date.getUTCMonth() !== month - 1 ||
    date.getUTCDate() !== day
  ) {
    throw new UnprocessableEntityException('Fecha de nacimiento inválida en el PDF417.');
  }

  return `${yearString}-${monthString}-${dayString}`;
}

function getField(tokens: string[], ...indexes: number[]): string | null {
  for (const index of indexes) {
    if (index < tokens.length) {
      const value = tokens[index]?.trim();
      if (value) {
        return value;
      }
    }
  }
  return null;
}

export function parseDniPdf417Payload(payload: string): ScanDniResultDto {
  const tokens = payload
    .replace(/\u0000/g, '')
    .split('@')
    .map((token) => token.trim());

  if (tokens.length < 7) {
    throw new UnprocessableEntityException('No se pudo interpretar el contenido del PDF417.');
  }

  const lastNameRaw = getField(tokens, 1, 4);
  const firstNameRaw = getField(tokens, 2, 5);
  const sexRaw = getField(tokens, 3, 8);
  const dniRaw = getField(tokens, 4, 1);
  const birthDateRaw = getField(tokens, 6, 7);

  if (!lastNameRaw || !firstNameRaw || !sexRaw || !dniRaw || !birthDateRaw) {
    throw new UnprocessableEntityException('Datos incompletos en el PDF417.');
  }

  const result: ScanDniResultDto = {
    lastName: normalizeText(lastNameRaw),
    firstName: normalizeText(firstNameRaw),
    sex: normalizeSex(sexRaw),
    dni: normalizeDni(dniRaw),
    birthDate: normalizeBirthDate(birthDateRaw),
  };

  if (!/^\d{6,9}$/.test(result.dni)) {
    throw new UnprocessableEntityException('DNI inválido en el PDF417.');
  }

  return result;
}
