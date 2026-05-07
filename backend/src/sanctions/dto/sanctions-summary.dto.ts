import { CardResponseDto } from './card.dto';
import { SuspensionResponseDto } from './suspension.dto';
import { DeductionResponseDto } from './deduction.dto';

export class TournamentSanctionsSummaryDto {
  pending: CardResponseDto[];
  active: SuspensionResponseDto[];
  completed: SuspensionResponseDto[];  // Sanciones cumplidas
  cancelled: SuspensionResponseDto[];  // Sanciones canceladas
  deductions: DeductionResponseDto[];  // Deducciones de puntos
}
