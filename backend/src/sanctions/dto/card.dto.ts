import { IsEnum, IsInt, IsOptional, IsString, Min, Max } from 'class-validator';
import { CardType } from '@prisma/client';

export class CreateCardDto {
  @IsInt()
  playerId: number;

  @IsInt()
  clubId: number;

  @IsEnum(CardType)
  cardType: CardType;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(120)
  minute?: number;
}

export class CardResponseDto {
  id: number;
  matchCategoryId: number;
  playerId: number;
  clubId: number;
  cardType: CardType;
  minute: number | null;
  disciplinaryStatus: string;
  createdAt: Date;
  player?: {
    id: number;
    firstName: string;
    lastName: string;
    dni: string;
  };
  club?: {
    id: number;
    name: string;
  };
  // Campos adicionales para UI
  canSuspend?: boolean;
  yellowCount?: number;
  matchCategory?: {
    id: number;
    match?: {
      id: number;
      matchday: number;
      round?: string;
      date?: Date;
      homeClub?: {
        id: number;
        name: string;
      };
      awayClub?: {
        id: number;
        name: string;
      };
    };
  };
}

export class CardAlertDto {
  type: 'YELLOW_LIMIT' | 'DIRECT_RED' | 'DOUBLE_YELLOW' | null;
  yellowCount: number;
}

export class CreateCardResponseDto {
  card: CardResponseDto;
  alert: CardAlertDto;
}
