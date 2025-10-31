import { Injectable, NotFoundException } from '@nestjs/common';
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
  ): Promise<SiteIdentityResponse> {
    const existing = await this.ensureIdentity();
    let iconKey: string | null | undefined;

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

    const updated = await this.prisma.siteIdentity.upsert({
      where: { id: existing.id },
      update: {
        title: dto.title,
        iconKey: iconKey !== undefined ? iconKey : existing.iconKey,
      },
      create: {
        id: existing.id,
        title: dto.title,
        iconKey: iconKey ?? null,
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

  private async ensureIdentity(): Promise<SiteIdentity> {
    const existing = await this.prisma.siteIdentity.findUnique({ where: { id: 1 } });
    if (existing) {
      return existing;
    }
    return this.prisma.siteIdentity.create({
      data: {
        id: 1,
        title: 'Ligas Deportivas',
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
    return {
      title: identity.title,
      iconUrl,
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
}
