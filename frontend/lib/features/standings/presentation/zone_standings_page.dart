import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/api_client.dart';
import '../../shared/widgets/app_data_table_style.dart';

final zoneStandingsProvider = FutureProvider.autoDispose.family<ZoneStandingsData, int>((ref, zoneId) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<Map<String, dynamic>>('/zones/$zoneId/standings');
  final data = response.data ?? <String, dynamic>{};
  return ZoneStandingsData.fromJson(data);
});

class ZoneStandingsPage extends ConsumerWidget {
  const ZoneStandingsPage({super.key, required this.zoneId});

  final int zoneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standingsAsync = ref.watch(zoneStandingsProvider(zoneId));

    return standingsAsync.when(
      data: (data) => _ZoneStandingsView(data: data),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(
                  'No pudimos cargar las tablas de la zona.',
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
                  onPressed: () => ref.invalidate(zoneStandingsProvider(zoneId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ZoneStandingsView extends ConsumerWidget {
  const _ZoneStandingsView({required this.data});

  final ZoneStandingsData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final leagueColors = ref.watch(leagueColorsProvider);
    final leagueColor =
        leagueColors[data.zone.leagueId] ?? theme.colorScheme.primary;
    final subtitle = '${data.zone.tournamentName} ${data.zone.tournamentYear} · ${data.zone.leagueName}';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          data.zone.name,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 24),
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
                const SizedBox(height: 12),
                Text(
                  'La tabla general suma los resultados de todas las categorías que participan en la zona (excepto las promocionales).',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                _StandingsTable(
                  storageKey: 'zone-${data.zone.id}-general-table',
                  rows: data.general,
                  emptyMessage: 'Todavía no hay datos para la tabla general.',
                  leagueColor: leagueColor,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Tablas por categoría',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (data.categories.isEmpty)
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
          ...data.categories.map(
            (category) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                key: PageStorageKey('zone-${data.zone.id}-category-${category.tournamentCategoryId}'),
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
                  _StandingsTable(
                    storageKey:
                        'zone-${data.zone.id}-category-${category.tournamentCategoryId}-table',
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

class _StandingsTable extends StatelessWidget {
  const _StandingsTable({
    required this.storageKey,
    required this.rows,
    required this.emptyMessage,
    required this.leagueColor,
  });

  final String storageKey;
  final List<StandingsRow> rows;
  final String emptyMessage;
  final Color leagueColor;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          emptyMessage,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final theme = Theme.of(context);
    final colors = AppDataTableColors.score(theme, leagueColor);
    final headerStyle =
        theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: colors.headerText);

    return SingleChildScrollView(
      key: PageStorageKey<String>(storageKey),
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: buildHeaderColor(colors.headerBackground),
        headingTextStyle: headerStyle,
        columns: const [
          DataColumn(label: Text('Posición')),
          DataColumn(label: Text('Club')),
          DataColumn(label: Text('PJ'), numeric: true),
          DataColumn(label: Text('PG'), numeric: true),
          DataColumn(label: Text('PE'), numeric: true),
          DataColumn(label: Text('PP'), numeric: true),
          DataColumn(label: Text('GF'), numeric: true),
          DataColumn(label: Text('GC'), numeric: true),
          DataColumn(label: Text('DG'), numeric: true),
          DataColumn(label: Text('Pts'), numeric: true),
        ],
        rows: [
          for (var index = 0; index < rows.length; index++)
            DataRow(
              color: buildStripedRowColor(index: index, colors: colors),
              cells: [
                DataCell(Text('${index + 1}')),
                DataCell(Text(rows[index].clubName)),
                DataCell(Text(rows[index].played.toString())),
                DataCell(Text(rows[index].wins.toString())),
                DataCell(Text(rows[index].draws.toString())),
                DataCell(Text(rows[index].losses.toString())),
                DataCell(Text(rows[index].goalsFor.toString())),
                DataCell(Text(rows[index].goalsAgainst.toString())),
                DataCell(Text(rows[index].goalDifference.toString())),
                DataCell(Text(rows[index].points.toString())),
              ],
            ),
        ],
      ),
    );
  }
}

class ZoneStandingsData {
  ZoneStandingsData({
    required this.zone,
    required this.general,
    required this.categories,
  });

  factory ZoneStandingsData.fromJson(Map<String, dynamic> json) {
    final generalRows = _parseStandingsList(json['general']);
    final categoryRows = <ZoneCategoryStandings>[];
    for (final category in _asList(json['categories'])) {
      final parsed = _tryParseCategoryStandings(_asMap(category));
      if (parsed != null) {
        categoryRows.add(parsed);
      }
    }

    return ZoneStandingsData(
      zone: ZoneStandingsInfo.fromJson(_asMap(json['zone'])),
      general: generalRows,
      categories: categoryRows,
    );
  }

  final ZoneStandingsInfo zone;
  final List<StandingsRow> general;
  final List<ZoneCategoryStandings> categories;
}

class ZoneStandingsInfo {
  ZoneStandingsInfo({
    required this.id,
    required this.name,
    required this.tournamentId,
    required this.tournamentName,
    required this.tournamentYear,
    required this.leagueId,
    required this.leagueName,
  });

  factory ZoneStandingsInfo.fromJson(Map<String, dynamic> json) {
    return ZoneStandingsInfo(
      id: _parseInt(json['id']),
      name: _parseString(json['name'], fallback: 'Zona'),
      tournamentId: _parseInt(json['tournamentId']),
      tournamentName: _parseString(json['tournamentName'], fallback: 'Torneo'),
      tournamentYear: _parseInt(json['tournamentYear']),
      leagueId: _parseInt(json['leagueId']),
      leagueName: _parseString(json['leagueName'], fallback: 'Liga'),
    );
  }

  final int id;
  final String name;
  final int tournamentId;
  final String tournamentName;
  final int tournamentYear;
  final int leagueId;
  final String leagueName;
}

class ZoneCategoryStandings {
  ZoneCategoryStandings({
    required this.tournamentCategoryId,
    required this.categoryId,
    required this.categoryName,
    required this.countsForGeneral,
    required this.standings,
  });

  factory ZoneCategoryStandings.fromJson(Map<String, dynamic> json) {
    return ZoneCategoryStandings(
      tournamentCategoryId: _parseInt(json['tournamentCategoryId']),
      categoryId: _parseInt(json['categoryId']),
      categoryName: _parseString(json['categoryName'], fallback: 'Categoría'),
      countsForGeneral: _parseBool(json['countsForGeneral'], fallback: true),
      standings: _parseStandingsList(json['standings']),
    );
  }

  final int tournamentCategoryId;
  final int categoryId;
  final String categoryName;
  final bool countsForGeneral;
  final List<StandingsRow> standings;
}

ZoneCategoryStandings? _tryParseCategoryStandings(Map<String, dynamic> json) {
  if (json.isEmpty) {
    return null;
  }
  try {
    return ZoneCategoryStandings.fromJson(json);
  } catch (_) {
    try {
      return ZoneCategoryStandings(
        tournamentCategoryId: _parseInt(json['tournamentCategoryId']),
        categoryId: _parseInt(json['categoryId']),
        categoryName: _parseString(json['categoryName'], fallback: 'Categoría'),
        countsForGeneral: _parseBool(json['countsForGeneral'], fallback: true),
        standings: _parseStandingsList(json['standings']),
      );
    } catch (_) {
      return null;
    }
  }
}

class StandingsRow {
  StandingsRow({
    required this.clubId,
    required this.clubName,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
  });

  factory StandingsRow.fromJson(Map<String, dynamic> json) {
    final club = _asMap(json['club']);
    final goalsFor = _parseInt(json['goalsFor']);
    final goalsAgainst = _parseInt(json['goalsAgainst']);
    return StandingsRow(
      clubId: _parseInt(json['clubId'], fallback: _parseInt(club['id'])),
      clubName: _parseString(json['clubName'], fallback: _parseString(club['name'], fallback: 'Club')),
      played: _parseInt(json['played']),
      wins: _parseInt(json['wins']),
      draws: _parseInt(json['draws']),
      losses: _parseInt(json['losses']),
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
      goalDifference: _parseGoalDifference(json['goalDifference'], goalsFor: goalsFor, goalsAgainst: goalsAgainst),
      points: _parseInt(json['points']),
    );
  }

  final int clubId;
  final String clubName;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;
}

List<StandingsRow> _parseStandingsList(dynamic value) {
  final rows = <StandingsRow>[];
  for (final entry in _asList(value)) {
    final parsed = _tryParseStandingsRow(_asMap(entry));
    if (parsed != null) {
      rows.add(parsed);
    }
  }
  return rows;
}

int _parseGoalDifference(dynamic value, {required int goalsFor, required int goalsAgainst}) {
  final parsed = _tryParseInt(value);
  if (parsed != null) {
    return parsed;
  }
  return goalsFor - goalsAgainst;
}

int _parseInt(dynamic value, {int fallback = 0}) {
  return _tryParseInt(value) ?? fallback;
}

int? _tryParseInt(dynamic value) {
  if (value is bool) {
    return value ? 1 : 0;
  }
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.round();
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    final parsedInt = int.tryParse(value);
    if (parsedInt != null) {
      return parsedInt;
    }
    final parsedDouble = double.tryParse(value);
    if (parsedDouble != null) {
      return parsedDouble.round();
    }
  }
  return null;
}

StandingsRow? _tryParseStandingsRow(Map<String, dynamic> json) {
  if (json.isEmpty) {
    return null;
  }
  try {
    return StandingsRow.fromJson(json);
  } catch (_) {
    try {
      final goalsFor = _parseInt(json['goalsFor']);
      final goalsAgainst = _parseInt(json['goalsAgainst']);
      return StandingsRow(
        clubId: _parseInt(json['clubId']),
        clubName: _parseString(json['clubName'], fallback: 'Club'),
        played: _parseInt(json['played']),
        wins: _parseInt(json['wins']),
        draws: _parseInt(json['draws']),
        losses: _parseInt(json['losses']),
        goalsFor: goalsFor,
        goalsAgainst: goalsAgainst,
        goalDifference: _parseGoalDifference(
          json['goalDifference'],
          goalsFor: goalsFor,
          goalsAgainst: goalsAgainst,
        ),
        points: _parseInt(json['points']),
      );
    } catch (_) {
      return null;
    }
  }
}

String _parseString(dynamic value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  if (value is String) {
    if (value.trim().isEmpty) {
      return fallback;
    }
    return value;
  }
  if (value is num || value is bool) {
    return value.toString();
  }
  return fallback;
}

bool _parseBool(dynamic value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    if (value == 1) {
      return true;
    }
    if (value == 0) {
      return false;
    }
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'si' || normalized == 'sí') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
  }
  return fallback;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, dynamic v) => MapEntry('$key', v));
  }
  return <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) {
    return value;
  }
  return const <dynamic>[];
}
