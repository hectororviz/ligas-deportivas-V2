import { buildPlanillaRegions } from './planilla.definitions';

describe('Planilla de resultados - geometría', () => {
  it('define una columna por cada categoría participante (columnas dinámicas)', () => {
    const regions = buildPlanillaRegions(7);
    expect(regions.columns).toHaveLength(7);
  });

  it('sin categorías no dibuja columnas', () => {
    const regions = buildPlanillaRegions(0);
    expect(regions.columns).toHaveLength(0);
  });

  it('cada columna tiene geometría de categoría, local y visitante independientes', () => {
    const regions = buildPlanillaRegions(8);
    expect(regions.columns).toHaveLength(8);
    let cells = 0;
    for (const col of regions.columns) {
      expect(col.category).toBeDefined();
      expect(col.local).toBeDefined();
      expect(col.visitor).toBeDefined();
      expect(col.category.width).toBeGreaterThan(0);
      expect(col.local.width).toBeGreaterThan(0);
      expect(col.visitor.width).toBeGreaterThan(0);
      cells += 3;
    }
    expect(cells).toBe(24);
  });

  it('el encabezado define un título y posiciones para los escudos', () => {
    const regions = buildPlanillaRegions(5);
    expect(regions.title).toBeDefined();
    expect(regions.title.width).toBeGreaterThan(0);
    expect(regions.escudos.local).toBeDefined();
    expect(regions.escudos.visitor).toBeDefined();
    expect(regions.escudos.local.width).toBeGreaterThan(0);
    expect(regions.escudos.visitor.width).toBeGreaterThan(0);
  });

  it('define las etiquetas LOCAL y VISITANTE para las filas de resultados', () => {
    const regions = buildPlanillaRegions(5);
    expect(regions.rowLabels.local).toBeDefined();
    expect(regions.rowLabels.visitor).toBeDefined();
  });

  it('no define marcadores ni posición de QR (diseño para personas, no para IA)', () => {
    const regions = buildPlanillaRegions(5) as unknown as Record<string, unknown>;
    expect(regions.arucos).toBeUndefined();
    expect(regions.qr).toBeUndefined();
  });

  it('el pie define una línea de firma y etiquetas debajo', () => {
    const regions = buildPlanillaRegions(5);
    expect(regions.signLine.local.line).toBeDefined();
    expect(regions.signLine.local.label).toBeDefined();
    expect(regions.signLine.visitor.line).toBeDefined();
    expect(regions.signLine.visitor.label).toBeDefined();
    expect(regions.signLine.referee.line).toBeDefined();
    expect(regions.signLine.referee.label).toBeDefined();
  });
});
