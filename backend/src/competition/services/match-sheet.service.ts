import { Injectable, NotFoundException } from '@nestjs/common';
import { Category, Gender } from '@prisma/client';

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
  tournamentName: string;
  zoneName: string;
  categoryName: string;
  homeClubName: string;
  awayClubName: string;
  homePlayers: SheetPlayer[];
  awayPlayers: SheetPlayer[];
}

@Injectable()
export class MatchSheetService {
  constructor(private readonly prisma: PrismaService) {}

  async generate(matchId: number): Promise<{ buffer: Buffer; contentType: string; fileExtension: string }> {
    const match = await this.prisma.match.findUnique({
      where: { id: matchId },
      include: {
        zone: true,
        tournament: true,
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
        tournamentName: match.tournament.name,
        zoneName: match.zone?.name ?? 'Sin zona',
        categoryName: category?.name ?? 'Categoría',
        homeClubName: match.homeClub?.name ?? 'Club local',
        awayClubName: match.awayClub?.name ?? 'Club visitante',
        homePlayers,
        awayPlayers,
      });
    }

    if (!pages.length) {
      pages.push({
        tournamentName: match.tournament.name,
        zoneName: match.zone?.name ?? 'Sin zona',
        categoryName: 'Sin categorías',
        homeClubName: match.homeClub?.name ?? 'Club local',
        awayClubName: match.awayClub?.name ?? 'Club visitante',
        homePlayers: [],
        awayPlayers: [],
      });
    }

    return {
      buffer: this.buildPdf(pages),
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

    return players.map<SheetPlayer>((player) => ({
      firstName: player.firstName,
      lastName: player.lastName,
      dni: player.dni,
    }));
  }

  private buildPdf(pages: SheetPageData[]) {
    const objects: string[] = [];
    objects.push('<< /Type /Catalog /Pages 2 0 R >>');
    objects.push('');
    objects.push('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>');

    const pageObjectNumbers: number[] = [];

    for (const page of pages) {
      const stream = this.renderPageStream(page);
      const contentObjectNumber = objects.length + 1;
      objects.push(`<< /Length ${Buffer.byteLength(stream, 'utf8')} >>\nstream\n${stream}\nendstream`);

      const pageObjectNumber = objects.length + 1;
      pageObjectNumbers.push(pageObjectNumber);
      objects.push(
        `<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ${PAGE_WIDTH} ${PAGE_HEIGHT}] /Resources << /Font << /F1 3 0 R >> >> /Contents ${contentObjectNumber} 0 R >>`,
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

  private renderPageStream(data: SheetPageData) {
    const draw = new PdfDraw();
    const fullWidth = PAGE_WIDTH - MARGIN * 2;

    let y = MARGIN;
    draw.rectTop(MARGIN, y, fullWidth, 32);
    draw.textCentered(data.tournamentName, MARGIN, y + 8, fullWidth, 17, true);

    y += 32;
    draw.rectTop(MARGIN, y, fullWidth, 22);
    draw.text(`Zona: ${data.zoneName}`, MARGIN + 8, y + 7, 10);

    y += 22;
    draw.rectTop(MARGIN, y, fullWidth, 22);
    draw.text(`Categoría: ${data.categoryName}`, MARGIN + 8, y + 7, 10);

    y += 30;
    y = this.drawTeamTable(draw, y, data.homeClubName, data.homePlayers);
    y += 12;
    y = this.drawTeamTable(draw, y, data.awayClubName, data.awayPlayers);

    y += 12;
    draw.rectTop(MARGIN, y, fullWidth, 54);
    draw.text('Observaciones', MARGIN + 6, y + 6, 10);

    y += 54;
    const colWidth = fullWidth / 3;
    draw.rectTop(MARGIN, y, colWidth, 42);
    draw.rectTop(MARGIN + colWidth, y, colWidth, 42);
    draw.rectTop(MARGIN + colWidth * 2, y, colWidth, 42);
    draw.text('Firma delegado local', MARGIN + 6, y + 6, 9);
    draw.text('Firma delegado visitante', MARGIN + colWidth + 6, y + 6, 9);
    draw.text('Observaciones', MARGIN + colWidth * 2 + 6, y + 6, 9);

    return draw.build();
  }

  private drawTeamTable(draw: PdfDraw, startY: number, clubName: string, players: SheetPlayer[]) {
    const x = MARGIN;
    const width = PAGE_WIDTH - MARGIN * 2;
    const titleHeight = 18;
    const headerHeight = 15;
    const rowHeight = 14;
    const columns = [24, 56, 88, 88, 58, 104, 42, 21, 21];
    const labels = ['Nº', 'Número', 'Apellido', 'Nombre', 'DNI', 'Firma', 'Goles', 'A', 'R'];

    let y = startY;
    draw.rectTop(x, y, width, titleHeight);
    draw.text(clubName, x + 6, y + 5, 11, true);
    draw.text('Resultado', x + width - 112, y + 5, 10, true);
    draw.rectTop(x + width - 54, y + 3, 44, titleHeight - 6);

    y += titleHeight;
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
    this.commands.push(`BT /F1 ${bold ? this.f(size + 0.2) : this.f(size)} Tf ${this.f(x)} ${this.f(y)} Td (${normalized}) Tj ET`);
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
