import {
  BadRequestException,
  InternalServerErrorException,
  Injectable,
  Logger,
  NotFoundException,
  UnprocessableEntityException,
  UnsupportedMediaTypeException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { spawn } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import { constants } from 'node:fs';
import { access, mkdir, unlink, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { Action, Gender, Module, Prisma, Scope } from '@prisma/client';
import * as sharp from 'sharp';

import { PrismaService } from '../../prisma/prisma.service';
import { RequestUser } from '../../common/interfaces/request-user.interface';
import { CreatePlayerDto } from '../dto/create-player.dto';
import { ListPlayersDto } from '../dto/list-players.dto';
import { SearchPlayersDto } from '../dto/search-players.dto';
import { UpdatePlayerDto } from '../dto/update-player.dto';
import { ScanDniResultDto } from '../dto/scan-dni-result.dto';
import { parseDniPdf417Payload } from '../utils/dni-pdf417-parser';

const DEFAULT_DNI_SCAN_DECODER_COMMAND = '/usr/local/bin/dni-pdf417-decoder --format PDF417';
const DECODER_TIMEOUT_MS = 8_000;
const DECODER_FILE_PLACEHOLDER_TOKENS = new Set(['{file}', '__INPUT_FILE__']);

class DecoderUnavailableError extends Error {}
class DecoderTimeoutError extends Error {}

type DecoderInputMode = 'stdin' | 'file';

type DecoderCommandSpec = {
  binary: string;
  args: string[];
  inputMode: DecoderInputMode;
  inputFileToken?: string;
};

type DecoderRunResult = {
  exitCode: number | null;
  stdout: string;
  stderr: string;
  spawnElapsedMs?: number;
  wrapperElapsedMs?: number;
};

type DecoderAttemptDetail = DecoderRunResult & {
  elapsedMs: number;
  payloadRaw: string;
};

type DecodePdf417Detail = {
  payloadRaw: string;
  stdoutRaw: string;
  stderrRaw: string;
  exitCode: number | null;
  elapsedMs: number;
  decoderCommand: string;
  decoderBinary: string;
  requestId: string;
  tempRoiPath?: string;
};

type PlayerWithMemberships = Prisma.PlayerGetPayload<{
  include: {
    playerTournamentClubs: {
      select: {
        tournamentId: true;
        club: { select: { id: true; name: true } };
      };
    };
  };
}>;

@Injectable()
export class PlayersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {}

  private readonly logger = new Logger(PlayersService.name);

  private readonly include = {
    playerTournamentClubs: {
      select: {
        tournamentId: true,
        club: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    },
  } satisfies Prisma.PlayerInclude;

  private writableTmpDirPromise: Promise<string> | null = null;

  async create(dto: CreatePlayerDto) {
    await this.ensureUniqueDni(dto.dni);

    try {
      const player = await this.prisma.player.create({
        data: {
          firstName: dto.firstName.trim(),
          lastName: dto.lastName.trim(),
          dni: dto.dni.trim(),
          birthDate: new Date(dto.birthDate),
          gender: dto.gender,
          active: dto.active ?? true,
          addressStreet: this.normalizeNullable(dto.address?.street),
          addressNumber: this.normalizeNullable(dto.address?.number),
          addressCity: this.normalizeNullable(dto.address?.city),
          emergencyName: this.normalizeNullable(dto.emergencyContact?.name),
          emergencyRelationship: this.normalizeNullable(dto.emergencyContact?.relationship),
          emergencyPhone: this.normalizeNullable(dto.emergencyContact?.phone),
        },
        include: this.include,
      });

      return this.mapPlayer(player);
    } catch (error) {
      throw this.handlePrismaError(error);
    }
  }

  async scanDniFromImage(file?: Express.Multer.File): Promise<ScanDniResultDto> {
    if (!file) {
      throw new BadRequestException('Debe adjuntar una imagen.');
    }

    if (!file.mimetype.startsWith('image/')) {
      throw new UnsupportedMediaTypeException('Solo se admiten imágenes para escanear DNI.');
    }

    const metadata = await sharp(file.buffer, { failOn: 'none' }).metadata();
    const debugEnabled = this.isScanDebugEnabled();
    const requestId = randomUUID();

    const t0 = Date.now();
    this.logger.log(
      `[DNI_SCAN][requestId=${requestId}][t0] incoming file mimetype=${file.mimetype} size=${file.size} width=${metadata.width ?? 'unknown'} height=${metadata.height ?? 'unknown'}`,
    );

    try {
      const decodeDetail = await this.decodePdf417Payload(file.buffer, t0, requestId);
      const payload = decodeDetail.payloadRaw;
      const tokensCount = payload.split('@').length;
      if (debugEnabled) {
        this.logger.log(`[DNI_SCAN][requestId=${requestId}] payloadRaw=${payload}`);
      }
      this.logger.log(
        `[DNI_SCAN][requestId=${requestId}] decoder payload stats payloadLength=${payload.length} tokensCount=${tokensCount}`,
      );
      if (tokensCount < 5) {
        throw new UnprocessableEntityException(
          debugEnabled
            ? {
                message: 'decoded but unexpected format',
                payloadRaw: payload,
                stdoutRaw: decodeDetail.stdoutRaw,
              }
            : 'decoded but unexpected format',
        );
      }
      const parsed = parseDniPdf417Payload(payload);
      return parsed;
    } finally {
      this.logger.log(`[DNI_SCAN][requestId=${requestId}][tEnd] totalElapsedMs=${Date.now() - t0}`);
    }
  }

  async scanDniDiagnostic(file?: Express.Multer.File) {
    if (!this.isScanDebugEnabled()) {
      throw new NotFoundException('Not Found');
    }

    if (!file) {
      throw new BadRequestException('Debe adjuntar una imagen.');
    }

    if (!file.mimetype.startsWith('image/')) {
      throw new UnsupportedMediaTypeException('Solo se admiten imágenes para escanear DNI.');
    }

    const requestId = randomUUID();
    const decodeDetail = await this.decodePdf417Payload(file.buffer, Date.now(), requestId, true);
    const payloadLength = decodeDetail.payloadRaw.length;
    const tokensCount = decodeDetail.payloadRaw ? decodeDetail.payloadRaw.split('@').length : 0;
    return {
      requestId,
      decoderCommand: decodeDetail.decoderCommand,
      decoderBinary: decodeDetail.decoderBinary,
      mimetype: file.mimetype,
      size: file.size,
      payloadRaw: decodeDetail.payloadRaw,
      stdoutRaw: decodeDetail.stdoutRaw,
      stderrRaw: decodeDetail.stderrRaw,
      payloadLength,
      tokensCount,
      exitCode: decodeDetail.exitCode,
      elapsedMs: decodeDetail.elapsedMs,
      tempRoiPath: decodeDetail.tempRoiPath,
    };
  }

  private async decodePdf417Payload(
    imageBuffer: Buffer,
    t0: number,
    requestId: string,
    diagnosticsMode = false,
  ): Promise<DecodePdf417Detail> {
    const decoderSpec = this.resolveDecoderCommandSpec();
    const debugEnabled = this.isScanDebugEnabled();
    const debugKeepTmpEnabled = this.isScanDebugKeepTmpEnabled();
    const decoderCommand = `${decoderSpec.binary} ${decoderSpec.args.join(' ')}`.trim();
    let lastAttempt: DecoderAttemptDetail | null = null;
    let tempRoiPath: string | undefined;

    try {
      const preprocessed = await this.preprocessDecodeImage(imageBuffer);
      this.logger.log(
        `[DNI_SCAN][requestId=${requestId}][t1] preprocess elapsedMs=${Date.now() - t0} resized=${preprocessed.resizedWidth}x${preprocessed.resizedHeight} roi=${preprocessed.roiWidth}x${preprocessed.roiHeight}`,
      );
      this.logger.log(
        `[DNI_SCAN][requestId=${requestId}][t1b] roi buffer info byteLength=${preprocessed.roiRawByteLength}`,
      );
      this.logger.log(
        `[DNI_SCAN][requestId=${requestId}][t1c] png encode info byteLength=${preprocessed.roiPngByteLength}`,
      );
      if (debugEnabled) {
        this.logger.log(
          `[DNI_SCAN][requestId=${requestId}][debug] resizedW,H=${preprocessed.resizedWidth},${preprocessed.resizedHeight}`,
        );
        this.logger.log(
          `[DNI_SCAN][requestId=${requestId}][debug] extract params ${JSON.stringify(preprocessed.extractParams)}`,
        );

        const tmpDir = '/tmp';
        const tempFullPath = join(tmpDir, `dni-full-${requestId}.png`);
        tempRoiPath = join(tmpDir, `dni-roi-${requestId}.png`);
        await writeFile(tempFullPath, preprocessed.resizedBuffer);
        await writeFile(tempRoiPath, preprocessed.roiBuffer);
        this.logger.log(
          `[DNI_SCAN][requestId=${requestId}][tmp] savedFull=${tempFullPath} bytes=${preprocessed.resizedBuffer.byteLength}`,
        );
        this.logger.log(
          `[DNI_SCAN][requestId=${requestId}][tmp] savedBaseRoi=${tempRoiPath} bytes=${preprocessed.roiBuffer.byteLength}`,
        );
      }

      this.logger.log(
        `[DNI_SCAN][requestId=${requestId}] decoder command=${decoderCommand} binary=${decoderSpec.binary}`,
      );
      this.logger.log(`[DNI_SCAN][requestId=${requestId}][t1d] enter decode loop`);
      const decodeTargets = [
        { name: 'roi', buffer: preprocessed.roiBuffer },
        { name: 'full', buffer: preprocessed.resizedBuffer },
      ] as const;

      for (const target of decodeTargets) {
        const strategies = await this.buildDecodeStrategies(target.buffer);

        for (let index = 0; index < strategies.length; index += 1) {
          const strategy = strategies[index];
          this.logger.log(
            `[DNI_SCAN][requestId=${requestId}][t2] target=${target.name} strategy start variant=${index + 1}/${strategies.length} strategy=${strategy.name} rotation=${strategy.rotation}`,
          );

          if (debugEnabled && debugKeepTmpEnabled) {
            const tmpDir = await this.resolveWritableTmpDir();
            const strategyPath = join(
              tmpDir,
              `dni-${target.name}-${requestId}-${strategy.name}-rot${strategy.rotation}.png`,
            );
            await writeFile(strategyPath, strategy.buffer);
            this.logger.log(
              `[DNI_SCAN][requestId=${requestId}][tmp] savedVariant=${strategyPath} bytes=${strategy.buffer.byteLength}`,
            );
          }

          const startedAt = Date.now();
          this.logger.log(
            `[DNI_SCAN][requestId=${requestId}][t1e] before spawn decoder target=${target.name} strategy=${strategy.name} rotation=${strategy.rotation}`,
          );
          try {
            const result = await this.runDecoder(
              decoderSpec,
              strategy.buffer,
              DECODER_TIMEOUT_MS,
              requestId,
            );
            const elapsedMs = Date.now() - startedAt;
            const stdoutRaw = result.stdout.trim();
            const stderrRaw = result.stderr.trim();
            const payload = this.extractPayloadFromDecoderOutput(stdoutRaw);
            lastAttempt = { ...result, elapsedMs, payloadRaw: payload };
            if (debugEnabled) {
              this.logger.log(`[DNI_SCAN][requestId=${requestId}] stdoutRaw=${stdoutRaw}`);
              this.logger.log(`[DNI_SCAN][requestId=${requestId}] stderrRaw=${stderrRaw}`);
            } else {
              this.logger.log(
                `[DNI_SCAN][requestId=${requestId}] decoder io stdoutLength=${stdoutRaw.length} stderrLength=${stderrRaw.length}`,
              );
            }
            this.logger.log(
              `[DNI_SCAN][requestId=${requestId}] decoder run exitCode=${result.exitCode} elapsedMs=${elapsedMs} spawnElapsedMs=${result.spawnElapsedMs ?? -1} wrapperElapsedMs=${result.wrapperElapsedMs ?? -1}`,
            );
            if (result.exitCode !== 0) {
              throw new Error(
                `decoder exited with code ${result.exitCode}${stderrRaw ? ` stderr=${stderrRaw}` : ''}`,
              );
            }
            if (!payload) {
              throw new Error('empty decoder output');
            }
            if (debugEnabled) {
              this.logger.log(`[DNI_SCAN][requestId=${requestId}] payloadRaw=${payload}`);
            }
            this.logger.log(
              `[DNI_SCAN][requestId=${requestId}] payloadLength=${payload.length} tokensCount=${payload.split('@').length}`,
            );

            this.logger.log(
              `[DNI_SCAN][requestId=${requestId}][t3] target=${target.name} strategy end variant=${index + 1}/${strategies.length} strategy=${strategy.name} rotation=${strategy.rotation} result=ok elapsedMs=${elapsedMs}`,
            );

            if (debugEnabled) {
              this.logger.log(
                `[DNI_SCAN] decoder success variant=${index + 1}/${strategies.length} strategy=${strategy.name} rotation=${strategy.rotation} elapsedMs=${elapsedMs}`,
              );
            }

            return {
              payloadRaw: payload,
              stdoutRaw,
              stderrRaw,
              exitCode: result.exitCode,
              elapsedMs,
              decoderCommand,
              decoderBinary: decoderSpec.binary,
              requestId,
              tempRoiPath,
            };
          } catch (error) {
            if (error instanceof DecoderUnavailableError) {
              if (debugEnabled) {
                this.logger.error(`[DNI_SCAN] decoder unavailable error=${error.message}`);
              }
              throw new InternalServerErrorException(
                `DNI scan decoder unavailable: ${error.message}`,
              );
            }

            const elapsedMs = Date.now() - startedAt;
            const errorMessage =
              error instanceof DecoderTimeoutError
                ? 'timeout'
                : error instanceof Error
                  ? error.message
                  : 'unknown decoder error';
            this.logger.warn(
              `[DNI_SCAN][requestId=${requestId}][t3] target=${target.name} strategy end variant=${index + 1}/${strategies.length} strategy=${strategy.name} rotation=${strategy.rotation} result=fail elapsedMs=${elapsedMs} error=${errorMessage}`,
            );

            if (debugEnabled) {
              this.logger.warn(
                `[DNI_SCAN] decoder failed variant=${index + 1}/${strategies.length} strategy=${strategy.name} rotation=${strategy.rotation} elapsedMs=${elapsedMs} error=${errorMessage}`,
              );
            }
          }
        }
      }

      if (diagnosticsMode) {
        return {
          payloadRaw: lastAttempt?.payloadRaw ?? '',
          stdoutRaw: lastAttempt?.stdout ?? '',
          stderrRaw: lastAttempt?.stderr ?? '',
          exitCode: lastAttempt?.exitCode ?? null,
          elapsedMs: lastAttempt?.elapsedMs ?? 0,
          decoderCommand,
          decoderBinary: decoderSpec.binary,
          requestId,
          tempRoiPath,
        };
      }
      throw new Error('all decoder variants failed');
    } catch (error) {
      if (error instanceof InternalServerErrorException) {
        throw error;
      }
      if (debugEnabled) {
        this.logger.warn('DNI scan failed to decode.');
      }
      throw new UnprocessableEntityException('No se pudo decodificar el PDF417.');
    } finally {
      if (tempRoiPath && debugEnabled) {
        this.logger.log(`[DNI_SCAN][requestId=${requestId}][tmp] keepingRoi=${tempRoiPath}`);
      }
    }
  }

  private resolveDecoderCommandSpec(): DecoderCommandSpec {
    const rawCommand = this.configService.get('DNI_SCAN_DECODER_COMMAND');
    const command =
      typeof rawCommand === 'string' && rawCommand.trim().length > 0
        ? rawCommand.trim()
        : DEFAULT_DNI_SCAN_DECODER_COMMAND;
    const [binary, ...args] = command.split(/\s+/).filter(Boolean);
    const inputFileToken = args.find((arg) => DECODER_FILE_PLACEHOLDER_TOKENS.has(arg));
    return {
      binary,
      args,
      inputMode: inputFileToken ? 'file' : 'stdin',
      inputFileToken,
    };
  }

  private runDecoder(
    decoderSpec: DecoderCommandSpec,
    input: Buffer,
    timeoutMs: number,
    requestId?: string,
  ): Promise<DecoderRunResult> {
    if (decoderSpec.inputMode === 'file') {
      return this.runDecoderUsingInputFile(decoderSpec, input, timeoutMs, requestId);
    }
    return this.runDecoderUsingStdin(
      decoderSpec.binary,
      decoderSpec.args,
      input,
      timeoutMs,
      requestId,
    );
  }

  private runDecoderUsingStdin(
    binary: string,
    args: string[],
    input: Buffer,
    timeoutMs: number,
    requestId?: string,
  ): Promise<DecoderRunResult> {
    return new Promise<DecoderRunResult>((resolve, reject) => {
      const wrapperStartedAt = Date.now();
      const spawnStartedAt = Date.now();
      const child = spawn(binary, args, { stdio: ['pipe', 'pipe', 'pipe'] });
      const spawnElapsedMs = Date.now() - spawnStartedAt;
      if (requestId) {
        this.logger.log(
          `[DNI_SCAN][requestId=${requestId}][t1f] after spawn started spawnElapsedMs=${spawnElapsedMs} binary=${binary}`,
        );
      }
      const chunks: Buffer[] = [];
      const errors: Buffer[] = [];
      let settled = false;

      const timeoutHandle = setTimeout(() => {
        if (settled) {
          return;
        }
        settled = true;
        child.kill('SIGKILL');
        this.logger.warn(`[DNI_SCAN] decoder timeout timeoutMs=${timeoutMs}`);
        reject(new DecoderTimeoutError(`timeout after ${timeoutMs}ms`));
      }, timeoutMs);

      child.stdout.on('data', (chunk: Buffer) => chunks.push(chunk));
      child.stderr.on('data', (chunk: Buffer) => errors.push(chunk));
      child.on('error', (error: NodeJS.ErrnoException) => {
        if (settled) {
          return;
        }
        settled = true;
        clearTimeout(timeoutHandle);
        if (error.code === 'ENOENT' || error.code === 'EACCES') {
          reject(new DecoderUnavailableError(`${binary} (${error.code ?? 'spawn error'})`));
          return;
        }
        reject(error);
      });
      child.on('close', (code) => {
        if (settled) {
          return;
        }
        settled = true;
        clearTimeout(timeoutHandle);
        const wrapperElapsedMs = Date.now() - wrapperStartedAt;
        resolve({
          exitCode: code,
          stdout: Buffer.concat(chunks).toString('utf-8'),
          stderr: Buffer.concat(errors).toString('utf-8').trim(),
          spawnElapsedMs,
          wrapperElapsedMs,
        });
      });

      child.stdin.write(input);
      child.stdin.end();
    });
  }

  private async runDecoderUsingInputFile(
    decoderSpec: DecoderCommandSpec,
    input: Buffer,
    timeoutMs: number,
    requestId?: string,
  ): Promise<DecoderRunResult> {
    const tmpDir = await this.resolveWritableTmpDir();
    const tempPath = join(tmpDir, `dni-scan-input-${randomUUID()}.png`);
    await writeFile(tempPath, input);

    try {
      const args = decoderSpec.args.map((arg) =>
        arg === decoderSpec.inputFileToken ? tempPath : arg,
      );
      return await this.runDecoderUsingStdin(
        decoderSpec.binary,
        args,
        Buffer.alloc(0),
        timeoutMs,
        requestId,
      );
    } finally {
      await this.cleanupTempInputFile(tempPath);
    }
  }

  private isScanDebugKeepTmpEnabled(): boolean {
    const rawValue =
      this.configService.get('SCAN_DEBUG_KEEP_TMP') ?? process.env.SCAN_DEBUG_KEEP_TMP;
    return this.parseEnvBool(rawValue, false);
  }

  private resolveWritableTmpDir(): Promise<string> {
    if (!this.writableTmpDirPromise) {
      this.writableTmpDirPromise = this.findWritableTmpDir();
    }
    return this.writableTmpDirPromise;
  }

  private async findWritableTmpDir(): Promise<string> {
    const candidates = ['/tmp', '/app/tmp'];

    for (const candidate of candidates) {
      try {
        await mkdir(candidate, { recursive: true });
        await access(candidate, constants.W_OK);
        this.logger.log(`[DNI_SCAN] writable tmp dir selected path=${candidate}`);
        return candidate;
      } catch {
        this.logger.warn(`[DNI_SCAN] tmp dir unavailable path=${candidate}`);
      }
    }

    throw new InternalServerErrorException('No writable tmp directory available for DNI scan.');
  }

  private async cleanupTempInputFile(path: string): Promise<void> {
    try {
      await unlink(path);
    } catch (error) {
      if (
        error &&
        typeof error === 'object' &&
        'code' in error &&
        (error as { code?: string }).code === 'ENOENT'
      ) {
        return;
      }
      this.logger.warn(
        `[DNI_SCAN] input temp file cleanup failed path=${path} error=${error instanceof Error ? error.message : 'unknown'}`,
      );
    }
  }

  private async preprocessDecodeImage(imageBuffer: Buffer) {
    const normalized = sharp(imageBuffer, { failOn: 'none' }).rotate();
    const metadata = await normalized.metadata();
    const resizedBuffer = await normalized
      .clone()
      .resize({ width: 1200, withoutEnlargement: true })
      .png({ compressionLevel: 3 })
      .toBuffer();
    const resizedMetadata = await sharp(resizedBuffer, { failOn: 'none' }).metadata();

    const resizedWidth = resizedMetadata.width ?? metadata.width ?? 0;
    const resizedHeight = resizedMetadata.height ?? metadata.height ?? 0;
    const extractLeft = Math.max(0, Math.floor(resizedWidth * 0.05));
    const extractTop = Math.max(0, Math.floor(resizedHeight * 0.55));
    const extractWidth = Math.max(
      1,
      Math.min(resizedWidth - extractLeft, Math.floor(resizedWidth * 0.9)),
    );
    const extractHeight = Math.max(
      1,
      Math.min(resizedHeight - extractTop, Math.floor(resizedHeight * 0.4)),
    );

    const extracted = sharp(resizedBuffer, { failOn: 'none' }).extract({
      left: extractLeft,
      top: extractTop,
      width: extractWidth,
      height: extractHeight,
    });
    const roiRawBuffer = await extracted.clone().raw().toBuffer();
    const roiBuffer = await extracted.clone().png({ compressionLevel: 3 }).toBuffer();

    return {
      roiBuffer,
      roiRawByteLength: roiRawBuffer.length,
      roiPngByteLength: roiBuffer.length,
      resizedBuffer,
      resizedWidth,
      resizedHeight,
      roiWidth: extractWidth,
      roiHeight: extractHeight,
      extractParams: {
        left: extractLeft,
        top: extractTop,
        width: extractWidth,
        height: extractHeight,
      },
    };
  }

  private async buildDecodeStrategies(imageBuffer: Buffer) {
    const rotations = [0, 90, 180, 270] as const;
    const strategies: Array<{ name: string; rotation: number; buffer: Buffer }> = [];
    const image = sharp(imageBuffer, { failOn: 'none' }).rotate();
    const metadata = await image.metadata();

    const pushUnique = (name: string, rotation: number, buffer: Buffer) => {
      if (!strategies.some((strategy) => strategy.buffer.equals(buffer))) {
        strategies.push({ name, rotation, buffer });
      }
    };

    for (const rotation of rotations) {
      const base = image.clone().rotate(rotation);
      pushUnique('raw', rotation, await base.clone().png({ compressionLevel: 3 }).toBuffer());
      pushUnique(
        'grayscale',
        rotation,
        await base.clone().greyscale().normalize().png({ compressionLevel: 3 }).toBuffer(),
      );
      pushUnique(
        'threshold',
        rotation,
        await base
          .clone()
          .greyscale()
          .normalize()
          .threshold(165)
          .png({ compressionLevel: 3 })
          .toBuffer(),
      );

      if (metadata.width && metadata.height) {
        pushUnique(
          'upscale_x2',
          rotation,
          await base
            .clone()
            .resize({
              width: metadata.width * 2,
              height: metadata.height * 2,
              kernel: sharp.kernel.nearest,
            })
            .normalize()
            .sharpen()
            .png({ compressionLevel: 3 })
            .toBuffer(),
        );
        pushUnique(
          'upscale_x3',
          rotation,
          await base
            .clone()
            .resize({
              width: metadata.width * 3,
              height: metadata.height * 3,
              kernel: sharp.kernel.nearest,
            })
            .normalize()
            .sharpen()
            .png({ compressionLevel: 3 })
            .toBuffer(),
        );
      }
    }

    return strategies;
  }

  private isScanDebugEnabled(): boolean {
    const rawValue =
      this.configService.get('SCAN_DEBUG') ??
      this.configService.get('DNI_SCAN_DEBUG') ??
      process.env.SCAN_DEBUG;
    return this.parseEnvBool(rawValue, false);
  }

  private parseEnvBool(v: unknown, defaultValue = false): boolean {
    if (v === undefined || v === null) return defaultValue;
    if (typeof v === 'boolean') return v;
    if (typeof v === 'number') return v === 1;
    if (typeof v !== 'string') return defaultValue;

    const s = v.trim().toLowerCase();
    if (['1', 'true', 'yes', 'y', 'on'].includes(s)) return true;
    if (['0', 'false', 'no', 'n', 'off', ''].includes(s)) return false;
    return defaultValue;
  }

  private extractPayloadFromDecoderOutput(output: string): string {
    const trimmed = output.trim();
    if (!trimmed) {
      return '';
    }

    const lines = trimmed
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter(Boolean);

    for (const line of lines) {
      const atIndex = line.indexOf('@');
      if (atIndex >= 0) {
        return line.slice(atIndex).trim();
      }

      const prefixedMatch = line.match(/^(Text|Content|Raw\s+text|Payload)\s*:\s*(.+)$/i);
      if (prefixedMatch?.[2]) {
        return prefixedMatch[2].trim();
      }

      if (!line.includes(':')) {
        return line;
      }
    }

    return '';
  }

  async findAll(query: ListPlayersDto, user?: RequestUser) {
    const {
      search,
      status,
      dni,
      page,
      pageSize,
      clubId,
      tournamentId,
      gender,
      birthYear,
      birthYearMin,
      birthYearMax,
    } = query;

    const where: Prisma.PlayerWhereInput = {};

    if (clubId !== undefined && clubId !== null && tournamentId === undefined) {
      throw new BadRequestException('El filtro por club requiere un torneo.');
    }

    const trimmedDni = dni?.trim();
    if (trimmedDni) {
      where.dni = trimmedDni;
    } else if (search?.trim()) {
      const term = search.trim();
      where.OR = [
        { firstName: { contains: term, mode: 'insensitive' } },
        { lastName: { contains: term, mode: 'insensitive' } },
        { dni: { contains: term, mode: 'insensitive' } },
      ];
    }

    if (status === 'active') {
      where.active = true;
    } else if (status === 'inactive') {
      where.active = false;
    }

    if (gender) {
      where.gender = gender;
    }

    if (birthYear !== undefined && (birthYearMin !== undefined || birthYearMax !== undefined)) {
      throw new BadRequestException(
        'No se puede combinar el filtro por año de nacimiento único con un rango.',
      );
    }

    if (birthYearMin !== undefined && birthYearMax !== undefined && birthYearMin > birthYearMax) {
      throw new BadRequestException('El año mínimo no puede ser mayor al año máximo.');
    }

    if (birthYear !== undefined) {
      const start = new Date(Date.UTC(birthYear, 0, 1));
      const end = new Date(Date.UTC(birthYear + 1, 0, 1));
      const existingBirthDateFilter =
        where.birthDate && typeof where.birthDate === 'object' && !(where.birthDate instanceof Date)
          ? (where.birthDate as Prisma.DateTimeFilter)
          : undefined;
      where.birthDate = {
        ...(existingBirthDateFilter ?? {}),
        gte: start,
        lt: end,
      };
    }

    if (birthYearMin !== undefined || birthYearMax !== undefined) {
      const existingBirthDateFilter =
        where.birthDate && typeof where.birthDate === 'object' && !(where.birthDate instanceof Date)
          ? (where.birthDate as Prisma.DateTimeFilter)
          : undefined;
      const filter: Prisma.DateTimeFilter = {
        ...(existingBirthDateFilter ?? {}),
      };
      if (birthYearMin !== undefined) {
        filter.gte = new Date(Date.UTC(birthYearMin, 0, 1));
      }
      if (birthYearMax !== undefined) {
        filter.lt = new Date(Date.UTC(birthYearMax + 1, 0, 1));
      }
      where.birthDate = filter;
    }

    const restrictedClubIds = this.getRestrictedClubIds(user);
    const membershipFilters: Prisma.PlayerTournamentClubWhereInput[] = [];
    const buildMembershipCriteria = (
      filters: Prisma.PlayerTournamentClubWhereInput[],
    ): Prisma.PlayerTournamentClubWhereInput => (filters.length ? { AND: filters } : {});

    if (tournamentId !== undefined) {
      membershipFilters.push({ tournamentId });
    }

    if (restrictedClubIds !== null) {
      if (clubId !== undefined) {
        if (clubId === null) {
          where.playerTournamentClubs = { none: buildMembershipCriteria(membershipFilters) };
        } else if (restrictedClubIds.includes(clubId)) {
          membershipFilters.push({ clubId });
          where.playerTournamentClubs = { some: buildMembershipCriteria(membershipFilters) };
        } else {
          where.playerTournamentClubs = {
            some: { AND: [...membershipFilters, { clubId: { in: [] } }] },
          };
        }
      } else {
        membershipFilters.push({ clubId: { in: restrictedClubIds } });
        where.playerTournamentClubs = { some: buildMembershipCriteria(membershipFilters) };
      }
    } else if (clubId !== undefined) {
      if (clubId === null) {
        where.playerTournamentClubs = { none: buildMembershipCriteria(membershipFilters) };
      } else {
        membershipFilters.push({ clubId });
        where.playerTournamentClubs = { some: buildMembershipCriteria(membershipFilters) };
      }
    } else if (membershipFilters.length) {
      where.playerTournamentClubs = { some: buildMembershipCriteria(membershipFilters) };
    }

    const skip = (page - 1) * pageSize;

    const [total, players] = await this.prisma.$transaction([
      this.prisma.player.count({ where }),
      this.prisma.player.findMany({
        where,
        include: this.include,
        orderBy: [{ lastName: 'asc' }, { firstName: 'asc' }],
        skip,
        take: pageSize,
      }),
    ]);

    return {
      data: players.map((player) => this.mapPlayer(player, tournamentId)),
      total,
      page,
      pageSize,
    };
  }

  async searchByDniAndCategory(query: SearchPlayersDto) {
    const trimmedDni = query.dni?.trim();
    const { tournamentId, categoryId, clubId } = query;

    if (
      !trimmedDni &&
      tournamentId === undefined &&
      categoryId === undefined &&
      query.onlyFree !== true &&
      clubId === undefined
    ) {
      throw new BadRequestException('Debe enviar al menos un filtro de búsqueda.');
    }

    if (query.onlyFree === true && clubId !== undefined) {
      throw new BadRequestException('No se puede combinar club y jugadores libres.');
    }

    if ((query.onlyFree === true || clubId !== undefined) && tournamentId === undefined) {
      throw new BadRequestException('El filtro por club requiere un torneo.');
    }

    let category: {
      birthYearMin: number;
      birthYearMax: number;
      gender: Gender;
      active: boolean;
    } | null = null;

    if (categoryId !== undefined) {
      category = await this.prisma.category.findUnique({
        where: { id: categoryId },
        select: {
          birthYearMin: true,
          birthYearMax: true,
          gender: true,
          active: true,
        },
      });

      if (!category || !category.active) {
        throw new BadRequestException('Categoría inválida o inactiva.');
      }

      if (tournamentId !== undefined) {
        const tournamentCategory = await this.prisma.tournamentCategory.findFirst({
          where: {
            tournamentId,
            categoryId,
            enabled: true,
          },
          select: { id: true },
        });

        if (!tournamentCategory) {
          throw new BadRequestException('La categoría no está habilitada en el torneo.');
        }
      }
    }

    const where: Prisma.PlayerWhereInput = { active: true };

    if (trimmedDni) {
      where.dni = { contains: trimmedDni, mode: 'insensitive' };
    }

    if (category) {
      const startDate = new Date(Date.UTC(category.birthYearMin, 0, 1));
      const endDate = new Date(Date.UTC(category.birthYearMax, 11, 31, 23, 59, 59, 999));
      where.birthDate = {
        gte: startDate,
        lte: endDate,
      };

      if (category.gender !== Gender.MIXTO) {
        where.gender = category.gender;
      }
    }

    const onlyFree = query.onlyFree === true;
    if (onlyFree) {
      where.playerTournamentClubs = {
        none: { tournamentId },
      };
    } else if (clubId !== undefined) {
      where.playerTournamentClubs = {
        some: {
          tournamentId,
          clubId,
        },
      };
    }

    const players = await this.prisma.player.findMany({
      where,
      include: {
        playerTournamentClubs: {
          ...(tournamentId !== undefined ? { where: { tournamentId } } : { where: { id: -1 } }),
          select: {
            clubId: true,
            club: { select: { id: true, name: true } },
            tournamentId: true,
          },
        },
      },
      orderBy: [{ lastName: 'asc' }, { firstName: 'asc' }],
    });

    return players.map((player) => {
      const assignment = tournamentId !== undefined ? player.playerTournamentClubs[0] : null;
      return {
        id: player.id,
        firstName: player.firstName,
        lastName: player.lastName,
        dni: player.dni,
        birthDate: player.birthDate.toISOString(),
        assignedClubId: assignment?.clubId ?? null,
        assignedClubName: assignment?.club?.name ?? null,
      };
    });
  }

  private getRestrictedClubIds(user?: RequestUser): number[] | null {
    if (!user) {
      return null;
    }

    const relevantGrants = user.permissions.filter(
      (grant) =>
        grant.module === Module.JUGADORES &&
        (grant.action === Action.VIEW || grant.action === Action.MANAGE),
    );

    if (relevantGrants.length === 0) {
      return this.getFallbackClubRestriction(user);
    }

    if (relevantGrants.some((grant) => grant.scope === Scope.GLOBAL)) {
      return null;
    }

    const clubIds = new Set<number>();
    for (const grant of relevantGrants) {
      if (grant.scope === Scope.CLUB && grant.clubs) {
        for (const clubId of grant.clubs) {
          clubIds.add(clubId);
        }
      }
    }

    if (clubIds.size > 0) {
      return Array.from(clubIds);
    }

    return this.getFallbackClubRestriction(user);
  }

  private getFallbackClubRestriction(user: RequestUser): number[] | null {
    if (!user.club) {
      return null;
    }

    const limitedRoles = new Set(['DELEGATE', 'COACH']);
    const hasLimitedRole = user.roles.some((role) => limitedRoles.has(role));

    if (!hasLimitedRole) {
      return null;
    }

    return [user.club.id];
  }

  async findById(id: number) {
    const player = await this.prisma.player.findUnique({
      where: { id },
      include: this.include,
    });
    if (!player) {
      throw new NotFoundException('Jugador no encontrado');
    }
    return this.mapPlayer(player);
  }

  async update(id: number, dto: UpdatePlayerDto) {
    const existing = await this.prisma.player.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundException('Jugador no encontrado');
    }

    if (dto.dni && dto.dni.trim() !== existing.dni) {
      await this.ensureUniqueDni(dto.dni, id);
    }

    const data: Prisma.PlayerUpdateInput = {};

    if (dto.firstName !== undefined) {
      data.firstName = dto.firstName.trim();
    }
    if (dto.lastName !== undefined) {
      data.lastName = dto.lastName.trim();
    }
    if (dto.dni !== undefined) {
      data.dni = dto.dni.trim();
    }
    if (dto.birthDate !== undefined) {
      data.birthDate = new Date(dto.birthDate);
    }
    if (dto.gender !== undefined) {
      data.gender = dto.gender;
    }
    if (dto.active !== undefined) {
      data.active = dto.active;
    }
    if (dto.address !== undefined) {
      data.addressStreet = this.normalizeNullable(dto.address?.street);
      data.addressNumber = this.normalizeNullable(dto.address?.number);
      data.addressCity = this.normalizeNullable(dto.address?.city);
    }
    if (dto.emergencyContact !== undefined) {
      data.emergencyName = this.normalizeNullable(dto.emergencyContact?.name);
      data.emergencyRelationship = this.normalizeNullable(dto.emergencyContact?.relationship);
      data.emergencyPhone = this.normalizeNullable(dto.emergencyContact?.phone);
    }

    try {
      const player = await this.prisma.player.update({
        where: { id },
        data,
        include: this.include,
      });
      return this.mapPlayer(player);
    } catch (error) {
      throw this.handlePrismaError(error);
    }
  }

  private mapPlayer(player: PlayerWithMemberships, tournamentId?: number) {
    const addressFields = [player.addressStreet, player.addressNumber, player.addressCity];
    const hasAddress = addressFields.some((value) => value && value.trim().length > 0);
    const emergencyFields = [
      player.emergencyName,
      player.emergencyRelationship,
      player.emergencyPhone,
    ];
    const hasEmergency = emergencyFields.some((value) => value && value.trim().length > 0);
    const memberships = player.playerTournamentClubs ?? [];
    const membership =
      tournamentId !== undefined
        ? memberships.find((entry) => entry.tournamentId === tournamentId)
        : memberships.length === 1
          ? memberships[0]
          : undefined;
    const club = membership?.club ?? null;

    return {
      id: player.id,
      firstName: player.firstName,
      lastName: player.lastName,
      dni: player.dni,
      birthDate: player.birthDate.toISOString(),
      gender: player.gender,
      active: player.active,
      club: club ? { id: club.id, name: club.name } : null,
      address: hasAddress
        ? {
            street: player.addressStreet,
            number: player.addressNumber,
            city: player.addressCity,
          }
        : null,
      emergencyContact: hasEmergency
        ? {
            name: player.emergencyName,
            relationship: player.emergencyRelationship,
            phone: player.emergencyPhone,
          }
        : null,
    };
  }

  private normalizeNullable(value?: string | null) {
    if (value === undefined) {
      return undefined;
    }
    if (value === null) {
      return null;
    }
    const trimmed = value.trim();
    return trimmed.length ? trimmed : null;
  }

  private async ensureUniqueDni(dni: string, excludeId?: number) {
    const existing = await this.prisma.player.findFirst({
      where: {
        dni: dni.trim(),
        NOT: excludeId ? { id: excludeId } : undefined,
      },
    });

    if (existing) {
      throw new BadRequestException('El DNI ingresado ya está en uso.');
    }
  }

  private handlePrismaError(error: unknown): never {
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
      if (Array.isArray(error.meta?.target) && error.meta?.target.includes('dni')) {
        throw new BadRequestException('El DNI ingresado ya está en uso.');
      }
    }
    throw error;
  }
}
