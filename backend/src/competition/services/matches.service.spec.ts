import { BadRequestException, NotFoundException } from '@nestjs/common';
import { ParseUUIDPipe } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { MatchesService } from './matches.service';

describe('ParseUUIDPipe para /matches/uuid/:uuid', () => {
  const pipe = new ParseUUIDPipe({ version: '4' });
  const metadata = { type: 'param' as const, metatype: String, data: 'uuid' };

  it('acepta un UUID válido', async () => {
    const value = await pipe.transform('aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee', metadata);
    expect(value).toBe('aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee');
  });

  it('rechaza un valor que no es UUID', async () => {
    await expect(pipe.transform('no-es-uuid', metadata)).rejects.toBeInstanceOf(BadRequestException);
  });

  it('rechaza un UUID con formato inválido', async () => {
    await expect(pipe.transform('zzzz-aaaa-bbbb-1111-2222', metadata)).rejects.toBeInstanceOf(BadRequestException);
  });
});

describe('MatchesService uuid', () => {
  const uuidPattern =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

  let prismaMock: any;
  let service: MatchesService;

  const baseMatch = {
    id: 130,
    uuid: 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
    matchday: 1,
    round: 'FIRST',
    status: 'PROGRAMMED',
    date: null,
    tournamentId: 5,
    zoneId: 9,
    homeClubId: 1,
    awayClubId: 2,
    homeClub: { id: 1, name: 'Soler', shortName: 'Soler', logoUrl: null, primaryColor: null, secondaryColor: null },
    awayClub: { id: 2, name: 'Santa Monica', shortName: 'Santa Monica', logoUrl: null, primaryColor: null, secondaryColor: null },
    zone: { id: 9, name: 'Super Liga' },
    categories: [],
  };

  const tournament = {
    id: 5,
    pointsWin: 3,
    pointsDraw: 1,
    pointsLoss: 0,
    controlsPlayers: false,
  };

  beforeEach(() => {
    prismaMock = {
      match: { findUnique: jest.fn(), findUniqueOrThrow: jest.fn() },
      tournament: { findUniqueOrThrow: jest.fn() },
    };
    service = new MatchesService(prismaMock, {} as any, {} as any);
  });

  it('getMatchByUuid busca por el campo uuid', async () => {
    prismaMock.match.findUnique.mockResolvedValue(baseMatch);
    prismaMock.tournament.findUniqueOrThrow.mockResolvedValue(tournament);

    const result = await service.getMatchByUuid(baseMatch.uuid);

    expect(prismaMock.match.findUnique).toHaveBeenCalledWith(
      expect.objectContaining({ where: { uuid: baseMatch.uuid } }),
    );
    expect(result.uuid).toBe(baseMatch.uuid);
    expect(result.id).toBe(baseMatch.id);
  });

  it('getMatchByUuid lanza 404 si el partido no existe', async () => {
    prismaMock.match.findUnique.mockResolvedValue(null);

    await expect(service.getMatchByUuid('aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('getMatchDetail por id numérico sigue devolviendo el partido e incluye uuid', async () => {
    prismaMock.match.findUnique.mockResolvedValue(baseMatch);
    prismaMock.tournament.findUniqueOrThrow.mockResolvedValue(tournament);

    const result = await service.getMatchDetail(130);

    expect(prismaMock.match.findUnique).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 130 } }),
    );
    expect(result.id).toBe(130);
    expect(result.uuid).toMatch(uuidPattern);
  });

  it('getMatchDetail lanza 404 si no existe (por id)', async () => {
    prismaMock.match.findUnique.mockResolvedValue(null);

    await expect(service.getMatchDetail(999)).rejects.toBeInstanceOf(NotFoundException);
  });
});
