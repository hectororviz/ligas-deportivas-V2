import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/responsive.dart';
import '../../../services/api_client.dart';
import '../../../services/auth_controller.dart';
import '../domain/zone_models.dart';
import '../domain/zone_match_models.dart';
import 'zone_providers.dart';
import 'zones_page.dart';

const _moduleFixture = 'FIXTURE';
const _actionUpdate = 'UPDATE';

enum FixtureGenerationMode { automatic, manual }

class ZoneFixturePageArgs {
  const ZoneFixturePageArgs({this.viewOnly = false});

  final bool viewOnly;
}

class ZoneFixturePage extends ConsumerStatefulWidget {
  const ZoneFixturePage({super.key, required this.zoneId, this.viewOnly = false});

  final int zoneId;
  final bool viewOnly;

  @override
  ConsumerState<ZoneFixturePage> createState() => _ZoneFixturePageState();
}

class _ZoneFixturePageState extends ConsumerState<ZoneFixturePage> {
  late final ScrollController _contentScrollController;
  ZoneFixturePreview? _preview;
  bool _loadingPreview = false;
  bool _submitting = false;
  String? _previewError;
  final Set<int> _finalizingMatchdays = <int>{};
  final Set<int> _updatingMatchdays = <int>{};
  FixtureGenerationMode _generationMode = FixtureGenerationMode.automatic;

  bool _isFinalizing(int matchday) => _finalizingMatchdays.contains(matchday);
  bool _isUpdatingDate(int matchday) => _updatingMatchdays.contains(matchday);

  FixtureMatchdayStatus _mapFixtureStatus(ZoneMatchdayStatus status) {
    switch (status) {
      case ZoneMatchdayStatus.inProgress:
        return FixtureMatchdayStatus.inProgress;
      case ZoneMatchdayStatus.incomplete:
        return FixtureMatchdayStatus.incomplete;
      case ZoneMatchdayStatus.played:
        return FixtureMatchdayStatus.played;
      case ZoneMatchdayStatus.pending:
      default:
        return FixtureMatchdayStatus.pending;
    }
  }

  bool _shouldShowFinalize(FixtureMatchdayStatus status) {
    return status == FixtureMatchdayStatus.inProgress || status == FixtureMatchdayStatus.incomplete;
  }

  VoidCallback? _buildFinalizeCallback(_DecoratedMatchday matchday) {
    if (!_shouldShowFinalize(matchday.status)) {
      return null;
    }
    return () => _finalizeMatchday(matchday.matchdayNumber);
  }

  @override
  void initState() {
    super.initState();
    _contentScrollController = ScrollController();
  }

  @override
  void dispose() {
    _contentScrollController.dispose();
    super.dispose();
  }

  Future<void> _openManualBuilder(ZoneDetail zone) async {
    setState(() => _generationMode = FixtureGenerationMode.manual);
    await GoRouter.of(context).push('/zones/${zone.id}/fixture/manual');
    if (mounted) {
      setState(() => _generationMode = FixtureGenerationMode.automatic);
    }
  }

  Future<void> _finalizeMatchday(int matchday) async {
    if (_isFinalizing(matchday)) {
      return;
    }

    setState(() {
      _finalizingMatchdays.add(matchday);
    });

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post<List<dynamic>>(
        '/zones/${widget.zoneId}/matchdays/$matchday/finalize',
      );
      final entries = response.data ?? <dynamic>[];
      ZoneMatchdayStatus? status;
      for (final entry in entries) {
        if (entry is Map<String, dynamic> && (entry['matchday'] as int?) == matchday) {
          status = ZoneMatchdayStatusX.fromApi(entry['status'] as String? ?? 'PENDING');
          break;
        }
      }

      ref.invalidate(zoneMatchesProvider(widget.zoneId));
      ref.invalidate(zoneDetailProvider(widget.zoneId));
      ref.invalidate(zonesProvider);

      if (mounted) {
        String label;
        if (status == ZoneMatchdayStatus.played) {
          label = 'Fecha marcada como jugada.';
        } else if (status == ZoneMatchdayStatus.incomplete) {
          label = 'Fecha marcada como incompleta. Revisa los resultados pendientes.';
        } else {
          label = 'Estado de la fecha actualizado.';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
      }
    } on DioException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo finalizar la fecha: ${_mapError(error)}')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo finalizar la fecha: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _finalizingMatchdays.remove(matchday);
        });
      }
    }
  }

  Future<void> _updateMatchdayDate(int matchday, DateTime? date) async {
    if (_isUpdatingDate(matchday)) {
      return;
    }

    setState(() {
      _updatingMatchdays.add(matchday);
    });

    try {
      final api = ref.read(apiClientProvider);
      await api.patch('/zones/${widget.zoneId}/matchdays/$matchday', data: {
        'date': date?.toIso8601String(),
      });

      ref.invalidate(zoneMatchesProvider(widget.zoneId));

      if (mounted) {
        final label = date != null ? 'Fecha actualizada.' : 'Fecha eliminada.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
      }
    } on DioException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar la fecha: ${_mapError(error)}')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar la fecha: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _updatingMatchdays.remove(matchday);
        });
      }
    }
  }

  Future<void> _requestPreview() async {
    setState(() {
      _loadingPreview = true;
      _previewError = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post<Map<String, dynamic>>(
        '/zones/${widget.zoneId}/fixture/preview',
        data: const {'doubleRound': true},
      );
      final data = response.data ?? <String, dynamic>{};
      setState(() {
        _preview = ZoneFixturePreview.fromJson(data);
      });
    } on DioException catch (error) {
      setState(() {
        _previewError = 'No se pudo generar el anticipo del fixture: ${_mapError(error)}';
      });
    } catch (error) {
      setState(() {
        _previewError = 'No se pudo generar el anticipo del fixture: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _loadingPreview = false);
      }
    }
  }

  Future<void> _confirmGeneration(ZoneDetail zone) async {
    final preview = _preview;
    if (preview == null || _submitting) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar fixture'),
        content: const Text('¿Estás seguro de generar el fixture para esta zona?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          )
        ],
      ),
    );

    if (confirm != true || !mounted) {
      return;
    }

    setState(() => _submitting = true);

    try {
      final api = ref.read(apiClientProvider);
      await api.post('/zones/${widget.zoneId}/fixture', data: {
        'doubleRound': preview.doubleRound,
        if (preview.seed != null) 'seed': preview.seed,
      });

      setState(() => _preview = null);
      ref.invalidate(zoneMatchesProvider(widget.zoneId));
      ref.invalidate(zoneDetailProvider(widget.zoneId));
      ref.invalidate(zonesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fixture generado correctamente.')),
        );
      }
    } on DioException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar el fixture: ${_mapError(error)}')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar el fixture: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  String _mapError(Object error) {
    if (error is DioException) {
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        final message = responseData['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
        if (message is List) {
          final first = message.cast<Object?>().firstWhere(
            (item) => item is String && item.isNotEmpty,
            orElse: () => null,
          );
          if (first is String) {
            return first;
          }
        }
      }
      if (error.message != null && error.message!.isNotEmpty) {
        return error.message!;
      }
    }
    return 'Ocurrió un error inesperado. Intenta nuevamente.';
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(zoneDetailProvider(widget.zoneId));

    return detailAsync.when(
      data: (zone) {
        final fixtureAsync = ref.watch(zoneMatchesProvider(widget.zoneId));
        final authState = ref.watch(authControllerProvider);
        final user = authState.user;
        final isAdmin = user?.hasAnyRole(const ['ADMIN']) ?? false;
        final canManageFixture = isAdmin ||
            (!widget.viewOnly &&
                (user?.hasPermission(
                          module: _moduleFixture,
                          action: _actionUpdate,
                          leagueId: zone.tournament.leagueId,
                        ) ??
                    false));
        final hasPreview = _preview != null;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.sports_soccer_outlined, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fixture de ${zone.name}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${zone.tournament.leagueName} · ${zone.tournament.name}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  ZoneStatusChip(status: zone.status),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: fixtureAsync.when(
                  data: (fixtureData) {
                    Widget content;
                    final matches = fixtureData.matches;
                    if (matches.isEmpty && !hasPreview) {
                      content = _buildGenerationPrompt(zone, canManageFixture);
                    } else if (hasPreview) {
                      content = _buildPreview(zone, _preview!);
                    } else {
                      content = _buildFixtureSchedule(zone, fixtureData, canManageFixture);
                    }

                    final scrollView = SingleChildScrollView(
                      controller: _contentScrollController,
                      child: content,
                    );

                    if (Responsive.isMobile(context)) {
                      return scrollView;
                    }

                    return Scrollbar(
                      thumbVisibility: true,
                      controller: _contentScrollController,
                      child: scrollView,
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => _ErrorMessage(
                    message: 'No se pudieron cargar los partidos: $error',
                    onRetry: () => ref.invalidate(zoneMatchesProvider(widget.zoneId)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No se pudo cargar la zona: $error',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  ref.invalidate(zoneDetailProvider(widget.zoneId));
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenerationPrompt(ZoneDetail zone, bool canManageFixture) {
    if (widget.viewOnly || !canManageFixture) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aún no hay partidos programados para esta zona.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Cuando el fixture esté disponible podrás consultarlo desde esta pantalla.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final canGenerate = zone.status == ZoneStatus.inProgress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aún no se generó el fixture de esta zona.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SegmentedButton<FixtureGenerationMode>(
                  segments: const [
                    ButtonSegment(
                      value: FixtureGenerationMode.automatic,
                      label: Text('Automático'),
                      icon: Icon(Icons.auto_mode_outlined),
                    ),
                    ButtonSegment(
                      value: FixtureGenerationMode.manual,
                      label: Text('Manual (Drag & Drop)'),
                      icon: Icon(Icons.drag_indicator),
                    ),
                  ],
                  selected: {_generationMode},
                  onSelectionChanged: canGenerate
                      ? (selection) {
                          final next = selection.first;
                          if (next == FixtureGenerationMode.manual) {
                            _openManualBuilder(zone);
                          } else {
                            setState(() => _generationMode = next);
                          }
                        }
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  'Se generará un fixture ida y vuelta siguiendo el método de todos contra todos, '
                  'respetando descansos (BYE) cuando la cantidad de clubes sea impar.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (!canGenerate) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Debes finalizar la zona para habilitar la generación del fixture.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 16),
                if (_previewError != null) ...[
                  Text(
                    _previewError!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton.icon(
                  onPressed: _loadingPreview || !canGenerate ? null : _requestPreview,
                  icon: _loadingPreview
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_mode_outlined),
                  label: Text(_loadingPreview ? 'Generando...' : 'Generar'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(ZoneDetail zone, ZoneFixturePreview preview) {
    final clubs = {for (final club in zone.clubs) club.id: club};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (preview.seed != null) ...[
          Text('Semilla utilizada: ${preview.seed}', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
        ],
        ..._decorateMatchdays(
          preview.matchdays
              .map(
                (matchday) => _MatchdayContent(
                  round: matchday.round,
                  matchdayNumber: matchday.matchday,
                  matches: matchday.matches
                      .map(
                        (match) => FixtureMatchRow(
                          homeName: clubs[match.homeClubId]?.shortName ??
                              clubs[match.homeClubId]?.name ??
                              'Club ${match.homeClubId}',
                          awayName: clubs[match.awayClubId]?.shortName ??
                              clubs[match.awayClubId]?.name ??
                              'Club ${match.awayClubId}',
                        ),
                      )
                      .toList(),
                  byeClubName: matchday.byeClubId != null
                      ? clubs[matchday.byeClubId]?.shortName ??
                          clubs[matchday.byeClubId]?.name ??
                          'Club ${matchday.byeClubId}'
                      : null,
                ),
              )
              .toList(),
        ).map(
          (matchday) => _FixtureMatchdayCard(
            title: 'Fecha ${matchday.displayIndex}',
            round: matchday.round,
            matches: matchday.matches,
            byeClubName: matchday.byeClubName,
            status: matchday.status,
          ),
        ),
        if (!widget.viewOnly) ...[
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _submitting ? null : () => _confirmGeneration(zone),
              icon: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check_circle_outline),
              label: Text(_submitting ? 'Confirmando...' : 'Confirmar'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFixtureSchedule(ZoneDetail zone, ZoneMatchesData data, bool canManageFixture) {
    final matches = data.matches;
    final clubs = {for (final club in zone.clubs) club.id: club};
    if (matches.isEmpty) {
      return const SizedBox.shrink();
    }

    final statusMap = {
      for (final entry in data.matchdays)
        entry.matchday: _mapFixtureStatus(entry.status),
    };
    final matchdayDates = {
      for (final entry in data.matchdays) entry.matchday: entry.date,
    };

    final grouped = <_MatchdayKey, List<ZoneMatch>>{};
    for (final match in matches) {
      final key = _MatchdayKey(round: match.round, matchday: match.matchday);
      grouped.putIfAbsent(key, () => <ZoneMatch>[]).add(match);
    }

    final matchdayCards = _decorateMatchdays(
      grouped.entries
          .map(
            (entry) {
              final dayMatches = entry.value;
              final round = entry.key.round;
              final playingClubIds = <int>{};
              for (final match in dayMatches) {
                if (match.homeClub?.id != null) {
                  playingClubIds.add(match.homeClub!.id);
                }
                if (match.awayClub?.id != null) {
                  playingClubIds.add(match.awayClub!.id);
                }
              }
              final byeClubId = zone.clubs.length % 2 == 1
                  ? zone.clubs.map((club) => club.id).firstWhere(
                        (clubId) => !playingClubIds.contains(clubId),
                        orElse: () => 0,
                      )
                  : null;
              final byeName = byeClubId != null && byeClubId != 0
                  ? (clubs[byeClubId]?.shortName ??
                      clubs[byeClubId]?.name ??
                      'Club $byeClubId')
                  : null;

              return _MatchdayContent(
                round: round,
                matchdayNumber: entry.key.matchday,
                date: matchdayDates[entry.key.matchday],
                matches: dayMatches
                    .map(
                      (match) => FixtureMatchRow(
                        homeName: match.homeDisplayName,
                        awayName: match.awayDisplayName,
                        homePoints: match.homePoints,
                        awayPoints: match.awayPoints,
                        onTap: () => _openMatchDetail(zone, match),
                      ),
                    )
                    .toList(),
                byeClubName: byeName,
              );
            },
          )
          .toList(),
      statusByMatchday: statusMap.isEmpty ? null : statusMap,
      matchdayDates: matchdayDates,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (zone.fixtureSeed != null) ...[
          Text('Semilla utilizada: ${zone.fixtureSeed}', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
        ],
        ...matchdayCards.map(
          (matchday) => _FixtureMatchdayCard(
            title: 'Fecha ${matchday.displayIndex}',
            round: matchday.round,
            matches: matchday.matches,
            byeClubName: matchday.byeClubName,
            status: matchday.status,
            date: matchday.date,
            canEditDate: canManageFixture,
            isUpdatingDate: _isUpdatingDate(matchday.matchdayNumber),
            onDateSelected: canManageFixture ? () => _selectMatchdayDate(matchday) : null,
            onClearDate: canManageFixture && matchday.date != null
                ? () => _updateMatchdayDate(matchday.matchdayNumber, null)
                : null,
            showFinalizeButton:
                canManageFixture && _shouldShowFinalize(matchday.status),
            isFinalizing: canManageFixture && _isFinalizing(matchday.matchdayNumber),
            onFinalize: canManageFixture ? _buildFinalizeCallback(matchday) : null,
            showSummaryButton: matchday.status == FixtureMatchdayStatus.played,
            onViewSummary: matchday.status == FixtureMatchdayStatus.played
                ? () => _openMatchdaySummary(zone, matchday)
                : null,
          ),
        ),
      ],
    );
  }

  Future<void> _selectMatchdayDate(_DecoratedMatchday matchday) async {
    final initialDate = matchday.date ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (selected == null) {
      return;
    }

    await _updateMatchdayDate(matchday.matchdayNumber, selected);
  }

  void _openMatchdaySummary(ZoneDetail zone, _DecoratedMatchday matchday) {
    if (!mounted) {
      return;
    }
    final route = '/zones/${zone.id}/fixture/matchdays/${matchday.matchdayNumber}/summary';
    GoRouter.of(context).push(route);
  }

  void _openMatchDetail(ZoneDetail zone, ZoneMatch match) {
    if (!mounted) {
      return;
    }
    final route = '/zones/${zone.id}/fixture/matches/${match.id}';
    GoRouter.of(context).push(route, extra: match);
  }
}

class ZoneFixturePreview {
  ZoneFixturePreview({
    required this.matchdays,
    required this.doubleRound,
    required this.totalMatchdays,
    this.seed,
  });

  factory ZoneFixturePreview.fromJson(Map<String, dynamic> json) {
    final matchdays = json['matchdays'] as List<dynamic>? ?? [];
    return ZoneFixturePreview(
      matchdays: matchdays
          .map((entry) => FixtureMatchdayPreview.fromJson(entry as Map<String, dynamic>))
          .toList(),
      doubleRound: json['doubleRound'] as bool? ?? true,
      totalMatchdays: json['totalMatchdays'] as int? ?? 0,
      seed: json['seed'] as int?,
    );
  }

  final List<FixtureMatchdayPreview> matchdays;
  final bool doubleRound;
  final int totalMatchdays;
  final int? seed;
}

class FixtureMatchdayPreview {
  FixtureMatchdayPreview({
    required this.matchday,
    required this.round,
    required this.matches,
    this.byeClubId,
  });

  factory FixtureMatchdayPreview.fromJson(Map<String, dynamic> json) {
    final matches = json['matches'] as List<dynamic>? ?? [];
    return FixtureMatchdayPreview(
      matchday: json['matchday'] as int? ?? 0,
      round: FixtureRoundX.fromApi(json['round'] as String? ?? 'FIRST'),
      matches: matches
          .map((entry) => FixtureMatchPreview.fromJson(entry as Map<String, dynamic>))
          .toList(),
      byeClubId: json['byeClubId'] as int?,
    );
  }

  final int matchday;
  final FixtureRound round;
  final List<FixtureMatchPreview> matches;
  final int? byeClubId;
}

class FixtureMatchPreview {
  FixtureMatchPreview({
    required this.homeClubId,
    required this.awayClubId,
  });

  factory FixtureMatchPreview.fromJson(Map<String, dynamic> json) {
    return FixtureMatchPreview(
      homeClubId: json['homeClubId'] as int? ?? 0,
      awayClubId: json['awayClubId'] as int? ?? 0,
    );
  }

  final int homeClubId;
  final int awayClubId;
}

class ZoneStatusChip extends StatelessWidget {
  const ZoneStatusChip({super.key, required this.status});

  final ZoneStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(status.label),
      backgroundColor: status.color.withOpacity(0.12),
      labelStyle: TextStyle(color: status.color, fontWeight: FontWeight.w600),
      side: BorderSide(color: status.color.withOpacity(0.4)),
    );
  }
}

class _FixtureMatchdayCard extends StatelessWidget {
  const _FixtureMatchdayCard({
    required this.title,
    required this.round,
    required this.matches,
    required this.status,
    this.date,
    this.canEditDate = false,
    this.isUpdatingDate = false,
    this.onDateSelected,
    this.onClearDate,
    this.onFinalize,
    this.isFinalizing = false,
    this.showFinalizeButton = false,
    this.byeClubName,
    this.showSummaryButton = false,
    this.onViewSummary,
  });

  final String title;
  final FixtureRound round;
  final List<FixtureMatchRow> matches;
  final FixtureMatchdayStatus status;
  final DateTime? date;
  final bool canEditDate;
  final bool isUpdatingDate;
  final VoidCallback? onDateSelected;
  final VoidCallback? onClearDate;
  final VoidCallback? onFinalize;
  final bool isFinalizing;
  final bool showFinalizeButton;
  final String? byeClubName;
  final bool showSummaryButton;
  final VoidCallback? onViewSummary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseTitleStyle = theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);
    final dateFormatter = DateFormat('dd/MM');
    final dateLabel =
        date != null ? dateFormatter.format(date!.toLocal()) : 'Sin fecha';
    final isMobile = Responsive.isMobile(context);
    final dateField = _MatchdayDateField(
      date: date,
      dateLabel: dateLabel,
      canEdit: canEditDate,
      isUpdating: isUpdatingDate,
      onSelectDate: onDateSelected,
      onClearDate: onClearDate,
    );
    final summaryButton = TextButton.icon(
      onPressed: onViewSummary,
      icon: const Icon(Icons.summarize_outlined),
      label: const Text('Resumen'),
    );
    final finalizeButton = TextButton.icon(
      onPressed: isFinalizing ? null : onFinalize,
      icon: isFinalizing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.flag_outlined),
      label: const Text('Finalizar'),
    );

    final titleWidget = RichText(
      textAlign: isMobile ? TextAlign.center : TextAlign.left,
      text: TextSpan(
        style: baseTitleStyle,
        children: [
          TextSpan(text: '${round.shortLabel} - '),
          TextSpan(
            text: title,
            style: baseTitleStyle?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );

    final header = isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.center,
                child: titleWidget,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: dateField,
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: showSummaryButton ? summaryButton : const SizedBox.shrink(),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _FixtureMatchdayStatusIndicator(status: status),
                    ),
                  ),
                ],
              ),
              if (showFinalizeButton) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: finalizeButton,
                ),
              ],
            ],
          )
        : Row(
            children: [
              Expanded(child: titleWidget),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 120),
                child: Align(
                  alignment: Alignment.center,
                  child: dateField,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showSummaryButton) ...[
                    summaryButton,
                    const SizedBox(width: 8),
                  ],
                  if (showFinalizeButton) ...[
                    finalizeButton,
                    const SizedBox(width: 8),
                  ],
                  _FixtureMatchdayStatusIndicator(status: status),
                ],
              ),
            ],
          );
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: header,
            children: [
              const Divider(height: 24),
              ...matches,
              if (byeClubName != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Libre: $byeClubName',
                  style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchdayDateField extends StatelessWidget {
  const _MatchdayDateField({
    required this.date,
    required this.dateLabel,
    required this.canEdit,
    required this.isUpdating,
    this.onSelectDate,
    this.onClearDate,
  });

  final DateTime? date;
  final String dateLabel;
  final bool canEdit;
  final bool isUpdating;
  final VoidCallback? onSelectDate;
  final VoidCallback? onClearDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);

    if (!canEdit) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        alignment: Alignment.center,
        child: Text(dateLabel, style: labelStyle, textAlign: TextAlign.center),
      );
    }

    final dateField = InkWell(
      onTap: isUpdating ? null : onSelectDate,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        alignment: Alignment.center,
        child: isUpdating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(dateLabel, style: labelStyle, textAlign: TextAlign.center),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dateField,
        if (date != null) ...[
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Quitar fecha',
            onPressed: isUpdating ? null : onClearDate,
            icon: const Icon(Icons.clear),
          ),
        ],
      ],
    );
  }
}

class FixtureMatchRow extends StatelessWidget {
  const FixtureMatchRow({
    super.key,
    required this.homeName,
    required this.awayName,
    this.homePoints,
    this.awayPoints,
    this.onTap,
  });

  final String homeName;
  final String awayName;
  final int? homePoints;
  final int? awayPoints;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final homePointsLabel = homePoints?.toString() ?? '-';
    final awayPointsLabel = awayPoints?.toString() ?? '-';
    final basePointsStyle = theme.textTheme.bodyMedium;
    final pointsTextStyle = basePointsStyle?.copyWith(fontWeight: FontWeight.w600) ??
        theme.textTheme.bodyMedium;

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        children: [
          Expanded(child: Text(homeName, style: theme.textTheme.bodyLarge)),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(homePointsLabel, style: pointsTextStyle),
              const SizedBox(width: 4),
              Icon(Icons.swap_horiz, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(awayPointsLabel, style: pointsTextStyle),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              awayName,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: content,
    );
  }
}

class _FixtureMatchdayStatusIndicator extends StatelessWidget {
  const _FixtureMatchdayStatusIndicator({required this.status});

  final FixtureMatchdayStatus status;

  @override
  Widget build(BuildContext context) {
    final foreground = status.textColor;
    final background = status.backgroundColor;
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: foreground.withOpacity(0.6)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        status.label,
        style: theme.textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ) ??
            TextStyle(color: foreground, fontWeight: FontWeight.w600),
      ),
    );
  }
}

enum FixtureMatchdayStatus { pending, inProgress, incomplete, played }

extension FixtureMatchdayStatusX on FixtureMatchdayStatus {
  String get label {
    switch (this) {
      case FixtureMatchdayStatus.pending:
        return 'Pendiente';
      case FixtureMatchdayStatus.inProgress:
        return 'En juego';
      case FixtureMatchdayStatus.incomplete:
        return 'Incompleta';
      case FixtureMatchdayStatus.played:
        return 'Jugada';
    }
  }

  Color get textColor {
    switch (this) {
      case FixtureMatchdayStatus.pending:
        return const Color(0xFFC62828);
      case FixtureMatchdayStatus.inProgress:
        return const Color(0xFFF9A825);
      case FixtureMatchdayStatus.incomplete:
        return const Color(0xFF6D4C41);
      case FixtureMatchdayStatus.played:
        return const Color(0xFF009688);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case FixtureMatchdayStatus.pending:
        return const Color(0xFFFDEDED);
      case FixtureMatchdayStatus.inProgress:
        return const Color(0xFFFFF4CF);
      case FixtureMatchdayStatus.incomplete:
        return const Color(0xFFF1E0D6);
      case FixtureMatchdayStatus.played:
        return const Color(0xFFDBEDF1);
    }
  }
}

class _MatchdayContent {
  _MatchdayContent({
    required this.round,
    required this.matchdayNumber,
    required this.matches,
    this.date,
    this.byeClubName,
  });

  final FixtureRound round;
  final int matchdayNumber;
  final List<FixtureMatchRow> matches;
  final DateTime? date;
  final String? byeClubName;
}

class _DecoratedMatchday {
  _DecoratedMatchday({
    required this.displayIndex,
    required this.matchdayNumber,
    required this.round,
    required this.matches,
    required this.status,
    this.date,
    this.byeClubName,
  });

  final int displayIndex;
  final int matchdayNumber;
  final FixtureRound round;
  final List<FixtureMatchRow> matches;
  final FixtureMatchdayStatus status;
  final DateTime? date;
  final String? byeClubName;
}

class _MatchdayKey {
  const _MatchdayKey({required this.round, required this.matchday});

  final FixtureRound round;
  final int matchday;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _MatchdayKey && other.round == round && other.matchday == matchday;
  }

  @override
  int get hashCode => Object.hash(round, matchday);
}

List<_DecoratedMatchday> _decorateMatchdays(
  List<_MatchdayContent> matchdays, {
  int playedMatchdaysCount = 0,
  Map<int, FixtureMatchdayStatus>? statusByMatchday,
  Map<int, DateTime?>? matchdayDates,
}) {
  if (matchdays.isEmpty) {
    return const <_DecoratedMatchday>[];
  }

  final sorted = [...matchdays]
    ..sort((a, b) {
      final roundComparison = a.round.index.compareTo(b.round.index);
      if (roundComparison != 0) {
        return roundComparison;
      }
      return a.matchdayNumber.compareTo(b.matchdayNumber);
    });

  final effectivePlayed = playedMatchdaysCount.clamp(0, sorted.length).toInt();
  final decorated = <_DecoratedMatchday>[];
  final seenDisplayIndexes = <int>{};
  for (var index = 0; index < sorted.length; index++) {
    final raw = sorted[index];
    FixtureMatchdayStatus status;
    final overrideStatus = statusByMatchday?[raw.matchdayNumber];
    if (overrideStatus != null) {
      status = overrideStatus;
    } else if (index < effectivePlayed) {
      status = FixtureMatchdayStatus.played;
    } else if (index == effectivePlayed && effectivePlayed < sorted.length) {
      status = FixtureMatchdayStatus.inProgress;
    } else {
      status = FixtureMatchdayStatus.pending;
    }

    final sequentialIndex = index + 1;
    final preferredIndex = raw.matchdayNumber > 0 ? raw.matchdayNumber : sequentialIndex;
    final displayIndex = seenDisplayIndexes.add(preferredIndex)
        ? preferredIndex
        : sequentialIndex;
    seenDisplayIndexes.add(displayIndex);
    final sortedMatches = [...raw.matches]
      ..sort(
        (a, b) => a.homeName.toLowerCase().compareTo(b.homeName.toLowerCase()),
      );
    final matchdayDate = raw.date ?? matchdayDates?[raw.matchdayNumber];

    decorated.add(
      _DecoratedMatchday(
        displayIndex: displayIndex,
        matchdayNumber: raw.matchdayNumber,
        round: raw.round,
        matches: sortedMatches,
        status: status,
        date: matchdayDate,
        byeClubName: raw.byeClubName,
      ),
    );
  }

  return decorated;
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    );
  }
}
