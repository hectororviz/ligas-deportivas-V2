import { Injectable, NotFoundException } from '@nestjs/common';
import { Category, Gender } from '@prisma/client';
import axios from 'axios';
import { promises as fs } from 'node:fs';
import path from 'node:path';
import sharp from 'sharp';

import { PrismaService } from '../../prisma/prisma.service';

const PAGE_WIDTH = 595.28;
const PAGE_HEIGHT = 841.89;
const MARGIN = 36;
const ROWS_PER_TEAM = 14;

interface SheetPlayer {
  firstName: string;
  lastName: string;
  dni: string;
}

interface SheetPageData {
  leagueName: string;
  tournamentName: string;
  tournamentYear: number;
  zoneName: string;
  categoryName: string;
  homeClubName: string;
  awayClubName: string;
  homeClubLogoUrl: string | null;
  awayClubLogoUrl: string | null;
  homePlayers: SheetPlayer[];
  awayPlayers: SheetPlayer[];
}

interface PdfImageObject {
  name: string;
  width: number;
  height: number;
  object: string;
}

interface PreparedPage {
  stream: string;
  images: PdfImageObject[];
}

@Injectable()
export class MatchSheetService {
  constructor(private readonly prisma: PrismaService) {}

  async generate(
    matchId: number,
  ): Promise<{ buffer: Buffer; contentType: string; fileExtension: string }> {
    const match = await this.prisma.match.findUnique({
      where: { id: matchId },
      include: {
        zone: true,
        tournament: {
          include: {
            league: true,
          },
        },
        homeClub: true,
        awayClub: true,
        categories: {
          include: {
            tournamentCategory: {
              include: {
                category: true,
              },
            },
          },
          orderBy: [{ kickoffTime: 'asc' }, { id: 'asc' }],
        },
      },
    });

    if (!match) {
      throw new NotFoundException('Partido no encontrado.');
    }

    const pages: SheetPageData[] = [];
    for (const matchCategory of match.categories) {
      const category = matchCategory.tournamentCategory?.category;
      const [homePlayers, awayPlayers] = await Promise.all([
        this.findPlayersForSheet(match.homeClub, match.tournament.id, category),
        this.findPlayersForSheet(match.awayClub, match.tournament.id, category),
      ]);
      pages.push({
        leagueName: match.tournament.league?.name ?? 'Liga',
        tournamentName: match.tournament.name,
        tournamentYear: match.tournament.year,
        zoneName: match.zone?.name ?? 'Sin zona',
        categoryName: category?.name ?? 'Categoría',
        homeClubName: match.homeClub?.name ?? 'Club local',
        awayClubName: match.awayClub?.name ?? 'Club visitante',
        homeClubLogoUrl: match.homeClub?.logoUrl ?? null,
        awayClubLogoUrl: match.awayClub?.logoUrl ?? null,
        homePlayers,
        awayPlayers,
      });
    }

    if (!pages.length) {
      pages.push({
        leagueName: match.tournament.league?.name ?? 'Liga',
        tournamentName: match.tournament.name,
        tournamentYear: match.tournament.year,
        zoneName: match.zone?.name ?? 'Sin zona',
        categoryName: 'Sin categorías',
        homeClubName: match.homeClub?.name ?? 'Club local',
        awayClubName: match.awayClub?.name ?? 'Club visitante',
        homeClubLogoUrl: match.homeClub?.logoUrl ?? null,
        awayClubLogoUrl: match.awayClub?.logoUrl ?? null,
        homePlayers: [],
        awayPlayers: [],
      });
    }

    return {
      buffer: await this.buildPdf(pages),
      contentType: 'application/pdf',
      fileExtension: 'pdf',
    };
  }

  private async findPlayersForSheet(
    club: { id: number } | null,
    tournamentId: number,
    category: Category | null | undefined,
  ) {
    if (!club || !category) {
      return [];
    }

    const where: Parameters<typeof this.prisma.player.findMany>[0]['where'] = {
      playerTournamentClubs: {
        some: {
          clubId: club.id,
          tournamentId,
        },
      },
      active: true,
      birthDate: {
        gte: new Date(Date.UTC(category.birthYearMin, 0, 1)),
        lte: new Date(Date.UTC(category.birthYearMax, 11, 31, 23, 59, 59, 999)),
      },
    };

    if (category.gender !== Gender.MIXTO) {
      where.gender = category.gender;
    }

    const players = await this.prisma.player.findMany({
      where,
      orderBy: [{ lastName: 'asc' }, { firstName: 'asc' }],
      take: ROWS_PER_TEAM,
    });

    const sortedPlayers = [...players].sort((left, right) => {
      const leftLastName = left.lastName.toLocaleLowerCase('es-AR');
      const rightLastName = right.lastName.toLocaleLowerCase('es-AR');
      if (leftLastName !== rightLastName) {
        return leftLastName.localeCompare(rightLastName, 'es-AR');
      }

      const leftFirstName = left.firstName.toLocaleLowerCase('es-AR');
      const rightFirstName = right.firstName.toLocaleLowerCase('es-AR');
      return leftFirstName.localeCompare(rightFirstName, 'es-AR');
    });

    return sortedPlayers.map<SheetPlayer>((player) => ({
      firstName: player.firstName,
      lastName: player.lastName,
      dni: player.dni,
    }));
  }

  private async buildPdf(pages: SheetPageData[]) {
    const objects: string[] = [];
    objects.push('<< /Type /Catalog /Pages 2 0 R >>');
    objects.push('');
    objects.push('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>');

    const pageObjectNumbers: number[] = [];

    for (const page of pages) {
      const preparedPage = await this.renderPageStream(page);
      const imageResourceRefs: string[] = [];
      for (const image of preparedPage.images) {
        const imageObjectNumber = objects.length + 1;
        objects.push(image.object);
        imageResourceRefs.push(`/${image.name} ${imageObjectNumber} 0 R`);
      }

      const xObjectResources = imageResourceRefs.length
        ? ` /XObject << ${imageResourceRefs.join(' ')} >>`
        : '';

      const contentObjectNumber = objects.length + 1;
      objects.push(
        `<< /Length ${Buffer.byteLength(preparedPage.stream, 'utf8')} >>\nstream\n${preparedPage.stream}\nendstream`,
      );

      const pageObjectNumber = objects.length + 1;
      pageObjectNumbers.push(pageObjectNumber);
      objects.push(
        `<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ${PAGE_WIDTH} ${PAGE_HEIGHT}] /Resources << /Font << /F1 3 0 R >>${xObjectResources} >> /Contents ${contentObjectNumber} 0 R >>`,
      );
    }

    objects[1] = `<< /Type /Pages /Count ${pageObjectNumbers.length} /Kids [${pageObjectNumbers.map((num) => `${num} 0 R`).join(' ')}] >>`;

    let pdf = '%PDF-1.4\n';
    const offsets: number[] = [0];

    for (let i = 0; i < objects.length; i += 1) {
      offsets.push(Buffer.byteLength(pdf, 'utf8'));
      pdf += `${i + 1} 0 obj\n${objects[i]}\nendobj\n`;
    }

    const xrefStart = Buffer.byteLength(pdf, 'utf8');
    pdf += `xref\n0 ${objects.length + 1}\n`;
    pdf += '0000000000 65535 f \n';
    for (let i = 1; i <= objects.length; i += 1) {
      pdf += `${offsets[i].toString().padStart(10, '0')} 00000 n \n`;
    }

    pdf += `trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n${xrefStart}\n%%EOF`;
    return Buffer.from(pdf, 'utf8');
  }

  private async renderPageStream(data: SheetPageData): Promise<PreparedPage> {
    const draw = new PdfDraw();
    const fullWidth = PAGE_WIDTH - MARGIN * 2;
    const headerHeight = 90;
    const logoSize = 84;

    const [homeLogo, awayLogo] = await Promise.all([
      this.loadLogoForPdf(data.homeClubLogoUrl, logoSize),
      this.loadLogoForPdf(data.awayClubLogoUrl, logoSize),
    ]);

    const images: PdfImageObject[] = [];

    let y = MARGIN;
    const logoTop = y + (headerHeight - logoSize) / 2;
    if (homeLogo) {
      const imageName = 'ImHome';
      images.push({
        name: imageName,
        width: homeLogo.width,
        height: homeLogo.height,
        object: this.buildImageObject(homeLogo.width, homeLogo.height, homeLogo.jpeg),
      });
      draw.image(imageName, MARGIN + 4, logoTop, homeLogo.width, homeLogo.height);
    }
    if (awayLogo) {
      const imageName = 'ImAway';
      images.push({
        name: imageName,
        width: awayLogo.width,
        height: awayLogo.height,
        object: this.buildImageObject(awayLogo.width, awayLogo.height, awayLogo.jpeg),
      });
      draw.image(
        imageName,
        MARGIN + fullWidth - awayLogo.width - 4,
        logoTop,
        awayLogo.width,
        awayLogo.height,
      );
    }
    draw.textCentered(
      `${data.leagueName} - ${data.tournamentName} ${data.tournamentYear}`,
      MARGIN + logoSize + 12,
      y + 36,
      fullWidth - (logoSize + 12) * 2,
      18,
      true,
    );

    y += headerHeight;
    draw.rectTop(MARGIN, y, fullWidth, 22);
    draw.text(`Zona: ${data.zoneName}`, MARGIN + 8, y + 7, 10);
    draw.textRight(`Categoría: ${data.categoryName}`, MARGIN + fullWidth - 8, y + 7, 10);

    y += 30;
    y = this.drawTeamTable(draw, y, data.homeClubName, data.homePlayers);
    y += 12;
    y = this.drawTeamTable(draw, y, data.awayClubName, data.awayPlayers);

    y += 12;
    draw.rectTop(MARGIN, y, fullWidth, 54);
    draw.text('Observaciones', MARGIN + 6, y + 6, 10);

    y += 54;
    const colWidth = fullWidth / 3;
    draw.rectTop(MARGIN, y, colWidth, 54);
    draw.rectTop(MARGIN + colWidth, y, colWidth, 54);
    draw.rectTop(MARGIN + colWidth * 2, y, colWidth, 54);
    draw.text('Firma delegado local', MARGIN + 6, y + 6, 9);
    draw.text('Firma delegado visitante', MARGIN + colWidth + 6, y + 6, 9);
    draw.text('Observaciones', MARGIN + colWidth * 2 + 6, y + 6, 9);

    return {
      stream: draw.build(),
      images,
    };
  }

  private drawTeamTable(draw: PdfDraw, startY: number, clubName: string, players: SheetPlayer[]) {
    const x = MARGIN;
    const width = PAGE_WIDTH - MARGIN * 2;
    const titleHeight = 18;
    const headerHeight = 15;
    const rowHeight = 14;
    const columns = [24, 56, 88, 88, 58, 104, 63, 21, 21];
    const usedWidth = columns.reduce((total, colWidth) => total + colWidth, 0);
    columns[6] += width - usedWidth;
    const labels = ['Nº', 'Número', 'Apellido', 'Nombre', 'DNI', 'Firma', 'Goles', 'A', 'R'];

    let y = startY;
    draw.rectTop(x, y, width, titleHeight);
    draw.text(clubName, x + 6, y + 5, 11, true);
    draw.text('Resultado', x + width - 112, y + 5, 10, true);
    draw.rectTop(x + width - 54, y + 3, 44, titleHeight - 6);

    y += titleHeight + 4;
    let cursorX = x;
    for (let i = 0; i < columns.length; i += 1) {
      const colWidth = columns[i];
      draw.rectTop(cursorX, y, colWidth, headerHeight);
      draw.textCentered(labels[i], cursorX, y + 4, colWidth, 9, true);
      cursorX += colWidth;
    }

    y += headerHeight;
    for (let row = 0; row < ROWS_PER_TEAM; row += 1) {
      const player = players[row];
      const rowData = [
        String(row + 1),
        '',
        player?.lastName ?? '',
        player?.firstName ?? '',
        player?.dni ?? '',
        '',
        '',
        '',
        '',
      ];

      cursorX = x;
      for (let col = 0; col < columns.length; col += 1) {
        const colWidth = columns[col];
        draw.rectTop(cursorX, y, colWidth, rowHeight);
        if (col === 0) {
          draw.textCentered(rowData[col], cursorX, y + 3, colWidth, 8);
        } else {
          draw.text(rowData[col], cursorX + 2, y + 3, 8);
        }
        cursorX += colWidth;
      }
      y += rowHeight;
    }

    return y;
  }

  private buildImageObject(width: number, height: number, jpeg: Buffer) {
    const jpegHex = `${jpeg.toString('hex')}>`;
    return `<< /Type /XObject /Subtype /Image /Width ${width} /Height ${height} /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter [/ASCIIHexDecode /DCTDecode] /Length ${jpegHex.length} >>\nstream\n${jpegHex}\nendstream`;
  }

  private async loadLogoForPdf(logoUrl: string | null, maxSize: number) {
    if (!logoUrl) {
      return null;
    }

    const logoBuffer = await this.readLogoBuffer(logoUrl);
    if (!logoBuffer) {
      return null;
    }

    const { data, info } = await sharp(logoBuffer)
      .flatten({ background: '#ffffff' })
      .resize({ width: maxSize, height: maxSize, fit: 'inside' })
      .jpeg({ quality: 85 })
      .toBuffer({ resolveWithObject: true });

    return {
      jpeg: data,
      width: info.width,
      height: info.height,
    };
  }

  private async readLogoBuffer(logoUrl: string) {
    try {
      if (logoUrl.startsWith('http://') || logoUrl.startsWith('https://')) {
        const response = await axios.get<ArrayBuffer>(logoUrl, {
          responseType: 'arraybuffer',
          timeout: 5000,
        });
        return Buffer.from(response.data);
      }

      const normalized = logoUrl.startsWith('/') ? logoUrl.slice(1) : logoUrl;
      if (normalized.startsWith('uploads/')) {
        const filePath = path.resolve(process.cwd(), 'storage', normalized);
        return await fs.readFile(filePath);
      }

      const uploadIndex = normalized.indexOf('uploads/');
      if (uploadIndex >= 0) {
        const relativeUploadPath = normalized.slice(uploadIndex);
        const filePath = path.resolve(process.cwd(), 'storage', relativeUploadPath);
        return await fs.readFile(filePath);
      }

      return null;
    } catch {
      return null;
    }
  }
}

class PdfDraw {
  private commands: string[] = ['0.4 w'];

  rectTop(x: number, topY: number, width: number, height: number) {
    const y = this.toPdfY(topY + height);
    this.commands.push(`${this.f(x)} ${this.f(y)} ${this.f(width)} ${this.f(height)} re S`);
  }

  text(value: string, x: number, topY: number, size: number, bold = false) {
    const normalized = this.normalizeText(value);
    if (!normalized) {
      return;
    }
    const y = this.toPdfY(topY + size);
    this.commands.push(
      `BT /F1 ${bold ? this.f(size + 0.2) : this.f(size)} Tf ${this.f(x)} ${this.f(y)} Td (${normalized}) Tj ET`,
    );
  }

  textCentered(value: string, x: number, topY: number, width: number, size: number, bold = false) {
    const normalized = this.normalizeText(value);
    if (!normalized) {
      return;
    }
    const approxWidth = normalized.length * size * 0.48;
    const left = x + Math.max(0, (width - approxWidth) / 2);
    this.text(normalized, left, topY, size, bold);
  }

  image(name: string, x: number, topY: number, width: number, height: number) {
    const y = this.toPdfY(topY + height);
    this.commands.push(
      `q ${this.f(width)} 0 0 ${this.f(height)} ${this.f(x)} ${this.f(y)} cm /${name} Do Q`,
    );
  }

  textRight(value: string, rightX: number, topY: number, size: number, bold = false) {
    const normalized = this.normalizeText(value);
    if (!normalized) {
      return;
    }
    const approxWidth = normalized.length * size * 0.48;
    this.text(normalized, rightX - approxWidth, topY, size, bold);
  }
  build() {
    return this.commands.join('\n');
  }

  private toPdfY(topValue: number) {
    return PAGE_HEIGHT - topValue;
  }

  private f(value: number) {
    return value.toFixed(2);
  }

  private normalizeText(value: string) {
    return value
      .replace(/[\u2018\u2019]/g, "'")
      .replace(/[\u201C\u201D]/g, '"')
      .replace(/[–—]/g, '-')
      .replace(/á/g, 'a')
      .replace(/é/g, 'e')
      .replace(/í/g, 'i')
      .replace(/ó/g, 'o')
      .replace(/ú/g, 'u')
      .replace(/Á/g, 'A')
      .replace(/É/g, 'E')
      .replace(/Í/g, 'I')
      .replace(/Ó/g, 'O')
      .replace(/Ú/g, 'U')
      .replace(/ñ/g, 'n')
      .replace(/Ñ/g, 'N')
      .replace(/º/g, 'o')
      .replace(/[\r\n\t]/g, ' ')
      .replace(/\\/g, '\\\\')
      .replace(/\(/g, '\\(')
      .replace(/\)/g, '\\)')
      .trim();
  }
}
