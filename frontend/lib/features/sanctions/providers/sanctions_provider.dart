import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/api_client.dart';
import '../domain/sanctions_models.dart';

// Provider para el servicio de sanciones
final sanctionsServiceProvider = Provider<SanctionsService>((ref) {
  return SanctionsService(ref.read(apiClientProvider));
});

// Provider para las sanciones de un torneo
final tournamentSanctionsProvider = FutureProvider.family<TournamentSanctionsSummary, int>((ref, tournamentId) async {
  final service = ref.read(sanctionsServiceProvider);
  return service.getTournamentSanctions(tournamentId);
});

// Provider para las reglas disciplinarias
final disciplinaryRulesProvider = FutureProvider.family<DisciplinaryRules, int>((ref, tournamentId) async {
  final service = ref.read(sanctionsServiceProvider);
  return service.getDisciplinaryRules(tournamentId);
});

class SanctionsService {
  final ApiClient _api;

  SanctionsService(this._api);

  // Tarjetas
  Future<CreateCardResponse> createCard(int matchCategoryId, CreateCardDto dto) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/match-categories/$matchCategoryId/cards',
      data: dto.toJson(),
    );
    return CreateCardResponse.fromJson(response.data!);
  }

  // Suspensiones
  Future<TournamentSanctionsSummary> getTournamentSanctions(int tournamentId) async {
    final response = await _api.get<Map<String, dynamic>>(
      '/tournaments/$tournamentId/sanctions',
    );
    return TournamentSanctionsSummary.fromJson(response.data!);
  }

  Future<PlayerSuspension> createSuspension(int tournamentId, CreateSuspensionDto dto) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/tournaments/$tournamentId/suspensions',
      data: dto.toJson(),
    );
    return PlayerSuspension.fromJson(response.data!);
  }

  Future<PlayerSuspension> updateSuspension(int suspensionId, UpdateSuspensionDto dto) async {
    final response = await _api.patch<Map<String, dynamic>>(
      '/suspensions/$suspensionId',
      data: dto.toJson(),
    );
    return PlayerSuspension.fromJson(response.data!);
  }

  // Deducciones
  Future<PointDeduction> createDeduction(int tournamentId, CreateDeductionDto dto) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/tournaments/$tournamentId/deductions',
      data: dto.toJson(),
    );
    return PointDeduction.fromJson(response.data!);
  }

  Future<void> deleteDeduction(int deductionId) async {
    await _api.delete('/deductions/$deductionId');
  }

  // Reglas disciplinarias
  Future<DisciplinaryRules> getDisciplinaryRules(int tournamentId) async {
    final response = await _api.get<Map<String, dynamic>>(
      '/tournaments/$tournamentId/disciplinary-rules',
    );
    return DisciplinaryRules.fromJson(response.data!);
  }

  Future<DisciplinaryRules> updateDisciplinaryRules(
    int tournamentId,
    UpdateDisciplinaryRulesDto dto,
  ) async {
    final response = await _api.patch<Map<String, dynamic>>(
      '/tournaments/$tournamentId/disciplinary-rules',
      data: dto.toJson(),
    );
    return DisciplinaryRules.fromJson(response.data!);
  }
}

// Providers para invalidar datos
class SanctionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  SanctionsNotifier(this._ref) : super(const AsyncValue.data(null));

  void invalidateTournamentSanctions(int tournamentId) {
    _ref.invalidate(tournamentSanctionsProvider(tournamentId));
  }

  void invalidateDisciplinaryRules(int tournamentId) {
    _ref.invalidate(disciplinaryRulesProvider(tournamentId));
  }
}

final sanctionsNotifierProvider = StateNotifierProvider<SanctionsNotifier, AsyncValue<void>>((ref) {
  return SanctionsNotifier(ref);
});
