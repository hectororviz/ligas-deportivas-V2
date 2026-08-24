/**
 * Planilla de resultados - hoja 0 del Listado.
 *
 * Única fuente de verdad para la geometría de la planilla.
 * Sistema de coordenadas:
 *   - A4 vertical, medidas en PUNTOS PDF (1 pt = 1/72 in).
 *   - A4 = 595.28 x 841.89 pt.
 *   - La planilla ocupa la MITAD SUPERIOR del A4: 210mm x 148.5mm
 *     -> 595.28 x 420.94 pt.
 *   - Origen (0,0) = esquina superior izquierda del A4 (coordenadas PDF
 *     "hacia abajo", al igual que el resto del circuito de planillas).
 *
 * Es una hoja pensada para las personas: encabezado con escudos, tabla
 * horizontal con SOLO las columnas de las categorías participantes y panel
 * de firmas. No contiene QR ni marcadores de orientación.
 */

/** A4 portrait en puntos */
export const A4_WIDTH = 595.28;
export const A4_HEIGHT = 841.89;

/** Altura de la media hoja superior (aproximadamente A5 horizontal). */
export const PLANILLA_HEIGHT = 420.94;

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

/** Un bloque de firma: línea de fondo y etiqueta debajo. */
export interface SignatureBlock {
  line: Rect; // línea de fondo (firma)
  label: Rect; // etiqueta "Rep. X - Firma y aclaracion"
}

/** Panel de firmas: Rep. Local y Visitante (arriba) y Arbitro (abajo, centrado). */
export interface SignArea {
  local: SignatureBlock;
  visitor: SignatureBlock;
  referee: SignatureBlock;
}

export interface PlanillaRegions {
  /** Zona total de la planilla (media hoja superior). */
  sheet: Rect;
  /** Título "Local VS Visitante" centrado, con los escudos a los lados. */
  title: Rect;
  /** Posición de los escudos de los clubes en el encabezado. */
  escudos: {
    local: Rect;
    visitor: Rect;
  };
  /** Detalle del partido (Liga - torneo año - zona - Fecha N - dd/mm/aaaa). */
  detail: Rect;
  /** Etiqueta "RESULTADOS" sobre la tabla. */
  tableLabel: Rect;
  /** Etiquetas "LOCAL" y "VISITANTE" del costado izquierdo de la tabla. */
  rowLabels: {
    local: Rect;
    visitor: Rect;
  };
  /** Columnas de la tabla (una por categoría participante). */
  columns: ResultTableColumn[];
  /** Línea de firma, firma y aclaración por rol. */
  signLine: SignArea;
  /** Posición vertical (y) de la línea de corte. */
  cutLineY: number;
}

/**
 * Construye el layout geométrico de la planilla.
 * `categoryCount` define cuántas columnas de resultados se dibujan (solo las
 * categorías participantes; ya no son fijas en 10).
 */
export function buildPlanillaRegions(categoryCount: number): PlanillaRegions {
  const sheet: Rect = { x: 0, y: 0, width: A4_WIDTH, height: PLANILLA_HEIGHT };

  const marginX = 16;

  // Encabezado: título centrado con un escudo a cada lado.
  const escudoSize = 34;
  const escudoGap = 8;
  const titleTop = 16;
  const escudos = {
    local: { x: marginX, y: titleTop, width: escudoSize, height: escudoSize },
    visitor: {
      x: A4_WIDTH - marginX - escudoSize,
      y: titleTop,
      width: escudoSize,
      height: escudoSize,
    },
  };

  const title: Rect = {
    x: marginX + escudoSize + escudoGap,
    y: titleTop + 4,
    width: A4_WIDTH - marginX * 2 - (escudoSize + escudoGap) * 2,
    height: 26,
  };

  // Detalle del partido en una sola línea, centrado y con mayor separación.
  const detail: Rect = {
    x: marginX,
    y: titleTop + escudoSize + 12,
    width: A4_WIDTH - marginX * 2,
    height: 14,
  };

  const tableLabel: Rect = {
    x: marginX,
    y: detail.y + detail.height + 6,
    width: A4_WIDTH - marginX * 2,
    height: 14,
  };

  const tableTop = tableLabel.y + tableLabel.height + 2;

  const catRowH = 24;
  const scoreRowH = 44;

  // Etiquetas del costado izquierdo (LOCAL / VISITANTE), ya que los escudos
  // y nombres se movieron al encabezado y quedan sin columna de clubes.
  const rowLabelWidth = 46;
  const rowLabels = {
    local: { x: marginX, y: tableTop + catRowH, width: rowLabelWidth, height: scoreRowH },
    visitor: {
      x: marginX,
      y: tableTop + catRowH + scoreRowH,
      width: rowLabelWidth,
      height: scoreRowH,
    },
  };

  const count = Math.max(0, categoryCount);
  const columnsStartX = marginX + rowLabelWidth;
  const columnsWidth = A4_WIDTH - marginX - columnsStartX;
  const colGap = 4;
  const colW = count > 0 ? (columnsWidth - colGap * (count - 1)) / count : 0;

  const columns: ResultTableColumn[] = [];
  for (let i = 0; i < count; i += 1) {
    const x = columnsStartX + i * (colW + colGap);
    columns.push({
      index: i,
      category: { x, y: tableTop, width: colW, height: catRowH },
      local: { x, y: tableTop + catRowH, width: colW, height: scoreRowH },
      visitor: { x, y: tableTop + catRowH + scoreRowH, width: colW, height: scoreRowH },
    });
  }

  const tableEndY = tableTop + catRowH + scoreRowH * 2;

  // Panel de firmas con márgenes de 2 cm.
  const margin2cm = 56.7; // 2 cm en puntos PDF
  const rowWidth = A4_WIDTH - marginX * 2;

  // Primera línea de fondo: 2 cm por debajo de la tabla.
  const topLineY = tableEndY + margin2cm;

  // Fila 1: Representante Local (izquierda) y Representante Visitante (derecha).
  const halfGap = 24;
  const halfW = (rowWidth - halfGap) / 2;
  const lineLen = halfW * 0.72;
  const labelTop1 = topLineY + 6;
  const localBlock: SignatureBlock = {
    line: { x: marginX + (halfW - lineLen) / 2, y: topLineY, width: lineLen, height: 1 },
    label: { x: marginX, y: labelTop1, width: halfW, height: 16 },
  };
  const visitorBlock: SignatureBlock = {
    line: {
      x: marginX + halfW + halfGap + (halfW - lineLen) / 2,
      y: topLineY,
      width: lineLen,
      height: 1,
    },
    label: { x: marginX + halfW + halfGap, y: labelTop1, width: halfW, height: 16 },
  };

  // Última línea de fondo (Arbitro, centrada): 2 cm antes del fondo de la planilla.
  const refereeLineY = PLANILLA_HEIGHT - margin2cm;
  const refLen = 220;
  const refX = marginX + (rowWidth - refLen) / 2;
  const refereeBlock: SignatureBlock = {
    line: { x: refX, y: refereeLineY, width: refLen, height: 1 },
    label: { x: marginX, y: refereeLineY + 6, width: rowWidth, height: 16 },
  };

  const signArea: SignArea = {
    local: localBlock,
    visitor: visitorBlock,
    referee: refereeBlock,
  };

  return {
    sheet,
    title,
    escudos,
    detail,
    tableLabel,
    rowLabels,
    columns,
    signLine: signArea,
    cutLineY: PLANILLA_HEIGHT,
  };
}
