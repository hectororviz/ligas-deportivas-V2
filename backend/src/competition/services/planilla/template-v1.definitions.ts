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

/** Una columna de la tabla horizontal de resultados (una por categoría). */
export interface ResultTableColumn {
  index: number;
  category: Rect; // Fila 1: nombre de la categoría
  local: Rect; // Fila 2: resultado local
  visitor: Rect; // Fila 3: resultado visitante
}

/** Primera columna de la tabla: escudo + nombre corto de cada club. */
export interface ClubColumn {
  local: Rect; // fila local (arriba)
  visitor: Rect; // fila visitante (abajo)
}

/** Pie: línea de firma, áreas de firma y aclaración de cada rol, y campo de fecha. */
export interface SignArea {
  line: Rect; // línea continua de firma
  aclaracion: Rect; // rótulo "FIRMA Y ACLARACION"
  entries: {
    local: Rect; // Representante Local
    visitor: Rect; // Representante Visitante
    referee: Rect; // Arbitro
  };
  date: Rect; // campo para la fecha
}

export interface PlanillaRegions {
  /** Zona total de la planilla (media hoja superior). */
  sheet: Rect;
  /** Título "Local VS Visitante" (izquierda, debajo de los ArUco). */
  title: Rect;
  /** Detalle del partido en una sola línea (Liga - año - zona - Fecha N). */
  detail: Rect;
  /** Primera columna de la tabla con escudos y nombres cortos de los clubes. */
  clubColumn: ClubColumn;
  /** 10 columnas de la tabla horizontal (categoría / local / visitante). */
  columns: ResultTableColumn[];
  /** Etiqueta "RESULTADOS" sobre la tabla. */
  tableLabel: Rect;
  qr: Rect;
  arucos: {
    topLeft: Rect;
    topRight: Rect;
    bottomRight: Rect;
    bottomLeft: Rect;
  };
  /** Línea de firma, firma y aclaración por rol, y campo de fecha. */
  signLine: SignArea;
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

  // El QR ocupa la franja derecha superior; el título y los datos van alineados
  // a la izquierda para no superponerse con él.
  const qrX = A4_WIDTH - marginX - qrSize; // 475.28
  const leftWidth = qrX - marginX - 12; // contenido izquierdo que no pisa el QR

  const arucoTopY = 10;
  const arucoBottomY = PLANILLA_HEIGHT - arucoSize - 8;

  // QR arriba a la derecha, claramente separado del marcador ArUco superior derecho.
  const qr: Rect = {
    x: qrX,
    y: arucoTopY + arucoSize + 14,
    width: qrSize,
    height: qrSize,
  };

  // El título se coloca por debajo de los marcadores ArUco superiores (que son
  // los "cuadros guía de centrado"), para no quedar detrás de ellos.
  const title: Rect = { x: marginX, y: 66, width: leftWidth, height: 30 };

  // Detalle del partido en una sola línea, con mayor separación del título.
  const detail: Rect = { x: marginX, y: title.y + title.height + 16, width: leftWidth, height: 14 };

  const tableLabel: Rect = { x: marginX, y: detail.y + detail.height + 6, width: leftWidth, height: 14 };

  // La tabla horizontal comienza por debajo del QR para no superponerse.
  const tableTop = qr.y + qr.height + 4;

  const catRowH = 24;
  const scoreRowH = 40;

  // Primera columna: escudo + nombre corto de cada club (local arriba, visitante abajo).
  const clubGap = 12;
  const clubColW = 128;
  const clubColumn: ClubColumn = {
    local: { x: marginX, y: tableTop + catRowH, width: clubColW, height: scoreRowH },
    visitor: {
      x: marginX,
      y: tableTop + catRowH + scoreRowH,
      width: clubColW,
      height: scoreRowH,
    },
  };

  // Columnas de categorías (10), después de la primera columna de clubes.
  const colGap = 4;
  const columnsStartX = marginX + clubColW + clubGap;
  const columnsWidth = A4_WIDTH - marginX - columnsStartX;
  const colW = (columnsWidth - colGap * (CATEGORY_ROWS - 1)) / CATEGORY_ROWS;

  const columns: ResultTableColumn[] = [];
  for (let i = 0; i < CATEGORY_ROWS; i += 1) {
    const x = columnsStartX + i * (colW + colGap);
    columns.push({
      index: i,
      category: { x, y: tableTop, width: colW, height: catRowH },
      local: { x, y: tableTop + catRowH, width: colW, height: scoreRowH },
      visitor: { x, y: tableTop + catRowH + scoreRowH, width: colW, height: scoreRowH },
    });
  }

  const tableEndY = tableTop + catRowH + scoreRowH * 2;

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

  // Línea continua de firma, firma y aclaración por rol, y campo de fecha.
  const lineY = tableEndY + 16;
  const aclaracion: Rect = { x: marginX, y: lineY - 16, width: A4_WIDTH - marginX * 2, height: 12 };
  const entriesTop = lineY + 8;
  const entriesGap = 12;
  const entriesW = (A4_WIDTH - marginX * 2 - entriesGap * 2) / 3;
  const entryH = 38;
  const signArea: SignArea = {
    line: { x: marginX, y: lineY, width: A4_WIDTH - marginX * 2, height: 1 },
    aclaracion,
    entries: {
      local: { x: marginX, y: entriesTop, width: entriesW, height: entryH },
      visitor: { x: marginX + (entriesW + entriesGap), y: entriesTop, width: entriesW, height: entryH },
      referee: {
        x: marginX + (entriesW + entriesGap) * 2,
        y: entriesTop,
        width: entriesW,
        height: entryH,
      },
    },
    date: { x: marginX, y: entriesTop + entryH + 8, width: 200, height: 16 },
  };

  return {
    sheet,
    title,
    detail,
    clubColumn,
    columns,
    tableLabel,
    qr,
    arucos,
    signLine: signArea,
    cutLineY: PLANILLA_HEIGHT,
  };
}

