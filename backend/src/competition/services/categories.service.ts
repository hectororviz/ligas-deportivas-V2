import { BadRequestException, Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';

import { PrismaService } from '../../prisma/prisma.service';
import { CreateCategoryDto } from '../dto/create-category.dto';

@Injectable()
export class CategoriesService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreateCategoryDto) {
    if (dto.birthYearMin > dto.birthYearMax) {
      throw new BadRequestException('El año mínimo no puede ser mayor al máximo.');
    }

    await this.ensureUniqueName(dto.name);

    try {
      return await this.prisma.category.create({
        data: {
          name: dto.name.trim(),
          birthYearMin: dto.birthYearMin,
          birthYearMax: dto.birthYearMax,
          gender: dto.gender,
          active: dto.active ?? true,
          promotional: dto.promotional ?? false,
        },
      });
    } catch (error) {
      throw this.handlePrismaError(error);
    }
  }

  findAll() {
    return this.prisma.category.findMany({
      orderBy: { name: 'asc' },
    });
  }

  private async ensureUniqueName(name: string) {
    const trimmed = name.trim();
    const existing = await this.prisma.category.findFirst({
      where: { name: { equals: trimmed, mode: 'insensitive' } },
    });
    if (existing) {
      throw new BadRequestException(`Ya existe una categoría con el nombre "${trimmed}".`);
    }
  }

  private handlePrismaError(error: unknown): never {
    if (error instanceof Prisma.PrismaClientKnownRequestError) {
      if (error.code === 'P2002') {
        const target = Array.isArray(error.meta?.target)
          ? (error.meta?.target[0] as string)
          : (error.meta?.target as string | undefined);
        if (target && target.includes('name')) {
          throw new BadRequestException('Ya existe una categoría con ese nombre.');
        }
      }
    }
    throw error;
  }
}
