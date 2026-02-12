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

  it('throws 500 when decoder binary is unavailable', async () => {
    const service = buildService('/definitely/missing-decoder --format PDF417');
    jest.spyOn(service as never, 'buildDecodeStrategies' as never).mockResolvedValue([
      { name: 'raw', rotation: 0, buffer: Buffer.from('img') },
    ] as never);

    await expect((service as any).decodePdf417Payload(Buffer.from('input'))).rejects.toBeInstanceOf(
      InternalServerErrorException,
    );
  });

  it('returns 422 when decoder runs but cannot decode payload', async () => {
    const service = buildService();
    jest.spyOn(service as never, 'buildDecodeStrategies' as never).mockResolvedValue([
      { name: 'raw', rotation: 0, buffer: Buffer.from('img') },
    ] as never);
    jest.spyOn(service as never, 'runDecoder' as never).mockResolvedValue({
      exitCode: 0,
      stdout: '',
      stderr: '',
    } as never);

    await expect((service as any).decodePdf417Payload(Buffer.from('input'))).rejects.toBeInstanceOf(
      UnprocessableEntityException,
    );
  });

  it('uses default decoder command when env var is missing', async () => {
    const service = buildService();
    jest.spyOn(service as never, 'buildDecodeStrategies' as never).mockResolvedValue([
      { name: 'raw', rotation: 0, buffer: Buffer.from('img') },
    ] as never);

    const runDecoderSpy = jest.spyOn(service as never, 'runDecoder' as never).mockResolvedValue({
      exitCode: 0,
      stdout: '@payload@',
      stderr: '',
    } as never);

    await expect((service as any).decodePdf417Payload(Buffer.from('input'))).resolves.toEqual('@payload@');
    expect(runDecoderSpy).toHaveBeenCalledWith(
      '/usr/local/bin/dni-pdf417-decoder',
      ['--format', 'PDF417'],
      expect.any(Buffer),
    );
  });
});
