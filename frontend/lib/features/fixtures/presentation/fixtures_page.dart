import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/responsive.dart';
import '../../../services/api_client.dart';
import '../../zones/domain/zone_models.dart';
import '../../zones/presentation/zone_fixture_page.dart';

final fixturesTournamentsProvider =
    FutureProvider<List<FixtureTournament>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<List<dynamic>>('/zones');
  final data = response.data ?? <dynamic>[];
  final zones = data
      .whereType<Map<String, dynamic>>()
      .map((json) => ZoneSummary.fromJson(json))
      .where((zone) =>
          zone.status == ZoneStatus.inProgress ||
          zone.status == ZoneStatus.playing)
      .toList();

  final grouped = <int, _FixtureTournamentBuilder>{};
  for (final zone in zones) {
    final builder = grouped.putIfAbsent(
      zone.tournamentId,
      () => _FixtureTournamentBuilder(
        id: zone.tournamentId,
        name: zone.tournamentName,
        year: zone.tournamentYear,
        leagueName: zone.leagueName,
      ),
    );
    builder.zones.add(zone);
  }

  final tournaments = grouped.values
      .map((builder) => builder.build())
      .where((tournament) => tournament.zones.isNotEmpty)
      .toList()
    ..sort((a, b) {
      final yearComparison = b.year.compareTo(a.year);
      if (yearComparison != 0) {
        return yearComparison;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

  for (final tournament in tournaments) {
    tournament.zones
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  return tournaments;
});

class FixturesPage extends ConsumerWidget {
  const FixturesPage({super.key});

  void _openZoneFixture(BuildContext context, ZoneSummary zone) {
    GoRouter.of(context).push(
      '/zones/${zone.id}/fixture',
      extra: const ZoneFixturePageArgs(viewOnly: true),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentsAsync = ref.watch(fixturesTournamentsProvider);

    return tournamentsAsync.when(
      data: (tournaments) {
        final padding = Responsive.pagePadding(context);
        if (tournaments.isEmpty) {
          return Center(
            child: Padding(
              padding: padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline,
                      size: 56, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'No hay torneos en juego por el momento.',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cuando haya torneos en curso podrás navegar sus zonas y ver los fixtures desde aquí.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: padding,
          itemCount: tournaments.length,
          itemBuilder: (context, index) {
            final tournament = tournaments[index];
            return _TournamentAccordion(
              tournament: tournament,
              onOpenZone: (zone) => _openZoneFixture(context, zone),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        final padding = Responsive.pagePadding(context);
        return Center(
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(
                  'No pudimos cargar los torneos en juego.',
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
                  onPressed: () => ref.invalidate(fixturesTournamentsProvider),
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

class FixtureTournament {
  FixtureTournament({
    required this.id,
    required this.name,
    required this.year,
    required this.leagueName,
    required this.zones,
  });

  final int id;
  final String name;
  final int year;
  final String leagueName;
  final List<ZoneSummary> zones;

  String get displayName => name;
}

class _FixtureTournamentBuilder {
  _FixtureTournamentBuilder({
    required this.id,
    required this.name,
    required this.year,
    required this.leagueName,
  });

  final int id;
  final String name;
  final int year;
  final String leagueName;
  final List<ZoneSummary> zones = <ZoneSummary>[];

  FixtureTournament build() {
    return FixtureTournament(
      id: id,
      name: name,
      year: year,
      leagueName: leagueName,
      zones: List<ZoneSummary>.from(zones),
    );
  }
}

class _TournamentAccordion extends StatelessWidget {
  const _TournamentAccordion({
    required this.tournament,
    required this.onOpenZone,
  });

  final FixtureTournament tournament;
  final ValueChanged<ZoneSummary> onOpenZone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        key: PageStorageKey('tournament-${tournament.id}'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Text(
          tournament.displayName,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle:
            Text(tournament.leagueName, style: theme.textTheme.bodyMedium),
        children: [
          for (final zone in tournament.zones)
            _ZoneAccordion(
              zone: zone,
              onOpen: () => onOpenZone(zone),
            ),
        ],
      ),
    );
  }
}

class _ZoneAccordion extends StatelessWidget {
  const _ZoneAccordion({
    required this.zone,
    required this.onOpen,
  });

  final ZoneSummary zone;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 600;

            final header = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  zone.name,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Clubes: ${zone.clubCount} · Partidos: ${zone.matchCount}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            );

            final actions = Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: isCompact ? WrapAlignment.start : WrapAlignment.end,
              children: [
                ZoneStatusChip(status: zone.status),
                FilledButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Ver fixture'),
                ),
              ],
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  header,
                  const SizedBox(height: 12),
                  actions,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: header),
                const SizedBox(width: 12),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}
