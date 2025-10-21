import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';

final standingsProvider = FutureProvider.autoDispose<List<StandingsGroup>>((ref) async {
  final tournamentId = ref.watch(_tournamentIdProvider);
  if (tournamentId == null) {
    return [];
  }
  final api = ref.read(apiClientProvider);
  final response = await api.get<List<dynamic>>('/tournaments/$tournamentId/standings');
  final data = response.data ?? [];
  return data.map((json) => StandingsGroup.fromJson(json as Map<String, dynamic>)).toList();
});

final _tournamentIdProvider = StateProvider<int?>((ref) => null);

class StandingsPage extends ConsumerWidget {
  const StandingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standings = ref.watch(standingsProvider);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 200,
                child: TextField(
                  decoration: const InputDecoration(labelText: 'ID Torneo'),
                  keyboardType: TextInputType.number,
                  onSubmitted: (value) {
                    final id = int.tryParse(value);
                    ref.read(_tournamentIdProvider.notifier).state = id;
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(standingsProvider);
                },
                child: const Text('Actualizar'),
              )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: standings.when(
              data: (groups) {
                if (groups.isEmpty) {
                  return const Center(child: Text('Ingresa un torneo para consultar sus tablas.'));
                }
                return ListView(
                  children: groups
                      .map(
                        (group) => Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.categoryName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Club')),
                                    DataColumn(label: Text('Pts')),
                                    DataColumn(label: Text('PJ')),
                                    DataColumn(label: Text('PG')),
                                    DataColumn(label: Text('PE')),
                                    DataColumn(label: Text('PP')),
                                    DataColumn(label: Text('GF')),
                                    DataColumn(label: Text('GC')),
                                  ],
                                  rows: group.standings
                                      .map(
                                        (row) => DataRow(cells: [
                                          DataCell(Text(row.clubName)),
                                          DataCell(Text(row.points.toString())),
                                          DataCell(Text(row.played.toString())),
                                          DataCell(Text(row.wins.toString())),
                                          DataCell(Text(row.draws.toString())),
                                          DataCell(Text(row.losses.toString())),
                                          DataCell(Text(row.goalsFor.toString())),
                                          DataCell(Text(row.goalsAgainst.toString())),
                                        ]),
                                      )
                                      .toList(),
                                )
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error al obtener tablas: $error')),
            ),
          )
        ],
      ),
    );
  }
}

class StandingsGroup {
  const StandingsGroup({required this.categoryName, required this.standings});

  factory StandingsGroup.fromJson(Map<String, dynamic> json) => StandingsGroup(
        categoryName: json['categoryName'] as String? ?? 'Categoría',
        standings: (json['standings'] as List<dynamic>? ?? [])
            .map((row) => StandingRow.fromJson(row as Map<String, dynamic>))
            .toList(),
      );

  final String categoryName;
  final List<StandingRow> standings;
}

class StandingRow {
  const StandingRow({
    required this.clubName,
    required this.points,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst
  });

  factory StandingRow.fromJson(Map<String, dynamic> json) => StandingRow(
        clubName: (json['club']['name'] as String?) ?? 'Club',
        points: json['points'] as int? ?? 0,
        played: json['played'] as int? ?? 0,
        wins: json['wins'] as int? ?? 0,
        draws: json['draws'] as int? ?? 0,
        losses: json['losses'] as int? ?? 0,
        goalsFor: json['goalsFor'] as int? ?? 0,
        goalsAgainst: json['goalsAgainst'] as int? ?? 0,
      );

  final String clubName;
  final int points;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
}
