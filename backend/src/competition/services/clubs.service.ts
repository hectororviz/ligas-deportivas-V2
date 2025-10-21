import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateClubDto } from '../dto/create-club.dto';
import { slugify } from '../../common/utils/slugify';
import { AssignClubZoneDto } from '../dto/assign-club-zone.dto';

@Injectable()
export class ClubsService {
  constructor(private readonly prisma: PrismaService) {}

  create(dto: CreateClubDto) {
    return this.prisma.club.create({
      data: {
        name: dto.name,
        shortName: dto.shortName,
        slug: dto.slug ?? slugify(dto.name),
        leagueId: dto.leagueId,
        primaryColor: dto.primaryColor,
        secondaryColor: dto.secondaryColor
      }
    });
  }

  findAll() {
    return this.prisma.club.findMany({
      orderBy: { name: 'asc' }
    });
  }

  async assignToZone(zoneId: number, dto: AssignClubZoneDto) {
    const zone = await this.prisma.zone.findUnique({
      where: { id: zoneId },
      include: {
        tournament: {
          include: {
            zones: {
              include: {
                clubZones: true
              }
            }
          }
        }
      }
    });

    if (!zone) {
      throw new BadRequestException('Zona inexistente');
    }

    const alreadyAssigned = zone.tournament.zones.some((zoneItem) =>
      zoneItem.clubZones.some((assignment) => assignment.clubId === dto.clubId)
    );

    if (alreadyAssigned) {
      throw new BadRequestException('El club ya está asignado a una zona en este torneo');
    }

    await this.prisma.clubZone.create({
      data: {
        clubId: dto.clubId,
        zoneId: zone.id
      }
    });

    return this.prisma.zone.findUnique({
      where: { id: zoneId },
      include: {
        clubZones: {
          include: { club: true }
        }
      }
    });
  }
}
