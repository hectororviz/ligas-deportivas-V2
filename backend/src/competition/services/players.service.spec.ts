import {
  BadRequestException,
  InternalServerErrorException,
  NotFoundException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Gender } from '@prisma/client';

import { PrismaService } from '../../prisma/prisma.service';
import { PlayersService } from './players.service';

describe('PlayersService decoder wrapper', () => {
  const prismaMock = {} as PrismaService;

  const buildService = (
    decoderCommand?: unknown,
    scanDebug?: unknown,
    scanDebugKeepTmp?: unknown,
    scanDeadlineMs?: unknown,
    scanDecoderTimeoutMs?: unknown,
  ) => {
    const configMock = {
      get: jest.fn((key: string) => {
        if (key === 'DNI_SCAN_DECODER_COMMAND') {
          return decoderCommand;
        }
        if (key === 'SCAN_DEBUG') {
          return scanDebug;
        }
        if (key === 'SCAN_DEBUG_KEEP_TMP') {
          return scanDebugKeepTmp;
        }
        if (key === 'SCAN_DEADLINE_MS') {
          return scanDeadlineMs;
        }
        if (key === 'SCAN_DECODER_TIMEOUT_MS') {
          return scanDecoderTimeoutMs;
        }
        return undefined;
      }),
    } as unknown as ConfigService;

    return new PlayersService(prismaMock, configMock);
  };

  const mockPreprocess = (service: PlayersService) => {
    jest.spyOn(service as never, 'preprocessDecodeImage' as never).mockResolvedValue({
      roiBuffer: Buffer.from('roi'),
      resizedBuffer: Buffer.from('full'),
      resizedWidth: 1200,
      resizedHeight: 900,
      roiWidth: 1200,
      roiHeight: 315,
      roiRawByteLength: 100,
      roiPngByteLength: 80,
      extractParams: { left: 60, top: 495, width: 1080, height: 360 },
    } as never);
  };

  it('throws 500 when decoder binary is unavailable', async () => {
    const service = buildService('/definitely/missing-decoder --format PDF417');
    mockPreprocess(service);
    jest
      .spyOn(service as never, 'buildDecodeStrategies' as never)
      .mockResolvedValue([{ name: 'raw', rotation: 0, buffer: Buffer.from('img') }] as never);

    await expect(
      (service as any).decodePdf417Payload(Buffer.from('input'), Date.now(), 'req-1'),
    ).rejects.toBeInstanceOf(InternalServerErrorException);
  });

  it('returns 422 when decoder runs but cannot decode payload', async () => {
    const service = buildService();
    mockPreprocess(service);
    jest
      .spyOn(service as never, 'buildDecodeStrategies' as never)
      .mockResolvedValue([{ name: 'raw', rotation: 0, buffer: Buffer.from('img') }] as never);
    jest.spyOn(service as never, 'runDecoder' as never).mockResolvedValue({
      exitCode: 0,
      stdout: '',
      stderr: '',
    } as never);

    await expect(
      (service as any).decodePdf417Payload(Buffer.from('input'), Date.now(), 'req-1'),
    ).rejects.toBeInstanceOf(UnprocessableEntityException);
  });

  it('uses default decoder command when env var is missing', async () => {
    const service = buildService();
    mockPreprocess(service);
    jest
      .spyOn(service as never, 'buildDecodeStrategies' as never)
      .mockResolvedValue([{ name: 'raw', rotation: 0, buffer: Buffer.from('img') }] as never);

    const runDecoderSpy = jest.spyOn(service as never, 'runDecoder' as never).mockResolvedValue({
      exitCode: 0,
      stdout: '@payload@',
      stderr: '',
    } as never);

    await expect(
      (service as any).decodePdf417Payload(Buffer.from('input'), Date.now(), 'req-1'),
    ).resolves.toMatchObject({ payloadRaw: '@payload@' });
    expect(runDecoderSpy).toHaveBeenCalledWith(
      {
        binary: '/usr/local/bin/dni-pdf417-decoder',
        args: [],
        inputMode: 'stdin',
        inputFileToken: undefined,
      },
      expect.any(Buffer),
      1200,
      'req-1',
    );
  });

  it('uses file input mode when command contains file placeholder token', async () => {
    const service = buildService('/usr/local/bin/dni-pdf417-decoder {file}');
    mockPreprocess(service);
    jest
      .spyOn(service as never, 'buildDecodeStrategies' as never)
      .mockResolvedValue([{ name: 'raw', rotation: 0, buffer: Buffer.from('img') }] as never);

    const runDecoderSpy = jest.spyOn(service as never, 'runDecoder' as never).mockResolvedValue({
      exitCode: 0,
      stdout: '@payload@',
      stderr: '',
    } as never);

    await expect(
      (service as any).decodePdf417Payload(Buffer.from('input'), Date.now(), 'req-1'),
    ).resolves.toMatchObject({ payloadRaw: '@payload@' });
    expect(runDecoderSpy).toHaveBeenCalledWith(
      {
        binary: '/usr/local/bin/dni-pdf417-decoder',
        args: ['{file}'],
        inputMode: 'file',
        inputFileToken: '{file}',
      },
      expect.any(Buffer),
      1200,
      'req-1',
    );
  });

  it('returns timeout scan when deadline is exceeded', async () => {
    const service = buildService(undefined, undefined, undefined, 1);
    mockPreprocess(service);

    await expect(
      (service as any).decodePdf417Payload(
        Buffer.from('input'),
        Date.now() - 50,
        'req-timeout',
        false,
        1,
      ),
    ).rejects.toThrow('timeout scan');
  });


  it('accepts boolean/number/string values in SCAN_DEBUG without crashing', () => {
    const serviceWithBool = buildService(undefined, true);
    const serviceWithNumber = buildService(undefined, 1);
    const serviceWithString = buildService(undefined, 'yes');

    expect((serviceWithBool as any).isScanDebugEnabled()).toBe(true);
    expect((serviceWithNumber as any).isScanDebugEnabled()).toBe(true);
    expect((serviceWithString as any).isScanDebugEnabled()).toBe(true);
  });

  it('accepts boolean/number/string values in SCAN_DEBUG_KEEP_TMP without crashing', () => {
    const serviceWithBool = buildService(undefined, undefined, false);
    const serviceWithNumber = buildService(undefined, undefined, 1);
    const serviceWithString = buildService(undefined, undefined, 'off');

    expect((serviceWithBool as any).isScanDebugKeepTmpEnabled()).toBe(false);
    expect((serviceWithNumber as any).isScanDebugKeepTmpEnabled()).toBe(true);
    expect((serviceWithString as any).isScanDebugKeepTmpEnabled()).toBe(false);
  });

  it('requires SCAN_DEBUG=1 for diagnostic endpoint', async () => {
    const service = buildService(undefined, '0');

    await expect(
      service.scanDniDiagnostic({
        buffer: Buffer.from('img'),
        mimetype: 'image/png',
        size: 3,
      } as Express.Multer.File),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('returns raw payload/output details in diagnostic mode', async () => {
    const service = buildService(undefined, '1');
    mockPreprocess(service);
    jest
      .spyOn(service as never, 'buildDecodeStrategies' as never)
      .mockResolvedValue([{ name: 'raw', rotation: 0, buffer: Buffer.from('img') }] as never);
    jest.spyOn(service as never, 'runDecoder' as never).mockResolvedValue({
      exitCode: 0,
      stdout: 'Text: @123456@DOE@JOHN@M@',
      stderr: '',
    } as never);

    await expect(
      service.scanDniDiagnostic({
        buffer: Buffer.from('img'),
        mimetype: 'image/png',
        size: 3,
      } as Express.Multer.File),
    ).resolves.toMatchObject({
      payloadRaw: '@123456@DOE@JOHN@M@',
      stdoutRaw: 'Text: @123456@DOE@JOHN@M@',
      payloadLength: 19,
      tokensCount: 6,
    });
  });
});

describe('PlayersService.searchByDniAndCategory', () => {
  const configMock = {
    get: jest.fn(),
  } as unknown as ConfigService;

  it('filters players by tournament gender when tournament is feminine', async () => {
    const prismaMock = {
      tournament: {
        findUnique: jest.fn().mockResolvedValue({ gender: Gender.FEMENINO }),
      },
      player: {
        findMany: jest.fn().mockResolvedValue([]),
      },
    } as unknown as PrismaService;
    const service = new PlayersService(prismaMock, configMock);

    await service.searchByDniAndCategory({ tournamentId: 10 });

    expect(prismaMock.player.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ gender: Gender.FEMENINO }),
      }),
    );
  });

  it('returns empty list when category and tournament genders conflict', async () => {
    const prismaMock = {
      tournament: {
        findUnique: jest.fn().mockResolvedValue({ gender: Gender.MASCULINO }),
      },
      tournamentCategory: {
        findFirst: jest.fn().mockResolvedValue({ id: 1 }),
      },
      category: {
        findUnique: jest.fn().mockResolvedValue({
          birthYearMin: 2000,
          birthYearMax: 2010,
          gender: Gender.FEMENINO,
          active: true,
        }),
      },
      player: {
        findMany: jest.fn(),
      },
    } as unknown as PrismaService;
    const service = new PlayersService(prismaMock, configMock);

    const result = await service.searchByDniAndCategory({ tournamentId: 1, categoryId: 2 });

    expect(result).toEqual([]);
    expect(prismaMock.player.findMany).not.toHaveBeenCalled();
  });

  it('throws when tournament does not exist', async () => {
    const prismaMock = {
      tournament: {
        findUnique: jest.fn().mockResolvedValue(null),
      },
    } as unknown as PrismaService;
    const service = new PlayersService(prismaMock, configMock);

    await expect(service.searchByDniAndCategory({ tournamentId: 999 })).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });
});
