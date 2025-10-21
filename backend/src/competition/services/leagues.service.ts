import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateLeagueDto } from '../dto/create-league.dto';
import { UpdateLeagueDto } from '../dto/update-league.dto';
import { slugify } from '../../common/utils/slugify';

@Injectable()
export class LeaguesService {
  constructor(private readonly prisma: PrismaService) {}

  create(dto: CreateLeagueDto) {
    return this.prisma.league.create({
      data: {
        name: dto.name,
        slug: dto.slug ?? slugify(dto.name),
        colorHex: dto.colorHex
      }
    });
  }

  findAll() {
    return this.prisma.league.findMany({
      orderBy: { name: 'asc' }
    });
  }

  findOne(id: number) {
    return this.prisma.league.findUnique({
      where: { id },
      include: {
        tournaments: true
      }
    });
  }

  update(id: number, dto: UpdateLeagueDto) {
    const data: any = { ...dto };
    if (dto.name && !dto.slug) {
      data.slug = slugify(dto.name);
    }
    return this.prisma.league.update({
      where: { id },
      data
    });
  }
}
