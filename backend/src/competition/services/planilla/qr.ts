import QRCode = require('qrcode');
import { TEMPLATE_PAYLOAD_KEY, TEMPLATE_PAYLOAD_VALUE } from './template-v1.definitions';

/**
 * Identificadores que componen el payload del QR de la planilla.
 * Todos se obtienen desde el backend a partir del Partido real.
 */
export interface PlanillaQrData {
  uuid: string;
  matchId: number;
  tournamentId: number;
  zoneId: number;
  homeClubId: number;
  awayClubId: number;
}

/**
 * Construye el payload EXACTO del QR. El TEMPLATE y los identificadores se
 * obtienen desde el backend (nunca de query params del frontend).
 */
export function buildPlanillaQrPayload(data: PlanillaQrData): string {
  return [
    `${TEMPLATE_PAYLOAD_KEY}=${TEMPLATE_PAYLOAD_VALUE}`,
    `UUID=${data.uuid}`,
    `ID_PARTIDO=${data.matchId}`,
    `ID_TORNEO=${data.tournamentId}`,
    `ID_ZONA=${data.zoneId}`,
    `ID_LOCAL=${data.homeClubId}`,
    `ID_VISITANTE=${data.awayClubId}`,
  ].join('\n');
}

export async function generatePlanillaQrPng(payload: string): Promise<Buffer> {
  return QRCode.toBuffer(payload, {
    errorCorrectionLevel: 'H',
    type: 'png',
    margin: 1,
    width: 600,
  });
}

/**
 * Parsea un payload de QR devuelto por buildPlanillaQrPayload.
 * Útil para tests y para la futura etapa de lectura.
 */
export function parsePlanillaQrPayload(payload: string): Record<string, string> {
  const result: Record<string, string> = {};
  for (const line of payload.split('\n')) {
    const separator = line.indexOf('=');
    if (separator <= 0) {
      continue;
    }
    const key = line.slice(0, separator).trim();
    const value = line.slice(separator + 1).trim();
    if (key) {
      result[key] = value;
    }
  }
  return result;
}
