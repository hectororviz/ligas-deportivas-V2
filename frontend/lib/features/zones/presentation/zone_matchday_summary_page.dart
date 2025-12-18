import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/api_client.dart';
import '../../standings/presentation/standings_table.dart';
import '../../standings/domain/standings_models.dart';
import '../../shared/widgets/app_data_table_style.dart';
import '../domain/zone_match_models.dart';
import '../domain/zone_matchday_summary.dart';

final matchdaySummaryProvider = FutureProvider.autoDispose
    .family<ZoneMatchdaySummary, _MatchdaySummaryRequest>((ref, request) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<Map<String, dynamic>>(
    '/zones/${request.zoneId}/matchdays/${request.matchday}/summary',
  );
  final data = response.data ?? <String, dynamic>{};
  return ZoneMatchdaySummary.fromJson(data);
});

class ZoneMatchdaySummaryPage extends ConsumerWidget {
  const ZoneMatchdaySummaryPage({super.key, required this.zoneId, required this.matchday});

  final int zoneId;
  final int matchday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = _MatchdaySummaryRequest(zoneId: zoneId, matchday: matchday);
    final summaryAsync = ref.watch(matchdaySummaryProvider(request));

    return summaryAsync.when(
      data: (data) => _MatchdaySummaryView(data: data),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(
                'No pudimos cargar el resumen de la fecha.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(matchdaySummaryProvider(request)),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchdaySummaryView extends ConsumerWidget {
  const _MatchdaySummaryView({required this.data});

  final ZoneMatchdaySummary data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final leagueColors = ref.watch(leagueColorsProvider);
    final leagueColor = leagueColors[data.zone.leagueId] ?? theme.colorScheme.primary;
    final subtitle = '${data.zone.tournamentName} ${data.zone.tournamentYear} · ${data.zone.leagueName}';
    final dateLabel = data.matchday.date != null
        ? DateFormat('dd/MM/yyyy').format(data.matchday.date!.toLocal())
        : 'Sin fecha definida';
    final generalStandings = ZoneStandingsData(
      zone: data.zone,
      general: data.generalStandings,
      categories: data.categoryStandings,
    );

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.summarize_outlined, color: leagueColor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fecha ${data.matchday.matchday} · ${data.zone.name}',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(dateLabel, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            _MatchdayStatusChip(status: data.matchday.status),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resultados por partido',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _MatchResultsList(matches: data.matches),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Puntos por categoría',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Las categorías que no suman a la tabla general aparecen después del total de puntos.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                _MatchdayScoreboardTable(scoreboard: data.scoreboard, highlightColor: leagueColor),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tabla general',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                StandingsTable(
                  storageKey: 'zone-${data.zone.id}-matchday-${data.matchday.matchday}-general',
                  rows: generalStandings.general,
                  emptyMessage: 'Todavía no hay datos para la tabla general.',
                  leagueColor: leagueColor,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Tablas por categoría',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (generalStandings.categories.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No hay categorías con estadísticas disponibles en esta zona.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          )
        else
          ...generalStandings.categories.map(
            (category) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                key: PageStorageKey('zone-${data.zone.id}-matchday-${data.matchday.matchday}-category-${category.tournamentCategoryId}'),
                tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                title: Text(
                  category.categoryName,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: category.countsForGeneral
                    ? null
                    : Text(
                        'Categoría promocional (no suma a la tabla general).',
                        style: theme.textTheme.bodySmall,
                      ),
                children: [
                  StandingsTable(
                    storageKey:
                        'zone-${data.zone.id}-matchday-${data.matchday.matchday}-category-${category.tournamentCategoryId}',
                    rows: category.standings,
                    emptyMessage: 'No hay datos para esta categoría.',
                    leagueColor: leagueColor,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MatchResultsList extends StatelessWidget {
  const _MatchResultsList({required this.matches});

  final List<MatchdaySummaryMatch> matches;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (matches.isEmpty) {
      return Text(
        'No hay resultados registrados para esta fecha.',
        style: theme.textTheme.bodyMedium,
      );
    }

    return Column(
      children: matches
          .map(
            (match) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                match.round.label,
                                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${match.homeClub?.displayName ?? 'Por definir'} vs ${match.awayClub?.displayName ?? 'Por definir'}',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.sports_soccer, size: 20),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._sortedCategories(match.categories).map(
                      (category) => _CategoryResultRow(category: category),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CategoryResultRow extends StatelessWidget {
  const _CategoryResultRow({required this.category});

  final MatchdaySummaryCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600);
    final scores = '${category.homeScore ?? '-'} - ${category.awayScore ?? '-'}';
    final chipColor = category.countsForGeneral
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.tertiaryContainer;
    final chipTextColor = category.countsForGeneral
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onTertiaryContainer;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(category.categoryName, style: labelStyle),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              category.countsForGeneral ? 'General' : 'Promocional',
              style: theme.textTheme.labelMedium?.copyWith(
                color: chipTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(scores, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _MatchdayScoreboardTable extends StatelessWidget {
  const _MatchdayScoreboardTable({required this.scoreboard, required this.highlightColor});

  final MatchdayScoreboard scoreboard;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    if (scoreboard.categories.isEmpty) {
      return Text(
        'No hay categorías configuradas para este torneo.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    final generalCategories =
        scoreboard.categories.where((category) => category.countsForGeneral).toList();
    final promotionalCategories =
        scoreboard.categories.where((category) => !category.countsForGeneral).toList();
    final theme = Theme.of(context);
    final colors = AppDataTableColors.score(theme, highlightColor);
    final headerStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: colors.headerText,
    );

    final columns = <DataColumn>[
      const DataColumn(label: Text('Club')),
      ...generalCategories.map((category) => DataColumn(label: Text(category.categoryName))),
      const DataColumn(label: Text('Puntos'), numeric: true),
      ...promotionalCategories.map((category) => DataColumn(label: Text(category.categoryName))),
    ];

    String formatPoints(MatchdayScoreboardRow row, MatchdayScoreboardCategory category) {
      final value = row.categoryPoints[category.tournamentCategoryId];
      return value == null ? '-' : value.toString();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: buildHeaderColor(colors.headerBackground),
        headingTextStyle: headerStyle,
        columns: columns,
        rows: [
          for (var index = 0; index < scoreboard.rows.length; index++)
            DataRow(
              color: buildStripedRowColor(index: index, colors: colors),
              cells: [
                DataCell(Text(scoreboard.rows[index].clubName)),
                ...generalCategories.map(
                  (category) => DataCell(Text(formatPoints(scoreboard.rows[index], category))),
                ),
                DataCell(Text(scoreboard.rows[index].generalPoints.toString())),
                ...promotionalCategories.map(
                  (category) => DataCell(Text(formatPoints(scoreboard.rows[index], category))),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MatchdayStatusChip extends StatelessWidget {
  const _MatchdayStatusChip({required this.status});

  final ZoneMatchdayStatus status;

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusStyle.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusStyle.foreground.withOpacity(0.5)),
      ),
      child: Text(
        statusStyle.label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: statusStyle.foreground,
              fontWeight: FontWeight.w700,
            ) ??
            TextStyle(color: statusStyle.foreground, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StatusStyle {
  _StatusStyle({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;
}

_StatusStyle _statusStyle(ZoneMatchdayStatus status) {
  switch (status) {
    case ZoneMatchdayStatus.inProgress:
      return _StatusStyle(
        label: 'En juego',
        foreground: const Color(0xFFF9A825),
        background: const Color(0xFFFFF4CF),
      );
    case ZoneMatchdayStatus.incomplete:
      return _StatusStyle(
        label: 'Incompleta',
        foreground: const Color(0xFF6D4C41),
        background: const Color(0xFFF1E0D6),
      );
    case ZoneMatchdayStatus.played:
      return _StatusStyle(
        label: 'Jugada',
        foreground: const Color(0xFF009688),
        background: const Color(0xFFDBEDF1),
      );
    case ZoneMatchdayStatus.pending:
    default:
      return _StatusStyle(
        label: 'Pendiente',
        foreground: const Color(0xFFC62828),
        background: const Color(0xFFFDEDED),
      );
  }
}

List<MatchdaySummaryCategory> _sortedCategories(List<MatchdaySummaryCategory> categories) {
  final sorted = [...categories];
  sorted.sort((a, b) {
    if (a.countsForGeneral != b.countsForGeneral) {
      return a.countsForGeneral ? -1 : 1;
    }
    return a.categoryName.toLowerCase().compareTo(b.categoryName.toLowerCase());
  });
  return sorted;
}

class _MatchdaySummaryRequest {
  const _MatchdaySummaryRequest({required this.zoneId, required this.matchday});

  final int zoneId;
  final int matchday;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _MatchdaySummaryRequest &&
        other.zoneId == zoneId &&
        other.matchday == matchday;
  }

  @override
  int get hashCode => Object.hash(zoneId, matchday);
}
