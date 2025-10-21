import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';

final leaguesProvider = FutureProvider<List<League>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<List<dynamic>>('/leagues');
  final data = response.data ?? [];
  return data.map((json) => League.fromJson(json as Map<String, dynamic>)).toList();
});

class LeaguesPage extends ConsumerWidget {
  const LeaguesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leagues = ref.watch(leaguesProvider);
    return leagues.when(
      data: (items) => ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final league = items[index];
          return Card(
            child: ListTile(
              title: Text(league.name),
              subtitle: Text('Color: ${league.colorHex}'),
              leading: CircleAvatar(backgroundColor: league.color),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('No se pudieron cargar las ligas: $error'),
      ),
    );
  }
}

class League {
  const League({required this.id, required this.name, required this.colorHex});

  factory League.fromJson(Map<String, dynamic> json) => League(
        id: json['id'] as int,
        name: json['name'] as String,
        colorHex: json['colorHex'] as String? ?? '#0057B8',
      );

  final int id;
  final String name;
  final String colorHex;

  Color get color => Color(int.parse(colorHex.replaceFirst('#', '0xff')));
}
