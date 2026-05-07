import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/responsive.dart';
import '../../../services/api_client.dart';
import '../../shared/widgets/page_scaffold.dart';
import '../domain/sanctions_models.dart';
import '../providers/sanctions_provider.dart';
import 'create_suspension_dialog.dart';
import 'edit_rules_dialog.dart';

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
                        card,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Sanciones Vigentes (activas con partidos pendientes)
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

                  // Sanciones Cumplidas (completed)
                  if (sanctions.completed.isNotEmpty) ...[
                    _CompletedSuspensionsSection(
                      suspensions: sanctions.completed,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Sanciones Canceladas
                  if (sanctions.cancelled.isNotEmpty) ...[
                    _CancelledSuspensionsSection(
                      suspensions: sanctions.cancelled,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Deducciones de Puntos
                  if (sanctions.deductions.isNotEmpty) ...[
                    _DeductionsSection(deductions: sanctions.deductions),
                    const SizedBox(height: 16),
                  ],
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
    showDialog(
      context: context,
      builder: (context) => EditRulesDialog(
        rules: rules,
        onSave: (updated) async {
          final service = ref.read(sanctionsServiceProvider);
          try {
            await service.updateDisciplinaryRules(
              tournamentId,
              UpdateDisciplinaryRulesDto(
                yellowCardLimit: updated.yellowCardLimit,
                yellowLimitSuspensionMatches: updated.yellowLimitSuspensionMatches,
                directRedSuspensionMatches: updated.directRedSuspensionMatches,
                doubleYellowSuspensionMatches: updated.doubleYellowSuspensionMatches,
                resetYellowsOnPhaseChange: updated.resetYellowsOnPhaseChange,
              ),
            );
            ref.invalidate(disciplinaryRulesProvider(tournamentId));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reglas actualizadas correctamente')),
              );
            }
          } catch (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error al actualizar reglas: $error')),
              );
            }
          }
        },
      ),
    );
  }

  void _showCreateSuspensionDialog(
    BuildContext context,
    WidgetRef ref,
    PlayerCard card,
  ) async {
    final playerName = card.player?.fullName ?? 'Jugador ${card.playerId}';
    
    final result = await showDialog<CreateSuspensionResult>(
      context: context,
      builder: (context) => CreateSuspensionDialog(
        playerName: playerName,
        yellowCardCount: card.yellowCount ?? 0,
      ),
    );
    
    // If user cancelled, result is null
    if (result == null) return;
    
    final service = ref.read(sanctionsServiceProvider);
    
    try {
      await service.createSuspension(
        tournamentId,
        CreateSuspensionDto(
          playerId: card.playerId,
          originalMatches: result.originalMatches,
          cardIds: [card.id],
          reason: result.reason,
        ),
      );
      
      // Invalidate the cache to refresh the data
      ref.invalidate(tournamentSanctionsProvider(tournamentId));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Suspensión creada para $playerName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear suspensión: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUpdateSuspensionDialog(
    BuildContext context,
    WidgetRef ref,
    PlayerSuspension suspension,
  ) {
    // TODO: Implementar diálogo de actualización de suspensión
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gestionar Suspensión'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jugador: ${suspension.player?.fullName ?? suspension.playerId}'),
            Text('Fechas restantes: ${suspension.remainingMatches}'),
            const SizedBox(height: 16),
            if (suspension.reason != null)
              Text('Motivo: ${suspension.reason}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          if (suspension.status == SuspensionStatus.ACTIVE)
            TextButton(
              onPressed: () async {
                final service = ref.read(sanctionsServiceProvider);
                final notifier = ref.read(sanctionsNotifierProvider.notifier);
                
                try {
                  await service.updateSuspension(
                    suspension.id,
                    UpdateSuspensionDto(status: SuspensionStatus.CANCELLED),
                  );
                  
                  notifier.invalidateTournamentSanctions(tournamentId);
                  
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Suspensión cancelada')),
                    );
                  }
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $error')),
                    );
                  }
                }
              },
              child: const Text('Cancelar Suspensión'),
            ),
        ],
      ),
    );
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
                final matchInfo = card.matchCategory?.match;
                final matchDisplay = matchInfo?.displayName ?? 'Partido desconocido';
                
                // Determinar estado de la tarjeta
                String? statusText;
                Color? statusColor;
                if (card.cardType == CardType.YELLOW) {
                  if (card.canSuspend) {
                    statusText = 'Límite alcanzado (${card.yellowCount}/${card.yellowCount})';
                    statusColor = Colors.orange;
                  } else {
                    statusText = '${card.yellowCount} amarilla(s)';
                    statusColor = Colors.grey;
                  }
                }
                
                return ListTile(
                  leading: _CardTypeIcon(cardType: card.cardType),
                  title: Text(card.player?.fullName ?? 'Jugador ${card.playerId}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card.club?.name ?? 'Club ${card.clubId}'),
                      const SizedBox(height: 2),
                      Text(
                        matchDisplay,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      if (card.minute != null)
                        Text(
                          'Minuto: ${card.minute}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (statusText != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor?.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: card.canSuspend
                    ? TextButton.icon(
                        onPressed: () => onCreateSuspension(card),
                        icon: const Icon(Icons.add),
                        label: const Text('Suspender'),
                      )
                    : Chip(
                        label: const Text('No aplica'),
                        backgroundColor: Colors.grey.shade200,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
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
                    'Sanciones Vigentes',
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

class _CompletedSuspensionsSection extends StatelessWidget {
  final List<PlayerSuspension> suspensions;

  const _CompletedSuspensionsSection({required this.suspensions});

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
                  Icons.check_circle_outlined,
                  color: Colors.green,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sanciones Cumplidas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Chip(
                  label: Text('${suspensions.length}'),
                  backgroundColor: Colors.green.shade100,
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
                  leading: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                  title: Text(suspension.player?.fullName ?? 'Jugador ${suspension.playerId}'),
                  subtitle: Text(
                    '${suspension.originalMatches} fecha(s) - Cumplida',
                  ),
                  trailing: suspension.reason != null
                      ? Tooltip(
                          message: suspension.reason!,
                          child: const Icon(Icons.info_outline),
                        )
                      : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CancelledSuspensionsSection extends StatelessWidget {
  final List<PlayerSuspension> suspensions;

  const _CancelledSuspensionsSection({required this.suspensions});

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
                  Icons.cancel_outlined,
                  color: Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sanciones Canceladas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Chip(
                  label: Text('${suspensions.length}'),
                  backgroundColor: Colors.grey.shade200,
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
                  leading: const Icon(
                    Icons.cancel,
                    color: Colors.grey,
                  ),
                  title: Text(suspension.player?.fullName ?? 'Jugador ${suspension.playerId}'),
                  subtitle: Text(
                    '${suspension.originalMatches} fecha(s) - Cancelada',
                  ),
                  trailing: suspension.reason != null
                      ? Tooltip(
                          message: suspension.reason!,
                          child: const Icon(Icons.info_outline),
                        )
                      : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DeductionsSection extends StatelessWidget {
  final List<PointDeduction> deductions;

  const _DeductionsSection({required this.deductions});

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
                  Icons.remove_circle_outline,
                  color: Colors.red,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Deducciones de Puntos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Chip(
                  label: Text('${deductions.length}'),
                  backgroundColor: Colors.red.shade100,
                ),
              ],
            ),
            const Divider(height: 24),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: deductions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final deduction = deductions[index];
                return ListTile(
                  leading: const Icon(
                    Icons.remove_circle,
                    color: Colors.red,
                  ),
                  title: Text(deduction.club?.name ?? 'Club ${deduction.clubId}'),
                  subtitle: Text(deduction.reason),
                  trailing: Text(
                    '-${deduction.points} pts',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
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

extension on Color {
  Color darken(double amount) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}
