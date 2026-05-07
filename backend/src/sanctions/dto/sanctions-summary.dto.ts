import { CardResponseDto } from './card.dto';
import { SuspensionResponseDto } from './suspension.dto';
import { DeductionResponseDto } from './deduction.dto';

export class TournamentSanctionsSummaryDto {
  pending: CardResponseDto[];
  active: SuspensionResponseDto[];
  history: (SuspensionResponseDto | DeductionResponseDto)[];
}
