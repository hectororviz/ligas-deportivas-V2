import { InternalServerErrorException, UnprocessableEntityException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { PrismaService } from '../../prisma/prisma.service';
import { PlayersService } from './players.service';

describe('PlayersService decoder wrapper', () => {
  const prismaMock = {} as PrismaService;

  const buildService = (decoderCommand?: string) => {
    const configMock = {
      get: jest.fn((key: string) => {
        if (key === 'DNI_SCAN_DECODER_COMMAND') {
          return decoderCommand;
        }
        return undefined;
      }),
    } as unknown as ConfigService;

    return new PlayersService(prismaMock, configMock);
  };

  const mockPreprocess = (service: PlayersService) => {
    jest.spyOn(service as never, 'preprocessDecodeImage' as never).mockResolvedValue({
      roiBuffer: Buffer.from('roi'),
      resizedWidth: 1200,
      resizedHeight: 900,
      roiWidth: 1200,
      roiHeight: 315,
    } as never);
  };

  it('throws 500 when decoder binary is unavailable', async () => {
    const service = buildService('/definitely/missing-decoder --format PDF417');
    mockPreprocess(service);
    jest.spyOn(service as never, 'buildDecodeStrategies' as never).mockResolvedValue([
      { name: 'raw', rotation: 0, buffer: Buffer.from('img') },
    ] as never);

    await expect((service as any).decodePdf417Payload(Buffer.from('input'), Date.now())).rejects.toBeInstanceOf(
      InternalServerErrorException,
    );
  });

  it('returns 422 when decoder runs but cannot decode payload', async () => {
    const service = buildService();
    mockPreprocess(service);
    jest.spyOn(service as never, 'buildDecodeStrategies' as never).mockResolvedValue([
      { name: 'raw', rotation: 0, buffer: Buffer.from('img') },
    ] as never);
    jest.spyOn(service as never, 'runDecoder' as never).mockResolvedValue({
      exitCode: 0,
      stdout: '',
      stderr: '',
    } as never);

    await expect((service as any).decodePdf417Payload(Buffer.from('input'), Date.now())).rejects.toBeInstanceOf(
      UnprocessableEntityException,
    );
  });

  it('uses default decoder command when env var is missing', async () => {
    const service = buildService();
    mockPreprocess(service);
    jest.spyOn(service as never, 'buildDecodeStrategies' as never).mockResolvedValue([
      { name: 'raw', rotation: 0, buffer: Buffer.from('img') },
    ] as never);

    const runDecoderSpy = jest.spyOn(service as never, 'runDecoder' as never).mockResolvedValue({
      exitCode: 0,
      stdout: '@payload@',
      stderr: '',
    } as never);

    await expect((service as any).decodePdf417Payload(Buffer.from('input'), Date.now())).resolves.toEqual('@payload@');
    expect(runDecoderSpy).toHaveBeenCalledWith(
      {
        binary: '/usr/local/bin/dni-pdf417-decoder',
        args: ['--format', 'PDF417'],
        inputMode: 'stdin',
        inputFileToken: undefined,
      },
      expect.any(Buffer),
      8000,
    );
  });

  it('uses file input mode when command contains file placeholder token', async () => {
    const service = buildService('/usr/local/bin/dni-pdf417-decoder --format PDF417 {file}');
    mockPreprocess(service);
    jest.spyOn(service as never, 'buildDecodeStrategies' as never).mockResolvedValue([
      { name: 'raw', rotation: 0, buffer: Buffer.from('img') },
    ] as never);

    const runDecoderSpy = jest.spyOn(service as never, 'runDecoder' as never).mockResolvedValue({
      exitCode: 0,
      stdout: '@payload@',
      stderr: '',
    } as never);

    await expect((service as any).decodePdf417Payload(Buffer.from('input'), Date.now())).resolves.toEqual('@payload@');
    expect(runDecoderSpy).toHaveBeenCalledWith(
      {
        binary: '/usr/local/bin/dni-pdf417-decoder',
        args: ['--format', 'PDF417', '{file}'],
        inputMode: 'file',
        inputFileToken: '{file}',
      },
      expect.any(Buffer),
      8000,
    );
  });
});
