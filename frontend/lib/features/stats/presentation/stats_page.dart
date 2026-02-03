import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/responsive.dart';
import '../../../services/api_client.dart';
import '../../shared/widgets/table_filters_bar.dart';
import '../../zones/domain/zone_models.dart';
import '../domain/stats_models.dart';

class StatsFilters {
  const StatsFilters({
    required this.tournamentId,
    required this.zoneId,
    required this.categoryId,
  });

  final int? tournamentId;
  final int? zoneId;
  final int? categoryId;

  StatsFilters copyWith({
    int? tournamentId,
    int? zoneId,
    bool zoneIdSet = false,
    int? categoryId,
    bool categoryIdSet = false,
  }) {
    return StatsFilters(
      tournamentId: tournamentId ?? this.tournamentId,
      zoneId: zoneIdSet ? zoneId : this.zoneId,
      categoryId: categoryIdSet ? categoryId : this.categoryId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StatsFilters &&
        other.tournamentId == tournamentId &&
        other.zoneId == zoneId &&
        other.categoryId == categoryId;
  }

  @override
  int get hashCode => Object.hash(tournamentId, zoneId, categoryId);
}

final statsTournamentsProvider =
    FutureProvider<List<StatsTournamentSummary>>((ref) async {
  final includeInactive = ref.watch(statsIncludeInactiveProvider);
  final api = ref.read(apiClientProvider);
  final response = await api.get<List<dynamic>>(
    '/tournaments',
    queryParameters: includeInactive ? {'includeInactive': 'true'} : null,
  );
  final data = response.data ?? <dynamic>[];
  final tournaments = data
      .whereType<Map<String, dynamic>>()
      .map(StatsTournamentSummary.fromJson)
      .toList()
    ..sort((a, b) {
      final yearComparison = b.year.compareTo(a.year);
      if (yearComparison != 0) {
        return yearComparison;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  return tournaments;
});

final statsTournamentDetailProvider =
    FutureProvider.family<StatsTournamentDetail, int>((ref, tournamentId) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<Map<String, dynamic>>('/tournaments/$tournamentId');
  return StatsTournamentDetail.fromJson(response.data ?? const {});
});

final statsZonesProvider = FutureProvider<List<ZoneSummary>>((ref) async {
  final includeInactive = ref.watch(statsIncludeInactiveProvider);
  final api = ref.read(apiClientProvider);
  final response = await api.get<List<dynamic>>(
    '/zones',
    queryParameters: includeInactive ? {'includeInactive': 'true'} : null,
  );
  final data = response.data ?? <dynamic>[];
  return data
      .whereType<Map<String, dynamic>>()
      .map(ZoneSummary.fromJson)
      .toList();
});

final statsIncludeInactiveProvider = StateProvider<bool>((ref) => false);

final statsLeaderboardsProvider =
    FutureProvider.family<StatsLeaderboardsResponse, StatsFilters>((ref, filters) async {
  if (filters.tournamentId == null) {
    throw StateError('Selecciona un torneo para ver estadísticas.');
  }
  final api = ref.read(apiClientProvider);
  final query = <String, dynamic>{
    'tournamentId': filters.tournamentId.toString(),
  };
  if (filters.zoneId != null) {
    query['zoneId'] = filters.zoneId.toString();
  }
  if (filters.categoryId != null) {
    query['categoryId'] = filters.categoryId.toString();
  }
  final response = await api.get<Map<String, dynamic>>(
    '/stats/leaderboards',
    queryParameters: query,
  );
  return StatsLeaderboardsResponse.fromJson(response.data ?? const {});
});

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  int? _selectedTournamentId;
  int? _selectedZoneId;
  int? _selectedCategoryId;

  void _ensureTournamentSelected(List<StatsTournamentSummary> tournaments) {
    if (_selectedTournamentId != null || tournaments.isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedTournamentId = tournaments.first.id;
        _selectedZoneId = null;
        _selectedCategoryId = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final tournamentsAsync = ref.watch(statsTournamentsProvider);
    final zonesAsync = ref.watch(statsZonesProvider);
    final includeInactive = ref.watch(statsIncludeInactiveProvider);
    final padding = Responsive.pagePadding(context);

    return tournamentsAsync.when(
      data: (tournaments) {
        _ensureTournamentSelected(tournaments);
        final selectedTournament = tournaments.firstWhere(
          (tournament) => tournament.id == _selectedTournamentId,
          orElse: () => tournaments.isNotEmpty
              ? tournaments.first
              : StatsTournamentSummary(id: 0, name: '', year: 0, leagueName: ''),
        );
        final tournamentId = selectedTournament.id == 0 ? null : selectedTournament.id;
        final detailAsync = tournamentId == null
            ? const AsyncValue<StatsTournamentDetail>.loading()
            : ref.watch(statsTournamentDetailProvider(tournamentId));

        final zones = zonesAsync.valueOrNull ?? const <ZoneSummary>[];
        final tournamentZones =
            zones.where((zone) => zone.tournamentId == tournamentId).toList()
              ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        final filters = StatsFilters(
          tournamentId: tournamentId,
          zoneId: _selectedZoneId,
          categoryId: _selectedCategoryId,
        );

        return ListView(
          padding: padding,
          children: [
            _StatsFiltersCollapsible(
              child: _StatsFiltersBar(
                tournaments: tournaments,
                zones: tournamentZones,
                detailAsync: detailAsync,
                selectedTournamentId: tournamentId,
                selectedZoneId: _selectedZoneId,
                selectedCategoryId: _selectedCategoryId,
                includeInactive: includeInactive,
                onTournamentChanged: (value) {
                  setState(() {
                    _selectedTournamentId = value;
                    _selectedZoneId = null;
                    _selectedCategoryId = null;
                  });
                },
                onZoneChanged: (value) {
                  setState(() {
                    _selectedZoneId = value;
                  });
                },
                onCategoryChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
                onIncludeInactiveChanged: (value) {
                  ref.read(statsIncludeInactiveProvider.notifier).state = value ?? false;
                },
              ),
            ),
            const SizedBox(height: 24),
            if (tournamentId == null)
              const _StatsEmptyState(
                icon: Icons.emoji_events_outlined,
                title: 'Selecciona un torneo para continuar.',
                message: 'Elegí un torneo en los filtros para ver estadísticas.',
              )
            else
              _StatsContent(
                filters: filters,
                zones: tournamentZones,
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: padding,
          child: _StatsErrorState(
            message: 'No pudimos cargar los torneos disponibles.',
            error: error.toString(),
            onRetry: () => ref.invalidate(statsTournamentsProvider),
          ),
        ),
      ),
    );
  }
}

class _StatsFiltersBar extends StatelessWidget {
  const _StatsFiltersBar({
    required this.tournaments,
    required this.zones,
    required this.detailAsync,
    required this.selectedTournamentId,
    required this.selectedZoneId,
    required this.selectedCategoryId,
    required this.includeInactive,
    required this.onTournamentChanged,
    required this.onZoneChanged,
    required this.onCategoryChanged,
    required this.onIncludeInactiveChanged,
  });

  final List<StatsTournamentSummary> tournaments;
  final List<ZoneSummary> zones;
  final AsyncValue<StatsTournamentDetail> detailAsync;
  final int? selectedTournamentId;
  final int? selectedZoneId;
  final int? selectedCategoryId;
  final bool includeInactive;
  final ValueChanged<int?> onTournamentChanged;
  final ValueChanged<int?> onZoneChanged;
  final ValueChanged<int?> onCategoryChanged;
  final ValueChanged<bool?> onIncludeInactiveChanged;

  @override
  Widget build(BuildContext context) {
    return TableFiltersBar(
      showContainer: false,
      children: [
        TableFilterField(
          label: 'Torneo',
          width: 260,
          child: DropdownButton<int?>(
            value: selectedTournamentId,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            items: tournaments
                .map((tournament) => DropdownMenuItem<int?>(
                      value: tournament.id,
                      child: Text(tournament.displayName),
                    ))
                .toList(),
            onChanged: (value) => onTournamentChanged(value),
          ),
        ),
        TableFilterField(
          label: 'Estado',
          width: 220,
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Mostrar inactivos'),
            value: includeInactive,
            onChanged: onIncludeInactiveChanged,
          ),
        ),
        TableFilterField(
          label: 'Zona',
          width: 220,
          child: DropdownButton<int?>(
            value: selectedZoneId,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Todas'),
              ),
              ...zones.map((zone) => DropdownMenuItem<int?>(
                    value: zone.id,
                    child: Text(zone.name),
                  )),
            ],
            onChanged: (value) => onZoneChanged(value),
          ),
        ),
        TableFilterField(
          label: 'Categoría',
          width: 240,
          child: detailAsync.when(
            data: (detail) {
              final categories = detail.categories
                ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
              return DropdownButton<int?>(
                value: selectedCategoryId,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Todas'),
                  ),
                  ...categories.map(
                    (category) => DropdownMenuItem<int?>(
                      value: category.id,
                      child: Text(category.name),
                    ),
                  ),
                ],
                onChanged: (value) => onCategoryChanged(value),
              );
            },
            loading: () => const SizedBox(
              height: 32,
              child: Align(
                alignment: Alignment.centerLeft,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (error, stackTrace) => Text(
              'Error al cargar categorías',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsFiltersCollapsible extends StatelessWidget {
  const _StatsFiltersCollapsible({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      child: ExpansionTile(
        title: const Text('Busqueda'),
        initiallyExpanded: false,
        collapsedBackgroundColor: theme.colorScheme.surface,
        backgroundColor: theme.colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        collapsedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        childrenPadding: EdgeInsets.zero,
        children: [child],
      ),
    );
  }
}

class _StatsContent extends StatelessWidget {
  const _StatsContent({
    required this.filters,
    required this.zones,
  });

  final StatsFilters filters;
  final List<ZoneSummary> zones;

  @override
  Widget build(BuildContext context) {
    if (filters.zoneId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatsLeaderboardBlock(
            title: 'General (todas las zonas)',
            filters: filters,
          ),
          const SizedBox(height: 24),
          if (zones.isEmpty)
            const _StatsEmptyState(
              icon: Icons.info_outline,
              title: 'No hay zonas para mostrar.',
              message: 'El torneo seleccionado todavía no tiene zonas con datos.',
            )
          else
            _StatsZonesAccordion(
              zones: zones,
              filters: filters,
            ),
        ],
      );
    }

    return _StatsLeaderboardBlock(
      title: 'Zona seleccionada',
      filters: filters,
    );
  }
}

class _StatsLeaderboardBlock extends ConsumerWidget {
  const _StatsLeaderboardBlock({
    required this.title,
    required this.filters,
  });

  final String title;
  final StatsFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardsAsync = ref.watch(statsLeaderboardsProvider(filters));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        leaderboardsAsync.when(
          data: (data) => _StatsLeaderboardGrid(leaderboards: data.leaderboards),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _StatsErrorState(
            message: 'No pudimos cargar las estadísticas.',
            error: error.toString(),
            onRetry: () => ref.invalidate(statsLeaderboardsProvider(filters)),
          ),
        ),
      ],
    );
  }
}

class _StatsZonesAccordion extends StatelessWidget {
  const _StatsZonesAccordion({
    required this.zones,
    required this.filters,
  });

  final List<ZoneSummary> zones;
  final StatsFilters filters;

  @override
  Widget build(BuildContext context) {
    return ExpansionPanelList.radio(
      elevation: 1,
      expandedHeaderPadding: const EdgeInsets.symmetric(vertical: 8),
      children: zones
          .map((zone) => ExpansionPanelRadio(
                value: zone.id,
                headerBuilder: (context, isExpanded) => ListTile(
                  title: Text(
                    zone.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(zone.tournamentName),
                ),
                body: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _StatsLeaderboardBlock(
                    title: 'Top 3 de ${zone.name}',
                    filters: filters.copyWith(zoneId: zone.id, zoneIdSet: true),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _StatsLeaderboardGrid extends StatelessWidget {
  const _StatsLeaderboardGrid({required this.leaderboards});

  final StatsLeaderboards leaderboards;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatsLeaderboardCard(
        title: 'Goleadores',
        valueLabel: 'goles',
        entries: leaderboards.topScorersPlayers
            .map((entry) => _StatsLeaderboardEntryView(
                  title: entry.playerName,
                  subtitle: entry.clubName,
                  value: entry.goals.toString(),
                ))
            .toList(),
      ),
      _StatsLeaderboardCard(
        title: 'Más partidos marcando',
        valueLabel: 'partidos',
        entries: leaderboards.mostMatchesScoringPlayers
            .map((entry) => _StatsLeaderboardEntryView(
                  title: entry.playerName,
                  subtitle: entry.clubName,
                  value: entry.matchesWithGoal.toString(),
                ))
            .toList(),
      ),
      _StatsLeaderboardCard(
        title: 'Más dobletes',
        valueLabel: 'dobletes',
        entries: leaderboards.mostBracesPlayers
            .map((entry) => _StatsLeaderboardEntryView(
                  title: entry.playerName,
                  subtitle: entry.clubName,
                  value: entry.bracesCount.toString(),
                ))
            .toList(),
      ),
      _StatsLeaderboardCard(
        title: 'Más hat-tricks',
        valueLabel: 'hat-tricks',
        entries: leaderboards.mostHatTricksPlayers
            .map((entry) => _StatsLeaderboardEntryView(
                  title: entry.playerName,
                  subtitle: entry.clubName,
                  value: entry.hatTricksCount.toString(),
                ))
            .toList(),
      ),
      _StatsLeaderboardCard(
        title: 'Equipo más goleador',
        valueLabel: 'goles',
        entries: leaderboards.topScoringTeams
            .map((entry) => _StatsLeaderboardEntryView(
                  title: entry.clubName,
                  subtitle: 'GF',
                  value: entry.goalsFor.toString(),
                ))
            .toList(),
      ),
      _StatsLeaderboardCard(
        title: 'Mejor defensa',
        valueLabel: 'goles',
        entries: leaderboards.bestDefenseTeams
            .map((entry) => _StatsLeaderboardEntryView(
                  title: entry.clubName,
                  subtitle: 'GC',
                  value: entry.goalsAgainst.toString(),
                ))
            .toList(),
      ),
      _StatsLeaderboardCard(
        title: 'Más vallas invictas',
        valueLabel: 'vallas',
        entries: leaderboards.mostCleanSheetsTeams
            .map((entry) => _StatsLeaderboardEntryView(
                  title: entry.clubName,
                  subtitle: 'Invictas',
                  value: entry.cleanSheets.toString(),
                ))
            .toList(),
      ),
      _StatsLeaderboardCard(
        title: 'Más victorias',
        valueLabel: 'victorias',
        entries: leaderboards.mostWinsTeams
            .map((entry) => _StatsLeaderboardEntryView(
                  title: entry.clubName,
                  subtitle: 'Ganados',
                  value: entry.wins.toString(),
                ))
            .toList(),
      ),
      _StatsLeaderboardCard(
        title: 'Partidos con más goles',
        valueLabel: 'goles',
        entries: leaderboards.mostGoalsMatches
            .map((entry) => _StatsLeaderboardEntryView(
                  title:
                      '${entry.homeClubName} ${entry.homeScore} - ${entry.awayScore} ${entry.awayClubName}',
                  subtitle: _matchSubtitle(entry.zoneName, entry.categoryName),
                  value: entry.totalGoals.toString(),
                ))
            .toList(),
      ),
      _StatsLeaderboardCard(
        title: 'Mayor goleada',
        valueLabel: 'diferencia',
        entries: leaderboards.biggestWinsMatches
            .map((entry) => _StatsLeaderboardEntryView(
                  title:
                      '${entry.homeClubName} ${entry.homeScore} - ${entry.awayScore} ${entry.awayClubName}',
                  subtitle: _matchSubtitle(entry.zoneName, entry.categoryName),
                  value: entry.goalDiff.toString(),
                ))
            .toList(),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final cardWidth = min(360.0, maxWidth);
        final isMobile = Responsive.isMobile(context);
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          children: cards
              .map((card) => SizedBox(
                    width: cardWidth,
                    child: card,
                  ))
              .toList(),
        );
      },
    );
  }

  static String _matchSubtitle(String? zoneName, String categoryName) {
    final zoneLabel = zoneName?.isNotEmpty == true ? zoneName! : 'Sin zona';
    return '$zoneLabel · $categoryName';
  }
}

class _StatsLeaderboardCard extends StatelessWidget {
  const _StatsLeaderboardCard({
    required this.title,
    required this.valueLabel,
    required this.entries,
  });

  final String title;
  final String valueLabel;
  final List<_StatsLeaderboardEntryView> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleEntries = entries.take(3).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Top 3',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              Text(
                'Sin datos disponibles.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...List.generate(
                visibleEntries.length,
                (index) => _StatsLeaderboardRow(
                  rank: index + 1,
                  entry: visibleEntries[index],
                ),
              ),
            const SizedBox(height: 8),
            if (entries.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _openTopTen(context),
                  child: const Text('Ver Top 10'),
                ),
              ),
            Text(
              'Ordenado por $valueLabel',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openTopTen(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: min(10, entries.length),
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _StatsLeaderboardRow(
                      rank: index + 1,
                      entry: entry,
                      dense: true,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsLeaderboardRow extends StatelessWidget {
  const _StatsLeaderboardRow({
    required this.rank,
    required this.entry,
    this.dense = false,
  });

  final int rank;
  final _StatsLeaderboardEntryView entry;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medal = _medalForRank(rank);
    final rankLabel = medal == null ? '$rank.' : '$rank. $medal';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 4 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Text(
              rankLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title, style: theme.textTheme.bodyMedium),
                if (entry.subtitle.isNotEmpty)
                  Text(
                    entry.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            entry.value,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  static String? _medalForRank(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return null;
    }
  }
}

class _StatsLeaderboardEntryView {
  const _StatsLeaderboardEntryView({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  final String title;
  final String subtitle;
  final String value;
}

class _StatsEmptyState extends StatelessWidget {
  const _StatsEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _StatsErrorState extends StatelessWidget {
  const _StatsErrorState({
    required this.message,
    required this.error,
    required this.onRetry,
  });

  final String message;
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 48),
        const SizedBox(height: 12),
        Text(
          message,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          error,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      ],
    );
  }
}
