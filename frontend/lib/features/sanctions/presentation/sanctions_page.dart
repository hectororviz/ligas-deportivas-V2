import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/responsive.dart';
import '../../../services/api_client.dart';
import '../../shared/widgets/page_scaffold.dart';
import '../domain/sanctions_models.dart';
import '../providers/sanctions_provider.dart';

// Provider para lista de torneos activos
final activeTournamentsProvider = FutureProvider<List<_TournamentSummary>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<List<dynamic>>('/tournaments');
  final data = response.data ?? [];
  return data
      .whereType<Map<String, dynamic>>()
      .where((t) => t['status'] == 'ACTIVE')
      .map((t) => _TournamentSummary(
            id: t['id'] as int,
            name: '${t['name']} ${t['year']}',
          ))
      .toList();
});

class _TournamentSummary {
  final int id;
  final String name;

  _TournamentSummary({required this.id, required this.name});
}

class SanctionsPage extends ConsumerStatefulWidget {
  final int? tournamentId;
  final String? tournamentName;

  const SanctionsPage({
    super.key,
    this.tournamentId,
    this.tournamentName,
  });

  @override
  ConsumerState<SanctionsPage> createState() => _SanctionsPageState();
}

class _SanctionsPageState extends ConsumerState<SanctionsPage> {
  int? _selectedTournamentId;
  String? _selectedTournamentName;

  @override
  void initState() {
    super.initState();
    _selectedTournamentId = widget.tournamentId;
    _selectedTournamentName = widget.tournamentName;
  }

  @override
  Widget build(BuildContext context) {
    // Si no hay torneo seleccionado, mostrar selector
    if (_selectedTournamentId == null) {
      return _TournamentSelector(
        onSelect: (id, name) {
          setState(() {
            _selectedTournamentId = id;
            _selectedTournamentName = name;
          });
        },
      );
    }

    return _SanctionsDetailPage(
      tournamentId: _selectedTournamentId!,
      tournamentName: _selectedTournamentName!,
      onBack: () {
        setState(() {
          _selectedTournamentId = null;
          _selectedTournamentName = null;
        });
      },
    );
  }
}

class _TournamentSelector extends ConsumerWidget {
  final Function(int, String) onSelect;

  const _TournamentSelector({required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentsAsync = ref.watch(activeTournamentsProvider);

    return PageScaffold(
      backgroundColor: Colors.transparent,
      builder: (context, scrollController) {
        final padding = Responsive.pagePadding(context);

        return ListView(
          controller: scrollController,
          padding: padding,
          children: [
            Text(
              'Sanciones',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecciona un torneo para ver y gestionar las sanciones disciplinarias.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            tournamentsAsync.when(
              data: (tournaments) {
                if (tournaments.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('No hay torneos activos disponibles.'),
                      ),
                    ),
                  );
                }
                return Column(
                  children: tournaments.map((t) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          Icons.emoji_events_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(t.name),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => onSelect(t.id, t.name),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Error cargando torneos: $error'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SanctionsDetailPage extends ConsumerWidget {
  final int tournamentId;
  final String tournamentName;
  final VoidCallback onBack;

  const _SanctionsDetailPage({
    required this.tournamentId,
    required this.tournamentName,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sanctionsAsync = ref.watch(tournamentSanctionsProvider(tournamentId));
    final rulesAsync = ref.watch(disciplinaryRulesProvider(tournamentId));

    return PageScaffold(
      backgroundColor: Colors.transparent,
      builder: (context, scrollController) {
        final isMobile = Responsive.isMobile(context);
        final padding = Responsive.pagePadding(context);

        return ListView(
          controller: scrollController,
          padding: padding,
          children: [
            // Header
            _buildHeader(context),
            const SizedBox(height: 16),

            // Reglas disciplinarias
            rulesAsync.when(
              data: (rules) => _DisciplinaryRulesCard(
                rules: rules,
                onEdit: () => _showEditRulesDialog(context, ref, rules),
              ),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error cargando reglas: $error'),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Resumen de sanciones
            sanctionsAsync.when(
              data: (sanctions) => Column(
                children: [
                  // Tarjetas pendientes
                  if (sanctions.pending.isNotEmpty) ...[
                    _PendingCardsSection(
                      cards: sanctions.pending,
                      onCreateSuspension: (card) => _showCreateSuspensionDialog(
                        context,
                        ref,
                        card.playerId,
                        [card.id],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Suspensiones activas
                  if (sanctions.active.isNotEmpty) ...[
                    _ActiveSuspensionsSection(
                      suspensions: sanctions.active,
                      onUpdate: (suspension) => _showUpdateSuspensionDialog(
                        context,
                        ref,
                        suspension,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Historial
                  if (sanctions.history.isNotEmpty)
                    _HistorySection(history: sanctions.history),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Error cargando sanciones: $error'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver'),
            ),
          ],
        ),
        Text(
          'Sanciones',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          tournamentName,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Gestión de tarjetas, suspensiones y deducciones de puntos',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  void _showEditRulesDialog(BuildContext context, WidgetRef ref, DisciplinaryRules rules) {
    // TODO: Implementar diálogo de edición de reglas
  }

  void _showCreateSuspensionDialog(
    BuildContext context,
    WidgetRef ref,
    int playerId,
    List<int> cardIds,
  ) {
    // TODO: Implementar diálogo de creación de suspensión
  }

  void _showUpdateSuspensionDialog(
    BuildContext context,
    WidgetRef ref,
    PlayerSuspension suspension,
  ) {
    // TODO: Implementar diálogo de actualización de suspensión
  }
}

class _DisciplinaryRulesCard extends StatelessWidget {
  final DisciplinaryRules rules;
  final VoidCallback onEdit;

  const _DisciplinaryRulesCard({
    required this.rules,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.gavel_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Reglas Disciplinarias',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                _RuleItem(
                  label: 'Límite amarillas',
                  value: '${rules.yellowCardLimit}',
                  sublabel: 'Suspensión: ${rules.yellowLimitSuspensionMatches} fecha(s)',
                ),
                _RuleItem(
                  label: 'Roja directa',
                  value: '${rules.directRedSuspensionMatches}',
                  sublabel: 'fecha(s) de suspensión',
                ),
                _RuleItem(
                  label: 'Doble amarilla',
                  value: '${rules.doubleYellowSuspensionMatches}',
                  sublabel: 'fecha(s) de suspensión',
                ),
                _RuleItem(
                  label: 'Reset por fase',
                  value: rules.resetYellowsOnPhaseChange ? 'Sí' : 'No',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final String label;
  final String value;
  final String? sublabel;

  const _RuleItem({
    required this.label,
    required this.value,
    this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        if (sublabel != null)
          Text(
            sublabel!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}

class _PendingCardsSection extends StatelessWidget {
  final List<PlayerCard> cards;
  final Function(PlayerCard) onCreateSuspension;

  const _PendingCardsSection({
    required this.cards,
    required this.onCreateSuspension,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.credit_card_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tarjetas Pendientes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Chip(
                  label: Text('${cards.length}'),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                ),
              ],
            ),
            const Divider(height: 24),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final card = cards[index];
                return ListTile(
                  leading: _CardTypeIcon(cardType: card.cardType),
                  title: Text(card.player?.fullName ?? 'Jugador ${card.playerId}'),
                  subtitle: Text(card.club?.name ?? 'Club ${card.clubId}'),
                  trailing: TextButton.icon(
                    onPressed: () => onCreateSuspension(card),
                    icon: const Icon(Icons.add),
                    label: const Text('Suspender'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CardTypeIcon extends StatelessWidget {
  final CardType cardType;

  const _CardTypeIcon({required this.cardType});

  @override
  Widget build(BuildContext context) {
    final color = cardType == CardType.RED ? Colors.red : Colors.amber;
    return Container(
      width: 24,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.darken(0.2)),
      ),
    );
  }
}

class _ActiveSuspensionsSection extends StatelessWidget {
  final List<PlayerSuspension> suspensions;
  final Function(PlayerSuspension) onUpdate;

  const _ActiveSuspensionsSection({
    required this.suspensions,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.block_outlined,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Suspensiones Activas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Chip(
                  label: Text('${suspensions.length}'),
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                ),
              ],
            ),
            const Divider(height: 24),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: suspensions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final suspension = suspensions[index];
                return ListTile(
                  title: Text(suspension.player?.fullName ?? 'Jugador ${suspension.playerId}'),
                  subtitle: Text(
                    '${suspension.remainingMatches} de ${suspension.originalMatches} fecha(s) restantes',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (suspension.reason != null)
                        Tooltip(
                          message: suspension.reason!,
                          child: const Icon(Icons.info_outline),
                        ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => onUpdate(suspension),
                        child: const Text('Gestionar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  final List<dynamic> history;

  const _HistorySection({required this.history});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Historial',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Chip(
                  label: Text('${history.length}'),
                ),
              ],
            ),
            const Divider(height: 24),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = history[index];
                if (item is PlayerSuspension) {
                  return ListTile(
                    leading: Icon(
                      item.status == SuspensionStatus.COMPLETED
                          ? Icons.check_circle_outlined
                          : Icons.cancel_outlined,
                      color: item.status == SuspensionStatus.COMPLETED
                          ? Colors.green
                          : Colors.grey,
                    ),
                    title: Text(item.player?.fullName ?? 'Jugador ${item.playerId}'),
                    subtitle: Text('Suspensión ${item.status.name.toLowerCase()}'),
                    trailing: Text(
                      '${item.originalMatches} fecha(s)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                } else if (item is PointDeduction) {
                  return ListTile(
                    leading: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                    ),
                    title: Text(item.club?.name ?? 'Club ${item.clubId}'),
                    subtitle: Text(item.reason),
                    trailing: Text(
                      '-${item.points} pts',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

extension on Color {
  Color darken(double amount) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}
