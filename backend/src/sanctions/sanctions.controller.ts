import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  ParseIntPipe,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { SanctionsService } from './sanctions.service';
import { CreateCardDto, CreateCardResponseDto } from './dto/card.dto';
import { CreateSuspensionDto, UpdateSuspensionDto, SuspensionResponseDto } from './dto/suspension.dto';
import { CreateDeductionDto, DeductionResponseDto } from './dto/deduction.dto';
import { UpdateDisciplinaryRulesDto, DisciplinaryRulesResponseDto } from './dto/disciplinary-rules.dto';
import { TournamentSanctionsSummaryDto } from './dto/sanctions-summary.dto';

@ApiTags('Sanciones')
@Controller()
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class SanctionsController {
  constructor(private readonly sanctionsService: SanctionsService) {}

  // ============================================================================
  // TARJETAS
  // ============================================================================

  @Post('match-categories/:id/cards')
  @ApiOperation({ summary: 'Registrar una tarjeta en un partido' })
  async createCard(
    @Param('id', ParseIntPipe) matchCategoryId: number,
    @Body() dto: CreateCardDto,
  ): Promise<CreateCardResponseDto> {
    return this.sanctionsService.createCard(matchCategoryId, dto);
  }

  // ============================================================================
  // SUSPENSIONES
  // ============================================================================

  @Get('tournaments/:id/sanctions')
  @ApiOperation({ summary: 'Obtener resumen de sanciones de un torneo' })
  async getTournamentSanctions(
    @Param('id', ParseIntPipe) tournamentId: number,
  ): Promise<TournamentSanctionsSummaryDto> {
    return this.sanctionsService.getTournamentSanctions(tournamentId);
  }

  @Post('tournaments/:id/suspensions')
  @ApiOperation({ summary: 'Crear una suspensión manualmente' })
  async createSuspension(
    @Param('id', ParseIntPipe) tournamentId: number,
    @Body() dto: CreateSuspensionDto,
    @Request() req,
  ): Promise<SuspensionResponseDto> {
    return this.sanctionsService.createSuspension(tournamentId, dto, req.user.id);
  }

  @Patch('suspensions/:id')
  @ApiOperation({ summary: 'Actualizar una suspensión (cancelar o corregir)' })
  async updateSuspension(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateSuspensionDto,
  ): Promise<SuspensionResponseDto> {
    return this.sanctionsService.updateSuspension(id, dto);
  }

  // ============================================================================
  // DEDUCCIONES DE PUNTOS
  // ============================================================================

  @Post('tournaments/:id/deductions')
  @ApiOperation({ summary: 'Crear una quita de puntos' })
  async createDeduction(
    @Param('id', ParseIntPipe) tournamentId: number,
    @Body() dto: CreateDeductionDto,
    @Request() req,
  ): Promise<DeductionResponseDto> {
    return this.sanctionsService.createDeduction(tournamentId, dto, req.user.id);
  }

  @Delete('deductions/:id')
  @ApiOperation({ summary: 'Eliminar una deducción de puntos' })
  async deleteDeduction(
    @Param('id', ParseIntPipe) id: number,
  ): Promise<{ success: boolean }> {
    await this.sanctionsService.deleteDeduction(id);
    return { success: true };
  }

  // ============================================================================
  // REGLAS DISCIPLINARIAS
  // ============================================================================

  @Get('tournaments/:id/disciplinary-rules')
  @ApiOperation({ summary: 'Obtener reglas disciplinarias del torneo' })
  async getDisciplinaryRules(
    @Param('id', ParseIntPipe) tournamentId: number,
  ): Promise<DisciplinaryRulesResponseDto> {
    return this.sanctionsService.getOrCreateDisciplinaryRules(tournamentId);
  }

  @Patch('tournaments/:id/disciplinary-rules')
  @ApiOperation({ summary: 'Actualizar reglas disciplinarias del torneo' })
  async updateDisciplinaryRules(
    @Param('id', ParseIntPipe) tournamentId: number,
    @Body() dto: UpdateDisciplinaryRulesDto,
  ): Promise<DisciplinaryRulesResponseDto> {
    return this.sanctionsService.updateDisciplinaryRules(tournamentId, dto);
  }
}
