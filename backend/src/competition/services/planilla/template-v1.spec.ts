import {
  buildPlanillaRegions,
  CATEGORY_ROWS,
  ARUCO_DICT_4X4_50_BITS,
  TEMPLATE_PAYLOAD_KEY,
  TEMPLATE_PAYLOAD_VALUE,
  ArucoId,
} from './template-v1.definitions';
import { buildPlanillaQrPayload, parsePlanillaQrPayload, generatePlanillaQrPng } from './qr';

describe('TEMPLATE 1 - geometría', () => {
  it('define exactamente 10 posiciones de categorías', () => {
    const regions = buildPlanillaRegions();
    expect(regions.columns).toHaveLength(10);
    expect(CATEGORY_ROWS).toBe(10);
  });

  it('define 20 casilleros de resultado (10 local + 10 visitante)', () => {
    const regions = buildPlanillaRegions();
    const locals = regions.columns.filter((col) => col.local.width > 0 && col.local.height > 0);
    const visitors = regions.columns.filter(
      (col) => col.visitor.width > 0 && col.visitor.height > 0,
    );
    expect(locals).toHaveLength(10);
    expect(visitors).toHaveLength(10);
  });

  it('define 4 marcadores ArUco (esquinas superiores e inferiores)', () => {
    const regions = buildPlanillaRegions();
    const arucos = regions.arucos;
    expect(arucos.topLeft).toBeDefined();
    expect(arucos.topRight).toBeDefined();
    expect(arucos.bottomLeft).toBeDefined();
    expect(arucos.bottomRight).toBeDefined();
  });

  it('cada columna tiene geometría de categoría, local y visitante independientes', () => {
    const regions = buildPlanillaRegions();
    for (const col of regions.columns) {
      expect(col.category).toBeDefined();
      expect(col.local).toBeDefined();
      expect(col.visitor).toBeDefined();
      expect(col.category.width).toBeGreaterThan(0);
      expect(col.local.width).toBeGreaterThan(0);
      expect(col.visitor.width).toBeGreaterThan(0);
    }
  });

  it('el pie define bloques de Representante Local, Visitante y Referí', () => {
    const regions = buildPlanillaRegions();
    expect(regions.footer.local).toBeDefined();
    expect(regions.footer.visitor).toBeDefined();
    expect(regions.footer.referee).toBeDefined();
  });

  it('usa el diccionario ArUco 4x4_50 con IDs fijos 0..3', () => {
    for (const id of [
      ArucoId.TOP_LEFT,
      ArucoId.TOP_RIGHT,
      ArucoId.BOTTOM_RIGHT,
      ArucoId.BOTTOM_LEFT,
    ]) {
      const bits = ARUCO_DICT_4X4_50_BITS[id];
      expect(bits).toBeDefined();
      expect(bits).toHaveLength(4);
      for (const row of bits) {
        expect(row).toHaveLength(4);
      }
    }
  });
});

describe('TEMPLATE 1 - payload del QR', () => {
  const data = {
    uuid: 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
    matchId: 130,
    tournamentId: 4,
    zoneId: 5,
    homeClubId: 1,
    awayClubId: 8,
  };

  it('incluye TEMPLATE=1 y todos los identificadores', () => {
    const payload = buildPlanillaQrPayload(data);
    const parsed = parsePlanillaQrPayload(payload);
    expect(parsed[TEMPLATE_PAYLOAD_KEY]).toBe(String(TEMPLATE_PAYLOAD_VALUE));
    expect(parsed['TEMPLATE']).toBe('1');
    expect(parsed['UUID']).toBe(data.uuid);
    expect(parsed['ID_PARTIDO']).toBe('130');
    expect(parsed['ID_TORNEO']).toBe('4');
    expect(parsed['ID_ZONA']).toBe('5');
    expect(parsed['ID_LOCAL']).toBe('1');
    expect(parsed['ID_VISITANTE']).toBe('8');
  });

  it('el payload se construye desde backend y no desde query params', () => {
    const payload = buildPlanillaQrPayload(data);
    expect(payload).toContain(`UUID=${data.uuid}`);
    // Los valores vienen de los IDs reales del partido, no de la URL.
    expect(payload).not.toContain('zona=');
    expect(payload).not.toContain('club=');
    expect(payload).not.toContain('fecha=');
  });

  it('genera un PNG de QR real (ECC alto)', async () => {
    const payload = buildPlanillaQrPayload(data);
    const png = await generatePlanillaQrPng(payload);
    expect(Buffer.isBuffer(png)).toBe(true);
    expect(png.length).toBeGreaterThan(100);
    // cabecera PNG
    expect(png[0]).toBe(0x89);
    expect(png[1]).toBe(0x50);
  });
});
