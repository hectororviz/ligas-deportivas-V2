import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { RequestEmailChangeDto } from './dto/request-email-change.dto';
import { ConfirmEmailChangeDto } from './dto/confirm-email-change.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { RateLimiterService } from '../common/services/rate-limiter.service';
import { MailService } from '../mail/mail.service';
import { randomBytes } from 'crypto';
import * as argon2 from 'argon2';
import { StorageService } from '../storage/storage.service';

const AVATAR_SIZES = [48, 96, 256];
const MAX_AVATAR_BYTES = 2 * 1024 * 1024;
const MAX_DIMENSION = 2048;

interface ImageInfo {
  mime: string;
  width: number;
  height: number;
}

@Injectable()
export class MeService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly rateLimiter: RateLimiterService,
    private readonly mailService: MailService,
    private readonly storageService: StorageService
  ) {}

  async getProfile(userId: number) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        language: true,
        avatarHash: true,
        avatarUpdatedAt: true
      }
    });

    if (!user) {
      throw new NotFoundException('Usuario no encontrado');
    }

    return {
      id: user.id,
      email: user.email,
      name: this.combineName(user.firstName, user.lastName),
      language: user.language,
      avatar: this.buildAvatarUrls(user.id, user.avatarHash, user.avatarUpdatedAt)
    };
  }

  async updateProfile(userId: number, dto: UpdateProfileDto) {
    const { firstName, lastName } = this.splitName(dto.name);
    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: {
        firstName,
        lastName,
        language: dto.language
      }
    });

    return {
      id: updated.id,
      email: updated.email,
      name: this.combineName(updated.firstName, updated.lastName),
      language: updated.language,
      avatar: this.buildAvatarUrls(updated.id, updated.avatarHash, updated.avatarUpdatedAt)
    };
  }

  async requestEmailChange(userId: number, dto: RequestEmailChangeDto) {
    const newEmail = dto.newEmail.toLowerCase();
    this.rateLimiter.consume(`email-change:${userId}`, 5, 15 * 60 * 1000);

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, email: true, firstName: true }
    });

    if (!user) {
      throw new NotFoundException('Usuario no encontrado');
    }

    if (user.email === newEmail) {
      throw new BadRequestException('El correo nuevo debe ser diferente.');
    }

    const existing = await this.prisma.user.findUnique({ where: { email: newEmail } });
    if (existing) {
      throw new BadRequestException('El correo ya está en uso.');
    }

    const token = randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 1000 * 60 * 60 * 24);

    await this.prisma.$transaction([
      this.prisma.emailChangeRequest.deleteMany({ where: { userId } }),
      this.prisma.emailChangeRequest.create({
        data: {
          userId,
          newEmail,
          token,
          expiresAt
        }
      })
    ]);

    await this.mailService.sendEmailChangeConfirmation(user.email, newEmail, token, user.firstName);

    return { success: true };
  }

  async confirmEmailChange(userId: number, dto: ConfirmEmailChangeDto) {
    const record = await this.prisma.emailChangeRequest.findFirst({
      where: {
        token: dto.token,
        userId,
        confirmedAt: null
      }
    });

    if (!record || record.expiresAt < new Date()) {
      throw new BadRequestException('Token inválido o expirado.');
    }

    await this.prisma.$transaction([
      this.prisma.emailChangeRequest.update({
        where: { id: record.id },
        data: { confirmedAt: new Date() }
      }),
      this.prisma.user.update({
        where: { id: userId },
        data: { email: record.newEmail }
      }),
      this.prisma.userToken.deleteMany({ where: { userId } })
    ]);

    return { success: true };
  }

  async changePassword(userId: number, dto: ChangePasswordDto) {
    this.rateLimiter.consume(`password-change:${userId}`, 5, 60 * 60 * 1000);

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('Usuario no encontrado');
    }

    const valid = await argon2.verify(user.passwordHash, dto.currentPassword);
    if (!valid) {
      throw new BadRequestException('La contraseña actual es incorrecta.');
    }

    const newHash = await argon2.hash(dto.newPassword, {
      type: argon2.argon2id
    });

    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: userId },
        data: { passwordHash: newHash }
      }),
      this.prisma.userToken.deleteMany({ where: { userId } })
    ]);

    await this.mailService.sendPasswordChangeConfirmation(user.email, user.firstName);

    return { success: true };
  }

  async updateAvatar(userId: number, file: Express.Multer.File) {
    this.rateLimiter.consume(`avatar-upload:${userId}`, 10, 60 * 60 * 1000);

    if (!file) {
      throw new BadRequestException('No se recibió un archivo.');
    }

    if (file.size > MAX_AVATAR_BYTES) {
      throw new BadRequestException('La imagen supera los 2 MB permitidos.');
    }

    const info = this.inspectImage(file.buffer);
    if (info.width !== info.height) {
      throw new BadRequestException('La imagen debe ser cuadrada.');
    }
    if (info.width > MAX_DIMENSION || info.height > MAX_DIMENSION) {
      throw new BadRequestException('La imagen es demasiado grande.');
    }

    const hash = randomBytes(10).toString('hex');

    await this.storageService.clearAvatarVariants(userId);
    const variantKeys = await this.saveAvatarFiles(userId, hash, file.buffer);

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: {
        avatarHash: hash,
        avatarUpdatedAt: new Date(),
        avatarMime: info.mime
      }
    });

    return {
      avatar: this.buildAvatarUrls(updated.id, updated.avatarHash, updated.avatarUpdatedAt, variantKeys)
    };
  }

  private async saveAvatarFiles(userId: number, hash: string, buffer: Buffer) {
    const keys: Record<number, string> = {};
    for (const size of AVATAR_SIZES) {
      const key = await this.storageService.saveAvatarVariant({
        userId,
        hash,
        size,
        buffer
      });
      keys[size] = key;
    }
    return keys;
  }

  private splitName(name: string) {
    const trimmed = name.trim().replace(/\s+/g, ' ');
    if (!trimmed.includes(' ')) {
      return { firstName: trimmed, lastName: '' };
    }
    const parts = trimmed.split(' ');
    const firstName = parts.shift() ?? trimmed;
    const lastName = parts.join(' ').trim() || '-';
    return { firstName, lastName };
  }

  private combineName(firstName: string, lastName: string) {
    return `${firstName} ${lastName}`.replace(/\s+/g, ' ').trim();
  }

  private buildAvatarUrls(userId: number, hash: string | null, updatedAt?: Date | null, override?: Record<number, string>) {
    if (!hash) {
      return null;
    }
    const map: Record<string, string> = {};
    for (const size of AVATAR_SIZES) {
      const relativeKey = override?.[size] ?? `avatars/${userId}/${hash}_${size}.jpg`;
      const url = this.storageService.getPublicUrl(relativeKey);
      const version = updatedAt ? updatedAt.getTime() : Date.now();
      map[size.toString()] = `${url}?v=${version}`;
    }
    return map;
  }

  private inspectImage(buffer: Buffer): ImageInfo {
    if (buffer.length < 12) {
      throw new BadRequestException('Archivo inválido');
    }

    if (buffer[0] === 0xff && buffer[1] === 0xd8) {
      return this.inspectJpeg(buffer);
    }
    if (buffer.slice(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) {
      return this.inspectPng(buffer);
    }
    if (buffer.slice(0, 4).toString('ascii') === 'RIFF' && buffer.slice(8, 12).toString('ascii') === 'WEBP') {
      return this.inspectWebp(buffer);
    }

    throw new BadRequestException('Formato de imagen no soportado. Usa JPEG, PNG o WebP.');
  }

  private inspectJpeg(buffer: Buffer): ImageInfo {
    let offset = 2;
    while (offset < buffer.length) {
      if (buffer[offset] !== 0xff) {
        break;
      }
      const marker = buffer[offset + 1];
      const length = buffer.readUInt16BE(offset + 2);
      if (marker >= 0xc0 && marker <= 0xc3) {
        const height = buffer.readUInt16BE(offset + 5);
        const width = buffer.readUInt16BE(offset + 7);
        return { mime: 'image/jpeg', width, height };
      }
      offset += 2 + length;
    }
    throw new BadRequestException('No se pudo leer la imagen JPEG.');
  }

  private inspectPng(buffer: Buffer): ImageInfo {
    const width = buffer.readUInt32BE(16);
    const height = buffer.readUInt32BE(20);
    return { mime: 'image/png', width, height };
  }

  private inspectWebp(buffer: Buffer): ImageInfo {
    let offset = 12;
    while (offset + 8 <= buffer.length) {
      const chunkType = buffer.slice(offset, offset + 4).toString('ascii');
      const chunkSize = buffer.readUInt32LE(offset + 4);
      const chunkDataStart = offset + 8;
      if (chunkType === 'VP8X' && chunkSize >= 10) {
        const width = 1 + buffer.readUIntLE(chunkDataStart + 4, 3);
        const height = 1 + buffer.readUIntLE(chunkDataStart + 7, 3);
        return { mime: 'image/webp', width, height };
      }
      if (chunkType === 'VP8 ' && chunkSize >= 10) {
        const frameStart = chunkDataStart + 3;
        if (buffer[frameStart] === 0x9d && buffer[frameStart + 1] === 0x01 && buffer[frameStart + 2] === 0x2a) {
          const width = buffer.readUInt16LE(frameStart + 3);
          const height = buffer.readUInt16LE(frameStart + 5);
          return { mime: 'image/webp', width, height };
        }
      }
      if (chunkType === 'VP8L' && chunkSize >= 5) {
        const signature = buffer[chunkDataStart];
        if (signature === 0x2f) {
          const bits = buffer.readUInt32LE(chunkDataStart + 1);
          const width = (bits & 0x3fff) + 1;
          const height = ((bits >> 14) & 0x3fff) + 1;
          return { mime: 'image/webp', width, height };
        }
      }
      offset += 8 + chunkSize + (chunkSize % 2);
    }
    throw new BadRequestException('No se pudo leer la imagen WebP.');
  }
}
