/**
 * TEMPLATE 1 - "Planilla IA Ready V1"
 *
 * Única fuente de verdad para la geometría y configuración de la planilla.
 * Sistema de coordenadas:
 *   - A4 vertical, medidas en PUNTOS PDF (1 pt = 1/72 in).
 *   - A4 = 595.28 x 841.89 pt.
 *   - La planilla ocupa la MITAD SUPERIOR del A4: 210mm x 148.5mm
 *     -> 595.28 x 420.94 pt.
 *   - Origen (0,0) = esquina superior izquierda del A4 (coordenadas PDF
 *     "hacia abajo", al igual que el resto del circuito de planillas).
 *
 * Estas coordenadas se mantienen centralizadas aquí para permitir,
 * en el futuro, convertir las posiciones relativas a píxeles al procesar
 * una fotografía de la planilla.
 */

export const TEMPLATE_VERSION = 1;

/** A4 portrait en puntos */
export const A4_WIDTH = 595.28;
export const A4_HEIGHT = 841.89;

/** Altura de la media hoja superior (aproximadamente A5 horizontal). */
export const PLANILLA_HEIGHT = 420.94;

/** Número fijo de filas de categorías (siempre 10). */
export const CATEGORY_ROWS = 10;

/** Nombre de identificación humana de la versión. */
export const TEMPLATE_LABEL = 'PLANILLA IA READY V1';
export const TEMPLATE_SHORT_LABEL = 'PLANILLA V1';

/** Payload obligatorio dentro del QR. */
export const TEMPLATE_PAYLOAD_KEY = 'TEMPLATE';
export const TEMPLATE_PAYLOAD_VALUE = 1;

/** ArUco - identificadores fijos para TEMPLATE 1. */
export enum ArucoId {
  TOP_LEFT = 0,
  TOP_RIGHT = 1,
  BOTTOM_RIGHT = 2,
  BOTTOM_LEFT = 3,
}

/**
 * Matrices 4x4 interiores de los marcadores ArUco DICT_4X4_50 (1 = blanco, 0 = negro),
 * extraídas directamente de OpenCV (opencv.aruco.DICT_4X4_50).
 * El marcador impreso agrega un borde negro de 1 módulo alrededor.
 */
export const ARUCO_DICT_4X4_50_BITS: Record<number, number[][]> = {
  0: [
    [1, 0, 1, 1],
    [0, 1, 0, 1],
    [0, 0, 1, 1],
    [0, 0, 1, 0],
  ],
  1: [
    [0, 0, 0, 0],
    [1, 1, 1, 1],
    [1, 0, 0, 1],
    [1, 0, 1, 0],
  ],
  2: [
    [0, 0, 1, 1],
    [0, 0, 1, 1],
    [0, 0, 1, 0],
    [1, 1, 0, 1],
  ],
  3: [
    [1, 0, 0, 1],
    [1, 0, 0, 1],
    [0, 1, 0, 0],
    [0, 1, 1, 0],
  ],
};

export interface Rect {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface CategoryResultRow {
  index: number;
  category: Rect;
  local: Rect;
  visitor: Rect;
}

export interface PlanillaRegions {
  /** Zona total de la planilla (media hoja superior). */
  sheet: Rect;
  title: Rect;
  matchInfo: Rect;
  headers: {
    category: Rect;
    local: Rect;
    visitor: Rect;
  };
  rows: CategoryResultRow[];
  qr: Rect;
  arucos: {
    topLeft: Rect;
    topRight: Rect;
    bottomRight: Rect;
    bottomLeft: Rect;
  };
  administrative: {
    arbitrator: Rect;
    arbitratorSign: Rect;
    localRepresentative: Rect;
    localSign: Rect;
    visitorRepresentative: Rect;
    visitorSign: Rect;
  };
  instruction: Rect;
  /** Posición vertical (y) de la línea de corte. */
  cutLineY: number;
}

/**
 * Construye el layout geométrico de TEMPLATE 1.
 * Todas las medidas son relativas al A4 (coordenadas hacia abajo desde arriba).
 */
export function buildPlanillaRegions(): PlanillaRegions {
  const sheet: Rect = { x: 0, y: 0, width: A4_WIDTH, height: PLANILLA_HEIGHT };

  const marginX = 24;

  const qrSize = 96; // ~34mm
  const arucoSize = 48;

  // El borde/QR ocupa la franja derecha superior; el contenido y la tabla se
  // mantienen a la izquierda de la columna del QR para no superponerse.
  const qrX = A4_WIDTH - marginX - qrSize; // 475.28

  const leftWidth = qrX - marginX - 12; // contenido que no pisa el QR (~375)

  const title: Rect = { x: marginX, y: 12, width: leftWidth, height: 30 };

  const matchInfo: Rect = {
    x: marginX,
    y: title.y + title.height + 8,
    width: leftWidth,
    height: 62,
  };

  const rowsTop = matchInfo.y + matchInfo.height + 10;
  const headerHeight = 13;
  const rowHeight = 18;

  const categoryWidth = 196;
  const boxWidth = 88;
  const localX = marginX + categoryWidth + 18;
  const visitorX = localX + boxWidth + 16;

  const headers: PlanillaRegions['headers'] = {
    category: { x: marginX, y: rowsTop, width: categoryWidth, height: headerHeight },
    local: { x: localX, y: rowsTop, width: boxWidth, height: headerHeight },
    visitor: { x: visitorX, y: rowsTop, width: boxWidth, height: headerHeight },
  };

  const tableEndY = rowsTop + headerHeight + CATEGORY_ROWS * rowHeight;

  const rows: CategoryResultRow[] = [];
  for (let i = 0; i < CATEGORY_ROWS; i += 1) {
    const y = rowsTop + headerHeight + i * rowHeight;
    rows.push({
      index: i,
      category: { x: marginX, y, width: categoryWidth, height: rowHeight },
      local: { x: localX, y, width: boxWidth, height: rowHeight },
      visitor: { x: visitorX, y, width: boxWidth, height: rowHeight },
    });
  }

  const arucoTopY = 10;
  const arucoBottomY = PLANILLA_HEIGHT - arucoSize - 8;

  // QR arriba a la derecha, claramente separado del marcador ArUco superior derecho.
  const qr: Rect = {
    x: qrX,
    y: arucoTopY + arucoSize + 14,
    width: qrSize,
    height: qrSize,
  };

  const arucos = {
    topLeft: { x: 8, y: arucoTopY, width: arucoSize, height: arucoSize },
    topRight: { x: A4_WIDTH - arucoSize - 8, y: arucoTopY, width: arucoSize, height: arucoSize },
    bottomRight: {
      x: A4_WIDTH - arucoSize - 8,
      y: arucoBottomY,
      width: arucoSize,
      height: arucoSize,
    },
    bottomLeft: { x: 8, y: arucoBottomY, width: arucoSize, height: arucoSize },
  };

  const administrativeTop = tableEndY + 12;

  const adminHalfWidth = 180;
  const adminSignWidth = 60;
  const adminGap = 14;

  const arbitrator = { x: marginX, y: administrativeTop, width: adminHalfWidth, height: 24 };
  const arbitratorSign = {
    x: marginX + adminHalfWidth + adminGap,
    y: administrativeTop,
    width: adminSignWidth,
    height: 24,
  };

  const secondRowY = administrativeTop + 24 + 8;
  const localRepresentative = { x: marginX, y: secondRowY, width: adminHalfWidth, height: 24 };
  const localSign = {
    x: marginX + adminHalfWidth + adminGap,
    y: secondRowY,
    width: adminSignWidth,
    height: 24,
  };
  const visitorRepresentative = {
    x: marginX + adminHalfWidth + adminSignWidth + adminGap * 2 + 20,
    y: secondRowY,
    width: adminHalfWidth,
    height: 24,
  };
  const visitorSign = {
    x: A4_WIDTH - marginX - adminSignWidth,
    y: secondRowY,
    width: adminSignWidth,
    height: 24,
  };

  const administrativeEndY = secondRowY + 24;

  const instruction: Rect = {
    x: marginX + 40,
    y: administrativeEndY + 8,
    width: A4_WIDTH - marginX * 2 - 80,
    height: 24,
  };

  return {
    sheet,
    title,
    matchInfo,
    headers,
    rows,
    qr,
    arucos,
    administrative: {
      arbitrator,
      arbitratorSign,
      localRepresentative,
      localSign,
      visitorRepresentative,
      visitorSign,
    },
    instruction,
    cutLineY: PLANILLA_HEIGHT,
  };
}

