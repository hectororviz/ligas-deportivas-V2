import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../services/api_client.dart';
import '../../../services/auth_controller.dart';
import '../../shared/widgets/table_filters_bar.dart';

const _modulePlayers = 'JUGADORES';
const _actionCreate = 'CREATE';
const _actionUpdate = 'UPDATE';

final playersFiltersProvider =
    StateNotifierProvider<_PlayersFiltersController, _PlayersFilters>((ref) {
  return _PlayersFiltersController();
});

final playersProvider = FutureProvider<PaginatedPlayers>((ref) async {
  final filters = ref.watch(playersFiltersProvider);
  final api = ref.read(apiClientProvider);
  final response =
      await api.get<Map<String, dynamic>>('/players', queryParameters: {
    if (filters.query.trim().isNotEmpty) 'search': filters.query.trim(),
    if (filters.status != PlayerStatusFilter.all) 'status': filters.status.name,
    'page': filters.page,
    'pageSize': filters.pageSize,
  });
  final data = response.data ?? {};
  return PaginatedPlayers.fromJson(data);
});

final clubsCatalogProvider = FutureProvider<List<ClubSummary>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<Map<String, dynamic>>('/clubs', queryParameters: {
    'page': 1,
    'pageSize': 200,
    'status': 'active',
  });
  final json = response.data ?? {};
  final paginated = PaginatedClubs.fromJson(json);
  final clubs = [...paginated.clubs]
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return clubs;
});

class PlayersPage extends ConsumerStatefulWidget {
  const PlayersPage({super.key});

  @override
  ConsumerState<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends ConsumerState<PlayersPage> {
  late final TextEditingController _searchController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(playersFiltersProvider.notifier).setQuery(_searchController.text);
    });
  }

  Future<void> _openCreatePlayer() async {
    _PlayerFormResult? result;
    do {
      result = await _showPlayerForm(
        context,
        readOnly: false,
        allowSaveAndAdd: true,
      );
      if (!mounted || result == null) {
        break;
      }
      if (result.type == _PlayerFormResultType.saved ||
          result.type == _PlayerFormResultType.savedAndAddAnother) {
        ref.invalidate(playersProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jugador guardado correctamente.')),
        );
      } else if (result.type == _PlayerFormResultType.openExisting &&
          result.player != null) {
        await _openPlayerDetails(result.player!);
      }
    } while (result?.type == _PlayerFormResultType.savedAndAddAnother);
  }

  Future<void> _openPlayerDetails(Player player) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: _PlayerDetailsView(player: player),
        );
      },
    );
  }

  Future<void> _openEditPlayer(Player player) async {
    final result = await _showPlayerForm(
      context,
      readOnly: false,
      player: player,
    );
    if (!mounted || result == null) {
      return;
    }
    if (result.type == _PlayerFormResultType.saved) {
      ref.invalidate(playersProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Jugador "${player.fullName}" actualizado.')),
      );
    } else if (result.type == _PlayerFormResultType.openExisting &&
        result.player != null) {
      await _openPlayerDetails(result.player!);
    }
  }

  Future<_PlayerFormResult?> _showPlayerForm(
    BuildContext context, {
    Player? player,
    required bool readOnly,
    bool allowSaveAndAdd = false,
  }) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 640;
    const maxDialogWidth = 720.0;

    final dialog = _PlayerFormDialog(
      player: player,
      readOnly: readOnly,
      allowSaveAndAdd: allowSaveAndAdd,
    );

    if (isCompact) {
      return showModalBottomSheet<_PlayerFormResult>(
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
            child: dialog,
          );
        },
      );
    }

    return showDialog<_PlayerFormResult>(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SizedBox(
            width: math.min(maxDialogWidth, size.width - 120),
            child: dialog,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final canCreate =
        user?.hasPermission(module: _modulePlayers, action: _actionCreate) ??
            false;
    final canEdit =
        user?.hasPermission(module: _modulePlayers, action: _actionUpdate) ??
            false;
    final playersAsync = ref.watch(playersProvider);
    final filters = ref.watch(playersFiltersProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _openCreatePlayer,
              icon: const Icon(Icons.add),
              label: const Text('Agregar jugador'),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jugadores',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Gestioná las fichas de jugadores para tus competencias.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: TableFiltersBar(
                  children: [
                    TableFilterField(
                      label: 'Buscar',
                      width: 320,
                      child: TableFilterSearchField(
                        controller: _searchController,
                        placeholder: 'Buscar por apellido, nombre o DNI',
                        showClearButton: filters.query.isNotEmpty,
                        onClear: () {
                          _searchController.clear();
                          ref
                              .read(playersFiltersProvider.notifier)
                              .setQuery('');
                        },
                      ),
                    ),
                    TableFilterField(
                      label: 'Estado',
                      width: 200,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PlayerStatusFilter>(
                          value: filters.status,
                          isExpanded: true,
                          items: PlayerStatusFilter.values
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              ref
                                  .read(playersFiltersProvider.notifier)
                                  .setStatus(value);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                  trailing: TextButton.icon(
                    onPressed: filters.query.isEmpty &&
                            filters.status == PlayerStatusFilter.all
                        ? null
                        : () {
                            _searchController.clear();
                            ref
                                .read(playersFiltersProvider.notifier)
                                .reset();
                          },
                    icon: const Icon(Icons.filter_alt_off_outlined),
                    label: const Text('Limpiar filtros'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: playersAsync.when(
                data: (paginated) {
                  if (paginated.players.isEmpty) {
                    if (filters.query.isNotEmpty ||
                        filters.status != PlayerStatusFilter.all) {
                      return _PlayersEmptyFilterState(onClear: () {
                        ref.read(playersFiltersProvider.notifier).reset();
                        _searchController.clear();
                      });
                    }
                    return _PlayersEmptyState(
                      canCreate: canCreate,
                      onCreate: _openCreatePlayer,
                    );
                  }

                  return Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.badge_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Jugadores registrados',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              Text('${paginated.total} en total',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: _PlayersDataTable(
                            data: paginated,
                            canEdit: canEdit,
                            onEdit: _openEditPlayer,
                            onView: _openPlayerDetails,
                          ),
                        ),
                        _PlayersPaginationFooter(
                          page: paginated.page,
                          pageSize: paginated.pageSize,
                          total: paginated.total,
                          onPageChanged: (page) =>
                              ref.read(playersFiltersProvider.notifier).setPage(page),
                          onPageSizeChanged: (value) => ref
                              .read(playersFiltersProvider.notifier)
                              .setPageSize(value),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const _PlayersTableSkeleton(),
                error: (error, stackTrace) => _PlayersErrorState(
                  error: error,
                  onRetry: () => ref.invalidate(playersProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayersFilters {
  const _PlayersFilters({
    this.query = '',
    this.status = PlayerStatusFilter.all,
    this.page = 1,
    this.pageSize = 25,
  });

  final String query;
  final PlayerStatusFilter status;
  final int page;
  final int pageSize;

  _PlayersFilters copyWith({
    String? query,
    PlayerStatusFilter? status,
    int? page,
    int? pageSize,
  }) {
    return _PlayersFilters(
      query: query ?? this.query,
      status: status ?? this.status,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class _PlayersFiltersController extends StateNotifier<_PlayersFilters> {
  _PlayersFiltersController() : super(const _PlayersFilters());

  void setQuery(String query) {
    state = state.copyWith(query: query, page: 1);
  }

  void setStatus(PlayerStatusFilter status) {
    state = state.copyWith(status: status, page: 1);
  }

  void setPage(int page) {
    state = state.copyWith(page: page);
  }

  void setPageSize(int pageSize) {
    state = state.copyWith(pageSize: pageSize, page: 1);
  }

  void reset() {
    state = const _PlayersFilters();
  }
}

enum PlayerStatusFilter { all, active, inactive }

extension on PlayerStatusFilter {
  String get label {
    switch (this) {
      case PlayerStatusFilter.all:
        return 'Todos';
      case PlayerStatusFilter.active:
        return 'Activos';
      case PlayerStatusFilter.inactive:
        return 'Inactivos';
    }
  }

  String get name => switch (this) {
        PlayerStatusFilter.all => 'all',
        PlayerStatusFilter.active => 'active',
        PlayerStatusFilter.inactive => 'inactive',
      };
}

class _PlayersDataTable extends StatelessWidget {
  const _PlayersDataTable({
    required this.data,
    required this.canEdit,
    required this.onEdit,
    required this.onView,
  });

  final PaginatedPlayers data;
  final bool canEdit;
  final ValueChanged<Player> onEdit;
  final ValueChanged<Player> onView;

  @override
  Widget build(BuildContext context) {
    final players = [...data.players]
      ..sort((a, b) {
        final lastNameCompare =
            _normalizeForSort(a.lastName).compareTo(_normalizeForSort(b.lastName));
        if (lastNameCompare != 0) {
          return lastNameCompare;
        }
        return _normalizeForSort(a.firstName)
            .compareTo(_normalizeForSort(b.firstName));
      });

    final table = DataTable(
      columns: const [
        DataColumn(label: Text('Apellido')),
        DataColumn(label: Text('Nombre')),
        DataColumn(label: Text('Nacimiento')),
        DataColumn(label: Text('Estado')),
        DataColumn(label: Text('Acciones')),
      ],
      dataRowMinHeight: 64,
      dataRowMaxHeight: 80,
      headingRowHeight: 52,
      rows: players
          .map(
            (player) => DataRow(
              cells: [
                DataCell(Text(player.lastName)),
                DataCell(Text(player.firstName)),
                DataCell(Text(player.formattedBirthDateWithAge)),
                DataCell(
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      avatar: Icon(
                        player.active
                            ? Icons.check_circle
                            : Icons.pause_circle,
                        size: 18,
                        color: player.active
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      backgroundColor: player.active
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceVariant,
                      label: Text(
                        player.active ? 'Activo' : 'Inactivo',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: player.active
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => onView(player),
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Detalle'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: canEdit ? () => onEdit(player) : null,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: table,
          );
        }
        return table;
      },
    );
  }
}

class _PlayersPaginationFooter extends StatelessWidget {
  const _PlayersPaginationFooter({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  final int page;
  final int pageSize;
  final int total;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    final totalPages = (total / pageSize).ceil().clamp(1, double.maxFinite).toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Row(
        children: [
          Text('Página $page de $totalPages'),
          const Spacer(),
          DropdownButton<int>(
            value: pageSize,
            items: const [10, 25, 50, 100]
                .map((size) => DropdownMenuItem(
                      value: size,
                      child: Text('$size por página'),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onPageSizeChanged(value);
              }
            },
          ),
          const SizedBox(width: 16),
          IconButton(
            tooltip: 'Página anterior',
            onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'Página siguiente',
            onPressed: page < totalPages ? () => onPageChanged(page + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _PlayersEmptyState extends StatelessWidget {
  const _PlayersEmptyState({required this.canCreate, required this.onCreate});

  final bool canCreate;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_add_alt_1_outlined,
                size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Todavía no hay jugadores.',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Cargá la primera ficha para comenzar a armar planteles.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (canCreate)
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Agregar jugador'),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayersEmptyFilterState extends StatelessWidget {
  const _PlayersEmptyFilterState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_alt_off_outlined, size: 48),
          const SizedBox(height: 12),
          const Text('No se encontraron jugadores con los filtros actuales.'),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: onClear,
            child: const Text('Limpiar filtros'),
          ),
        ],
      ),
    );
  }
}

class _PlayersErrorState extends StatelessWidget {
  const _PlayersErrorState({required this.error, required this.onRetry});

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
          Text('No se pudieron cargar los jugadores: $error',
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _PlayersTableSkeleton extends StatelessWidget {
  const _PlayersTableSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemBuilder: (context, index) {
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 16,
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 12,
                            width: 120,
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemCount: 6,
            ),
          ),
        ],
      ),
    );
  }
}

enum _PlayerFormResultType { cancelled, saved, savedAndAddAnother, openExisting }

class _PlayerFormResult {
  const _PlayerFormResult._(this.type, {this.player});

  final _PlayerFormResultType type;
  final Player? player;

  static const cancelled =
      _PlayerFormResult._(_PlayerFormResultType.cancelled);
  static const saved = _PlayerFormResult._(_PlayerFormResultType.saved);
  static const savedAndAddAnother =
      _PlayerFormResult._(_PlayerFormResultType.savedAndAddAnother);

  factory _PlayerFormResult.openExisting(Player player) =>
      _PlayerFormResult._(_PlayerFormResultType.openExisting, player: player);
}

class _PlayerFormDialog extends ConsumerStatefulWidget {
  const _PlayerFormDialog({
    required this.readOnly,
    this.player,
    required this.allowSaveAndAdd,
  });

  final bool readOnly;
  final Player? player;
  final bool allowSaveAndAdd;

  @override
  ConsumerState<_PlayerFormDialog> createState() => _PlayerFormDialogState();
}

class _PlayerFormDialogState extends ConsumerState<_PlayerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _dniController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _streetController;
  late final TextEditingController _streetNumberController;
  late final TextEditingController _cityController;
  late final TextEditingController _emergencyNameController;
  late final TextEditingController _emergencyRelationshipController;
  late final TextEditingController _emergencyPhoneController;
  DateTime? _birthDate;
  int? _selectedClubId;
  bool _active = true;
  bool _isSaving = false;
  bool _checkingDni = false;
  Player? _duplicatePlayer;
  Timer? _dniDebounce;
  Object? _errorMessage;

  @override
  void initState() {
    super.initState();
    final player = widget.player;
    _firstNameController = TextEditingController(text: player?.firstName ?? '');
    _lastNameController = TextEditingController(text: player?.lastName ?? '');
    _dniController = TextEditingController(text: player?.dni ?? '');
    _birthDate = player?.birthDate;
    _birthDateController =
        TextEditingController(text: player?.formattedBirthDate ?? '');
    _streetController =
        TextEditingController(text: player?.address?.street ?? '');
    _streetNumberController =
        TextEditingController(text: player?.address?.number ?? '');
    _cityController = TextEditingController(text: player?.address?.city ?? '');
    _emergencyNameController =
        TextEditingController(text: player?.emergencyContact?.name ?? '');
    _emergencyRelationshipController = TextEditingController(
        text: player?.emergencyContact?.relationship ?? '');
    _emergencyPhoneController =
        TextEditingController(text: player?.emergencyContact?.phone ?? '');
    _selectedClubId = player?.club?.id;
    _active = player?.active ?? true;

    if (!widget.readOnly) {
      _dniController.addListener(_handleDniChanged);
    }
  }

  @override
  void dispose() {
    _dniDebounce?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dniController
      ..removeListener(_handleDniChanged)
      ..dispose();
    _birthDateController.dispose();
    _streetController.dispose();
    _streetNumberController.dispose();
    _cityController.dispose();
    _emergencyNameController.dispose();
    _emergencyRelationshipController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _handleDniChanged() {
    _dniDebounce?.cancel();
    final value = _dniController.text.trim();
    if (value.length < 6) {
      setState(() {
        _duplicatePlayer = null;
      });
      return;
    }
    _dniDebounce = Timer(const Duration(milliseconds: 350), () {
      _checkDuplicateDni(value);
    });
  }

  Future<void> _checkDuplicateDni(String dni) async {
    final api = ref.read(apiClientProvider);
    setState(() {
      _checkingDni = true;
      _errorMessage = null;
    });
    try {
      final response = await api.get<Map<String, dynamic>>('/players',
          queryParameters: {
            'dni': dni,
            'page': 1,
            'pageSize': 1,
          });
      final json = response.data ?? {};
      final paginated = PaginatedPlayers.fromJson(json);
      final found = paginated.players.firstOrNull;
      if (!mounted) return;
      if (found != null && found.id != widget.player?.id) {
        setState(() {
          _duplicatePlayer = found;
        });
      } else {
        setState(() {
          _duplicatePlayer = null;
        });
      }
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _duplicatePlayer = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error;
        _duplicatePlayer = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _checkingDni = false;
        });
      }
    }
  }

  Future<void> _pickBirthDate() async {
    if (widget.readOnly) {
      return;
    }
    final now = DateTime.now();
    final initialDate = _birthDate ?? DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 5),
      helpText: 'Seleccioná la fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      locale: const Locale('es'),
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  bool get _canSubmit {
    return !_isSaving &&
        _duplicatePlayer == null &&
        (_formKey.currentState?.validate() ?? false);
  }

  int? get _age {
    final birthDate = _birthDate;
    if (birthDate == null) {
      return null;
    }
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    final hasHadBirthday = (now.month > birthDate.month) ||
        (now.month == birthDate.month && now.day >= birthDate.day);
    if (!hasHadBirthday) {
      age -= 1;
    }
    return age;
  }

  Future<void> _submit({required bool addAnother}) async {
    if (!_canSubmit) {
      _formKey.currentState?.validate();
      return;
    }
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final payload = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'dni': _dniController.text.trim(),
      'birthDate': _birthDate != null
          ? DateFormat('yyyy-MM-dd').format(_birthDate!)
          : null,
      'active': _active,
      'clubId': _selectedClubId,
      'address': {
        'street': _streetController.text.trim(),
        'number': _streetNumberController.text.trim(),
        'city': _cityController.text.trim(),
      },
      'emergencyContact': {
        'name': _emergencyNameController.text.trim(),
        'relationship': _emergencyRelationshipController.text.trim(),
        'phone': _emergencyPhoneController.text.trim(),
      },
    };

    try {
      final api = ref.read(apiClientProvider);
      if (widget.player == null) {
        await api.post('/players', data: payload);
      } else {
        await api.patch('/players/${widget.player!.id}', data: payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop(
        addAnother
            ? _PlayerFormResult.savedAndAddAnother
            : _PlayerFormResult.saved,
      );
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.response?.data is Map<String, dynamic>
            ? (error.response?.data['message'] ?? error.message)
            : error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final readOnly = widget.readOnly;
    final clubsAsync = ref.watch(clubsCatalogProvider);
    final age = _age;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.player == null
                  ? 'Agregar jugador'
                  : (readOnly ? 'Ficha del jugador' : 'Editar jugador'),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              readOnly
                  ? 'Revisá los datos personales y de contacto.'
                  : 'Completá los datos obligatorios. Podrás actualizarlos luego.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _lastNameController,
              enabled: !readOnly,
              decoration: const InputDecoration(
                labelText: 'Apellido',
                hintText: 'Obligatorio',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El apellido es obligatorio.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _firstNameController,
              enabled: !readOnly,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Obligatorio',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es obligatorio.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _birthDateController,
              readOnly: true,
              onTap: _pickBirthDate,
              enabled: !readOnly,
              decoration: InputDecoration(
                labelText: 'Fecha de nacimiento',
                hintText: 'DD/MM/AAAA',
                suffixIcon: readOnly
                    ? null
                    : const Icon(Icons.calendar_today_outlined),
                helperText: age != null ? 'Edad: $age años' : ' ',
              ),
              validator: (value) {
                if (_birthDate == null) {
                  return 'La fecha de nacimiento es obligatoria.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dniController,
              enabled: !readOnly,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Número de DNI',
                hintText: 'Sin puntos',
                suffixIcon: _checkingDni
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return 'El DNI es obligatorio.';
                }
                if (text.length < 6) {
                  return 'Ingresá un DNI válido.';
                }
                if (_duplicatePlayer != null) {
                  return 'Este DNI ya está registrado.';
                }
                return null;
              },
            ),
            if (_duplicatePlayer != null) ...[
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'El DNI ingresado pertenece a ${_duplicatePlayer!.fullName}.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onErrorContainer),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.tonal(
                        onPressed: () {
                          final player = _duplicatePlayer;
                          if (player != null) {
                            Navigator.of(context)
                                .pop(_PlayerFormResult.openExisting(player));
                          }
                        },
                        child: const Text('Ir a ficha'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _streetController,
                    enabled: !readOnly,
                    decoration: const InputDecoration(
                      labelText: 'Calle',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La calle es obligatoria.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _streetNumberController,
                    enabled: !readOnly,
                    decoration: const InputDecoration(
                      labelText: 'Número',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Obligatorio';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              enabled: !readOnly,
              decoration: const InputDecoration(
                labelText: 'Localidad',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La localidad es obligatoria.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              title: const Text('Activo'),
              value: _active,
              onChanged: readOnly
                  ? null
                  : (value) {
                      setState(() {
                        _active = value;
                      });
                    },
            ),
            const SizedBox(height: 16),
            clubsAsync.when(
              data: (clubs) {
                return DropdownButtonFormField<int?>(
                  value: _selectedClubId,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Sin club asignado'),
                    ),
                    ...clubs.map(
                      (club) => DropdownMenuItem<int?>(
                        value: club.id,
                        child: Text(club.name),
                      ),
                    ),
                  ],
                  onChanged: readOnly
                      ? null
                      : (value) {
                          setState(() {
                            _selectedClubId = value;
                          });
                        },
                  decoration: const InputDecoration(
                    labelText: 'Club',
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(),
              ),
              error: (error, stackTrace) => Text(
                'No se pudieron cargar los clubes: $error',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Contacto de emergencia (opcional)',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emergencyNameController,
              enabled: !readOnly,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emergencyRelationshipController,
              enabled: !readOnly,
              decoration: const InputDecoration(
                labelText: 'Vínculo',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emergencyPhoneController,
              enabled: !readOnly,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
              ),
              keyboardType: TextInputType.phone,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                'Error: $_errorMessage',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(_PlayerFormResult.cancelled),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                if (!readOnly && widget.allowSaveAndAdd)
                  FilledButton.tonal(
                    onPressed: _isSaving
                        ? null
                        : () => _submit(addAnother: true),
                    child: const Text('Guardar y agregar otro'),
                  ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: readOnly
                      ? () => Navigator.of(context)
                          .pop(_PlayerFormResult.cancelled)
                      : (_isSaving
                          ? null
                          : () => _submit(addAnother: false)),
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(readOnly ? 'Cerrar' : 'Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerDetailsView extends StatelessWidget {
  const _PlayerDetailsView({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            player.fullName,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Ficha personal y de contacto.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          _DetailsRow(
            label: 'DNI',
            value: player.dni,
          ),
          _DetailsRow(
            label: 'Fecha de nacimiento',
            value: player.formattedBirthDateWithAge,
          ),
          _DetailsRow(
            label: 'Dirección',
            value: player.address?.formatted ?? 'Sin datos',
          ),
          _DetailsRow(
            label: 'Club',
            value: player.club?.name ?? 'Sin club asignado',
          ),
          _DetailsRow(
            label: 'Estado',
            value: player.active ? 'Activo' : 'Inactivo',
          ),
          if (player.emergencyContact != null) ...[
            const SizedBox(height: 16),
            Text(
              'Contacto de emergencia',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _DetailsRow(
              label: 'Nombre',
              value: player.emergencyContact!.name ?? 'Sin datos',
            ),
            _DetailsRow(
              label: 'Vínculo',
              value: player.emergencyContact!.relationship ?? 'Sin datos',
            ),
            _DetailsRow(
              label: 'Teléfono',
              value: player.emergencyContact!.phone ?? 'Sin datos',
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailsRow extends StatelessWidget {
  const _DetailsRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class PaginatedPlayers {
  PaginatedPlayers({
    required this.players,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory PaginatedPlayers.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as List<dynamic>? ?? [])
        .map((item) => Player.fromJson(item as Map<String, dynamic>))
        .toList();
    return PaginatedPlayers(
      players: data,
      total: json['total'] as int? ?? data.length,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? data.length,
    );
  }

  final List<Player> players;
  final int total;
  final int page;
  final int pageSize;
}

class Player {
  Player({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dni,
    required this.birthDate,
    required this.active,
    this.club,
    this.address,
    this.emergencyContact,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      dni: json['dni'] as String,
      birthDate: _parseDate(json['birthDate']),
      active: json['active'] as bool? ?? true,
      club: json['club'] == null
          ? null
          : ClubSummary.fromJson(json['club'] as Map<String, dynamic>),
      address: json['address'] == null
          ? null
          : PlayerAddress.fromJson(json['address'] as Map<String, dynamic>),
      emergencyContact: json['emergencyContact'] == null
          ? null
          : EmergencyContact.fromJson(
              json['emergencyContact'] as Map<String, dynamic>,
            ),
    );
  }

  final int id;
  final String firstName;
  final String lastName;
  final String dni;
  final DateTime? birthDate;
  final bool active;
  final ClubSummary? club;
  final PlayerAddress? address;
  final EmergencyContact? emergencyContact;

  String get fullName => '$lastName, $firstName';

  String get formattedBirthDate {
    if (birthDate == null) {
      return 'Sin datos';
    }
    return DateFormat('dd/MM/yyyy').format(birthDate!);
  }

  String get formattedBirthDateWithAge {
    if (birthDate == null) {
      return 'Sin datos';
    }
    final age = _calculateAge(birthDate!);
    return '${DateFormat('dd/MM/yyyy').format(birthDate!)}${age != null ? ' · $age años' : ''}';
  }
}

class PlayerAddress {
  PlayerAddress({this.street, this.number, this.city});

  factory PlayerAddress.fromJson(Map<String, dynamic> json) {
    return PlayerAddress(
      street: json['street'] as String?,
      number: json['number']?.toString(),
      city: json['city'] as String?,
    );
  }

  final String? street;
  final String? number;
  final String? city;

  Map<String, dynamic> toJson() => {
        'street': street,
        'number': number,
        'city': city,
      };

  String get formatted {
    final parts = [street, number, city]
        .where((value) => value != null && value!.trim().isNotEmpty)
        .map((value) => value!.trim())
        .toList();
    if (parts.isEmpty) {
      return 'Sin datos';
    }
    if (parts.length <= 2) {
      return parts.join(' ');
    }
    return '${parts[0]} ${parts[1]} - ${parts.sublist(2).join(', ')}';
  }
}

class EmergencyContact {
  EmergencyContact({this.name, this.relationship, this.phone});

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] as String?,
      relationship: json['relationship'] as String?,
      phone: json['phone'] as String?,
    );
  }

  final String? name;
  final String? relationship;
  final String? phone;
}

class ClubSummary {
  ClubSummary({required this.id, required this.name});

  factory ClubSummary.fromJson(Map<String, dynamic> json) {
    return ClubSummary(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  final int id;
  final String name;
}

class PaginatedClubs {
  PaginatedClubs({required this.clubs, required this.total, required this.page,
      required this.pageSize});

  factory PaginatedClubs.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as List<dynamic>? ?? [])
        .map((item) => ClubSummary.fromJson(item as Map<String, dynamic>))
        .toList();
    return PaginatedClubs(
      clubs: data,
      total: json['total'] as int? ?? data.length,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? data.length,
    );
  }

  final List<ClubSummary> clubs;
  final int total;
  final int page;
  final int pageSize;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
  return null;
}

int? _calculateAge(DateTime birthDate) {
  final now = DateTime.now();
  int age = now.year - birthDate.year;
  final hasHadBirthday =
      (now.month > birthDate.month) ||
      (now.month == birthDate.month && now.day >= birthDate.day);
  if (!hasHadBirthday) {
    age -= 1;
  }
  return age < 0 ? null : age;
}

String _normalizeForSort(String value) {
  const replacements = {
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'ã': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
  };
  final buffer = StringBuffer();
  for (final rune in value.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    buffer.write(replacements[char] ?? char);
  }
  return buffer.toString();
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
