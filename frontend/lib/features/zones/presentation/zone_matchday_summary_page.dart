import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
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
    final scoreboardGrouping = _buildScoreboardGrouping(data.scoreboard, data.matches);
    final matchdayPoints = _buildMatchdayPoints(data.matches);
    final clubShortNames = _buildClubShortNames(data.matches);
    final generalStandings = ZoneStandingsData(
      zone: data.zone,
      general: data.generalStandings,
      categories: data.categoryStandings,
    );

    final isMobile = Responsive.isMobile(context);
    final listPadding = isMobile
        ? const EdgeInsets.fromLTRB(8, 16, 8, 16)
        : const EdgeInsets.all(24);
    final sectionPadding = isMobile ? const EdgeInsets.all(12) : const EdgeInsets.all(20);
    final tilePadding = isMobile
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    final tileChildrenPadding =
        isMobile ? const EdgeInsets.fromLTRB(12, 0, 12, 12) : const EdgeInsets.fromLTRB(20, 0, 20, 16);

    return ListView(
      padding: listPadding,
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
            padding: sectionPadding,
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
        Card(
          child: Padding(
            padding: sectionPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resultados',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Los goles por categoría de la fecha se muestran en las columnas. '
                  'Las categorías promocionales aparecen después del total de puntos.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                _MatchdayScoreboardTable(
                  scoreboard: data.scoreboard,
                  highlightColor: leagueColor,
                  rows: scoreboardGrouping.rows,
                  clubGroupIndexes: scoreboardGrouping.clubGroupIndexes,
                  clubNameGroupIndexes: scoreboardGrouping.clubNameGroupIndexes,
                  pointsByClubId: matchdayPoints.byClubId,
                  pointsByClubName: matchdayPoints.byClubName,
                  shortNameByClubId: clubShortNames.byClubId,
                  shortNameByClubName: clubShortNames.byClubName,
                ),
                if (scoreboardGrouping.byeClubs.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Libre: ${scoreboardGrouping.byeClubs.join(', ')}',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
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
              padding: sectionPadding,
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
                tilePadding: tilePadding,
                childrenPadding: tileChildrenPadding,
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

class _MatchdayScoreboardTable extends StatelessWidget {
  const _MatchdayScoreboardTable({
    required this.scoreboard,
    required this.highlightColor,
    required this.rows,
    required this.clubGroupIndexes,
    required this.clubNameGroupIndexes,
    required this.pointsByClubId,
    required this.pointsByClubName,
    required this.shortNameByClubId,
    required this.shortNameByClubName,
  });

  final MatchdayScoreboard scoreboard;
  final Color highlightColor;
  final List<MatchdayScoreboardRow> rows;
  final Map<int, int> clubGroupIndexes;
  final Map<String, int> clubNameGroupIndexes;
  final Map<int, int> pointsByClubId;
  final Map<String, int> pointsByClubName;
  final Map<int, String> shortNameByClubId;
  final Map<String, String> shortNameByClubName;

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
    final dividerColor = theme.colorScheme.outlineVariant;
    final promoPadding = const EdgeInsets.only(left: 12);

    final columns = <DataColumn>[
      const DataColumn(label: Text('Club')),
      ...generalCategories.map((category) => DataColumn(label: Text(category.categoryName))),
      DataColumn(
        label: Container(
          padding: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: dividerColor)),
          ),
          child: const Text('Puntos'),
        ),
        numeric: true,
      ),
      ...promotionalCategories.map(
        (category) => DataColumn(
          label: Padding(
            padding: promoPadding,
            child: Text(category.categoryName),
          ),
        ),
      ),
    ];

    String formatGoals(MatchdayScoreboardRow row, MatchdayScoreboardCategory category) {
      final value = row.goalsByCategory[category.tournamentCategoryId];
      return (value ?? 0).toString();
    }

    int resolvePoints(MatchdayScoreboardRow row) {
      final byId = row.clubId != 0 ? pointsByClubId[row.clubId] : null;
      if (byId != null) {
        return byId;
      }
      return pointsByClubName[_normalizeName(row.clubName)] ?? 0;
    }

    String resolveClubName(MatchdayScoreboardRow row) {
      final byId = row.clubId != 0 ? shortNameByClubId[row.clubId] : null;
      if (byId != null && byId.isNotEmpty) {
        return byId;
      }
      return shortNameByClubName[_normalizeName(row.clubName)] ?? row.clubName;
    }

    final pointsStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.primary,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: buildHeaderColor(colors.headerBackground),
        headingTextStyle: headerStyle,
        columns: columns,
        rows: [
          for (var index = 0; index < rows.length; index++)
            DataRow(
              color: _buildMatchRowColor(
                index: index,
                groupIndex: _resolveGroupIndex(rows[index]),
                colors: colors,
              ),
              cells: [
                DataCell(Text(resolveClubName(rows[index]))),
                ...generalCategories.map(
                  (category) => DataCell(Text(formatGoals(rows[index], category))),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: dividerColor)),
                    ),
                    child: Text(
                      resolvePoints(rows[index]).toString(),
                      style: pointsStyle,
                    ),
                  ),
                ),
                ...promotionalCategories.map(
                  (category) => DataCell(
                    Padding(
                      padding: promoPadding,
                      child: Text(formatGoals(rows[index], category)),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  int? _resolveGroupIndex(MatchdayScoreboardRow row) {
    final byId = clubGroupIndexes[row.clubId];
    if (byId != null) {
      return byId;
    }
    return clubNameGroupIndexes[_normalizeName(row.clubName)];
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

String _normalizeName(String name) => name.trim().toLowerCase();

bool _hasRealClub(SummaryClub? club) {
  if (club == null) {
    return false;
  }
  return club.id != 0 && club.displayName.trim().isNotEmpty && club.name != 'Por definir';
}

MaterialStateProperty<Color?> _buildMatchRowColor({
  required int index,
  required int? groupIndex,
  required AppDataTableColors colors,
}) {
  return MaterialStateProperty.resolveWith((states) {
    if (groupIndex != null) {
      return groupIndex.isEven ? colors.oddRowBackground : colors.evenRowBackground;
    }
    return index.isEven ? colors.evenRowBackground : colors.oddRowBackground;
  });
}

_MatchdayPoints _buildMatchdayPoints(List<MatchdaySummaryMatch> matches) {
  final pointsByClubId = <int, int>{};
  final pointsByClubName = <String, int>{};

  void addPoints(SummaryClub club, int points) {
    if (club.id != 0) {
      pointsByClubId[club.id] = (pointsByClubId[club.id] ?? 0) + points;
      return;
    }
    final normalized = _normalizeName(club.displayName);
    pointsByClubName[normalized] = (pointsByClubName[normalized] ?? 0) + points;
  }

  for (final match in matches) {
    if (!_hasRealClub(match.homeClub) || !_hasRealClub(match.awayClub)) {
      continue;
    }
    for (final category in match.categories) {
      final homeScore = category.homeScore;
      final awayScore = category.awayScore;
      if (homeScore == null || awayScore == null) {
        continue;
      }
      if (homeScore == awayScore) {
        addPoints(match.homeClub!, 1);
        addPoints(match.awayClub!, 1);
      } else if (homeScore > awayScore) {
        addPoints(match.homeClub!, 3);
      } else {
        addPoints(match.awayClub!, 3);
      }
    }
  }

  return _MatchdayPoints(
    byClubId: pointsByClubId,
    byClubName: pointsByClubName,
  );
}

_MatchdayClubShortNames _buildClubShortNames(List<MatchdaySummaryMatch> matches) {
  final byClubId = <int, String>{};
  final byClubName = <String, String>{};

  void registerClub(SummaryClub? club) {
    if (!_hasRealClub(club)) {
      return;
    }
    final shortName = club!.shortName?.trim();
    if (shortName == null || shortName.isEmpty) {
      return;
    }
    byClubId[club.id] = shortName;
    byClubName[_normalizeName(club.name)] = shortName;
    byClubName[_normalizeName(club.displayName)] = shortName;
  }

  for (final match in matches) {
    registerClub(match.homeClub);
    registerClub(match.awayClub);
  }

  return _MatchdayClubShortNames(byClubId: byClubId, byClubName: byClubName);
}

_ScoreboardGrouping _buildScoreboardGrouping(
  MatchdayScoreboard scoreboard,
  List<MatchdaySummaryMatch> matches,
) {
  final rowsById = <int, MatchdayScoreboardRow>{
    for (final row in scoreboard.rows)
      if (row.clubId != 0) row.clubId: row,
  };
  final rowsByName = <String, MatchdayScoreboardRow>{
    for (final row in scoreboard.rows) _normalizeName(row.clubName): row,
  };
  final usedKeys = <String>{};
  final orderedRows = <MatchdayScoreboardRow>[];
  final clubGroupIndexes = <int, int>{};
  final clubNameGroupIndexes = <String, int>{};
  final byeClubs = <String>[];
  final byeClubKeys = <String>{};
  var groupIndex = 0;

  void addRow(MatchdayScoreboardRow? row, {int? group}) {
    if (row == null) {
      return;
    }
    final key = row.clubId != 0 ? 'id-${row.clubId}' : 'name-${_normalizeName(row.clubName)}';
    if (!usedKeys.add(key)) {
      return;
    }
    if (byeClubKeys.contains(key)) {
      return;
    }
    orderedRows.add(row);
    if (group != null) {
      if (row.clubId != 0) {
        clubGroupIndexes[row.clubId] = group;
      }
      clubNameGroupIndexes[_normalizeName(row.clubName)] = group;
    }
  }

  for (final match in matches) {
    final hasHome = _hasRealClub(match.homeClub);
    final hasAway = _hasRealClub(match.awayClub);

    if (hasHome && hasAway) {
      addRow(rowsById[match.homeClub!.id] ?? rowsByName[_normalizeName(match.homeClub!.displayName)],
          group: groupIndex);
      addRow(rowsById[match.awayClub!.id] ?? rowsByName[_normalizeName(match.awayClub!.displayName)],
          group: groupIndex);
      groupIndex += 1;
      continue;
    }

    if (hasHome || hasAway) {
      final club = hasHome ? match.homeClub! : match.awayClub!;
      byeClubs.add(club.displayName);
      if (club.id != 0) {
        byeClubKeys.add('id-${club.id}');
      }
      byeClubKeys.add('name-${_normalizeName(club.displayName)}');
      groupIndex += 1;
    }
  }

  for (final row in scoreboard.rows) {
    addRow(row);
  }

  return _ScoreboardGrouping(
    rows: orderedRows,
    clubGroupIndexes: clubGroupIndexes,
    clubNameGroupIndexes: clubNameGroupIndexes,
    byeClubs: byeClubs,
  );
}

class _ScoreboardGrouping {
  _ScoreboardGrouping({
    required this.rows,
    required this.clubGroupIndexes,
    required this.clubNameGroupIndexes,
    required this.byeClubs,
  });

  final List<MatchdayScoreboardRow> rows;
  final Map<int, int> clubGroupIndexes;
  final Map<String, int> clubNameGroupIndexes;
  final List<String> byeClubs;
}

class _MatchdayPoints {
  const _MatchdayPoints({
    required this.byClubId,
    required this.byClubName,
  });

  final Map<int, int> byClubId;
  final Map<String, int> byClubName;
}

class _MatchdayClubShortNames {
  const _MatchdayClubShortNames({
    required this.byClubId,
    required this.byClubName,
  });

  final Map<int, String> byClubId;
  final Map<String, String> byClubName;
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
