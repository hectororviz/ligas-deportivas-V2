import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../services/api_client.dart';
import '../domain/standings_models.dart';
import 'standings_table.dart';

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
    final isMobile = Responsive.isMobile(context);
    final cardPadding = isMobile ? const EdgeInsets.all(12) : const EdgeInsets.all(20);
    final tilePadding = isMobile
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    final tileChildrenPadding =
        isMobile ? const EdgeInsets.fromLTRB(12, 0, 12, 12) : const EdgeInsets.fromLTRB(20, 0, 20, 16);

    final listPadding = isMobile
        ? const EdgeInsets.fromLTRB(8, 16, 8, 16)
        : const EdgeInsets.all(24);

    return ListView(
      padding: listPadding,
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
            padding: cardPadding,
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
                StandingsTable(
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
              padding: cardPadding,
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
