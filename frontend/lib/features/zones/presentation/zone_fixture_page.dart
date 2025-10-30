import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';
import '../domain/zone_models.dart';
import 'zones_page.dart';

final zoneDetailProvider = FutureProvider.autoDispose.family<ZoneDetail, int>((ref, zoneId) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<Map<String, dynamic>>('/zones/$zoneId');
  final data = response.data ?? <String, dynamic>{};
  return ZoneDetail.fromJson(data);
});

final zoneMatchesProvider = FutureProvider.autoDispose.family<List<ZoneMatch>, int>((ref, zoneId) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<List<dynamic>>('/zones/$zoneId/matches');
  final data = response.data ?? [];
  return data.map((json) => ZoneMatch.fromJson(json as Map<String, dynamic>)).toList();
});

class ZoneFixturePage extends ConsumerStatefulWidget {
  const ZoneFixturePage({super.key, required this.zoneId});

  final int zoneId;

  @override
  ConsumerState<ZoneFixturePage> createState() => _ZoneFixturePageState();
}

class _ZoneFixturePageState extends ConsumerState<ZoneFixturePage> {
  final ScrollController _scrollController = ScrollController();
  ZoneFixturePreview? _preview;
  bool _loadingPreview = false;
  bool _submitting = false;
  String? _previewError;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
        final matchesAsync = ref.watch(zoneMatchesProvider(widget.zoneId));
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
                          '${zone.tournament.leagueName} · ${zone.tournament.name} ${zone.tournament.year}',
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
                child: matchesAsync.when(
                  data: (matches) {
                    Widget content;
                    if (matches.isEmpty && !hasPreview) {
                      content = _buildGenerationPrompt(zone);
                    } else if (hasPreview) {
                      content = _buildPreview(zone, _preview!);
                    } else {
                      content = _buildFixtureSchedule(zone, matches);
                    }

                    return Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: content,
                      ),
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

  Widget _buildGenerationPrompt(ZoneDetail zone) {
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
            subtitle: matchday.round.label,
            matches: matchday.matches,
            byeClubName: matchday.byeClubName,
            status: matchday.status,
          ),
        ),
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
    );
  }

  Widget _buildFixtureSchedule(ZoneDetail zone, List<ZoneMatch> matches) {
    final clubs = {for (final club in zone.clubs) club.id: club};
    if (matches.isEmpty) {
      return const SizedBox.shrink();
    }

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
                matches: dayMatches
                    .map(
                      (match) => FixtureMatchRow(
                        homeName: match.homeClub?.shortName ??
                            match.homeClub?.name ??
                            'Por definir',
                        awayName: match.awayClub?.shortName ??
                            match.awayClub?.name ??
                            'Por definir',
                      ),
                    )
                    .toList(),
                byeClubName: byeName,
              );
            },
          )
          .toList(),
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
            subtitle: matchday.round.label,
            matches: matchday.matches,
            byeClubName: matchday.byeClubName,
            status: matchday.status,
          ),
        ),
      ],
    );
  }
}

class ZoneMatch {
  ZoneMatch({
    required this.id,
    required this.matchday,
    required this.round,
    required this.homeClub,
    required this.awayClub,
  });

  factory ZoneMatch.fromJson(Map<String, dynamic> json) {
    return ZoneMatch(
      id: json['id'] as int? ?? 0,
      matchday: json['matchday'] as int? ?? 0,
      round: FixtureRoundX.fromApi(json['round'] as String? ?? 'FIRST'),
      homeClub: json['homeClub'] != null ? FixtureClub.fromJson(json['homeClub'] as Map<String, dynamic>) : null,
      awayClub: json['awayClub'] != null ? FixtureClub.fromJson(json['awayClub'] as Map<String, dynamic>) : null,
    );
  }

  final int id;
  final int matchday;
  final FixtureRound round;
  final FixtureClub? homeClub;
  final FixtureClub? awayClub;
}

class FixtureClub {
  FixtureClub({required this.id, required this.name, this.shortName});

  factory FixtureClub.fromJson(Map<String, dynamic> json) {
    return FixtureClub(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Club',
      shortName: json['shortName'] as String?,
    );
  }

  final int id;
  final String name;
  final String? shortName;
}

enum FixtureRound { first, second }

extension FixtureRoundX on FixtureRound {
  static FixtureRound fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'SECOND':
        return FixtureRound.second;
      default:
        return FixtureRound.first;
    }
  }

  String get label {
    switch (this) {
      case FixtureRound.first:
        return 'Rueda 1';
      case FixtureRound.second:
        return 'Rueda 2';
    }
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
    required this.subtitle,
    required this.matches,
    required this.status,
    this.byeClubName,
  });

  final String title;
  final String subtitle;
  final List<FixtureMatchRow> matches;
  final FixtureMatchdayStatus status;
  final String? byeClubName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _FixtureMatchdayStatusIndicator(status: status),
          ],
        ),
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
    );
  }
}

class FixtureMatchRow extends StatelessWidget {
  const FixtureMatchRow({super.key, required this.homeName, required this.awayName});

  final String homeName;
  final String awayName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(homeName, style: Theme.of(context).textTheme.bodyLarge)),
          Icon(Icons.swap_horiz, color: Theme.of(context).colorScheme.onSurfaceVariant),
          Expanded(
            child: Text(
              awayName,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
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

enum FixtureMatchdayStatus { pending, inProgress, played }

extension FixtureMatchdayStatusX on FixtureMatchdayStatus {
  String get label {
    switch (this) {
      case FixtureMatchdayStatus.pending:
        return 'Pendiente';
      case FixtureMatchdayStatus.inProgress:
        return 'En juego';
      case FixtureMatchdayStatus.played:
        return 'Jugado';
    }
  }

  Color get textColor {
    switch (this) {
      case FixtureMatchdayStatus.pending:
        return const Color(0xFFC62828);
      case FixtureMatchdayStatus.inProgress:
        return const Color(0xFFF9A825);
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
    this.byeClubName,
  });

  final FixtureRound round;
  final int matchdayNumber;
  final List<FixtureMatchRow> matches;
  final String? byeClubName;
}

class _DecoratedMatchday {
  _DecoratedMatchday({
    required this.displayIndex,
    required this.round,
    required this.matches,
    required this.status,
    this.byeClubName,
  });

  final int displayIndex;
  final FixtureRound round;
  final List<FixtureMatchRow> matches;
  final FixtureMatchdayStatus status;
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
  for (var index = 0; index < sorted.length; index++) {
    final raw = sorted[index];
    FixtureMatchdayStatus status;
    if (index < effectivePlayed) {
      status = FixtureMatchdayStatus.played;
    } else if (index == effectivePlayed && effectivePlayed < sorted.length) {
      status = FixtureMatchdayStatus.inProgress;
    } else {
      status = FixtureMatchdayStatus.pending;
    }

    decorated.add(
      _DecoratedMatchday(
        displayIndex: index + 1,
        round: raw.round,
        matches: raw.matches,
        status: status,
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
