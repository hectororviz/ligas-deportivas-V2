import { MatchSheetService } from './match-sheet.service';
import { PlanillaResultService } from './planilla/planilla-result.service';

describe('MatchSheetService - planilla IA colección primera página', () => {
  const prisma = {
    match: {
      findUnique: jest.fn(),
    },
    player: {
      findMany: jest.fn().mockResolvedValue([]),
    },
  };

  const match = {
    id: 130,
    tournamentId: 6,
    zoneId: 5,
    matchday: 13,
    round: 'FIRST',
    date: null,
    tournament: { name: 'Domingos', year: 2026, league: { name: 'Futbol Infantil (D)' } },
    zone: { name: 'Super Liga' },
    homeClub: { id: 1, name: 'Club Social y Deportivo Soler', logoKey: null, logoUrl: null },
    awayClub: { id: 14, name: 'Santa Mónica', logoKey: null, logoUrl: null },
    categories: [],
  };

  const planillaPage = {
    stream: 'BT /F1 14 Tf 72 780 Td (PLANILLA IA READY V1) Tj ET',
    images: [] as { name: string; width: number; height: number; object: string }[],
  };

  const storage = {} as any;
  const planillaService = {
    buildPlanillaPage: jest.fn().mockResolvedValue(planillaPage),
  } as unknown as PlanillaResultService;

  let service: MatchSheetService;

  beforeEach(() => {
    jest.clearAllMocks();
    prisma.match.findUnique.mockResolvedValue(match);
    service = new MatchSheetService(prisma as any, storage, planillaService);
  });

  it('genera un PDF y antepone la planilla como primera página', async () => {
    const result = await service.generate(130);
    expect(Buffer.isBuffer(result.buffer)).toBe(true);
    expect(result.contentType).toBe('application/pdf');
    expect(result.fileExtension).toBe('pdf');

    const text = result.buffer.toString('utf8');
    expect(text.startsWith('%PDF')).toBe(true);

    // El PDF debe tener 2 páginas (planilla + listado sin categorías).
    expect(planillaService.buildPlanillaPage).toHaveBeenCalledWith(130);
    const countMatch = text.match(/\/Count (\d+)/);
    expect(countMatch).toBeTruthy();
    expect(Number(countMatch![1])).toBe(2);
  });

  it('la planilla aparece antes que las páginas del listado', async () => {
    const result = await service.generate(130);
    const text = result.buffer.toString('utf8');
    const planillaIndex = text.indexOf('PLANILLA IA READY V1');
    const listadoIndex = text.indexOf('Sin categorias');
    expect(planillaIndex).toBeGreaterThan(-1);
    expect(listadoIndex).toBeGreaterThan(-1);
    expect(planillaIndex).toBeLessThan(listadoIndex);
  });
});
