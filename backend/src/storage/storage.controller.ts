import { Controller, Get, NotFoundException, Param, ParseIntPipe, Res } from '@nestjs/common';
import { Response } from 'express';
import { PrismaService } from '../prisma/prisma.service';
import { promises as fs } from 'fs';
import * as path from 'path';

@Controller('storage/avatars')
export class StorageController {
  constructor(private readonly prisma: PrismaService) {}

  @Get(':userId/:file')
  async serveAvatar(
    @Param('userId', ParseIntPipe) userId: number,
    @Param('file') file: string,
    @Res() res: Response
  ) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { avatarHash: true, avatarMime: true }
    });

    if (!user || !user.avatarHash || !file.startsWith(`${user.avatarHash}_`)) {
      throw new NotFoundException();
    }

    const filePath = path.join(process.cwd(), 'storage', 'avatars', String(userId), file);
    try {
      await fs.access(filePath);
    } catch {
      throw new NotFoundException();
    }

    res.setHeader('Cache-Control', 'public, max-age=86400');
    res.type(user.avatarMime ?? 'image/jpeg');
    return res.sendFile(filePath);
  }
}
