import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';
import '../../../services/auth_controller.dart';
import '../../shared/widgets/table_filters_bar.dart';

final zonesProvider = FutureProvider<List<ZoneSummary>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<List<dynamic>>('/zones');
  final data = response.data ?? [];
  return data.map((json) => ZoneSummary.fromJson(json as Map<String, dynamic>)).toList();
});

final zonesFiltersProvider =
    StateNotifierProvider<ZonesFiltersController, ZonesFilters>((ref) {
  return ZonesFiltersController();
});

class ZonesPage extends ConsumerStatefulWidget {
  const ZonesPage({super.key});

  @override
  ConsumerState<ZonesPage> createState() => _ZonesPageState();
}

class _ZonesPageState extends ConsumerState<ZonesPage> {
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
    _debounce = Timer(const Duration(milliseconds: 250), () {
      ref.read(zonesFiltersProvider.notifier).setQuery(_searchController.text);
    });
  }

  void _clearFilters() {
    _searchController.clear();
    ref.read(zonesFiltersProvider.notifier).reset();
  }

  List<ZoneSummary> _applyFilters(List<ZoneSummary> zones, ZonesFilters filters) {
    final query = filters.query.trim().toLowerCase();
    return zones.where((zone) {
      if (filters.leagueName != null && zone.leagueName != filters.leagueName) {
        return false;
      }
      if (filters.tournamentId != null && zone.tournamentId != filters.tournamentId) {
        return false;
      }
      if (filters.status != null && zone.status != filters.status) {
        return false;
      }
      if (query.isNotEmpty) {
        final haystack = '${zone.name} ${zone.leagueName} ${zone.tournamentName} ${zone.tournamentYear}'
            .toLowerCase();
        if (!haystack.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _openCreateZone() async {
    final result = await _showZoneEditor();
    if (!mounted || result == null) {
      return;
    }
    ref.invalidate(zonesProvider);
    if (result.saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Zona "${result.name}" creada correctamente.')),
      );
    }
  }

  Future<void> _openZoneEditor(ZoneSummary zone) async {
    final result = await _showZoneEditor(zone: zone);
    if (!mounted || result == null) {
      return;
    }
    ref.invalidate(zonesProvider);
    if (result.finalized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Zona "${result.name}" marcada en curso.')),
      );
    } else if (result.saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Zona "${result.name}" actualizada.')),
      );
    }
  }

  Future<void> _openZoneDetails(ZoneSummary zone) async {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 640;
    if (isCompact) {
      await showModalBottomSheet<void>(
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
            child: _ZoneDetailsDialog(zoneId: zone.id),
          );
        },
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _ZoneDetailsDialog(zoneId: zone.id),
          ),
        );
      },
    );
  }

  Future<ZoneEditorResult?> _showZoneEditor({ZoneSummary? zone}) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 720;
    if (isCompact) {
      return showModalBottomSheet<ZoneEditorResult>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (context) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: bottomInset + 24,
              left: 24,
              right: 24,
              top: 12,
            ),
            child: _ZoneEditorDialog(zone: zone, scrollableList: false),
          );
        },
      );
    }

    return showDialog<ZoneEditorResult>(
      context: context,
      builder: (context) {
        const insetPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 24);
        final media = MediaQuery.of(context);
        final availableHeight = media.size.height - insetPadding.vertical - media.viewInsets.vertical;

        return Dialog(
          insetPadding: insetPadding,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 640,
              maxHeight: availableHeight > 0 ? availableHeight : media.size.height * 0.8,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: _ZoneEditorDialog(zone: zone),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final zonesAsync = ref.watch(zonesProvider);
    final authState = ref.watch(authControllerProvider);
    final isAdmin = authState.user?.roles.contains('ADMIN') ?? false;
    final filters = ref.watch(zonesFiltersProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _openCreateZone,
              icon: const Icon(Icons.add),
              label: const Text('Agregar zona'),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zonas organizacionales',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Divide los clubes en grupos dentro de cada torneo para organizar el fixture de manera segura.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: zonesAsync.when(
                data: (zones) {
                  if (zones.isEmpty) {
                    return _EmptyZonesState(onCreate: isAdmin ? _openCreateZone : null);
                  }

                  final filteredZones = _applyFilters(zones, filters);

                  final leagues = <String>{
                    for (final zone in zones) zone.leagueName,
                  }.toList()
                    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

                  final tournamentsMap = <int, _ZoneTournamentFilterOption>{};
                  for (final zone in zones) {
                    if (filters.leagueName != null && zone.leagueName != filters.leagueName) {
                      continue;
                    }
                    if (zone.tournamentId == 0) {
                      continue;
                    }
                    tournamentsMap[zone.tournamentId] = _ZoneTournamentFilterOption(
                      id: zone.tournamentId,
                      name: zone.tournamentName,
                      year: zone.tournamentYear,
                    );
                  }
                  final tournamentOptions = tournamentsMap.values.toList()
                    ..sort((a, b) {
                      final yearCompare = b.year.compareTo(a.year);
                      if (yearCompare != 0) {
                        return yearCompare;
                      }
                      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                    });

                  final filtersController = ref.read(zonesFiltersProvider.notifier);
                  if (filters.leagueName != null && !leagues.contains(filters.leagueName)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      filtersController.setLeague(null);
                    });
                  }
                  final tournamentIds = tournamentOptions
                      .map<int>((_ZoneTournamentFilterOption option) => option.id)
                      .toSet();
                  if (filters.tournamentId != null && !tournamentIds.contains(filters.tournamentId)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      filtersController.setTournament(null);
                    });
                  }

                  final hasActiveFilters = filters.hasActiveFilters;
                  final headerCountText = hasActiveFilters
                      ? '${filteredZones.length} de ${zones.length} configuradas'
                      : '${zones.length} configuradas';

                  return Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.grid_view_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Zonas registradas',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              Text(
                                headerCountText,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                          child: TableFiltersBar(
                            children: [
                              TableFilterField(
                                label: 'Buscar',
                                width: 280,
                                child: TableFilterSearchField(
                                  controller: _searchController,
                                  placeholder: 'Buscar por liga, torneo o zona',
                                  showClearButton: filters.query.isNotEmpty,
                                  onClear: () {
                                    _searchController.clear();
                                    ref.read(zonesFiltersProvider.notifier).setQuery('');
                                  },
                                ),
                              ),
                              TableFilterField(
                                label: 'Liga',
                                width: 200,
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String?>(
                                    value: leagues.contains(filters.leagueName)
                                        ? filters.leagueName
                                        : null,
                                    isExpanded: true,
                                    items: [
                                      const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('Todas'),
                                      ),
                                      ...leagues.map(
                                        (league) => DropdownMenuItem<String?>(
                                          value: league,
                                          child: Text(league),
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      ref.read(zonesFiltersProvider.notifier).setLeague(value);
                                    },
                                  ),
                                ),
                              ),
                              TableFilterField(
                                label: 'Torneo',
                                width: 220,
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int?>(
                                    value: tournamentIds.contains(filters.tournamentId)
                                        ? filters.tournamentId
                                        : null,
                                    isExpanded: true,
                                    items: [
                                      const DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text('Todos'),
                                      ),
                                      ...tournamentOptions.map(
                                        (_ZoneTournamentFilterOption option) => DropdownMenuItem<int?>(
                                          value: option.id,
                                          child: Text(option.label),
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      ref.read(zonesFiltersProvider.notifier).setTournament(value);
                                    },
                                  ),
                                ),
                              ),
                              TableFilterField(
                                label: 'Estado',
                                width: 200,
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<ZoneStatus?>(
                                    value: filters.status,
                                    isExpanded: true,
                                    items: [
                                      const DropdownMenuItem<ZoneStatus?>(
                                        value: null,
                                        child: Text('Todos'),
                                      ),
                                      ...ZoneStatus.values.map(
                                        (status) => DropdownMenuItem<ZoneStatus?>(
                                          value: status,
                                          child: Text(status.label),
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      ref.read(zonesFiltersProvider.notifier).setStatus(value);
                                    },
                                  ),
                                ),
                              ),
                            ],
                            trailing: TextButton.icon(
                              onPressed: hasActiveFilters ? _clearFilters : null,
                              icon: const Icon(Icons.filter_alt_off_outlined),
                              label: const Text('Limpiar filtros'),
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: filteredZones.isEmpty
                              ? hasActiveFilters
                                  ? _ZonesEmptyFilterState(onClear: _clearFilters)
                                  : const SizedBox.shrink()
                              : _ZonesDataTable(
                                  zones: filteredZones,
                                  isAdmin: isAdmin,
                                  onView: _openZoneDetails,
                                  onEdit: _openZoneEditor,
                                ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => _ZonesErrorState(
                  error: error,
                  onRetry: () => ref.invalidate(zonesProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZonesDataTable extends StatelessWidget {
  const _ZonesDataTable({
    required this.zones,
    required this.isAdmin,
    required this.onView,
    required this.onEdit,
  });

  final List<ZoneSummary> zones;
  final bool isAdmin;
  final ValueChanged<ZoneSummary> onView;
  final ValueChanged<ZoneSummary> onEdit;

  @override
  Widget build(BuildContext context) {
    final table = DataTable(
      headingRowHeight: 52,
      dataRowMinHeight: 64,
      dataRowMaxHeight: 84,
      columns: const [
        DataColumn(label: Text('Liga')),
        DataColumn(label: Text('Torneo')),
        DataColumn(label: Text('Zona')),
        DataColumn(label: Text('Estado')),
        DataColumn(label: Text('Clubes')),
        DataColumn(label: Text('Acciones')),
      ],
      rows: zones
          .map(
            (zone) => DataRow(
              cells: [
                DataCell(Text(zone.leagueName)),
                DataCell(Text('${zone.tournamentName} ${zone.tournamentYear}')),
                DataCell(Text(zone.name)),
                DataCell(_ZoneStatusChip(status: zone.status)),
                DataCell(Text('${zone.clubCount}')), 
                DataCell(
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => onView(zone),
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Ver'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed:
                            isAdmin && zone.isEditable ? () => onEdit(zone) : null,
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
        return Scrollbar(
          thumbVisibility: true,
          controller: PrimaryScrollController.maybeOf(context),
          child: SingleChildScrollView(
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

class _ZoneStatusChip extends StatelessWidget {
  const _ZoneStatusChip({required this.status});

  final ZoneStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(status.label),
      backgroundColor: status.color.withOpacity(0.12),
      labelStyle: TextStyle(color: status.color, fontWeight: FontWeight.w600),
      side: BorderSide(color: status.color.withOpacity(0.4)),
    );
  }
}

class _EmptyZonesState extends StatelessWidget {
  const _EmptyZonesState({this.onCreate});

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.grid_view_outlined,
                  size: 72, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Crea tu primera zona para comenzar a agrupar clubes antes de generar el fixture.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              if (onCreate != null)
                FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('Crear zona'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZonesEmptyFilterState extends StatelessWidget {
  const _ZonesEmptyFilterState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_alt_off_outlined, size: 48),
          const SizedBox(height: 12),
          const Text('No se encontraron zonas con los filtros seleccionados.'),
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

class _ZonesErrorState extends StatelessWidget {
  const _ZonesErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(
            'No pudimos cargar las zonas: $error',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class ZoneEditorResult {
  ZoneEditorResult({
    required this.zoneId,
    required this.name,
    required this.saved,
    required this.finalized,
  });

  final int zoneId;
  final String name;
  final bool saved;
  final bool finalized;
}

class _ZoneEditorDialog extends ConsumerStatefulWidget {
  const _ZoneEditorDialog({this.zone, this.scrollableList = true});

  final ZoneSummary? zone;
  final bool scrollableList;

  @override
  ConsumerState<_ZoneEditorDialog> createState() => _ZoneEditorDialogState();
}

class _ZoneEditorDialogState extends ConsumerState<_ZoneEditorDialog> {
  final _nameController = TextEditingController();
  final Set<int> _selectedClubs = <int>{};
  final Set<int> _initialSelectedClubs = <int>{};

  List<TournamentOption> _tournaments = [];
  List<TournamentClubEligibility> _clubs = [];
  TournamentOption? _selectedTournament;
  ZoneStatus _status = ZoneStatus.open;
  bool _loading = true;
  bool _loadingClubs = false;
  bool _submitting = false;
  bool _zoneLocked = false;
  bool _tournamentLocked = false;
  String? _errorMessage;
  int? _zoneId;

  double? _clubListHeight(BuildContext context) {
    if (!widget.scrollableList || _clubs.isEmpty) {
      return null;
    }
    const minHeight = 160.0;
    const rowHeight = 68.0;
    final estimatedHeight = _clubs.length * rowHeight;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final targetHeight = math.min(screenHeight * 0.45, 360.0);
    final maxHeight = math.max(minHeight, targetHeight);
    return estimatedHeight.clamp(minHeight, maxHeight).toDouble();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      if (widget.zone == null) {
        final tournaments = await _fetchTournaments();
        TournamentOption? selected;
        if (tournaments.isNotEmpty) {
          selected = tournaments.first;
        }
        _tournaments = tournaments;
        _selectedTournament = selected;
        _status = ZoneStatus.open;
        _zoneLocked = false;
        _tournamentLocked = selected?.fixtureLocked ?? false;
        _zoneId = null;
        if (selected != null) {
          await _loadClubsForTournament(selected.id);
        }
      } else {
        final detail = await _fetchZoneDetail(widget.zone!.id);
        _nameController.text = detail.name;
        _status = detail.status;
        _zoneLocked = detail.isLocked;
        _tournamentLocked = detail.tournament.fixtureLocked;
        _zoneId = detail.id;
        _selectedClubs
          ..clear()
          ..addAll(detail.clubs.map((club) => club.id));
        _initialSelectedClubs
          ..clear()
          ..addAll(_selectedClubs);
        final option = TournamentOption(
          id: detail.tournament.id,
          name: detail.tournament.name,
          year: detail.tournament.year,
          leagueName: detail.tournament.leagueName,
          fixtureLocked: detail.tournament.fixtureLocked,
        );
        _tournaments = [option];
        _selectedTournament = option;
        await _loadClubsForTournament(detail.tournament.id);
      }
    } catch (error) {
      _errorMessage = _mapError(error);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<List<TournamentOption>> _fetchTournaments() async {
    final api = ref.read(apiClientProvider);
    final response = await api.get<List<dynamic>>('/tournaments');
    final data = response.data ?? [];
    return data
        .map((json) => TournamentOption.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ZoneDetail> _fetchZoneDetail(int id) async {
    final api = ref.read(apiClientProvider);
    final response = await api.get<Map<String, dynamic>>('/zones/$id');
    final data = response.data ?? <String, dynamic>{};
    return ZoneDetail.fromJson(data);
  }

  Future<void> _loadClubsForTournament(int tournamentId) async {
    setState(() {
      _loadingClubs = true;
    });
    try {
      final api = ref.read(apiClientProvider);
      final response =
          await api.get<List<dynamic>>('/tournaments/$tournamentId/zones/clubs');
      final data = response.data ?? [];
      setState(() {
        _clubs = data
            .map((json) =>
                TournamentClubEligibility.fromJson(json as Map<String, dynamic>))
            .toList();
      });
    } catch (error) {
      setState(() {
        _errorMessage = _mapError(error);
        _clubs = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingClubs = false;
        });
      }
    }
  }

  String _mapError(Object error) {
    if (error is DioException) {
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        final message = responseData['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
      if (error.message != null) {
        return error.message!;
      }
    }
    return 'Ocurrió un error inesperado. Intenta nuevamente.';
  }

  Future<void> _onSelectTournament(TournamentOption? option) async {
    if (option == null || _submitting) {
      return;
    }
    setState(() {
      _selectedTournament = option;
      _tournamentLocked = option.fixtureLocked;
      _selectedClubs.clear();
      _initialSelectedClubs.clear();
    });
    await _loadClubsForTournament(option.id);
  }

  Future<void> _save() async {
    await _submit(finalize: false);
  }

  Future<void> _submit({required bool finalize}) async {
    if (_submitting) {
      return;
    }
    final tournament = _selectedTournament;
    if (tournament == null) {
      setState(() {
        _errorMessage = 'Selecciona un torneo antes de continuar.';
      });
      return;
    }
    final zoneName = _nameController.text.trim();
    if (_zoneId == null && zoneName.isEmpty) {
      setState(() {
        _errorMessage = 'El nombre de la zona es obligatorio.';
      });
      return;
    }
    if (finalize && _zoneId == null) {
      setState(() {
        _errorMessage = 'Guarda la zona antes de confirmarla.';
      });
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      int zoneId = _zoneId ?? 0;
      String finalName = zoneName.isNotEmpty ? zoneName : (widget.zone?.name ?? zoneName);
      if (_zoneId == null) {
        final response = await api.post<Map<String, dynamic>>(
          '/tournaments/${tournament.id}/zones',
          data: {'name': zoneName},
        );
        final data = response.data ?? <String, dynamic>{};
        zoneId = data['id'] as int? ?? 0;
        finalName = data['name'] as String? ?? zoneName;
        _zoneId = zoneId;
      }

      if (zoneId <= 0) {
        setState(() {
          _errorMessage = 'No pudimos determinar la zona creada. Intenta nuevamente.';
        });
        return;
      }

      await _syncSelectedClubs(api, zoneId);

      if (finalize) {
        await api.post('/zones/$zoneId/finalize');
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(
        ZoneEditorResult(
          zoneId: zoneId,
          name: finalName,
          saved: true,
          finalized: finalize,
        ),
      );
    } catch (error) {
      setState(() {
        _errorMessage = _mapError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _syncSelectedClubs(ApiClient api, int zoneId) async {
    final desired = Set<int>.from(_selectedClubs);
    final initial = Set<int>.from(_initialSelectedClubs);
    final toRemove = initial.difference(desired);
    final toAdd = desired.difference(initial);

    if (toAdd.isEmpty && toRemove.isEmpty) {
      _initialSelectedClubs
        ..clear()
        ..addAll(_selectedClubs);
      return;
    }

    for (final clubId in toRemove) {
      await api.delete('/zones/$zoneId/clubs/$clubId');
    }
    for (final clubId in toAdd) {
      await api.post('/zones/$zoneId/clubs', data: {'clubId': clubId});
    }

    _initialSelectedClubs
      ..clear()
      ..addAll(_selectedClubs);
  }

  Future<void> _confirm() async {
    if (_submitting || _zoneId == null) {
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar zona'),
          content: const Text(
            'Para confirmar la zona debes asegurarte de que todos los clubes cumplan los requisitos. ¿Deseas continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
    if (confirm != true) {
      return;
    }
    await _submit(finalize: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final canEdit = !_zoneLocked && !_tournamentLocked && _status == ZoneStatus.open;
    final listHeight = _clubListHeight(context);

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.zone == null ? 'Crear zona' : 'Editar zona',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<TournamentOption>(
            value: _selectedTournament,
            decoration: const InputDecoration(labelText: 'Torneo'),
            onChanged: (widget.zone == null && !_submitting)
                ? (option) => _onSelectTournament(option)
                : null,
            items: _tournaments
                .map(
                  (tournament) => DropdownMenuItem<TournamentOption>(
                    value: tournament,
                    child: Text('${tournament.leagueName} - ${tournament.name} ${tournament.year}'),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            readOnly: widget.zone != null,
            decoration: const InputDecoration(labelText: 'Nombre de la zona'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ZoneStatusChip(status: _status),
              if (_tournamentLocked) ...[
                const SizedBox(width: 8),
                const Tooltip(
                  message: 'El torneo está bloqueado para fixture, no se permiten cambios.',
                  child: Icon(Icons.lock_outline, color: Colors.redAccent),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (_errorMessage != null) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _errorMessage!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.redAccent),
              ),
            ),
          ],
          Text(
            'Clubes participantes',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _loadingClubs
                ? const Center(child: CircularProgressIndicator())
                : _clubs.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text('No hay clubes inscriptos en este torneo.'),
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          Widget listView = ListView.separated(
                            primary: false,
                            shrinkWrap: !widget.scrollableList,
                            physics: widget.scrollableList
                                ? const AlwaysScrollableScrollPhysics()
                                : const NeverScrollableScrollPhysics(),
                            itemCount: _clubs.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final club = _clubs[index];
                              final selected = _selectedClubs.contains(club.id);
                              final isDisabled = _submitting || !canEdit;
                              final indicatorColor = club.eligible ? Colors.green : Colors.redAccent;
                              final tooltip = buildEligibilityTooltip(club);
                              return ListTile(
                                leading: Tooltip(
                                  message: tooltip,
                                  child: Icon(Icons.circle, size: 14, color: indicatorColor),
                                ),
                                title: Text(club.name),
                                subtitle: club.shortName != null
                                    ? Text('Alias: ${club.shortName}')
                                    : Text('${club.categories.where((category) => category.hasTeam).length} categorías con equipo'),
                                trailing: Checkbox(
                                  value: selected,
                                  onChanged: isDisabled
                                      ? null
                                      : (checked) {
                                          setState(() {
                                            if (checked == true) {
                                              _selectedClubs.add(club.id);
                                            } else {
                                              _selectedClubs.remove(club.id);
                                            }
                                          });
                                        },
                                ),
                                enabled: !isDisabled,
                                onTap: isDisabled
                                    ? null
                                    : () {
                                        setState(() {
                                          if (selected) {
                                            _selectedClubs.remove(club.id);
                                          } else {
                                            _selectedClubs.add(club.id);
                                          }
                                        });
                                      },
                              );
                            },
                          );
                          if (listHeight != null) {
                            listView = SizedBox(height: listHeight, child: listView);
                          }
                          return listView;
                        },
                      ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              OutlinedButton(
                onPressed: _submitting ? null : () => Navigator.of(context).maybePop(),
                child: const Text('Cancelar'),
              ),
              const Spacer(),
              if (widget.zone != null)
                FilledButton.tonal(
                  onPressed: canEdit && !_submitting ? _confirm : null,
                  child: _submitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirmar'),
                ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: !_submitting && canEdit ? _save : null,
                child: _submitting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Guardar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

class _ZoneDetailsDialog extends ConsumerStatefulWidget {
  const _ZoneDetailsDialog({required this.zoneId});

  final int zoneId;

  @override
  ConsumerState<_ZoneDetailsDialog> createState() => _ZoneDetailsDialogState();
}

class _ZoneDetailsDialogState extends ConsumerState<_ZoneDetailsDialog> {
  late Future<ZoneDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ZoneDetail> _load() async {
    final api = ref.read(apiClientProvider);
    final response = await api.get<Map<String, dynamic>>('/zones/${widget.zoneId}');
    final data = response.data ?? <String, dynamic>{};
    return ZoneDetail.fromJson(data);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<ZoneDetail>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return SizedBox(
            height: 240,
            child: Center(
              child: Text('No se pudo cargar la zona: ${snapshot.error}'),
            ),
          );
        }
        final detail = snapshot.data!;
        final clubs = [...detail.clubs]
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        final listHeight = clubs.isEmpty
            ? 0.0
            : math.min(360.0, math.max(72.0, clubs.length * 64.0));

        return SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                detail.name,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              if (clubs.isEmpty)
                const Text('Aún no hay clubes asignados a esta zona.')
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Clubes asignados (${clubs.length})',
                      style:
                          theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: listHeight,
                      child: Scrollbar(
                        thumbVisibility: listHeight >= 360.0,
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.only(bottom: 8),
                          itemCount: clubs.length,
                          itemBuilder: (context, index) {
                            final club = clubs[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 4),
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: theme.colorScheme.primaryContainer,
                                foregroundColor: theme.colorScheme.onPrimaryContainer,
                                child: Text('${index + 1}'),
                              ),
                              title: Text(
                                club.name,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              subtitle: club.shortName != null && club.shortName!.trim().isNotEmpty
                                  ? Text('Alias: ${club.shortName}')
                                  : null,
                            );
                          },
                          separatorBuilder: (_, __) => const Divider(height: 1),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class ZonesFilters {
  const ZonesFilters({
    this.query = '',
    this.leagueName,
    this.tournamentId,
    this.status,
  });

  final String query;
  final String? leagueName;
  final int? tournamentId;
  final ZoneStatus? status;

  bool get hasActiveFilters =>
      query.trim().isNotEmpty || leagueName != null || tournamentId != null || status != null;

  ZonesFilters copyWith({String? query}) {
    return ZonesFilters(
      query: query ?? this.query,
      leagueName: leagueName,
      tournamentId: tournamentId,
      status: status,
    );
  }
}

class ZonesFiltersController extends StateNotifier<ZonesFilters> {
  ZonesFiltersController() : super(const ZonesFilters());

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void setLeague(String? leagueName) {
    state = ZonesFilters(
      query: state.query,
      leagueName: leagueName,
      tournamentId: null,
      status: state.status,
    );
  }

  void setTournament(int? tournamentId) {
    state = ZonesFilters(
      query: state.query,
      leagueName: state.leagueName,
      tournamentId: tournamentId,
      status: state.status,
    );
  }

  void setStatus(ZoneStatus? status) {
    state = ZonesFilters(
      query: state.query,
      leagueName: state.leagueName,
      tournamentId: state.tournamentId,
      status: status,
    );
  }

  void reset() {
    state = const ZonesFilters();
  }
}

class _ZoneTournamentFilterOption {
  const _ZoneTournamentFilterOption({
    required this.id,
    required this.name,
    required this.year,
  });

  final int id;
  final String name;
  final int year;

  String get label => '$name $year';
}

class ZoneSummary {
  ZoneSummary({
    required this.id,
    required this.name,
    required this.tournamentId,
    required this.status,
    required this.lockedAt,
    required this.tournamentName,
    required this.tournamentYear,
    required this.tournamentLocked,
    required this.leagueName,
    required this.clubCount,
  });

  factory ZoneSummary.fromJson(Map<String, dynamic> json) {
    final tournament = json['tournament'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final league = tournament['league'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final statusValue = json['status'] as String? ?? 'OPEN';
    final lockedAtValue = json['lockedAt'] as String?;
    final count = json['_count'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return ZoneSummary(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Sin nombre',
      tournamentId: tournament['id'] as int? ?? 0,
      status: ZoneStatusX.fromApi(statusValue),
      lockedAt: lockedAtValue != null ? DateTime.tryParse(lockedAtValue) : null,
      tournamentName: tournament['name'] as String? ?? 'Torneo',
      tournamentYear: tournament['year'] as int? ?? 0,
      tournamentLocked: (tournament['fixtureLockedAt'] as String?) != null,
      leagueName: league['name'] as String? ?? 'Liga',
      clubCount: count['clubZones'] as int? ?? 0,
    );
  }

  final int id;
  final String name;
  final int tournamentId;
  final ZoneStatus status;
  final DateTime? lockedAt;
  final String tournamentName;
  final int tournamentYear;
  final bool tournamentLocked;
  final String leagueName;
  final int clubCount;

  bool get isEditable => status == ZoneStatus.open && !tournamentLocked;
}

class ZoneDetail {
  ZoneDetail({
    required this.id,
    required this.name,
    required this.status,
    required this.lockedAt,
    required this.tournament,
    required this.clubs,
  });

  factory ZoneDetail.fromJson(Map<String, dynamic> json) {
    final tournament = ZoneTournament.fromJson(
      json['tournament'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
    final clubZones = json['clubZones'] as List<dynamic>? ?? [];
    return ZoneDetail(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Sin nombre',
      status: ZoneStatusX.fromApi(json['status'] as String? ?? 'OPEN'),
      lockedAt: (json['lockedAt'] as String?) != null
          ? DateTime.tryParse(json['lockedAt'] as String)
          : null,
      tournament: tournament,
      clubs: clubZones
          .map((entry) => ZoneClub.fromJson(entry as Map<String, dynamic>))
          .toList(),
    );
  }

  final int id;
  final String name;
  final ZoneStatus status;
  final DateTime? lockedAt;
  final ZoneTournament tournament;
  final List<ZoneClub> clubs;

  bool get isLocked => status != ZoneStatus.open || lockedAt != null;
}

class ZoneTournament {
  ZoneTournament({
    required this.id,
    required this.name,
    required this.year,
    required this.leagueName,
    required this.fixtureLocked,
  });

  factory ZoneTournament.fromJson(Map<String, dynamic> json) {
    final league = json['league'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return ZoneTournament(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Torneo',
      year: json['year'] as int? ?? 0,
      leagueName: league['name'] as String? ?? 'Liga',
      fixtureLocked: (json['fixtureLockedAt'] as String?) != null,
    );
  }

  final int id;
  final String name;
  final int year;
  final String leagueName;
  final bool fixtureLocked;
}

class ZoneClub {
  ZoneClub({required this.id, required this.name, this.shortName});

  factory ZoneClub.fromJson(Map<String, dynamic> json) {
    final club = json['club'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return ZoneClub(
      id: club['id'] as int? ?? json['clubId'] as int? ?? 0,
      name: club['name'] as String? ?? 'Club',
      shortName: club['shortName'] as String?,
    );
  }

  final int id;
  final String name;
  final String? shortName;
}

class TournamentOption {
  TournamentOption({
    required this.id,
    required this.name,
    required this.year,
    required this.leagueName,
    required this.fixtureLocked,
  });

  factory TournamentOption.fromJson(Map<String, dynamic> json) {
    final league = json['league'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return TournamentOption(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Torneo',
      year: json['year'] as int? ?? 0,
      leagueName: league['name'] as String? ?? 'Liga',
      fixtureLocked: (json['fixtureLockedAt'] as String?) != null,
    );
  }

  final int id;
  final String name;
  final int year;
  final String leagueName;
  final bool fixtureLocked;
}

class TournamentClubEligibility {
  TournamentClubEligibility({
    required this.id,
    required this.name,
    required this.shortName,
    required this.eligible,
    required this.categories,
  });

  factory TournamentClubEligibility.fromJson(Map<String, dynamic> json) {
    final categories = json['categories'] as List<dynamic>? ?? [];
    return TournamentClubEligibility(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Club',
      shortName: json['shortName'] as String?,
      eligible: json['eligible'] as bool? ?? false,
      categories: categories
          .map((entry) => CategoryEligibility.fromJson(entry as Map<String, dynamic>))
          .toList(),
    );
  }

  final int id;
  final String name;
  final String? shortName;
  final bool eligible;
  final List<CategoryEligibility> categories;
}

String buildEligibilityTooltip(TournamentClubEligibility club) {
  if (club.eligible) {
    return 'El club cumple con todas las categorías requeridas.';
  }
  final missingTeams = club.categories.where(
    (category) => category.mandatory && (!category.hasTeam || category.playersCount < category.minPlayers),
  );
  final missingPlayers = club.categories.where(
    (category) => category.hasTeam && category.playersCount < category.minPlayers,
  );
  final buffer = <String>[];
  if (missingTeams.isNotEmpty) {
    buffer.add(
      'Faltan equipos obligatorios: ${missingTeams.map((c) => c.categoryName).join(', ')}.',
    );
  }
  if (missingPlayers.isNotEmpty) {
    buffer.add(
      "Jugadores insuficientes en: ${missingPlayers.map((c) => "${c.categoryName} (${c.playersCount}/${c.minPlayers})").join(', ')}.",
    );
  }
  if (buffer.isEmpty) {
    buffer.add('No cumple los requisitos definidos para el torneo.');
  }
  return buffer.join('\n');
}

class CategoryEligibility {
  CategoryEligibility({
    required this.tournamentCategoryId,
    required this.categoryId,
    required this.categoryName,
    required this.mandatory,
    required this.minPlayers,
    required this.hasTeam,
    required this.playersCount,
    required this.meetsMinPlayers,
  });

  factory CategoryEligibility.fromJson(Map<String, dynamic> json) {
    return CategoryEligibility(
      tournamentCategoryId: json['tournamentCategoryId'] as int? ?? 0,
      categoryId: json['categoryId'] as int? ?? 0,
      categoryName: json['categoryName'] as String? ?? 'Categoría',
      mandatory: json['mandatory'] as bool? ?? false,
      minPlayers: json['minPlayers'] as int? ?? 0,
      hasTeam: json['hasTeam'] as bool? ?? false,
      playersCount: json['playersCount'] as int? ?? 0,
      meetsMinPlayers: json['meetsMinPlayers'] as bool? ?? false,
    );
  }

  final int tournamentCategoryId;
  final int categoryId;
  final String categoryName;
  final bool mandatory;
  final int minPlayers;
  final bool hasTeam;
  final int playersCount;
  final bool meetsMinPlayers;
}

enum ZoneStatus { open, inProgress, finished }

extension ZoneStatusX on ZoneStatus {
  static ZoneStatus fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'IN_PROGRESS':
        return ZoneStatus.inProgress;
      case 'FINISHED':
        return ZoneStatus.finished;
      default:
        return ZoneStatus.open;
    }
  }

  String get label {
    switch (this) {
      case ZoneStatus.open:
        return 'Abierta';
      case ZoneStatus.inProgress:
        return 'En curso';
      case ZoneStatus.finished:
        return 'Finalizada';
    }
  }

  Color get color {
    switch (this) {
      case ZoneStatus.open:
        return Colors.blue;
      case ZoneStatus.inProgress:
        return Colors.orange;
      case ZoneStatus.finished:
        return Colors.green;
    }
  }
}
