import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/utils/csv_download.dart';
import '../../../core/utils/responsive.dart';
import '../../../services/api_client.dart';
import '../../../services/auth_controller.dart';
import '../../shared/widgets/app_data_table_style.dart';
import '../../shared/widgets/page_scaffold.dart';
import '../../shared/widgets/table_filters_bar.dart';
import 'widgets/authenticated_image.dart';

const _moduleClubes = 'CLUBES';
const _actionCreate = 'CREATE';
const _actionUpdate = 'UPDATE';
const _actionView = 'VIEW';
const _dateFormat = 'dd/MM/yyyy';
const double _clubLogoSize = 200;
const int _clubLogoMinSize = 200;
const int _clubLogoMaxSize = 500;

Map<String, String> _buildImageHeaders(WidgetRef ref) {
  final token = ref.read(authControllerProvider).accessToken;
  if (token == null || token.isEmpty) {
    return const {};
  }
  return {'Authorization': 'Bearer $token'};
}

final clubsFiltersProvider =
    StateNotifierProvider<ClubsFiltersController, ClubsFilters>((ref) {
  return ClubsFiltersController();
});

final clubsProvider = FutureProvider<PaginatedClubs>((ref) async {
  final filters = ref.watch(clubsFiltersProvider);
  final api = ref.read(apiClientProvider);
  final response =
      await api.get<Map<String, dynamic>>('/clubs', queryParameters: {
    if (filters.query.trim().isNotEmpty) 'search': filters.query.trim(),
    if (filters.status != ClubStatusFilter.all) 'status': filters.status.name,
    'page': filters.page,
    'pageSize': filters.pageSize,
  });
  final data = response.data ?? {};
  return PaginatedClubs.fromJson(data);
});

class ClubsPage extends ConsumerStatefulWidget {
  const ClubsPage({super.key});

  @override
  ConsumerState<ClubsPage> createState() => _ClubsPageState();
}

class _ClubsPageState extends ConsumerState<ClubsPage> {
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
      ref.read(clubsFiltersProvider.notifier).setQuery(_searchController.text);
    });
  }

  Future<void> _openCreateClub() async {
    _ClubFormResult? result;
    do {
      result = await _showClubForm(
        context,
        readOnly: false,
        allowSaveAndAdd: true,
      );
      if (!mounted || result == null) {
        break;
      }
      if (result == _ClubFormResult.saved ||
          result == _ClubFormResult.savedAndAddAnother) {
        ref.invalidate(clubsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Club guardado correctamente.')),
        );
      }
    } while (result == _ClubFormResult.savedAndAddAnother);
  }

  Future<_ClubFormResult?> _showClubForm(
    BuildContext context, {
    Club? club,
    required bool readOnly,
    bool allowSaveAndAdd = false,
  }) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 640;
    final maxDialogWidth = 720.0;

    final dialog = _ClubFormDialog(
      club: club,
      readOnly: readOnly,
      allowSaveAndAdd: allowSaveAndAdd,
    );

    if (isCompact) {
      return showModalBottomSheet<_ClubFormResult>(
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

    return showDialog<_ClubFormResult>(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SizedBox(
            width: math.min(maxDialogWidth, size.width - 120),
            child: dialog,
          ),
        );
      },
    );
  }

  Future<void> _openClubDetails(Club club) async {
    if (club.slug != null) {
      if (!mounted) {
        return;
      }
      GoRouter.of(context).push('/club/${club.slug}');
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: _ClubDetailsView(club: club),
        );
      },
    );
  }

  Future<void> _openEditClub(Club club) async {
    final result = await _showClubForm(
      context,
      club: club,
      readOnly: false,
    );
    if (!mounted || result == null) {
      return;
    }
    if (result == _ClubFormResult.saved) {
      ref.invalidate(clubsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Club "${club.name}" actualizado.')),
      );
    }
  }
  Future<void> _openClubRoster(Club club) async {
    GoRouter.of(context).push(
      '/clubs/${club.id}/roster',
      extra: club,
    );
  }


  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final canCreate =
        user?.hasPermission(module: _moduleClubes, action: _actionCreate) ?? false;
    final canEdit =
        user?.hasPermission(module: _moduleClubes, action: _actionUpdate) ?? false;
    final canViewRoster =
        user != null &&
        user.hasAnyRole(const ['ADMIN', 'COLLABORATOR', 'DELEGATE']) &&
        user.hasPermission(module: _moduleClubes, action: _actionView);
    final clubsAsync = ref.watch(clubsProvider);
    final filters = ref.watch(clubsFiltersProvider);

    return PageScaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _openCreateClub,
              icon: const Icon(Icons.add),
              label: const Text('Agregar club'),
            )
          : null,
      builder: (context, scrollController) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final padding = Responsive.pagePadding(context);
            final isMobile = Responsive.isMobile(context);
            final filterFieldWidth = isMobile ? constraints.maxWidth : 320.0;
            final statusFieldWidth = isMobile ? constraints.maxWidth : 200.0;

            return ListView(
              controller: scrollController,
              padding: padding,
              children: [
                Text(
                  'Clubes',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Administrá los clubes afiliados, sus colores e información general.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Card(
                  child: ExpansionTile(
                    title: const Text('Búsqueda'),
                    childrenPadding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    children: [
                      TableFiltersBar(
                        children: [
                          TableFilterField(
                            label: 'Buscar',
                            width: filterFieldWidth,
                            child: TableFilterSearchField(
                              controller: _searchController,
                              placeholder: 'Buscar por nombre o liga',
                              showClearButton: filters.query.isNotEmpty,
                              onClear: () {
                                _searchController.clear();
                                ref
                                    .read(clubsFiltersProvider.notifier)
                                    .setQuery('');
                              },
                            ),
                          ),
                          TableFilterField(
                            label: 'Estado',
                            width: statusFieldWidth,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<ClubStatusFilter>(
                                value: filters.status,
                                isExpanded: true,
                                items: ClubStatusFilter.values
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
                                        .read(clubsFiltersProvider.notifier)
                                        .setStatus(value);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                        trailing: TextButton.icon(
                          onPressed: filters.query.isEmpty &&
                                  filters.status == ClubStatusFilter.all
                              ? null
                              : () {
                                  _searchController.clear();
                                  ref.read(clubsFiltersProvider.notifier).reset();
                                },
                          icon: const Icon(Icons.filter_alt_off_outlined),
                          label: const Text('Limpiar filtros'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                clubsAsync.when(
                  data: (paginated) {
                  if (paginated.clubs.isEmpty) {
                    if (filters.query.isNotEmpty ||
                        filters.status != ClubStatusFilter.all) {
                      return _ClubsEmptyFilterState(onClear: () {
                        ref.read(clubsFiltersProvider.notifier).reset();
                        _searchController.clear();
                      });
                    }
                    return _ClubsEmptyState(
                      canCreate: canCreate,
                      onCreate: _openCreateClub,
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
                                Icons.groups_3_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Clubes registrados',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              Text('${paginated.total} en total',
                                  style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: _ClubsDataTable(
                            data: paginated,
                            canEdit: canEdit,
                            onEdit: _openEditClub,
                            onView: _openClubDetails,
                            onViewRoster: _openClubRoster,
                            canViewRoster: canViewRoster,
                            delegateClubId: user?.clubId,
                          ),
                        ),
                        const Divider(height: 1),
                        _ClubsPaginationFooter(
                          page: paginated.page,
                          pageSize: paginated.pageSize,
                          total: paginated.total,
                          onPageChanged: (page) =>
                              ref.read(clubsFiltersProvider.notifier).setPage(page),
                          onPageSizeChanged: (value) => ref
                              .read(clubsFiltersProvider.notifier)
                              .setPageSize(value),
                        ),
                      ],
                    ),
                  );
                  },
                  loading: () => const _ClubsTableSkeleton(),
                  error: (error, stackTrace) => _ClubsErrorState(
                    error: error,
                    onRetry: () => ref.invalidate(clubsProvider),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class ClubsFilters {
  const ClubsFilters({
    this.query = '',
    this.status = ClubStatusFilter.all,
    this.page = 1,
    this.pageSize = 25,
  });

  final String query;
  final ClubStatusFilter status;
  final int page;
  final int pageSize;

  ClubsFilters copyWith({
    String? query,
    ClubStatusFilter? status,
    int? page,
    int? pageSize,
  }) {
    return ClubsFilters(
      query: query ?? this.query,
      status: status ?? this.status,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class ClubsFiltersController extends StateNotifier<ClubsFilters> {
  ClubsFiltersController() : super(const ClubsFilters());

  void setQuery(String query) {
    state = state.copyWith(query: query, page: 1);
  }

  void setStatus(ClubStatusFilter status) {
    state = state.copyWith(status: status, page: 1);
  }

  void setPage(int page) {
    state = state.copyWith(page: page);
  }

  void setPageSize(int pageSize) {
    state = state.copyWith(pageSize: pageSize, page: 1);
  }

  void reset() {
    state = const ClubsFilters();
  }
}

enum ClubStatusFilter { all, active, inactive }

extension on ClubStatusFilter {
  String get label {
    switch (this) {
      case ClubStatusFilter.all:
        return 'Todos';
      case ClubStatusFilter.active:
        return 'Activos';
      case ClubStatusFilter.inactive:
        return 'Inactivos';
    }
  }

  String get name => switch (this) {
        ClubStatusFilter.all => 'all',
        ClubStatusFilter.active => 'active',
        ClubStatusFilter.inactive => 'inactive',
      };
}

class _ClubsDataTable extends StatelessWidget {
  const _ClubsDataTable({
    required this.data,
    required this.canEdit,
    required this.onEdit,
    required this.onView,
    required this.onViewRoster,
    required this.canViewRoster,
    required this.delegateClubId,
  });

  final PaginatedClubs data;
  final bool canEdit;
  final ValueChanged<Club> onEdit;
  final ValueChanged<Club> onView;
  final ValueChanged<Club> onViewRoster;
  final bool canViewRoster;
  final int? delegateClubId;

  @override
  Widget build(BuildContext context) {
    final clubs = [...data.clubs]
      ..sort((a, b) => _normalizeForSort(a.name).compareTo(_normalizeForSort(b.name)));

    final theme = Theme.of(context);
    final colors = AppDataTableColors.standard(theme);
    final headerStyle =
        theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: colors.headerText);
    final isMobile = Responsive.isMobile(context);
    final delegateClubIdIsRequired = delegateClubId != null;

    final table = DataTable(
      columns: [
        const DataColumn(label: Text('Nombre')),
        if (!isMobile) const DataColumn(label: Text('Estado')),
        if (!isMobile) const DataColumn(label: Text('Acciones')),
      ],
      dataRowMinHeight: 44,
      dataRowMaxHeight: 60,
      headingRowHeight: 48,
      showCheckboxColumn: false,
      headingRowColor: buildHeaderColor(colors.headerBackground),
      headingTextStyle: headerStyle,
      rows: [
        for (var index = 0; index < clubs.length; index++)
          DataRow(
            color: buildStripedRowColor(index: index, colors: colors),
            onSelectChanged: isMobile ? (_) => onView(clubs[index]) : null,
            cells: [
              DataCell(
                Row(
                  children: [
                    _ClubAvatar(club: clubs[index]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clubs[index].name,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (clubs[index].slug != null)
                            Text('Slug: ${clubs[index].slug}', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                DataCell(
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      avatar: Icon(
                        clubs[index].active ? Icons.check_circle : Icons.pause_circle,
                        size: 18,
                        color: clubs[index].active
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      backgroundColor: clubs[index].active
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceVariant,
                      label: Text(
                        clubs[index].active ? 'Activo' : 'Inactivo',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: clubs[index].active
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              if (!isMobile)
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => onView(clubs[index]),
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Detalles'),
                      ),
                      if (canViewRoster &&
                          (!delegateClubIdIsRequired || delegateClubId == clubs[index].id)) ...[
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () => onViewRoster(clubs[index]),
                          icon: const Icon(Icons.groups_outlined),
                          label: const Text('Plantel'),
                        ),
                      ],
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        onPressed: canEdit ? () => onEdit(clubs[index]) : null,
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
        final scrollView = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: table,
          ),
        );

        if (isMobile) {
          return scrollView;
        }

        return Scrollbar(
          thumbVisibility: true,
          notificationPredicate: (notification) =>
              notification.metrics.axis == Axis.horizontal,
          child: scrollView,
        );
      },
    );
  }
}


class ClubRosterPage extends ConsumerStatefulWidget {
  const ClubRosterPage({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  final int clubId;
  final String clubName;

  @override
  ConsumerState<ClubRosterPage> createState() => _ClubRosterPageState();
}

class _ClubRosterPageState extends ConsumerState<ClubRosterPage> {
  final DateFormat _birthDateFormat = DateFormat(_dateFormat);
  bool _loading = true;
  bool _exporting = false;
  String? _error;
  int? _selectedTournamentId;
  int? _selectedCategoryId;
  List<_RosterFilterOption> _tournaments = const [];
  List<_RosterFilterOption> _categories = const [];
  List<_ClubRosterRow> _rows = const [];
  final ScrollController _tableVerticalController = ScrollController();
  final ScrollController _tableHorizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    unawaited(_loadRoster(initialLoad: true));
  }

  @override
  void dispose() {
    _tableVerticalController.dispose();
    _tableHorizontalController.dispose();
    super.dispose();
  }

  Future<void> _loadRoster({required bool initialLoad}) async {
    if (initialLoad) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final api = ref.read(apiClientProvider);
      final query = <String, dynamic>{
        if (_selectedTournamentId != null) 'tournamentId': _selectedTournamentId,
      };

      final response = await api.get<Map<String, dynamic>>(
        '/clubs/${widget.clubId}/roster',
        queryParameters: query,
        options: Options(
          headers: {
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
          },
        ),
      );
      final data = response.data ?? {};
      final selectedTournamentId = data['selectedTournamentId'] as int?;
      final filters = data['filters'] as Map<String, dynamic>? ?? {};
      final tournaments = (filters['tournaments'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(_RosterFilterOption.fromJson)
          .toList();
      final categories = (filters['categories'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(_RosterFilterOption.fromJson)
          .toList();
      final rows = (data['rows'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(_ClubRosterRow.fromJson)
          .toList();
      setState(() {
        _tournaments = tournaments;
        if (selectedTournamentId != null) {
          _selectedTournamentId = selectedTournamentId;
        }
        _categories = categories;
        if (_selectedTournamentId != null &&
            !_tournaments.any((item) => item.id == _selectedTournamentId)) {
          _selectedTournamentId = _tournaments.isNotEmpty ? _tournaments.first.id : null;
        }
        if (_selectedCategoryId != null && !_categories.any((item) => item.id == _selectedCategoryId)) {
          _selectedCategoryId = null;
        }

        final selectedCategoryName = _selectedCategoryId == null
            ? null
            : _categories.firstWhere(
                (item) => item.id == _selectedCategoryId,
                orElse: () => const _RosterFilterOption(id: 0, name: ''),
              ).name;

        final selectedRows = _selectedCategoryId == null
            ? rows
            : rows
                .where(
                  (row) =>
                      (row.categoryId != null && row.categoryId == _selectedCategoryId) ||
                      (selectedCategoryName != null && row.categoryName == selectedCategoryName),
                )
                .toList();
        _rows = _sortRosterRows(selectedRows);
        _loading = false;
        _error = null;
      });
    } catch (error) {
      setState(() {
        _loading = false;
        _error = 'No se pudo cargar el plantel: $error';
      });
    }
  }

  List<_ClubRosterRow> _sortRosterRows(List<_ClubRosterRow> rows) {
    final sortedRows = List<_ClubRosterRow>.from(rows);
    sortedRows.sort((a, b) {
      final categoryComparison =
          a.categoryName.toLowerCase().compareTo(b.categoryName.toLowerCase());
      if (categoryComparison != 0) {
        return categoryComparison;
      }
      final lastNameComparison = a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase());
      if (lastNameComparison != 0) {
        return lastNameComparison;
      }
      return a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase());
    });
    return sortedRows;
  }

  Future<void> _exportCsv() async {
    if (_rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay datos para exportar.')),
      );
      return;
    }

    setState(() => _exporting = true);
    try {
      final buffer = StringBuffer();
      buffer.writeln('Nombre,Apellido,Fecha de nacimiento,DNI,Torneo,Categoría');
      for (final row in _rows) {
        buffer.writeln([
          _escapeCsv(row.firstName),
          _escapeCsv(row.lastName),
          _escapeCsv(_birthDateFormat.format(row.birthDate)),
          _escapeCsv(row.dni),
          _escapeCsv(row.tournamentName),
          _escapeCsv(row.categoryName),
        ].join(','));
      }
      final now = DateTime.now();
      final fileName = 'plantel_${widget.clubId}_${DateFormat('yyyyMMdd_HHmm').format(now)}.csv';
      await downloadCsv(content: buffer.toString(), filename: fileName);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo exportar el CSV: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PageScaffold(
      backgroundColor: Colors.transparent,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: Responsive.pagePadding(context),
        children: [
          Text(
            'Plantel · ${widget.clubName}',
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  SizedBox(
                    width: 320,
                    child: DropdownButtonFormField<int>(
                      value: _selectedTournamentId,
                      decoration: const InputDecoration(labelText: 'Torneo *'),
                      items: _tournaments
                          .map(
                            (item) => DropdownMenuItem<int>(
                              value: item.id,
                              child: Text(item.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedTournamentId = value;
                          _selectedCategoryId = null;
                        });
                        unawaited(_loadRoster(initialLoad: true));
                      },
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: DropdownButtonFormField<int?>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Todas'),
                        ),
                        ..._categories.map(
                          (item) => DropdownMenuItem<int?>(
                            value: item.id,
                            child: Text(item.name),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedCategoryId = value);
                        unawaited(_loadRoster(initialLoad: true));
                      },
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _exporting ? null : _exportCsv,
                    icon: _exporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_outlined),
                    label: const Text('Exportar CSV'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: SizedBox(
              height: 560,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _rows.isEmpty
                          ? const Center(
                              child: Text('No hay jugadores para los filtros seleccionados.'),
                            )
                          : Scrollbar(
                              controller: _tableVerticalController,
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                controller: _tableVerticalController,
                                child: Scrollbar(
                                  controller: _tableHorizontalController,
                                  thumbVisibility: true,
                                  notificationPredicate: (notification) =>
                                      notification.metrics.axis == Axis.horizontal,
                                  child: SingleChildScrollView(
                                    controller: _tableHorizontalController,
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columns: const [
                                        DataColumn(label: Text('Apellido')),
                                        DataColumn(label: Text('Nombre')),
                                        DataColumn(label: Text('Fecha de nacimiento')),
                                        DataColumn(label: Text('DNI')),
                                        DataColumn(label: Text('Torneo')),
                                        DataColumn(label: Text('Categoría')),
                                      ],
                                      rows: _rows
                                          .map(
                                            (row) => DataRow(cells: [
                                              DataCell(Text(row.lastName)),
                                              DataCell(Text(row.firstName)),
                                              DataCell(Text(_birthDateFormat.format(row.birthDate))),
                                              DataCell(Text(row.dni)),
                                              DataCell(Text(row.tournamentName)),
                                              DataCell(Text(row.categoryName)),
                                            ]),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
            ),
          ),
        ],
      ),
    );
  }

}

class _RosterFilterOption {
  const _RosterFilterOption({required this.id, required this.name});

  factory _RosterFilterOption.fromJson(Map<String, dynamic> json) {
    return _RosterFilterOption(
      id: json['id'] as int,
      name: json['name'] as String? ?? '—',
    );
  }

  final int id;
  final String name;
}

class _ClubRosterRow {
  const _ClubRosterRow({
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.dni,
    required this.categoryId,
    required this.tournamentName,
    required this.categoryName,
  });

  factory _ClubRosterRow.fromJson(Map<String, dynamic> json) {
    return _ClubRosterRow(
      firstName: json['firstName'] as String? ?? '—',
      lastName: json['lastName'] as String? ?? '—',
      birthDate: DateTime.tryParse(json['birthDate'] as String? ?? '') ?? DateTime(1900),
      dni: json['dni'] as String? ?? '—',
      categoryId: _parseCategoryId(json['categoryId']),
      tournamentName: json['tournamentName'] as String? ?? '—',
      categoryName: json['categoryName'] as String? ?? '—',
    );
  }

  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final String dni;
  final int? categoryId;
  final String tournamentName;
  final String categoryName;
}


int? _parseCategoryId(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is String) {
    return int.tryParse(value);
  }
  if (value is num) {
    return value.toInt();
  }
  return null;
}

String _escapeCsv(String value) {
  final escaped = value.replaceAll('"', '""');
  return '"$escaped"';
}

class _ClubsPaginationFooter extends StatelessWidget {
  const _ClubsPaginationFooter({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.onPageChanged,
    required this.onPageSizeChanged,
    this.pageSizes = const [25, 50],
  });

  final int page;
  final int pageSize;
  final int total;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;
  final List<int> pageSizes;

  @override
  Widget build(BuildContext context) {
    final totalPages = math.max(1, (total / pageSize).ceil());
    final start = ((page - 1) * pageSize) + 1;
    final end = math.min(page * pageSize, total);

    final availableSizes = {...pageSizes, pageSize}.toList()..sort();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Mostrando $start-$end de $total',
                style: theme.textTheme.bodySmall),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Filas por página', style: theme.textTheme.bodySmall),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: pageSize,
                    isDense: true,
                    items: availableSizes
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text('$value'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null && value != pageSize) {
                        onPageSizeChanged(value);
                      }
                    },
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Página anterior',
                  onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('$page de $totalPages'),
                IconButton(
                  tooltip: 'Página siguiente',
                  onPressed: page < totalPages ? () => onPageChanged(page + 1) : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClubAvatar extends ConsumerWidget {
  const _ClubAvatar({required this.club});

  final Club club;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = club.primaryColor ?? Theme.of(context).colorScheme.primary;
    final fallback = _ClubAvatarInitials(
      initials: club.initials,
      color: primary,
    );
    final logoUrl = club.logoUrl;

    return SizedBox(
      width: 48,
      height: 48,
      child: logoUrl != null && logoUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.zero,
              child: AuthenticatedImage(
                imageUrl: logoUrl,
                fit: BoxFit.contain,
                headers: _buildImageHeaders(ref),
                placeholder: Center(
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(primary),
                    ),
                  ),
                ),
                error: fallback,
              ),
            )
          : fallback,
    );
  }
}

class _ClubAvatarInitials extends StatelessWidget {
  const _ClubAvatarInitials({required this.initials, required this.color});

  final String initials;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ClubsTableSkeleton extends StatelessWidget {
  const _ClubsTableSkeleton();

  @override
  Widget build(BuildContext context) {
    final shimmerColor = Theme.of(context).colorScheme.surfaceVariant;

    return Card(
      child: Column(
        children: [
          const ListTile(
            leading:
                SizedBox(width: 32, height: 32, child: CircularProgressIndicator()),
            title: SizedBox(height: 16),
            subtitle: SizedBox(height: 16),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: List.generate(5, (index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: index == 4 ? 0 : 16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: shimmerColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 12,
                              width: 120,
                              decoration: BoxDecoration(
                                color: shimmerColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClubsEmptyState extends StatelessWidget {
  const _ClubsEmptyState({required this.canCreate, required this.onCreate});

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
            Icon(Icons.shield_moon_outlined,
                size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'No hay clubes todavía.',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea el primer club para comenzar a cargar planteles y fixtures.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (canCreate)
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Agregar club'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ClubsEmptyFilterState extends StatelessWidget {
  const _ClubsEmptyFilterState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_alt_off_outlined, size: 48),
          const SizedBox(height: 12),
          const Text('No se encontraron clubes con los filtros actuales.'),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: onClear, child: const Text('Limpiar filtros')),
        ],
      ),
    );
  }
}

class _ClubsErrorState extends StatelessWidget {
  const _ClubsErrorState({required this.error, required this.onRetry});

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
          Text('No se pudieron cargar los clubes: $error',
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _ClubDetailsView extends ConsumerWidget {
  const _ClubDetailsView({required this.club});

  final Club club;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 640,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            club.name,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text('Vista de solo lectura del club',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              _DetailItem(label: 'Estado', value: club.active ? 'Activo' : 'Inactivo'),
              if (club.slug != null) _DetailItem(label: 'Slug', value: club.slug!),
              if (club.shortName != null)
                _DetailItem(label: 'Nombre corto', value: club.shortName!),
              if (club.instagramUrl != null)
                _DetailLink(label: 'Instagram', url: club.instagramUrl!),
              if (club.facebookUrl != null)
                _DetailLink(label: 'Facebook', url: club.facebookUrl!),
            ],
          ),
          if (club.logoUrl != null && club.logoUrl!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AuthenticatedImage(
                  imageUrl: club.logoUrl!,
                  width: _clubLogoSize,
                  height: _clubLogoSize,
                  fit: BoxFit.cover,
                  headers: _buildImageHeaders(ref),
                  placeholder: Container(
                    width: _clubLogoSize,
                    height: _clubLogoSize,
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: Container(
                    width: _clubLogoSize,
                    height: _clubLogoSize,
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.shield_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _ColorBadge(
                  title: 'Color primario',
                  color: club.primaryColor,
                  hex: club.primaryHex),
              const SizedBox(width: 12),
              _ColorBadge(
                  title: 'Color secundario',
                  color: club.secondaryColor,
                  hex: club.secondaryHex),
            ],
          ),
          const SizedBox(height: 20),
          if (club.latitude != null && club.longitude != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 240,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(club.latitude!, club.longitude!),
                    initialZoom: 13,
                    interactionOptions:
                        const InteractionOptions(enableMultiFingerGestureRace: true),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'ligas_app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(club.latitude!, club.longitude!),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on,
                              color: Colors.red, size: 36),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            Text('Este club aún no tiene ubicación asignada.',
                style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar')),
          )
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _DetailLink extends StatelessWidget {
  const _DetailLink({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            url,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    );
  }
}

class _ColorBadge extends StatelessWidget {
  const _ColorBadge({required this.title, required this.color, required this.hex});

  final Color? color;
  final String? hex;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 72,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color ?? Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(hex ?? '—',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            )
          ],
        ),
      ),
    );
  }
}

enum _ClubFormResult { saved, savedAndAddAnother }

class _ClubFormDialog extends ConsumerStatefulWidget {
  const _ClubFormDialog({
    required this.readOnly,
    this.club,
    required this.allowSaveAndAdd,
  });

  final bool readOnly;
  final Club? club;
  final bool allowSaveAndAdd;

  @override
  ConsumerState<_ClubFormDialog> createState() => _ClubFormDialogState();
}

class _ClubFormDialogState extends ConsumerState<_ClubFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _slugController;
  late final TextEditingController _shortNameController;
  late final TextEditingController _primaryColorController;
  late final TextEditingController _secondaryColorController;
  late final TextEditingController _instagramController;
  late final TextEditingController _facebookController;
  late final TextEditingController _homeAddressController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _addressController;
  bool _active = true;
  bool _isSaving = false;
  bool _hasChanges = false;
  bool _slugManuallyEdited = false;
  bool _shortNameManuallyEdited = false;
  bool _updatingSlug = false;
  bool _updatingShortName = false;
  Uint8List? _logoBytes;
  String? _logoFileName;
  String? _logoUrl;
  String? _originalLogoUrl;
  bool _removeLogo = false;
  String? _errorMessage;
  LatLng? _selectedLocation;
  late final _ClubFormSnapshot _initialSnapshot;

  @override
  void initState() {
    super.initState();
    final club = widget.club;
    _nameController = TextEditingController(text: club?.name ?? '');
    _slugController = TextEditingController(text: club?.slug ?? '');
    _shortNameController = TextEditingController(
      text: club?.shortName ?? club?.name ?? '',
    );
    _shortNameManuallyEdited = widget.club != null && club?.shortName != null;
    _primaryColorController =
        TextEditingController(text: club?.primaryHex?.toUpperCase() ?? '');
    _secondaryColorController =
        TextEditingController(text: club?.secondaryHex?.toUpperCase() ?? '');
    _instagramController = TextEditingController(
      text: club?.instagramUrl ?? '',
    );
    _facebookController = TextEditingController(text: club?.facebookUrl ?? '');
    _homeAddressController = TextEditingController(text: club?.homeAddress ?? '');
    _latitudeController = TextEditingController(
      text: club?.latitude != null ? club!.latitude!.toStringAsFixed(6) : '',
    );
    _longitudeController = TextEditingController(
      text: club?.longitude != null ? club!.longitude!.toStringAsFixed(6) : '',
    );
    _addressController = TextEditingController();
    _active = club?.active ?? true;
    _logoUrl = club?.logoUrl;
    _originalLogoUrl = club?.logoUrl;
    if (club?.latitude != null && club?.longitude != null) {
      _selectedLocation = LatLng(club!.latitude!, club.longitude!);
    }

    _initialSnapshot = _ClubFormSnapshot(
      name: _nameController.text,
      slug: _slugController.text,
      shortName: _shortNameController.text,
      primaryColor: _primaryColorController.text,
      secondaryColor: _secondaryColorController.text,
      instagram: _instagramController.text,
      facebook: _facebookController.text,
      homeAddress: _homeAddressController.text,
      latitude: _latitudeController.text,
      longitude: _longitudeController.text,
      active: _active,
      location: _selectedLocation,
      logoUrl: _logoUrl,
      hasLogoFile: false,
      removeLogo: false,
    );

    _nameController.addListener(_handleNameChanged);
    _shortNameController.addListener(_handleShortNameChanged);
    _primaryColorController.addListener(_handleFieldChanged);
    _secondaryColorController.addListener(_handleFieldChanged);
    _instagramController.addListener(_handleFieldChanged);
    _facebookController.addListener(_handleFieldChanged);
    _homeAddressController.addListener(_handleFieldChanged);
    _latitudeController.addListener(_handleFieldChanged);
    _longitudeController.addListener(_handleFieldChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_handleNameChanged);
    _shortNameController.removeListener(_handleShortNameChanged);
    _nameController.dispose();
    _slugController.dispose();
    _shortNameController.dispose();
    _primaryColorController.dispose();
    _secondaryColorController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _homeAddressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _handleNameChanged() {
    if (!_shortNameManuallyEdited && widget.club == null) {
      final nameText = _nameController.text;
      if (_shortNameController.text != nameText) {
        _updatingShortName = true;
        _shortNameController.value = _shortNameController.value.copyWith(
          text: nameText,
          selection: TextSelection.collapsed(offset: nameText.length),
        );
        _updatingShortName = false;
      }
    }
    _handleFieldChanged();
  }

  void _handleShortNameChanged() {
    if (_updatingShortName) {
      _handleFieldChanged();
      return;
    }
    _shortNameManuallyEdited = true;
    _handleFieldChanged();
  }

  void _handleFieldChanged() {
    if (!_slugManuallyEdited) {
      final slug = slugify(_nameController.text);
      if (_slugController.text != slug) {
        _updatingSlug = true;
        _slugController.value = _slugController.value.copyWith(
          text: slug,
          selection: TextSelection.collapsed(offset: slug.length),
        );
        _updatingSlug = false;
      }
    }
    _checkDirtyState();
    setState(() {});
  }

  void _checkDirtyState() {
    final current = _ClubFormSnapshot(
      name: _nameController.text,
      slug: _slugController.text,
      shortName: _shortNameController.text,
      primaryColor: _primaryColorController.text,
      secondaryColor: _secondaryColorController.text,
      instagram: _instagramController.text,
      facebook: _facebookController.text,
      homeAddress: _homeAddressController.text,
      latitude: _latitudeController.text,
      longitude: _longitudeController.text,
      active: _active,
      location: _selectedLocation,
      logoUrl: _logoUrl,
      hasLogoFile: _logoBytes != null,
      removeLogo: _removeLogo,
    );
    _hasChanges = current != _initialSnapshot;
  }

  Future<void> _save({required bool addAnother}) async {
    if (_isSaving || widget.readOnly) {
      return;
    }
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final api = ref.read(apiClientProvider);
    final payload = {
      'name': _nameController.text.trim(),
      'slug': _slugController.text.trim().isEmpty
          ? null
          : _slugController.text.trim(),
      'shortName': _shortNameController.text.trim().isEmpty
          ? null
          : _shortNameController.text.trim(),
      'primaryColor': _primaryColorController.text.trim().isEmpty
          ? null
          : _primaryColorController.text.trim(),
      'secondaryColor': _secondaryColorController.text.trim().isEmpty
          ? null
          : _secondaryColorController.text.trim(),
      'instagram': _instagramController.text.trim().isEmpty
          ? null
          : _instagramController.text.trim(),
      'facebook': _facebookController.text.trim().isEmpty
          ? null
          : _facebookController.text.trim(),
      'homeAddress': _homeAddressController.text.trim().isEmpty
          ? null
          : _homeAddressController.text.trim(),
      'active': _active,
      'latitude': _latitudeController.text.trim().isEmpty
          ? null
          : double.tryParse(_latitudeController.text.trim()),
      'longitude': _longitudeController.text.trim().isEmpty
          ? null
          : double.tryParse(_longitudeController.text.trim()),
    };

    try {
      if (widget.club == null) {
        final response =
            await api.post<Map<String, dynamic>>('/clubs', data: payload);
        if (_logoBytes != null) {
          final data = response.data;
          final newClubId = data?['id'] as int?;
          if (newClubId == null) {
            throw Exception('La respuesta no incluyó el identificador del club.');
          }
          await _uploadLogo(api, newClubId);
        }
      } else {
        final clubId = widget.club!.id;
        await api.patch('/clubs/$clubId', data: payload);
        if (_logoBytes != null) {
          await _uploadLogo(api, clubId);
        } else if (_removeLogo) {
          await _deleteLogo(api, clubId);
        }
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(addAnother
          ? _ClubFormResult.savedAndAddAnother
          : _ClubFormResult.saved);
    } on DioException catch (error) {
      final message = error.response?.data is Map<String, dynamic>
          ? (error.response!.data['message'] as String?)
          : error.message;
      setState(() {
        _isSaving = false;
        _errorMessage = message ?? 'Ocurrió un error al guardar el club.';
      });
      if (mounted && message != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (error) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'No se pudo guardar el club: $error';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo guardar el club: $error')));
      }
    }
  }

  Future<void> _searchAddress() async {
    final query = _addressController.text.trim();
    if (query.isEmpty) {
      return;
    }
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://nominatim.openstreetmap.org',
        headers: {
          'User-Agent': 'ligas-app/1.0',
        },
      ),
    );

    try {
      final response = await dio.get<List<dynamic>>('/search', queryParameters: {
        'q': query,
        'format': 'jsonv2',
        'limit': 5,
      });
      final results = response.data ?? [];
      if (results.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontraron resultados.')));
        return;
      }
      if (!mounted) {
        return;
      }
      final selection = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        showDragHandle: true,
        builder: (context) {
          return ListView.separated(
            itemCount: results.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final result = results[index] as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.place_outlined),
                title: Text(result['display_name'] as String? ??
                    'Ubicación sin nombre'),
                onTap: () => Navigator.of(context).pop(result),
              );
            },
          );
        },
      );
      if (selection != null) {
        final lat = double.tryParse(selection['lat'] as String? ?? '');
        final lon = double.tryParse(selection['lon'] as String? ?? '');
        if (lat != null && lon != null) {
          setState(() {
            _selectedLocation = LatLng(lat, lon);
            _latitudeController.text = lat.toStringAsFixed(6);
            _longitudeController.text = lon.toStringAsFixed(6);
          });
          _checkDirtyState();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Ubicación actualizada a ${selection['display_name']}')),
          );
        }
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo buscar la dirección: $error')));
    }
  }

  void _updateLocation(LatLng value) {
    setState(() {
      _selectedLocation = value;
      _latitudeController.text = value.latitude.toStringAsFixed(6);
      _longitudeController.text = value.longitude.toStringAsFixed(6);
    });
    _checkDirtyState();
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo leer el archivo seleccionado.')),
      );
      return;
    }

    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      codec.dispose();
      final isSquare = image.width == image.height;
      final isInRange =
          image.width >= _clubLogoMinSize && image.width <= _clubLogoMaxSize;
      if (!isSquare || !isInRange) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'El escudo debe ser cuadrado y medir entre 200x200 y 500x500 píxeles.',
            ),
          ),
        );
        return;
      }
      image.dispose();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo procesar la imagen seleccionada.')),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _logoBytes = bytes;
      final name = file.name;
      _logoFileName = name.toLowerCase().endsWith('.png') ? name : '$name.png';
      _logoUrl = null;
      _removeLogo = false;
    });
    _checkDirtyState();
  }

  void _markLogoForRemoval() {
    setState(() {
      _logoBytes = null;
      _logoFileName = null;
      _logoUrl = null;
      _removeLogo = true;
    });
    _checkDirtyState();
  }

  void _restoreOriginalLogo() {
    setState(() {
      _logoBytes = null;
      _logoFileName = null;
      _logoUrl = _originalLogoUrl;
      _removeLogo = false;
    });
    _checkDirtyState();
  }

  Widget _buildLogoSection(bool readOnly) {
    final theme = Theme.of(context);
    final hasExistingLogo = (_logoUrl?.isNotEmpty ?? false) && !_removeLogo;
    final hasOriginalLogo = _originalLogoUrl?.isNotEmpty ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Escudo del club',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 20,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildLogoPreview(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!readOnly)
                  FilledButton.tonal(
                    onPressed: _isSaving ? null : _pickLogo,
                    child: const Text('Seleccionar archivo PNG'),
                  ),
                if (!readOnly && _logoBytes != null)
                  TextButton(
                    onPressed: _isSaving ? null : _restoreOriginalLogo,
                    child: Text(hasOriginalLogo ? 'Descartar selección' : 'Borrar selección'),
                  )
                else if (!readOnly && hasExistingLogo)
                  TextButton(
                    onPressed: _isSaving ? null : _markLogoForRemoval,
                    child: const Text('Quitar escudo'),
                  )
                else if (!readOnly && _removeLogo && hasOriginalLogo)
                  TextButton(
                    onPressed: _isSaving ? null : _restoreOriginalLogo,
                    child: const Text('Restaurar escudo original'),
                  ),
                SizedBox(
                  width: 260,
                  child: Text(
                    'Formato PNG cuadrado entre ${_clubLogoMinSize}×${_clubLogoMinSize} y ${_clubLogoMaxSize}×${_clubLogoMaxSize} píxeles.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLogoPreview() {
    Widget child;
    if (_logoBytes != null) {
      child = Image.memory(_logoBytes!, fit: BoxFit.cover);
    } else if (_logoUrl != null && _logoUrl!.isNotEmpty && !_removeLogo) {
      child = AuthenticatedImage(
        imageUrl: _logoUrl!,
        fit: BoxFit.cover,
        headers: _buildImageHeaders(ref),
        placeholder: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        error: Icon(
          Icons.shield_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      );
    } else {
      child = Icon(Icons.shield_outlined,
          size: 64, color: Theme.of(context).colorScheme.outlineVariant);
    }

    return Container(
      width: _clubLogoSize,
      height: _clubLogoSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: child,
    );
  }

  Future<void> _uploadLogo(ApiClient api, int clubId) async {
    if (_logoBytes == null) {
      return;
    }
    final filename = _logoFileName?.isNotEmpty == true ? _logoFileName! : 'club-logo.png';
    final normalizedName = filename.toLowerCase().endsWith('.png') ? filename : '$filename.png';
    final formData = FormData();
    formData.files.add(
      MapEntry(
        'logo',
        MultipartFile.fromBytes(
          _logoBytes!,
          filename: normalizedName,
        ),
      ),
    );
    await api.put('/clubs/$clubId/logo', data: formData);
  }

  Future<void> _deleteLogo(ApiClient api, int clubId) async {
    await api.delete('/clubs/$clubId/logo');
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges || widget.readOnly) {
      return true;
    }
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Descartar cambios'),
          content: const Text(
              'Tienes cambios sin guardar. ¿Deseas salir de todas formas?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Seguir editando')),
            FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Descartar')),
          ],
        );
      },
    );
    return shouldLeave ?? false;
  }

  bool get _canSubmit => !_isSaving && _nameController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final readOnly = widget.readOnly;
    final content = Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.club == null
                ? 'Agregar club'
                : (readOnly ? 'Detalle del club' : 'Editar club'),
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            readOnly
                ? 'Revisa la información institucional del club.'
                : 'Completa los datos principales. Podrás actualizar los planteles y escudos más adelante.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            enabled: !readOnly,
            decoration: const InputDecoration(
              labelText: 'Nombre del club',
              hintText: 'Ej. Club Atlético Central',
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
            controller: _shortNameController,
            enabled: !readOnly,
            decoration: const InputDecoration(
              labelText: 'Nombre corto',
              hintText: 'Opcional',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _slugController,
            enabled: !readOnly,
            decoration: const InputDecoration(
              labelText: 'Slug',
              hintText: 'ej. club-atletico-central',
              helperText: 'Se genera automáticamente, pero puedes personalizarlo.',
            ),
            onChanged: (_) {
              if (_updatingSlug) {
                return;
              }
              _slugManuallyEdited = true;
              _checkDirtyState();
              setState(() {});
            },
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) {
                return null;
              }
              final regex = RegExp(r'^[a-z0-9-]+$');
              if (!regex.hasMatch(text)) {
                return 'Solo se permiten minúsculas, números y guiones.';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            value: _active,
            onChanged: readOnly
                ? null
                : (value) {
                    setState(() {
                      _active = value;
                    });
                    _checkDirtyState();
                  },
            title: const Text('Club activo'),
            subtitle: const Text(
                'Los clubes inactivos no aparecerán en asignaciones nuevas.'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 280,
                child: _HexColorField(
                  controller: _primaryColorController,
                  label: 'Color primario (#RRGGBB)',
                  enabled: !readOnly,
                ),
              ),
              SizedBox(
                width: 280,
                child: _HexColorField(
                  controller: _secondaryColorController,
                  label: 'Color secundario (#RRGGBB)',
                  enabled: !readOnly,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLogoSection(readOnly),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 280,
                child: TextFormField(
                  controller: _instagramController,
                  enabled: !readOnly,
                  decoration: const InputDecoration(
                    labelText: 'Instagram',
                    hintText: '@usuario o URL',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return null;
                    }
                    if (!_isValidSocialHandle(text)) {
                      return 'Ingresa una URL válida o un @usuario.';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(
                width: 280,
                child: TextFormField(
                  controller: _facebookController,
                  enabled: !readOnly,
                  decoration: const InputDecoration(
                    labelText: 'Facebook',
                    hintText: '@usuario o URL',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return null;
                    }
                    if (!_isValidSocialHandle(text)) {
                      return 'Ingresa una URL válida o un @usuario.';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _homeAddressController,
            enabled: !readOnly,
            decoration: const InputDecoration(
              labelText: 'Dirección de localía',
              hintText: 'Ej. Estadio Central · Av. Principal 123',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 20),
          Text('Geolocalización',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Busca una dirección y ajusta la ubicación tocando el mapa.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _addressController,
                  enabled: !readOnly,
                  decoration: InputDecoration(
                    labelText: 'Buscar dirección',
                    suffixIcon: IconButton(
                      onPressed: readOnly ? null : _searchAddress,
                      icon: const Icon(Icons.search),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 160,
                child: TextFormField(
                  controller: _latitudeController,
                  enabled: !readOnly,
                  decoration: const InputDecoration(labelText: 'Latitud'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true, signed: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*\.?[0-9]*'))
                  ],
                  validator: (value) {
                    final text = value?.trim();
                    if (text == null || text.isEmpty) {
                      return null;
                    }
                    final parsed = double.tryParse(text);
                    if (parsed == null || parsed < -90 || parsed > 90) {
                      return 'Latitud inválida';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(
                width: 160,
                child: TextFormField(
                  controller: _longitudeController,
                  enabled: !readOnly,
                  decoration: const InputDecoration(labelText: 'Longitud'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true, signed: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*\.?[0-9]*'))
                  ],
                  validator: (value) {
                    final text = value?.trim();
                    if (text == null || text.isEmpty) {
                      return null;
                    }
                    final parsed = double.tryParse(text);
                    if (parsed == null || parsed < -180 || parsed > 180) {
                      return 'Longitud inválida';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 220,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter:
                      _selectedLocation ?? const LatLng(-34.6037, -58.3816),
                  initialZoom: _selectedLocation != null ? 13 : 4,
                  onTap: readOnly
                      ? null
                      : (tapPosition, latLng) {
                          _updateLocation(latLng);
                        },
                  interactionOptions:
                      const InteractionOptions(enableMultiFingerGestureRace: true),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'ligas_app',
                  ),
                  if (_selectedLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on,
                              color: Colors.red, size: 36),
                        )
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style:
                  TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSaving
                    ? null
                    : () async {
                        final shouldClose = await _onWillPop();
                        if (shouldClose && mounted) {
                          Navigator.of(context).maybePop();
                        }
                      },
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 12),
              if (!readOnly && widget.allowSaveAndAdd && widget.club == null) ...[
                FilledButton.tonal(
                  onPressed: _canSubmit ? () => _save(addAnother: true) : null,
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
              if (!readOnly)
                FilledButton(
                  onPressed: _canSubmit ? () => _save(addAnother: false) : null,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      :
                          Text(widget.club == null ? 'Guardar' : 'Guardar cambios'),
                )
            ],
          )
        ],
      ),
    );

    if (readOnly) {
      return content;
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(right: 12),
        child: content,
      ),
    );
  }

  bool _isValidSocialHandle(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('@')) {
      return trimmed.length > 1;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      return false;
    }
    return uri.hasAbsolutePath ||
        (uri.host.isNotEmpty && uri.scheme.startsWith('http'));
  }
}

class _HexColorField extends StatelessWidget {
  const _HexColorField({
    required this.controller,
    required this.label,
    required this.enabled,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            labelText: label,
            hintText: '#0057B8',
          ),
          textCapitalization: TextCapitalization.characters,
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) {
              return null;
            }
            final regex = RegExp(r'^#([0-9a-fA-F]{6})$');
            if (!regex.hasMatch(text)) {
              return 'Formato inválido. Usa #RRGGBB.';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            Color preview;
            try {
              preview = Color(int.parse(value.text.replaceFirst('#', '0xff')));
            } catch (_) {
              preview = Theme.of(context).colorScheme.surfaceVariant;
            }
            return Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: preview,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Vista previa',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            );
          },
        )
      ],
    );
  }
}

class _ClubFormSnapshot {
  const _ClubFormSnapshot({
    required this.name,
    required this.slug,
    required this.shortName,
    required this.primaryColor,
    required this.secondaryColor,
    required this.instagram,
    required this.facebook,
    required this.homeAddress,
    required this.latitude,
    required this.longitude,
    required this.active,
    required this.location,
    this.logoUrl,
    required this.hasLogoFile,
    required this.removeLogo,
  });

  final String name;
  final String slug;
  final String shortName;
  final String primaryColor;
  final String secondaryColor;
  final String instagram;
  final String facebook;
  final String homeAddress;
  final String latitude;
  final String longitude;
  final bool active;
  final LatLng? location;
  final String? logoUrl;
  final bool hasLogoFile;
  final bool removeLogo;

  @override
  bool operator ==(Object other) {
    return other is _ClubFormSnapshot &&
        other.name == name &&
        other.slug == slug &&
        other.shortName == shortName &&
        other.primaryColor == primaryColor &&
        other.secondaryColor == secondaryColor &&
        other.instagram == instagram &&
        other.facebook == facebook &&
        other.homeAddress == homeAddress &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.active == active &&
        other.logoUrl == logoUrl &&
        other.hasLogoFile == hasLogoFile &&
        other.removeLogo == removeLogo &&
        ((other.location == null && location == null) ||
            (other.location?.latitude == location?.latitude &&
                other.location?.longitude == location?.longitude));
  }

  @override
  int get hashCode => Object.hash(
      name,
      slug,
      shortName,
      primaryColor,
      secondaryColor,
      instagram,
      facebook,
      homeAddress,
      latitude,
      longitude,
      active,
      location?.latitude,
      location?.longitude,
      logoUrl,
      hasLogoFile,
      removeLogo);
}

class PaginatedClubs {
  PaginatedClubs({
    required this.clubs,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory PaginatedClubs.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as List<dynamic>? ?? [])
        .map((item) => Club.fromJson(item as Map<String, dynamic>))
        .toList();
    return PaginatedClubs(
      clubs: data,
      total: json['total'] as int? ?? data.length,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? data.length,
    );
  }

  final List<Club> clubs;
  final int total;
  final int page;
  final int pageSize;
}

class Club {
  Club({
    required this.id,
    required this.name,
    required this.active,
    this.slug,
    this.shortName,
    this.primaryHex,
    this.secondaryHex,
    this.instagramUrl,
    this.facebookUrl,
    this.homeAddress,
    this.latitude,
    this.longitude,
    this.logoUrl,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    final primary = json['primaryColor'] as String?;
    final secondary = json['secondaryColor'] as String?;
    return Club(
      id: json['id'] as int,
      name: json['name'] as String,
      active: json['active'] as bool? ?? true,
      slug: json['slug'] as String?,
      shortName: json['shortName'] as String?,
      primaryHex: primary,
      secondaryHex: secondary,
      instagramUrl: json['instagramUrl'] as String?,
      facebookUrl: json['facebookUrl'] as String?,
      homeAddress: json['homeAddress'] as String?,
      latitude: _parseCoordinate(json['latitude']),
      longitude: _parseCoordinate(json['longitude']),
      logoUrl: json['logoUrl'] as String?,
    );
  }

  final int id;
  final String name;
  final bool active;
  final String? slug;
  final String? shortName;
  final String? primaryHex;
  final String? secondaryHex;
  final String? instagramUrl;
  final String? facebookUrl;
  final String? homeAddress;
  final double? latitude;
  final double? longitude;
  final String? logoUrl;

  Color? get primaryColor => _parseHexColor(primaryHex);
  Color? get secondaryColor => _parseHexColor(secondaryHex);

  String get initials {
    if (name.isEmpty) {
      return 'C';
    }
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words.first.substring(0, math.min(2, words.first.length)).toUpperCase();
    }
    final initials = (words.take(2).map((word) => word[0]).join()).toUpperCase();
    return initials;
  }
}

Color? _parseHexColor(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  try {
    return Color(int.parse(value.replaceFirst('#', '0xff')));
  } catch (_) {
    return null;
  }
}

double? _parseCoordinate(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
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

String slugify(String value) {
  final lower = value.toLowerCase().trim();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    if (RegExp(r'[a-z0-9\s-]').hasMatch(char)) {
      buffer.write(char);
    }
  }
  final sanitized = buffer
      .toString()
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return sanitized;
}
