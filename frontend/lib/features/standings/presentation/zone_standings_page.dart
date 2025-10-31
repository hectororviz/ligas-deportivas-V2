import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';

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

class _ZoneStandingsView extends StatelessWidget {
  const _ZoneStandingsView({required this.data});

  final ZoneStandingsData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  rows: data.general,
                  emptyMessage: 'Todavía no hay datos para la tabla general.',
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
                    rows: category.standings,
                    emptyMessage: 'No hay datos para esta categoría.',
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
  const _StandingsTable({required this.rows, required this.emptyMessage});

  final List<StandingsRow> rows;
  final String emptyMessage;

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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
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
    final generalRows = (json['general'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(StandingsRow.fromJson)
        .toList();
    final categoryRows = (json['categories'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ZoneCategoryStandings.fromJson)
        .toList();

    return ZoneStandingsData(
      zone: ZoneStandingsInfo.fromJson(json['zone'] as Map<String, dynamic>? ?? <String, dynamic>{}),
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
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Zona',
      tournamentId: json['tournamentId'] as int? ?? 0,
      tournamentName: json['tournamentName'] as String? ?? 'Torneo',
      tournamentYear: json['tournamentYear'] as int? ?? 0,
      leagueId: json['leagueId'] as int? ?? 0,
      leagueName: json['leagueName'] as String? ?? 'Liga',
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
      tournamentCategoryId: json['tournamentCategoryId'] as int? ?? 0,
      categoryId: json['categoryId'] as int? ?? 0,
      categoryName: json['categoryName'] as String? ?? 'Categoría',
      countsForGeneral: json['countsForGeneral'] as bool? ?? true,
      standings: (json['standings'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(StandingsRow.fromJson)
          .toList(),
    );
  }

  final int tournamentCategoryId;
  final int categoryId;
  final String categoryName;
  final bool countsForGeneral;
  final List<StandingsRow> standings;
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
    final club = json['club'] as Map<String, dynamic>?;
    final goalsFor = json['goalsFor'] as int? ?? 0;
    final goalsAgainst = json['goalsAgainst'] as int? ?? 0;
    return StandingsRow(
      clubId: json['clubId'] as int? ?? club?['id'] as int? ?? 0,
      clubName: json['clubName'] as String? ?? club?['name'] as String? ?? 'Club',
      played: json['played'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      draws: json['draws'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
      goalDifference: json['goalDifference'] as int? ?? goalsFor - goalsAgainst,
      points: json['points'] as int? ?? 0,
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
