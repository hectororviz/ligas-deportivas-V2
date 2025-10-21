import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';
import '../../leagues/presentation/leagues_page.dart';

final selectedLeagueProvider = StateProvider<int?>((ref) => null);

final tournamentsProvider = FutureProvider.autoDispose<List<Tournament>>((ref) async {
  final leagueId = ref.watch(selectedLeagueProvider);
  final api = ref.read(apiClientProvider);
  if (leagueId == null) {
    return [];
  }
  final response = await api.get<List<dynamic>>('/leagues/$leagueId/tournaments');
  final data = response.data ?? [];
  return data.map((json) => Tournament.fromJson(json as Map<String, dynamic>)).toList();
});

class TournamentsPage extends ConsumerWidget {
  const TournamentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leagues = ref.watch(leaguesProvider);
    final tournaments = ref.watch(tournamentsProvider);
    final selectedLeague = ref.watch(selectedLeagueProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leagues.when(
            data: (items) => DropdownButton<int>(
              value: selectedLeague,
              hint: const Text('Selecciona una liga'),
              onChanged: (value) => ref.read(selectedLeagueProvider.notifier).state = value,
              items: items
                  .map((league) => DropdownMenuItem<int>(
                        value: league.id,
                        child: Text(league.name),
                      ))
                  .toList(),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => Text('Error: $error'),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: tournaments.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text('Selecciona una liga para ver sus torneos.'));
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final tournament = items[index];
                    return Card(
                      child: ListTile(
                        title: Text(tournament.name),
                        subtitle: Text('${tournament.year} • ${tournament.championMode}'),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error al cargar torneos: $error')),
            ),
          )
        ],
      ),
    );
  }
}

class Tournament {
  const Tournament({
    required this.id,
    required this.name,
    required this.year,
    required this.championMode
  });

  factory Tournament.fromJson(Map<String, dynamic> json) => Tournament(
        id: json['id'] as int,
        name: json['name'] as String,
        year: json['year'] as int,
        championMode: json['championMode'] as String? ?? 'GLOBAL',
      );

  final int id;
  final String name;
  final int year;
  final String championMode;
}
