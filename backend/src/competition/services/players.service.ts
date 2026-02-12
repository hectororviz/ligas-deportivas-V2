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
import { unlink, writeFile } from 'node:fs/promises';
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

    const t0 = Date.now();
    this.logger.log(
      `[DNI_SCAN][t0] incoming file mimetype=${file.mimetype} size=${file.size} width=${metadata.width ?? 'unknown'} height=${metadata.height ?? 'unknown'}`,
    );

    try {
      const payload = await this.decodePdf417Payload(file.buffer, t0);
      const tokensCount = payload.split('@').length;
      this.logger.log(
        `[DNI_SCAN] decoder payload stats payloadLength=${payload.length} tokensCount=${tokensCount}`,
      );
      if (tokensCount < 5) {
        throw new UnprocessableEntityException('decoded but unexpected format');
      }
      const parsed = parseDniPdf417Payload(payload);
      return parsed;
    } finally {
      this.logger.log(`[DNI_SCAN][tEnd] totalElapsedMs=${Date.now() - t0}`);
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

    const decoderSpec = this.resolveDecoderCommandSpec();
    const preprocessed = await this.preprocessDecodeImage(file.buffer);
    const strategies = await this.buildDecodeStrategies(preprocessed.roiBuffer);
    const report = [] as Array<Record<string, unknown>>;
    let payloadRaw: string | null = null;
    let decoderOutputRaw: string | null = null;
    let payloadLength = 0;
    let tokensCount = 0;

    for (const strategy of strategies) {
      const startedAt = Date.now();
      try {
        const result = await this.runDecoder(decoderSpec, strategy.buffer, DECODER_TIMEOUT_MS);
        const elapsedMs = Date.now() - startedAt;
        const decoderStdout = result.stdout.trim();
        const payload = this.extractPayloadFromDecoderOutput(decoderStdout);
        const outputDiffersFromPayload = decoderStdout !== payload;
        if (result.exitCode === 0 && payload.length > 0 && payloadRaw === null) {
          payloadRaw = payload;
          decoderOutputRaw = outputDiffersFromPayload ? decoderStdout : null;
          payloadLength = payload.length;
          tokensCount = payload.split('@').filter(Boolean).length;
        }
        report.push({
          strategy: strategy.name,
          rotation: strategy.rotation,
          success: result.exitCode === 0 && payload.length > 0,
          elapsedMs,
          exitCode: result.exitCode,
          stderr: result.stderr,
          error:
            result.exitCode === 0
              ? payload.length > 0
                ? null
                : 'empty decoder output'
              : 'decoder exited with non-zero code',
        });
      } catch (error) {
        const elapsedMs = Date.now() - startedAt;
        report.push({
          strategy: strategy.name,
          rotation: strategy.rotation,
          success: false,
          elapsedMs,
          exitCode: null,
          stderr: null,
          error: error instanceof Error ? error.message : 'unknown decoder error',
        });
      }
    }

    return {
      decoderCommand: `${decoderSpec.binary} ${decoderSpec.args.join(' ')}`.trim(),
      mimetype: file.mimetype,
      size: file.size,
      payloadRaw,
      decoderOutputRaw,
      payloadLength,
      tokensCount,
      report,
    };
  }

  private async decodePdf417Payload(imageBuffer: Buffer, t0: number): Promise<string> {
    const decoderSpec = this.resolveDecoderCommandSpec();
    const debugEnabled = this.isScanDebugEnabled();

    try {
      const preprocessed = await this.preprocessDecodeImage(imageBuffer);
      this.logger.log(
        `[DNI_SCAN][t1] base preprocess done elapsedMs=${Date.now() - t0} resized=${preprocessed.resizedWidth}x${preprocessed.resizedHeight} roi=${preprocessed.roiWidth}x${preprocessed.roiHeight}`,
      );
      const strategies = await this.buildDecodeStrategies(preprocessed.roiBuffer);

      for (let index = 0; index < strategies.length; index += 1) {
        const strategy = strategies[index];
        this.logger.log(
          `[DNI_SCAN][t2] strategy start variant=${index + 1}/${strategies.length} strategy=${strategy.name} rotation=${strategy.rotation}`,
        );
        const startedAt = Date.now();
        try {
          const result = await this.runDecoder(decoderSpec, strategy.buffer, DECODER_TIMEOUT_MS);
          const elapsedMs = Date.now() - startedAt;
          const payload = this.extractPayloadFromDecoderOutput(result.stdout.trim());
          if (result.exitCode !== 0) {
            throw new Error(
              `decoder exited with code ${result.exitCode}${result.stderr ? ` stderr=${result.stderr}` : ''}`,
            );
          }
          if (!payload) {
            throw new Error('empty decoder output');
          }

          this.logger.log(
            `[DNI_SCAN][t3] strategy end variant=${index + 1}/${strategies.length} strategy=${strategy.name} rotation=${strategy.rotation} result=ok elapsedMs=${elapsedMs}`,
          );

          if (debugEnabled) {
            this.logger.log(
              `[DNI_SCAN] decoder success variant=${index + 1}/${strategies.length} strategy=${strategy.name} rotation=${strategy.rotation} elapsedMs=${elapsedMs}`,
            );
          }

          return payload;
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
            `[DNI_SCAN][t3] strategy end variant=${index + 1}/${strategies.length} strategy=${strategy.name} rotation=${strategy.rotation} result=fail elapsedMs=${elapsedMs} error=${errorMessage}`,
          );

          if (debugEnabled) {
            this.logger.warn(
              `[DNI_SCAN] decoder failed variant=${index + 1}/${strategies.length} strategy=${strategy.name} rotation=${strategy.rotation} elapsedMs=${elapsedMs} error=${errorMessage}`,
            );
          }
        }
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
    }
  }

  private resolveDecoderCommandSpec(): DecoderCommandSpec {
    const command =
      this.configService.get<string>('DNI_SCAN_DECODER_COMMAND')?.trim() ||
      DEFAULT_DNI_SCAN_DECODER_COMMAND;
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
  ): Promise<DecoderRunResult> {
    if (decoderSpec.inputMode === 'file') {
      return this.runDecoderUsingInputFile(decoderSpec, input, timeoutMs);
    }
    return this.runDecoderUsingStdin(decoderSpec.binary, decoderSpec.args, input, timeoutMs);
  }

  private runDecoderUsingStdin(
    binary: string,
    args: string[],
    input: Buffer,
    timeoutMs: number,
  ): Promise<DecoderRunResult> {
    return new Promise<DecoderRunResult>((resolve, reject) => {
      const child = spawn(binary, args, { stdio: ['pipe', 'pipe', 'pipe'] });
      const chunks: Buffer[] = [];
      const errors: Buffer[] = [];
      let settled = false;

      const timeoutHandle = setTimeout(() => {
        if (settled) {
          return;
        }
        settled = true;
        child.kill('SIGKILL');
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
        resolve({
          exitCode: code,
          stdout: Buffer.concat(chunks).toString('utf-8'),
          stderr: Buffer.concat(errors).toString('utf-8').trim(),
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
  ): Promise<DecoderRunResult> {
    const tempPath = join('/tmp', `dni-scan-input-${randomUUID()}.png`);
    await writeFile(tempPath, input);

    try {
      const args = decoderSpec.args.map((arg) =>
        arg === decoderSpec.inputFileToken ? tempPath : arg,
      );
      return await this.runDecoderUsingStdin(decoderSpec.binary, args, Buffer.alloc(0), timeoutMs);
    } finally {
      await this.cleanupTempInputFile(tempPath);
    }
  }

  private async cleanupTempInputFile(path: string): Promise<void> {
    try {
      await unlink(path);
    } catch (error) {
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
      .resize({ width: 1800, withoutEnlargement: true })
      .png()
      .toBuffer();
    const resizedMetadata = await sharp(resizedBuffer, { failOn: 'none' }).metadata();

    const resizedWidth = resizedMetadata.width ?? metadata.width ?? 0;
    const resizedHeight = resizedMetadata.height ?? metadata.height ?? 0;
    const roiHeight = Math.max(1, Math.floor(resizedHeight * 0.35));
    const roiTop = Math.max(0, resizedHeight - roiHeight);
    const roiWidth = Math.max(1, resizedWidth);

    const roiBuffer = await sharp(resizedBuffer, { failOn: 'none' })
      .extract({
        left: 0,
        top: roiTop,
        width: roiWidth,
        height: roiHeight,
      })
      .png()
      .toBuffer();

    return {
      roiBuffer,
      resizedWidth,
      resizedHeight,
      roiWidth,
      roiHeight,
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
      pushUnique('raw', rotation, await base.clone().toBuffer());
      pushUnique(
        'grayscale',
        rotation,
        await base.clone().greyscale().normalize().png().toBuffer(),
      );
      pushUnique(
        'threshold',
        rotation,
        await base.clone().greyscale().normalize().threshold(165).png().toBuffer(),
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
            .png()
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
            .png()
            .toBuffer(),
        );
      }
    }

    return strategies;
  }

  private isScanDebugEnabled(): boolean {
    const rawValue =
      this.configService.get<string>('SCAN_DEBUG') ??
      this.configService.get<string>('DNI_SCAN_DEBUG');
    const value = rawValue?.trim().toLowerCase();
    return value === '1' || value === 'true';
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
