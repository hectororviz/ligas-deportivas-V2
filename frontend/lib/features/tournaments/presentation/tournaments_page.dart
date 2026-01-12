import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../services/api_client.dart';
import '../../../services/auth_controller.dart';
import '../../categories/providers/categories_catalog_provider.dart';
import '../../leagues/presentation/leagues_page.dart';
import '../../shared/widgets/app_data_table_style.dart';
import '../../shared/widgets/table_filters_bar.dart';

const _moduleTorneos = 'TORNEOS';
const _actionCreate = 'CREATE';
const _actionUpdate = 'UPDATE';

final tournamentFiltersProvider =
    StateNotifierProvider<TournamentFiltersController, TournamentFilters>(
  (ref) => TournamentFiltersController(),
);

final _leagueFilterProvider = Provider<int?>((ref) {
  return ref.watch(
    tournamentFiltersProvider.select((value) => value.leagueId),
  );
});

final _tournamentsSourceProvider =
    FutureProvider<List<TournamentSummary>>((ref) async {
  final leagueFilter = ref.watch(_leagueFilterProvider);
  final leagues = await ref.watch(leaguesProvider.future);
  if (leagues.isEmpty) {
    return [];
  }
  final api = ref.read(apiClientProvider);
  final leaguesToFetch = leagueFilter == null
      ? leagues
      : leagues.where((league) => league.id == leagueFilter).toList();
  if (leaguesToFetch.isEmpty) {
    return [];
  }
  final futures = leaguesToFetch.map((league) async {
    final response =
        await api.get<List<dynamic>>('/leagues/${league.id}/tournaments');
    final data = response.data ?? [];
    return data
        .map(
          (json) => TournamentSummary.fromJson(
            json as Map<String, dynamic>,
            league,
          ),
        )
        .toList();
  });
  final results = await Future.wait(futures);
  final tournaments = results.expand((element) => element).toList()
    ..sort((a, b) {
      final yearComparison = b.year.compareTo(a.year);
      if (yearComparison != 0) {
        return yearComparison;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  return tournaments;
});

final tournamentsProvider = Provider<AsyncValue<List<TournamentSummary>>>((ref) {
  final filters = ref.watch(tournamentFiltersProvider);
  final source = ref.watch(_tournamentsSourceProvider);
  return source.whenData((tournaments) {
    final query = filters.query.trim().toLowerCase();
    return tournaments.where((tournament) {
      if (filters.year != null && tournament.year != filters.year) {
        return false;
      }
      if (filters.status != null && tournament.status != filters.status) {
        return false;
      }
      if (query.isNotEmpty) {
        final normalizedName = tournament.name.toLowerCase();
        final normalizedLeague = tournament.leagueName.toLowerCase();
        if (!normalizedName.contains(query) &&
            !normalizedLeague.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  });
});

final availableTournamentYearsProvider = Provider<List<int>>((ref) {
  final source = ref.watch(_tournamentsSourceProvider);
  return source.maybeWhen(
    data: (tournaments) {
      final years = tournaments.map((t) => t.year).toSet().toList()
        ..sort((a, b) => b.compareTo(a));
      return years;
    },
    orElse: () => const [],
  );
});

class TournamentsPage extends ConsumerStatefulWidget {
  const TournamentsPage({super.key});

  @override
  ConsumerState<TournamentsPage> createState() => _TournamentsPageState();
}

class _TournamentsPageState extends ConsumerState<TournamentsPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<League> _filterLeaguesForPermission(
    List<League> leagues,
    AuthUser? user,
    String action,
  ) {
    if (user == null) {
      return const [];
    }
    final allowed = user.allowedLeaguesFor(module: _moduleTorneos, action: action);
    if (allowed == null) {
      return leagues;
    }
    return leagues.where((league) => allowed.contains(league.id)).toList();
  }

  Future<void> _openCreateTournament() async {
    final leagues = await ref.read(leaguesProvider.future);
    final user = ref.read(authControllerProvider).user;
    final allowedLeagues = _filterLeaguesForPermission(leagues, user, _actionCreate);
    final canConfigurePoster = user?.roles.contains('ADMIN') ?? false;
    if (!mounted) {
      return;
    }

    _TournamentFormResult? result;
    do {
      result = await _showTournamentForm(
        context,
        leagues: allowedLeagues,
        readOnly: false,
        allowedLeagueIds:
            user?.allowedLeaguesFor(module: _moduleTorneos, action: _actionCreate),
        allowSaveAndAdd: true,
        canConfigurePoster: canConfigurePoster,
      );
      if (!mounted || result == null) {
        break;
      }
      if (result == _TournamentFormResult.saved ||
          result == _TournamentFormResult.savedAndAddAnother) {
        ref.invalidate(_tournamentsSourceProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Torneo guardado correctamente.')),
        );
      }
    } while (result == _TournamentFormResult.savedAndAddAnother);
  }

  Future<void> _openEditTournament(TournamentSummary tournament) async {
    final leagues = await ref.read(leaguesProvider.future);
    final user = ref.read(authControllerProvider).user;
    final allowedLeagues = _filterLeaguesForPermission(leagues, user, _actionUpdate);
    final allowedLeagueIds =
        user?.allowedLeaguesFor(module: _moduleTorneos, action: _actionUpdate);
    final canConfigurePoster = user?.roles.contains('ADMIN') ?? false;

    if (!mounted) {
      return;
    }

    final result = await _showTournamentForm(
      context,
      tournament: tournament,
      leagues: allowedLeagues.isEmpty ? leagues : allowedLeagues,
      readOnly: false,
      allowedLeagueIds: allowedLeagueIds,
      allowSaveAndAdd: false,
      canConfigurePoster: canConfigurePoster,
    );

    if (!mounted || result == null) {
      return;
    }

    if (result == _TournamentFormResult.saved) {
      ref.invalidate(_tournamentsSourceProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Torneo "${tournament.name}" actualizado.')),
      );
    }
  }

  Future<_TournamentFormResult?> _showTournamentForm(
    BuildContext context, {
    TournamentSummary? tournament,
    required List<League> leagues,
    required bool readOnly,
    Set<int>? allowedLeagueIds,
    bool allowSaveAndAdd = false,
    required bool canConfigurePoster,
  }) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 640;
    final horizontalPadding = 48.0;
    final maxDialogWidth = 720.0;
    final estimatedContentWidth = isCompact
        ? math.max(0.0, size.width - horizontalPadding)
        : math.max(0.0, math.min(maxDialogWidth, size.width - horizontalPadding));

    final form = _TournamentFormDialog(
      leagues: leagues,
      tournament: tournament,
      readOnly: readOnly,
      allowedLeagueIds: allowedLeagueIds,
      allowSaveAndAdd: allowSaveAndAdd,
      maxContentWidth: estimatedContentWidth,
      canConfigurePoster: canConfigurePoster,
    );
    if (isCompact) {
      return showModalBottomSheet<_TournamentFormResult>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 12,
            ),
            child: form,
          );
        },
      );
    }
    return showDialog<_TournamentFormResult>(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: form,
          ),
        );
      },
    );
  }

  Future<void> _showTournamentDetails(TournamentSummary tournament) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Detalles de ${tournament.name}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _DetailRow(label: 'Liga', value: tournament.leagueName),
                _DetailRow(label: 'Año', value: tournament.year.toString()),
                _DetailRow(label: 'Estado', value: tournament.status.label),
                const SizedBox(height: 16),
                Text(
                  'Categorías participantes',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (tournament.categories.isEmpty)
                  Text(
                    'Aún no hay categorías asignadas.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  Column(
                    children: tournament.categories.map((category) {
                      final timeLabel = category.kickoffTime ?? 'Horario sin definir';
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          category.enabled ? Icons.check_circle : Icons.remove_circle_outline,
                          color: category.enabled
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).disabledColor,
                        ),
                        title: Text(category.categoryName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              category.enabled
                                  ? 'Horario: $timeLabel'
                                  : 'No participa en este torneo',
                            ),
                            Text(
                              '${category.birthYearRangeLabel} · ${category.genderLabel}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        trailing: category.promotional
                            ? const Tooltip(
                                message: 'Categoría promocional',
                                child: Icon(Icons.local_fire_department_outlined),
                              )
                            : null,
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Cerrar'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tournamentsAsync = ref.watch(tournamentsProvider);
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final isAdmin = user?.roles.contains('ADMIN') ?? false;
    final canCreate =
        isAdmin || (user?.hasPermission(module: _moduleTorneos, action: _actionCreate) ?? false);
    final years = ref.watch(availableTournamentYearsProvider);
    final leaguesAsync = ref.watch(leaguesProvider);
    final filters = ref.watch(tournamentFiltersProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _openCreateTournament,
              icon: const Icon(Icons.add),
              label: const Text('Agregar torneo'),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Torneos',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Gestiona los torneos activos de tus ligas y mantén organizada la planificación anual.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TableFiltersBar(
                        children: [
                          TableFilterField(
                            label: 'Buscar',
                            width: 320,
                            child: TableFilterSearchField(
                              controller: _searchController,
                              placeholder: 'Buscar por nombre o liga',
                              showClearButton: filters.query.isNotEmpty,
                              onChanged: (value) => ref
                                  .read(tournamentFiltersProvider.notifier)
                                  .updateQuery(value),
                              onClear: () {
                                _searchController.clear();
                                ref
                                    .read(tournamentFiltersProvider.notifier)
                                    .updateQuery('');
                              },
                            ),
                          ),
                          TableFilterField(
                            label: 'Liga',
                            width: 220,
                            child: leaguesAsync.when(
                              data: (leagues) {
                                return DropdownButtonHideUnderline(
                                  child: DropdownButton<int?>(
                                    value: filters.leagueId,
                                    isExpanded: true,
                                    items: [
                                      const DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text('Todas las ligas'),
                                      ),
                                      ...leagues.map(
                                        (league) => DropdownMenuItem<int?>(
                                          value: league.id,
                                          child: Text(league.name),
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) => ref
                                        .read(tournamentFiltersProvider.notifier)
                                        .updateLeague(value),
                                  ),
                                );
                              },
                              loading: () => const SizedBox(
                                height: 24,
                                child: LinearProgressIndicator(),
                              ),
                              error: (error, _) => Text(
                                'Error: $error',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Theme.of(context).colorScheme.error),
                              ),
                            ),
                          ),
                          TableFilterField(
                            label: 'Año',
                            width: 160,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int?>(
                                value: filters.year,
                                isExpanded: true,
                                items: [
                                  const DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text('Todos'),
                                  ),
                                  ...years.map(
                                    (year) => DropdownMenuItem<int?>(
                                      value: year,
                                      child: Text(year.toString()),
                                    ),
                                  ),
                                ],
                                onChanged: (value) => ref
                                    .read(tournamentFiltersProvider.notifier)
                                    .updateYear(value),
                              ),
                            ),
                          ),
                          TableFilterField(
                            label: 'Estado',
                            width: 220,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<TournamentStatus?>(
                                value: filters.status,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem<TournamentStatus?>(
                                    value: null,
                                    child: Text('Todos los estados'),
                                  ),
                                  DropdownMenuItem<TournamentStatus?>(
                                    value: TournamentStatus.draft,
                                    child: Text('Borrador'),
                                  ),
                                  DropdownMenuItem<TournamentStatus?>(
                                    value: TournamentStatus.scheduled,
                                    child: Text('Programado'),
                                  ),
                                  DropdownMenuItem<TournamentStatus?>(
                                    value: TournamentStatus.inProgress,
                                    child: Text('En juego'),
                                  ),
                                  DropdownMenuItem<TournamentStatus?>(
                                    value: TournamentStatus.finished,
                                    child: Text('Finalizado'),
                                  ),
                                ],
                                onChanged: (value) => ref
                                    .read(tournamentFiltersProvider.notifier)
                                    .updateStatus(value),
                              ),
                            ),
                          ),
                        ],
                        trailing: TextButton.icon(
                          onPressed: filters.isEmpty
                              ? null
                              : () {
                                  _searchController.clear();
                                  ref
                                      .read(tournamentFiltersProvider.notifier)
                                      .clear();
                                },
                          icon: const Icon(Icons.filter_alt_off_outlined),
                          label: const Text('Limpiar filtros'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      Expanded(
                        child: tournamentsAsync.when(
                          data: (tournaments) {
                            if (tournaments.isEmpty) {
                              return _EmptyTournamentsState(
                                onCreate: canCreate ? _openCreateTournament : null,
                              );
                            }
                            return _TournamentsDataTable(
                              tournaments: tournaments,
                              onDetails: _showTournamentDetails,
                              onEdit: _openEditTournament,
                              canEdit: (tournament) => user?.hasPermission(
                                    module: _moduleTorneos,
                                    action: _actionUpdate,
                                    leagueId: tournament.leagueId,
                                  ) ??
                                  false,
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, stackTrace) => _TournamentsErrorState(
                            error: error,
                            onRetry: () => ref.invalidate(_tournamentsSourceProvider),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          )
        ],
      ),
    );
  }
}

class _EmptyTournamentsState extends StatelessWidget {
  const _EmptyTournamentsState({this.onCreate});

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined,
                size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'No hay torneos para mostrar',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primer torneo para comenzar a planificar zonas, categorías y fixtures.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onCreate != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Crear torneo'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _TournamentsErrorState extends StatelessWidget {
  const _TournamentsErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text('No se pudieron cargar los torneos: $error',
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _TournamentsDataTable extends StatelessWidget {
  const _TournamentsDataTable({
    required this.tournaments,
    required this.onDetails,
    required this.onEdit,
    required this.canEdit,
  });

  final List<TournamentSummary> tournaments;
  final ValueChanged<TournamentSummary> onDetails;
  final ValueChanged<TournamentSummary> onEdit;
  final bool Function(TournamentSummary tournament) canEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppDataTableColors.standard(theme);
    final headerStyle =
        theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: colors.headerText);

    final table = DataTable(
      headingRowHeight: 52,
      dataRowMinHeight: 72,
      dataRowMaxHeight: 92,
      headingRowColor: buildHeaderColor(colors.headerBackground),
      headingTextStyle: headerStyle,
      columns: const [
        DataColumn(label: Text('Liga')),
        DataColumn(label: Text('Nombre del torneo')),
        DataColumn(label: Text('Año')),
        DataColumn(label: Text('Zonas')),
        DataColumn(label: Text('Categorías')),
        DataColumn(label: Text('Acciones')),
      ],
      rows: [
        for (var index = 0; index < tournaments.length; index++)
          DataRow(
            color: buildStripedRowColor(index: index, colors: colors),
            cells: [
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tournaments[index].leagueName,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text('ID ${tournaments[index].leagueId}',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tournaments[index].name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: switch (tournaments[index].status) {
                          TournamentStatus.draft => theme.colorScheme.surfaceVariant,
                          TournamentStatus.scheduled => theme.colorScheme.tertiaryContainer,
                          TournamentStatus.inProgress => theme.colorScheme.primaryContainer,
                          TournamentStatus.finished => theme.colorScheme.secondaryContainer,
                        },
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          tournaments[index].status.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(Text(tournaments[index].year.toString())),
              DataCell(Text('${tournaments[index].zonesCount}')),
              DataCell(Text('${tournaments[index].enabledCategoriesCount}')),
              DataCell(
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => onDetails(tournaments[index]),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Detalles'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go(
                        '/tournaments/${tournaments[index].id}/players',
                        extra: tournaments[index],
                      ),
                      icon: const Icon(Icons.people_alt_outlined),
                      label: const Text('Jugadores'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed:
                          canEdit(tournaments[index]) ? () => onEdit(tournaments[index]) : null,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final scrollController = PrimaryScrollController.maybeOf(context);
        return Scrollbar(
          thumbVisibility: true,
          controller: scrollController,
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.only(bottom: 12),
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: table,
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _TournamentFormResult { saved, savedAndAddAnother }

class _TournamentFormDialog extends ConsumerStatefulWidget {
  const _TournamentFormDialog({
    required this.leagues,
    this.tournament,
    required this.readOnly,
    this.allowedLeagueIds,
    this.allowSaveAndAdd = false,
    required this.maxContentWidth,
    required this.canConfigurePoster,
  });

  final List<League> leagues;
  final TournamentSummary? tournament;
  final bool readOnly;
  final Set<int>? allowedLeagueIds;
  final bool allowSaveAndAdd;
  final double maxContentWidth;
  final bool canConfigurePoster;

  @override
  ConsumerState<_TournamentFormDialog> createState() => _TournamentFormDialogState();
}

class _TournamentFormDialogState extends ConsumerState<_TournamentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _yearController;
  int? _selectedLeagueId;
  String _selectedGender = 'MIXTO';
  bool _isSaving = false;
  String? _errorMessage;
  String? _categoryError;
  bool _showCategoryErrors = false;
  List<_CategorySelection> _selections = [];
  bool _categoriesInitialized = false;

  void _openPosterTemplate() {
    final tournament = widget.tournament;
    if (tournament == null) {
      return;
    }
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(
      '/tournaments/${tournament.id}/poster-template',
      extra: tournament,
    );
  }

  @override
  void initState() {
    super.initState();
    final tournament = widget.tournament;
    final now = DateTime.now();
    final defaultYear = tournament?.year ?? now.year;
    _nameController = TextEditingController(text: tournament?.name ?? '');
    _yearController = TextEditingController(text: defaultYear.toString());
    _selectedLeagueId = tournament?.leagueId ?? _defaultLeagueId();
    _selectedGender = tournament?.gender ?? 'MIXTO';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  int? _defaultLeagueId() {
    if (widget.leagues.isEmpty) {
      return null;
    }
    final allowed = widget.allowedLeagueIds;
    if (allowed == null) {
      return widget.leagues.first.id;
    }
    final candidate = widget.leagues.firstWhere(
      (league) => allowed.contains(league.id),
      orElse: () => widget.leagues.first,
    );
    return allowed.contains(candidate.id) ? candidate.id : null;
  }

  Future<void> _submit({required bool addAnother}) async {
    if (_isSaving || widget.readOnly) {
      return;
    }
    final isValid = _formKey.currentState?.validate() ?? false;
    final categoriesValid = _validateCategories();
    if (!isValid || !categoriesValid) {
      setState(() => _showCategoryErrors = true);
      return;
    }
    final leagueId = _selectedLeagueId;
    if (leagueId == null) {
      setState(() {
        _errorMessage = 'Selecciona una liga para continuar.';
      });
      return;
    }
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final api = ref.read(apiClientProvider);
    final payload = {
      'leagueId': leagueId,
      'name': _nameController.text.trim(),
      'year': int.parse(_yearController.text.trim()),
      'championMode': 'GLOBAL',
      'pointsWin': 3,
      'pointsDraw': 1,
      'pointsLoss': 0,
      'gender': _selectedGender,
    };
    final selections = _selections;
    final selectedCategories =
        selections.where((selection) => selection.include).toList();
    final categoriesPayload = selections
        .map((selection) => {
              'categoryId': selection.category.id,
              'enabled': selection.include,
              'countsForGeneral': selection.countsForGeneral,
              if (selection.include)
                'kickoffTime': _formatTimeOfDay(selection.time!),
            })
        .toList();

    try {
      if (widget.tournament == null) {
        final response = await api.post<Map<String, dynamic>>(
          '/tournaments',
          data: payload,
        );
        final tournamentId = response.data?['id'] as int?;
        if (tournamentId == null) {
          throw StateError('La API no devolvió el identificador del torneo creado.');
        }
        for (final selection in selectedCategories) {
          await api.post(
            '/tournaments/$tournamentId/categories',
            data: {
              'categoryId': selection.category.id,
              'enabled': true,
              'kickoffTime': _formatTimeOfDay(selection.time!),
              'countsForGeneral': selection.countsForGeneral,
            },
          );
        }
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop(
          addAnother
              ? _TournamentFormResult.savedAndAddAnother
              : _TournamentFormResult.saved,
        );
      } else {
        await api.put(
          '/tournaments/${widget.tournament!.id}',
          data: {
            ...payload,
            'categories': categoriesPayload,
          },
        );
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop(_TournamentFormResult.saved);
      }
    } on DioException catch (error) {
      final message = error.response?.data is Map<String, dynamic>
          ? (error.response!.data['message'] as String?)
          : error.message;
      setState(() {
        _errorMessage = message ??
            'Ocurrió un error inesperado al guardar el torneo. Intenta nuevamente.';
        _isSaving = false;
      });
      if (message != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'No se pudo guardar el torneo: $error';
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar el torneo: $error')),
        );
      }
    }
  }

  bool _validateCategories() {
    final included = _selections
        .where(
          (selection) =>
              _matchesSelectedGender(selection.category) && selection.include,
        )
        .toList();
    if (included.isEmpty) {
      _categoryError = 'Selecciona al menos una categoría participante.';
      return false;
    }
    final missingTime = included.where((selection) => selection.time == null).toList();
    if (missingTime.isNotEmpty) {
      _categoryError = 'Define un horario para cada categoría incluida.';
      return false;
    }
    _categoryError = null;
    return true;
  }

  void _initializeSelections(List<CategoryModel> categories) {
    final existingSelectionsById = {
      for (final selection in _selections) selection.category.id: selection
    };
    final currentIds = existingSelectionsById.keys.toSet();
    final categoryIds = categories.map((category) => category.id).toSet();
    final shouldRebuild = !_categoriesInitialized ||
        currentIds.length != categoryIds.length ||
        categories.any((category) => !currentIds.contains(category.id));

    if (!shouldRebuild) {
      return;
    }
    final assignments = widget.tournament?.categories ?? const [];
    final byCategoryId = {
      for (final assignment in assignments) assignment.categoryId: assignment
    };
    _selections = categories.map((category) {
      final previous = existingSelectionsById[category.id];
      if (previous != null) {
        final restored = _CategorySelection(
          category: category,
          include: previous.include,
          time: previous.time,
        )..countsForGeneral = previous.countsForGeneral;
        return restored;
      }
      final assignment = byCategoryId[category.id];
      final selection = _CategorySelection(
        category: category,
        include: assignment?.enabled ?? false,
        time: _parseKickoffTime(assignment?.kickoffTime),
      );
      selection.countsForGeneral = assignment?.countsForGeneral ??
          (category.promotional ? false : true);
      return selection;
    }).toList();
    _categoriesInitialized = true;
    _applyGenderFilter();
  }

  void _applyGenderFilter() {
    for (final selection in _selections) {
      if (!_matchesSelectedGender(selection.category)) {
        selection
          ..include = false
          ..time = null
          ..countsForGeneral =
              selection.category.promotional ? false : true;
      }
    }
  }

  bool _matchesSelectedGender(CategoryModel category) {
    if (_selectedGender == 'MIXTO') {
      return true;
    }
    return category.gender == _selectedGender;
  }

  TimeOfDay? _parseKickoffTime(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final parts = value.split(':');
    if (parts.length != 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesCatalogProvider);
    final currentYear = DateTime.now().year;
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.tournament == null ? 'Crear torneo' : 'Editar torneo',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              widget.readOnly
                  ? 'Visualiza la configuración del torneo seleccionado.'
                  : 'Completa los datos esenciales. Podrás ajustar detalles avanzados más adelante.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (widget.canConfigurePoster) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Tooltip(
                      message: widget.tournament == null
                          ? 'Guarda el torneo para habilitar la configuración del poster.'
                          : 'Abre el editor de plantilla para el poster promocional del torneo.',
                      child: FilledButton.tonalIcon(
                        onPressed: widget.tournament == null ? null : _openPosterTemplate,
                        icon: const Icon(Icons.wallpaper_outlined),
                        label: const Text('Configurar poster'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Builder(
              builder: (context) {
                final availableLeagues = widget.leagues
                    .where((league) => widget.allowedLeagueIds == null ||
                        widget.allowedLeagueIds!.contains(league.id))
                    .toList();
                if (availableLeagues.isEmpty) {
                  return InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Liga',
                      errorText: 'No tienes ligas habilitadas para crear torneos.',
                    ),
                    child: Text(
                      'Solicita permisos para alguna liga o crea una nueva desde la sección correspondiente.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }
                return DropdownButtonFormField<int>(
                  value: _selectedLeagueId,
                  decoration: const InputDecoration(labelText: 'Liga'),
                  items: availableLeagues
                      .map(
                        (league) => DropdownMenuItem<int>(
                          value: league.id,
                          child: Text(league.name),
                        ),
                      )
                      .toList(),
                  onChanged: widget.readOnly
                      ? null
                      : (value) => setState(() => _selectedLeagueId = value),
                  validator: (value) {
                    if (value == null) {
                      return 'Selecciona la liga en la que se disputará el torneo.';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              readOnly: widget.readOnly,
              decoration: const InputDecoration(
                labelText: 'Nombre del torneo',
                hintText: 'Ej. Torneo 2024 Domingo',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return 'El nombre del torneo es obligatorio.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _yearController,
              readOnly: widget.readOnly,
              decoration: InputDecoration(
                labelText: 'Año del torneo (YYYY)',
                hintText: 'Ej. $currentYear',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.length != 4) {
                  return 'Ingresa un año válido de cuatro dígitos.';
                }
                final year = int.tryParse(text);
                if (year == null || year < 1900 || year > currentYear + 2) {
                  return 'Ingresa un año entre 1900 y ${currentYear + 2}.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration:
                  const InputDecoration(labelText: 'Género del torneo'),
              items: const [
                DropdownMenuItem(
                  value: 'MIXTO',
                  child: Text('Mixto'),
                ),
                DropdownMenuItem(
                  value: 'MASCULINO',
                  child: Text('Masculino'),
                ),
                DropdownMenuItem(
                  value: 'FEMENINO',
                  child: Text('Femenino'),
                ),
              ],
              onChanged: widget.readOnly
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedGender = value;
                        _applyGenderFilter();
                      });
                    },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Selecciona el género del torneo.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Categorías participantes',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            categoriesAsync.when(
              data: (categories) {
                if (!_categoriesInitialized) {
                  _initializeSelections(categories);
                }
                final visibleSelections = _selections
                    .where((selection) =>
                        _matchesSelectedGender(selection.category))
                    .toList();
                if (visibleSelections.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No hay categorías disponibles para el género seleccionado.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                return _CategorySelectionTable(
                  selections: visibleSelections,
                  readOnly: widget.readOnly,
                  onChanged: (selection) {
                    setState(() {});
                  },
                  minWidth: widget.maxContentWidth,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Error al cargar categorías: $error'),
              ),
            ),
            if (_categoryError != null && (_showCategoryErrors || widget.readOnly)) ...[
              const SizedBox(height: 12),
              Text(
                _categoryError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.of(context).maybePop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                if (widget.allowSaveAndAdd &&
                    widget.tournament == null &&
                    !widget.readOnly) ...[
                  FilledButton.tonal(
                    onPressed: _isSaving ? null : () => _submit(addAnother: true),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar y agregar otro'),
                  ),
                  const SizedBox(width: 12),
                ],
                FilledButton(
                  onPressed: widget.readOnly || _isSaving
                      ? null
                      : () => _submit(addAnother: false),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.tournament == null ? 'Guardar' : 'Guardar cambios'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _CategorySelectionTable extends StatefulWidget {
  const _CategorySelectionTable({
    required this.selections,
    required this.readOnly,
    required this.onChanged,
    required this.minWidth,
  });

  final List<_CategorySelection> selections;
  final bool readOnly;
  final ValueChanged<_CategorySelection> onChanged;
  final double minWidth;

  @override
  State<_CategorySelectionTable> createState() => _CategorySelectionTableState();
}

class _CategorySelectionTableState extends State<_CategorySelectionTable> {
  late final ScrollController _horizontalController;

  @override
  void initState() {
    super.initState();
    _horizontalController = ScrollController();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(_CategorySelection selection) async {
    if (!selection.include || widget.readOnly) {
      return;
    }
    final result = await showTimePicker(
      context: context,
      initialTime: selection.time ?? const TimeOfDay(hour: 18, minute: 0),
    );
    if (result != null) {
      setState(() {
        selection.time = result;
      });
      widget.onChanged(selection);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.selections
        .map(
          (selection) => DataRow(
            cells: [
              DataCell(Text(selection.category.name)),
              DataCell(Text(selection.category.birthYearRangeLabel)),
              DataCell(Text(selection.category.genderLabel)),
              DataCell(
                Align(
                  alignment: Alignment.center,
                  child: selection.countsForGeneral
                      ? const SizedBox.shrink()
                      : Icon(
                          Icons.check,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                ),
              ),
              DataCell(
                Checkbox(
                  value: selection.include,
                  onChanged: widget.readOnly
                      ? null
                      : (value) {
                          setState(() {
                            selection.include = value ?? false;
                            if (!selection.include) {
                              selection.time = null;
                              selection.countsForGeneral =
                                  selection.category.promotional ? false : true;
                            }
                          });
                          widget.onChanged(selection);
                        },
                ),
              ),
              DataCell(
                InkWell(
                  onTap: () => _pickTime(selection),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Horario',
                      enabled: !widget.readOnly && selection.include,
                    ),
                    child: Text(
                      selection.time != null
                          ? MaterialLocalizations.of(context)
                              .formatTimeOfDay(selection.time!, alwaysUse24HourFormat: true)
                          : '—',
                    ),
                  ),
                ),
              ),
              DataCell(
                Switch(
                  value: selection.countsForGeneral,
                  onChanged: widget.readOnly || !selection.include
                      ? null
                      : (value) {
                          setState(() {
                            selection.countsForGeneral = value;
                          });
                          widget.onChanged(selection);
                        },
                ),
              ),
            ],
          ),
        )
        .toList();

    final table = DataTable(
      columns: const [
        DataColumn(label: Text('Categoría')),
        DataColumn(label: Text('Años de nacimiento')),
        DataColumn(label: Text('Género')),
        DataColumn(label: Text('Promocional')),
        DataColumn(label: Text('Incluir')),
        DataColumn(label: Text('Horario')),
        DataColumn(label: Text('Pondera en tabla general')),
      ],
      rows: rows,
    );

    final constrainedTable = ConstrainedBox(
      constraints: BoxConstraints(minWidth: widget.minWidth),
      child: table,
    );

    final decoratedTable = DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: constrainedTable,
    );

    return Scrollbar(
      controller: _horizontalController,
      thumbVisibility: true,
      notificationPredicate: (notification) {
        return notification.metrics.axis == Axis.horizontal;
      },
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        child: decoratedTable,
      ),
    );
  }
}

class _CategorySelection {
  _CategorySelection({
    required this.category,
    this.include = false,
    TimeOfDay? time,
  })  : countsForGeneral = category.promotional ? false : true,
        time = include ? time : null;

  final CategoryModel category;
  bool include;
  TimeOfDay? time;
  bool countsForGeneral;
}

class TournamentSummary {
  TournamentSummary({
    required this.id,
    required this.name,
    required this.year,
    required this.leagueId,
    required this.leagueName,
    required this.gender,
    required this.zonesCount,
    required this.categories,
    required this.startDate,
    required this.endDate,
    required this.championMode,
  });

  factory TournamentSummary.fromJson(
    Map<String, dynamic> json,
    League league,
  ) {
    final categories = (json['categories'] as List<dynamic>? ?? [])
        .map((entry) => TournamentCategoryAssignment.fromJson(
            entry as Map<String, dynamic>))
        .toList();
    return TournamentSummary(
      id: json['id'] as int,
      name: json['name'] as String,
      year: json['year'] as int,
      leagueId: league.id,
      leagueName: league.name,
      gender: json['gender'] as String? ?? 'MIXTO',
      zonesCount: (json['zones'] as List<dynamic>? ?? []).length,
      categories: categories,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String)
          : null,
      championMode: json['championMode'] as String? ?? 'GLOBAL',
    );
  }

  final int id;
  final String name;
  final int year;
  final int leagueId;
  final String leagueName;
  final String gender;
  final int zonesCount;
  final List<TournamentCategoryAssignment> categories;
  final DateTime? startDate;
  final DateTime? endDate;
  final String championMode;

  int get enabledCategoriesCount =>
      categories.where((category) => category.enabled).length;

  String get genderLabel {
    switch (gender) {
      case 'MASCULINO':
        return 'Masculino';
      case 'FEMENINO':
        return 'Femenino';
      default:
        return 'Mixto';
    }
  }

  TournamentStatus get status {
    if (enabledCategoriesCount == 0 || zonesCount == 0) {
      return TournamentStatus.draft;
    }
    if (startDate == null) {
      return TournamentStatus.draft;
    }
    final now = DateTime.now();
    if (endDate != null && endDate!.isBefore(now)) {
      return TournamentStatus.finished;
    }
    if (startDate!.isAfter(now)) {
      return TournamentStatus.scheduled;
    }
    return TournamentStatus.inProgress;
  }
}

class TournamentCategoryAssignment {
  TournamentCategoryAssignment({
    required this.categoryId,
    required this.categoryName,
    required this.categoryBirthYearMin,
    required this.categoryBirthYearMax,
    required this.categoryGender,
    required this.promotional,
    required this.enabled,
    required this.kickoffTime,
    required this.countsForGeneral,
  });

  factory TournamentCategoryAssignment.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    return TournamentCategoryAssignment(
      categoryId: json['categoryId'] as int,
      categoryName: category?['name'] as String? ?? 'Categoría',
      categoryBirthYearMin: category?['birthYearMin'] as int? ?? 0,
      categoryBirthYearMax: category?['birthYearMax'] as int? ?? 0,
      categoryGender: category?['gender'] as String? ?? 'MIXTO',
      promotional: category?['promotional'] as bool? ?? false,
      enabled: json['enabled'] as bool? ?? false,
      kickoffTime: json['kickoffTime'] as String?,
      countsForGeneral: json['countsForGeneral'] as bool? ?? true,
    );
  }

  final int categoryId;
  final String categoryName;
  final int categoryBirthYearMin;
  final int categoryBirthYearMax;
  final String categoryGender;
  final bool promotional;
  final bool enabled;
  final String? kickoffTime;
  final bool countsForGeneral;

  String get genderLabel {
    switch (categoryGender) {
      case 'MASCULINO':
        return 'Masculino';
      case 'FEMENINO':
        return 'Femenino';
      default:
        return 'Mixto';
    }
  }

  String get birthYearRangeLabel {
    if (categoryBirthYearMin == 0 && categoryBirthYearMax == 0) {
      return '—';
    }
    if (categoryBirthYearMin == categoryBirthYearMax) {
      return '$categoryBirthYearMin';
    }
    return '$categoryBirthYearMin - $categoryBirthYearMax';
  }
}

enum TournamentStatus { draft, scheduled, inProgress, finished }

extension TournamentStatusLabel on TournamentStatus {
  String get label {
    switch (this) {
      case TournamentStatus.draft:
        return 'Borrador';
      case TournamentStatus.scheduled:
        return 'Programado';
      case TournamentStatus.inProgress:
        return 'En juego';
      case TournamentStatus.finished:
        return 'Finalizado';
    }
  }
}

class TournamentFilters {
  const TournamentFilters({
    this.query = '',
    this.leagueId,
    this.year,
    this.status,
  });

  final String query;
  final int? leagueId;
  final int? year;
  final TournamentStatus? status;

  bool get isEmpty =>
      query.isEmpty && leagueId == null && year == null && status == null;
}

class TournamentFiltersController extends StateNotifier<TournamentFilters> {
  TournamentFiltersController() : super(const TournamentFilters());

  void updateQuery(String query) {
    state = TournamentFilters(
      query: query,
      leagueId: state.leagueId,
      year: state.year,
      status: state.status,
    );
  }

  void updateLeague(int? leagueId) {
    state = TournamentFilters(
      query: state.query,
      leagueId: leagueId,
      year: state.year,
      status: state.status,
    );
  }

  void updateYear(int? year) {
    state = TournamentFilters(
      query: state.query,
      leagueId: state.leagueId,
      year: year,
      status: state.status,
    );
  }

  void updateStatus(TournamentStatus? status) {
    state = TournamentFilters(
      query: state.query,
      leagueId: state.leagueId,
      year: state.year,
      status: status,
    );
  }

  void clear() {
    state = const TournamentFilters();
  }
}
