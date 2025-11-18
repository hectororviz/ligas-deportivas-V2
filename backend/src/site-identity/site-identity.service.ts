import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { SiteIdentity } from '@prisma/client';
import { UpdateSiteIdentityDto } from './dto/update-site-identity.dto';
import { ConfigService } from '@nestjs/config';
import { promises as fs } from 'fs';
import * as path from 'path';

export interface SiteIdentityResponse {
  title: string;
  iconUrl: string | null;
  flyerUrl: string | null;
}

export interface SiteIdentityIcon {
  path: string;
  mimeType: string;
}

@Injectable()
export class SiteIdentityService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storageService: StorageService,
    private readonly configService: ConfigService,
  ) {}

  async getIdentity(): Promise<SiteIdentityResponse> {
    const identity = await this.ensureIdentity();
    return this.toResponse(identity);
  }

  async updateIdentity(
    dto: UpdateSiteIdentityDto,
    iconFile?: Express.Multer.File,
    flyerFile?: Express.Multer.File,
  ): Promise<SiteIdentityResponse> {
    const existing = await this.ensureIdentity();
    let iconKey: string | null | undefined;
    let flyerKey: string | null | undefined;

    if (dto.removeIcon) {
      if (existing.iconKey) {
        await this.storageService.deleteAttachment(existing.iconKey);
      }
      iconKey = null;
    }

    if (iconFile) {
      if (existing.iconKey && !dto.removeIcon) {
        await this.storageService.deleteAttachment(existing.iconKey);
      }
      iconKey = await this.storageService.saveAttachment(iconFile);
    }

    if (dto.removeFlyer) {
      if (existing.flyerKey) {
        await this.storageService.deleteAttachment(existing.flyerKey);
      }
      flyerKey = null;
    }

    if (flyerFile) {
      this.validateFlyerFile(flyerFile);
      if (existing.flyerKey && !dto.removeFlyer) {
        await this.storageService.deleteAttachment(existing.flyerKey);
      }
      flyerKey = await this.storageService.saveAttachment(flyerFile);
    }

    const updated = await this.prisma.siteIdentity.upsert({
      where: { id: existing.id },
      update: {
        title: dto.title,
        iconKey: iconKey !== undefined ? iconKey : existing.iconKey,
        flyerKey: flyerKey !== undefined ? flyerKey : existing.flyerKey,
      },
      create: {
        id: existing.id,
        title: dto.title,
        iconKey: iconKey ?? null,
        flyerKey: flyerKey ?? null,
      },
    });

    return this.toResponse(updated);
  }

  async getIconFile(): Promise<SiteIdentityIcon> {
    const identity = await this.ensureIdentity();
    if (!identity.iconKey) {
      throw new NotFoundException('El sitio no tiene un ícono configurado.');
    }

    let filePath: string;
    try {
      filePath = this.storageService.resolveAttachmentPath(identity.iconKey);
    } catch {
      throw new NotFoundException('El archivo del ícono no existe.');
    }

    try {
      await fs.access(filePath);
    } catch {
      throw new NotFoundException('El archivo del ícono no existe.');
    }

    return {
      path: filePath,
      mimeType: this.getMimeType(path.extname(filePath)),
    };
  }

  async getFlyerFile(): Promise<SiteIdentityIcon> {
    const identity = await this.ensureIdentity();
    if (!identity.flyerKey) {
      throw new NotFoundException('El sitio no tiene un flyer configurado.');
    }

    let filePath: string;
    try {
      filePath = this.storageService.resolveAttachmentPath(identity.flyerKey);
    } catch {
      throw new NotFoundException('El archivo del flyer no existe.');
    }

    try {
      await fs.access(filePath);
    } catch {
      throw new NotFoundException('El archivo del flyer no existe.');
    }

    return {
      path: filePath,
      mimeType: this.getMimeType(path.extname(filePath)),
    };
  }

  private async ensureIdentity(): Promise<SiteIdentity> {
    const existing = await this.prisma.siteIdentity.findUnique({ where: { id: 1 } });
    if (existing) {
      return existing;
    }
    return this.prisma.siteIdentity.create({
      data: {
        id: 1,
        title: 'Ligas Deportivas',
        flyerKey: null,
      },
    });
  }

  private toResponse(identity: SiteIdentity): SiteIdentityResponse {
    let iconUrl: string | null = null;
    if (identity.iconKey) {
      const appUrl = (this.configService.get<string>('app.url') ?? '').replace(/\/$/, '');
      const version = identity.updatedAt.getTime();
      iconUrl = `${appUrl}/api/v1/site-identity/icon?v=${version}`;
    }
    let flyerUrl: string | null = null;
    if (identity.flyerKey) {
      const appUrl = (this.configService.get<string>('app.url') ?? '').replace(/\/$/, '');
      const version = identity.updatedAt.getTime();
      flyerUrl = `${appUrl}/api/v1/site-identity/flyer?v=${version}`;
    }
    return {
      title: identity.title,
      iconUrl,
      flyerUrl,
    };
  }

  private getMimeType(extension: string) {
    switch (extension.toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.svg':
        return 'image/svg+xml';
      case '.bmp':
        return 'image/bmp';
      default:
        return 'application/octet-stream';
    }
  }

  private validateFlyerFile(file: Express.Multer.File) {
    if (!file || !file.buffer) {
      throw new BadRequestException('El archivo del flyer es inválido.');
    }

    const allowed = ['image/png', 'image/jpeg'];
    if (!allowed.includes(file.mimetype)) {
      throw new BadRequestException('El flyer debe ser un PNG o JPG.');
    }

    const buffer = file.buffer;
    const { width, height } =
      file.mimetype === 'image/png'
        ? this.readPngDimensions(buffer)
        : this.readJpegDimensions(buffer);

    if (width !== 1080 || height !== 1920) {
      throw new BadRequestException('El flyer debe medir exactamente 1080x1920 píxeles.');
    }

    if (file.size > 5 * 1024 * 1024) {
      throw new BadRequestException('El flyer supera el tamaño máximo permitido de 5 MB.');
    }
  }

  private readPngDimensions(buffer: Buffer) {
    if (buffer.length < 24) {
      throw new BadRequestException('El archivo de flyer es demasiado pequeño.');
    }
    return {
      width: buffer.readUInt32BE(16),
      height: buffer.readUInt32BE(20),
    };
  }

  private readJpegDimensions(buffer: Buffer) {
    let offset = 2;
    while (offset + 9 < buffer.length) {
      if (buffer[offset] !== 0xff) {
        break;
      }
      const marker = buffer[offset + 1];
      const length = buffer.readUInt16BE(offset + 2);
      if (length < 2) {
        break;
      }
      if (marker >= 0xc0 && marker <= 0xcf && marker !== 0xc4 && marker !== 0xcc) {
        if (offset + 7 >= buffer.length) {
          break;
        }
        const height = buffer.readUInt16BE(offset + 5);
        const width = buffer.readUInt16BE(offset + 7);
        return { width, height };
      }
      offset += 2 + length;
    }
    throw new BadRequestException('No se pudo leer las dimensiones del flyer.');
  }
}
