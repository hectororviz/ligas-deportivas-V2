import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../services/api_client.dart';
import '../../shared/widgets/app_data_table_style.dart';
import '../../shared/widgets/page_scaffold.dart';
import '../../shared/widgets/table_filters_bar.dart';
import 'tournaments_page.dart';

class TournamentPlayersPage extends ConsumerStatefulWidget {
  const TournamentPlayersPage({
    super.key,
    this.initialTournamentId,
    this.initialTournament,
  });

  final int? initialTournamentId;
  final TournamentSummary? initialTournament;

  @override
  ConsumerState<TournamentPlayersPage> createState() => _TournamentPlayersPageState();
}

class _TournamentPlayersPageState extends ConsumerState<TournamentPlayersPage> {
  final _dniController = TextEditingController();
  final _dateFormatter = DateFormat('dd/MM/yyyy');

  List<LeagueOption> _leagues = [];
  List<TournamentOption> _tournaments = [];
  List<CategoryOption> _categories = [];
  List<ClubOption> _clubs = [];

  int? _selectedLeagueId;
  int? _selectedTournamentId;
  int? _selectedCategoryId;

  bool _loadingLeagues = false;
  bool _loadingTournaments = false;
  bool _loadingCategories = false;
  bool _loadingClubs = false;
  bool _searchingPlayers = false;

  bool _onlyFree = false;
  Timer? _dniSearchDebounce;

  String? _loadError;
  String? _categoriesError;
  String? _clubsError;
  String? _playersError;

  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  _PlayerAssignmentDataSource? _dataSource;

  int? get _initialLeagueId => widget.initialTournament?.leagueId;

  @override
  void initState() {
    super.initState();
    unawaited(_loadLeagues());
  }

  @override
  void dispose() {
    _dniSearchDebounce?.cancel();
    _dniController.dispose();
    super.dispose();
  }

  Future<void> _loadLeagues() async {
    setState(() {
      _loadingLeagues = true;
      _loadError = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get<List<dynamic>>(
        '/leagues',
        queryParameters: const {'status': 'active'},
      );
      final data = response.data ?? [];
      final leagues =
          data.map((json) => LeagueOption.fromJson(json as Map<String, dynamic>)).toList();
      setState(() {
        _leagues = leagues;
      });

      final initialLeagueId = _initialLeagueId;
      if (initialLeagueId != null) {
        await _selectLeague(initialLeagueId, preselectTournamentId: widget.initialTournamentId);
      }
    } catch (error) {
      setState(() {
        _loadError = _formatError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingLeagues = false;
        });
      }
    }
  }

  Future<void> _selectLeague(
    int leagueId, {
    int? preselectTournamentId,
  }) async {
    setState(() {
      _selectedLeagueId = leagueId;
      _selectedTournamentId = null;
      _selectedCategoryId = null;
      _tournaments = [];
      _categories = [];
      _clubs = [];
      _dataSource = null;
      _categoriesError = null;
      _clubsError = null;
      _playersError = null;
    });

    await _loadTournaments(leagueId);

    if (preselectTournamentId != null &&
        _tournaments.any((tournament) => tournament.id == preselectTournamentId)) {
      await _selectTournament(preselectTournamentId);
    }
  }

  Future<void> _loadTournaments(int leagueId) async {
    setState(() {
      _loadingTournaments = true;
      _loadError = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get<List<dynamic>>('/leagues/$leagueId/tournaments');
      final data = response.data ?? [];
      setState(() {
        _tournaments = data
            .map((json) => TournamentOption.fromJson(json as Map<String, dynamic>))
            .toList();
      });
    } catch (error) {
      setState(() {
        _loadError = _formatError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingTournaments = false;
        });
      }
    }
  }

  Future<void> _selectTournament(int tournamentId) async {
    setState(() {
      _selectedTournamentId = tournamentId;
      _selectedCategoryId = null;
      _categories = [];
      _clubs = [];
      _dataSource = null;
      _categoriesError = null;
      _clubsError = null;
      _playersError = null;
    });

    await Future.wait([
      _loadCategories(tournamentId),
      _loadClubs(tournamentId),
    ]);
  }

  Future<void> _loadCategories(int tournamentId) async {
    setState(() {
      _loadingCategories = true;
      _categoriesError = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get<List<dynamic>>('/tournaments/$tournamentId/categories');
      final data = response.data ?? [];
      setState(() {
        _categories = data
            .map((json) => CategoryOption.fromJson(json as Map<String, dynamic>))
            .toList();
      });
    } catch (error) {
      setState(() {
        _categoriesError = _formatError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingCategories = false;
        });
      }
    }
  }

  Future<void> _loadClubs(int tournamentId) async {
    setState(() {
      _loadingClubs = true;
      _clubsError = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final response =
          await api.get<List<dynamic>>('/tournaments/$tournamentId/participating-clubs');
      final data = response.data ?? [];
      setState(() {
        _clubs = data.map((json) => ClubOption.fromJson(json as Map<String, dynamic>)).toList();
      });
    } catch (error) {
      setState(() {
        _clubsError = _formatError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingClubs = false;
        });
      }
    }
  }

  bool get _hasAtLeastOnePlayerFilter =>
      _selectedTournamentId != null ||
      _selectedCategoryId != null ||
      _dniController.text.trim().isNotEmpty ||
      _onlyFree;

  void _scheduleDniSearch() {
    _dniSearchDebounce?.cancel();
    _dniSearchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) {
        return;
      }
      if (!_hasAtLeastOnePlayerFilter) {
        setState(() {
          _playersError = null;
          _dataSource = null;
        });
        return;
      }
      unawaited(_searchPlayers());
    });
  }

  Future<void> _searchPlayers() async {
    final tournamentId = _selectedTournamentId;
    final categoryId = _selectedCategoryId;
    final dni = _dniController.text.trim();

    if (!_hasAtLeastOnePlayerFilter) {
      setState(() {
        _playersError = 'Ingresa al menos un filtro para buscar jugadores.';
      });
      return;
    }

    setState(() {
      _searchingPlayers = true;
      _playersError = null;
      _dataSource = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get<List<dynamic>>(
        '/players/search',
        queryParameters: {
          if (dni.isNotEmpty) 'dni': dni,
          if (_onlyFree) 'onlyFree': true,
          if (categoryId != null) 'categoryId': categoryId,
          if (tournamentId != null) 'tournamentId': tournamentId,
        },
      );
      final data = response.data ?? [];
      final players =
          data.map((json) => PlayerSearchResult.fromJson(json as Map<String, dynamic>)).toList();
      final rows = players.map((player) => PlayerAssignmentRow.fromPlayer(player)).toList();
      setState(() {
        _dataSource = _PlayerAssignmentDataSource(
          context: context,
          rows: rows,
          clubs: _clubs,
          dateFormatter: _dateFormatter,
          onClubSelected: _handleClubSelection,
          onRetry: _retryAssignment,
        );
      });
    } catch (error) {
      setState(() {
        _playersError = _formatError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _searchingPlayers = false;
        });
      }
    }
  }

  Future<void> _handleClubSelection(PlayerAssignmentRow row, int? clubId) async {
    if (row.selectedClubId == clubId) {
      return;
    }

    final previousClubId = row.assignedClubId;
    row.selectedClubId = clubId;
    _dataSource?.notifyListeners();

    if (previousClubId != null && previousClubId != clubId) {
      final confirmed = await _confirmReplace(row, clubId);
      if (!confirmed) {
        row.selectedClubId = previousClubId;
        _dataSource?.notifyListeners();
        return;
      }
    }

    await _saveAssignment(row, clubId);
  }

  Future<void> _retryAssignment(PlayerAssignmentRow row) async {
    if (!row.hasPendingClubChange) {
      return;
    }
    await _saveAssignment(row, row.pendingClubId);
  }

  Future<void> _saveAssignment(PlayerAssignmentRow row, int? clubId) async {
    final tournamentId = _selectedTournamentId;
    final categoryId = _selectedCategoryId;
    if (tournamentId == null || categoryId == null) {
      setState(() {
        _playersError =
            'Para asignar un club, selecciona también torneo y categoría.';
      });
      row.selectedClubId = row.assignedClubId;
      _dataSource?.notifyListeners();
      return;
    }

    row.status = PlayerAssignmentStatus.saving;
    row.errorMessage = null;
    row.pendingClubId = clubId;
    row.hasPendingClubChange = true;
    _dataSource?.notifyListeners();

    try {
      final api = ref.read(apiClientProvider);
      await api.put(
        '/tournaments/$tournamentId/player-club',
        data: {
          'playerId': row.playerId,
          'clubId': clubId,
          'categoryId': categoryId,
        },
      );
      row.assignedClubId = clubId;
      row.selectedClubId = clubId;
      row.status = PlayerAssignmentStatus.saved;
      row.pendingClubId = null;
      row.hasPendingClubChange = false;
    } catch (error) {
      row.status = PlayerAssignmentStatus.error;
      row.errorMessage = _formatError(error);
    } finally {
      _dataSource?.notifyListeners();
    }
  }

  Future<bool> _confirmReplace(PlayerAssignmentRow row, int? clubId) async {
    final currentClub = _clubs.firstWhere(
      (club) => club.id == row.assignedClubId,
      orElse: () => ClubOption(id: 0, name: 'Sin club', shortName: null),
    );
    final nextClub = clubId == null
        ? ClubOption(id: 0, name: 'Sin club', shortName: null)
        : _clubs.firstWhere(
            (club) => club.id == clubId,
            orElse: () => ClubOption(id: clubId, name: 'Nuevo club', shortName: null),
          );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar cambio'),
          content: Text(
            clubId == null
                ? 'Este jugador estaba asignado a ${currentClub.displayName}. '
                    '¿Quitar la asignación del club?'
                : 'Este jugador estaba asignado a ${currentClub.displayName}. '
                    '¿Reemplazar por ${nextClub.displayName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(clubId == null ? 'Quitar' : 'Reemplazar'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  String _formatError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
      return error.message ?? 'No se pudo completar la solicitud.';
    }
    return 'No se pudo completar la solicitud.';
  }

  Widget _buildSelectors() {
    return TableFiltersBar(
      children: [
        TableFilterField(
          label: 'Liga',
          width: 260,
          child: DropdownButtonFormField<int>(
            value: _selectedLeagueId,
            items: _leagues
                .map(
                  (league) => DropdownMenuItem<int>(
                    value: league.id,
                    child: Text(league.name),
                  ),
                )
                .toList(),
            onChanged: _loadingLeagues
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }
                    unawaited(_selectLeague(value));
                  },
            decoration: const InputDecoration(
              hintText: 'Seleccionar liga',
            ),
          ),
        ),
        TableFilterField(
          label: 'Torneo',
          width: 280,
          child: DropdownButtonFormField<int>(
            value: _selectedTournamentId,
            items: _tournaments
                .map(
                  (tournament) => DropdownMenuItem<int>(
                    value: tournament.id,
                    child: Text(tournament.label),
                  ),
                )
                .toList(),
            onChanged: _loadingTournaments || _selectedLeagueId == null
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }
                    unawaited(_selectTournament(value));
                  },
            decoration: const InputDecoration(
              hintText: 'Seleccionar torneo',
            ),
          ),
        ),
        TableFilterField(
          label: 'Categoría',
          width: 260,
          child: DropdownButtonFormField<int>(
            value: _selectedCategoryId,
            items: _categories
                .map(
                  (category) => DropdownMenuItem<int>(
                    value: category.id,
                    child: Text(category.label),
                  ),
                )
                .toList(),
            onChanged: _loadingCategories || _selectedTournamentId == null
                ? null
                : (value) {
                    setState(() {
                      _selectedCategoryId = value;
                      _playersError = null;
                      _dataSource = null;
                    });
                    if (_hasAtLeastOnePlayerFilter) {
                      unawaited(_searchPlayers());
                    }
                  },
            decoration: const InputDecoration(
              hintText: 'Seleccionar categoría',
            ),
          ),
        ),
        TableFilterField(
          label: 'DNI',
          width: 220,
          child: TextField(
            controller: _dniController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: 'Ingresar DNI (opcional)',
            ),
            onChanged: (_) => _scheduleDniSearch(),
            onSubmitted: (_) => _searchPlayers(),
          ),
        ),
        TableFilterField(
          label: ' ',
          width: 160,
          child: SizedBox(
            height: 48,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: _onlyFree,
                  onChanged: (value) {
                    setState(() {
                      _onlyFree = value ?? false;
                      _playersError = null;
                      _dataSource = null;
                    });
                    if (_hasAtLeastOnePlayerFilter) {
                      unawaited(_searchPlayers());
                    }
                  },
                ),
                const Text('Libres'),
              ],
            ),
          ),
        ),
        TableFilterField(
          label: ' ',
          width: 160,
          child: SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _searchingPlayers ? null : _searchPlayers,
              icon: _searchingPlayers
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: const Text('Buscar'),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tableColors = AppDataTableColors.standard(theme);
    final dataSource = _dataSource;

    return PageScaffold(
      backgroundColor: Colors.transparent,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Jugadores por torneo',
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Asocia jugadores a clubes dentro del torneo seleccionado.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_loadError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _loadError!,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: theme.colorScheme.error),
                        ),
                      ),
                    _buildSelectors(),
                    if (_categoriesError != null || _clubsError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          [
                            if (_categoriesError != null) _categoriesError,
                            if (_clubsError != null) _clubsError,
                          ].join(' · '),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.error),
                        ),
                      ),
                    if (_playersError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _playersError!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.error),
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (dataSource == null)
                      SizedBox(
                        height: 200,
                        child: Center(
                          child: Text(
                            _searchingPlayers
                                ? 'Buscando jugadores...'
                                : 'Ingresa uno o más filtros para mostrar jugadores.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      )
                    else if (dataSource.rows.isEmpty)
                      SizedBox(
                        height: 200,
                        child: Center(
                          child: Text(
                            'No se encontraron jugadores para los filtros seleccionados.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      )
                    else
                      DataTableTheme(
                        data: DataTableTheme.of(context).copyWith(
                          headingRowColor: buildHeaderColor(tableColors.headerBackground),
                          headingTextStyle: theme.textTheme.titleSmall?.copyWith(
                            color: tableColors.headerText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: PaginatedDataTable(
                          rowsPerPage: _rowsPerPage,
                          onRowsPerPageChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _rowsPerPage = value;
                            });
                          },
                          columns: const [
                            DataColumn(label: Text('Apellido')),
                            DataColumn(label: Text('Nombre')),
                            DataColumn(label: Text('DNI')),
                            DataColumn(label: Text('Fecha de Nacimiento')),
                            DataColumn(label: Text('Club')),
                            DataColumn(label: Text('Estado')),
                          ],
                          source: dataSource,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PlayerAssignmentDataSource extends DataTableSource {
  _PlayerAssignmentDataSource({
    required this.context,
    required this.rows,
    required this.clubs,
    required this.dateFormatter,
    required this.onClubSelected,
    required this.onRetry,
  });

  final BuildContext context;
  final List<PlayerAssignmentRow> rows;
  final List<ClubOption> clubs;
  final DateFormat dateFormatter;
  final Future<void> Function(PlayerAssignmentRow row, int? clubId) onClubSelected;
  final Future<void> Function(PlayerAssignmentRow row) onRetry;

  @override
  DataRow? getRow(int index) {
    if (index < 0 || index >= rows.length) {
      return null;
    }
    final row = rows[index];
    final theme = Theme.of(context);

    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(row.lastName)),
        DataCell(Text(row.firstName)),
        DataCell(Text(row.dni)),
        DataCell(Text(dateFormatter.format(row.birthDate))),
        DataCell(
          DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              isExpanded: true,
              value: row.selectedClubId,
              hint: const Text('Sin club'),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Sin club'),
                ),
                ...clubs.map(
                  (club) => DropdownMenuItem<int?>(
                    value: club.id,
                    child: Text(club.displayName),
                  ),
                ),
              ],
              onChanged: row.status == PlayerAssignmentStatus.saving
                  ? null
                  : (value) => onClubSelected(row, value),
            ),
          ),
        ),
        DataCell(_buildStatusCell(theme, row)),
      ],
    );
  }

  Widget _buildStatusCell(ThemeData theme, PlayerAssignmentRow row) {
    switch (row.status) {
      case PlayerAssignmentStatus.saving:
        return Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            const Text('Guardando...'),
          ],
        );
      case PlayerAssignmentStatus.saved:
        return Text(
          'Guardado ✓',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.green.shade700),
        );
      case PlayerAssignmentStatus.error:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              row.errorMessage ?? 'Error',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
            TextButton(
              onPressed: row.hasPendingClubChange ? () => onRetry(row) : null,
              child: const Text('Reintentar'),
            ),
          ],
        );
      case PlayerAssignmentStatus.idle:
        return const Text('—');
    }
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => rows.length;

  @override
  int get selectedRowCount => 0;
}

class LeagueOption {
  LeagueOption({required this.id, required this.name});

  factory LeagueOption.fromJson(Map<String, dynamic> json) {
    return LeagueOption(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  final int id;
  final String name;
}

class TournamentOption {
  TournamentOption({
    required this.id,
    required this.name,
    required this.year,
  });

  factory TournamentOption.fromJson(Map<String, dynamic> json) {
    return TournamentOption(
      id: json['id'] as int,
      name: json['name'] as String,
      year: json['year'] as int,
    );
  }

  final int id;
  final String name;
  final int year;

  String get label => '$name $year';
}

class CategoryOption {
  CategoryOption({
    required this.id,
    required this.name,
    required this.birthYearMin,
    required this.birthYearMax,
    required this.gender,
  });

  factory CategoryOption.fromJson(Map<String, dynamic> json) {
    return CategoryOption(
      id: json['categoryId'] as int,
      name: json['name'] as String,
      birthYearMin: json['birthYearMin'] as int,
      birthYearMax: json['birthYearMax'] as int,
      gender: json['gender'] as String? ?? 'MIXTO',
    );
  }

  final int id;
  final String name;
  final int birthYearMin;
  final int birthYearMax;
  final String gender;

  String get label => '$name ($birthYearMin-$birthYearMax)';
}

class ClubOption {
  ClubOption({
    required this.id,
    required this.name,
    required this.shortName,
  });

  factory ClubOption.fromJson(Map<String, dynamic> json) {
    return ClubOption(
      id: json['id'] as int,
      name: json['name'] as String,
      shortName: json['shortName'] as String?,
    );
  }

  final int id;
  final String name;
  final String? shortName;

  String get displayName => (shortName?.trim().isNotEmpty ?? false) ? shortName!.trim() : name;
}

class PlayerSearchResult {
  PlayerSearchResult({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dni,
    required this.birthDate,
    required this.assignedClubId,
  });

  factory PlayerSearchResult.fromJson(Map<String, dynamic> json) {
    return PlayerSearchResult(
      id: json['id'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      dni: json['dni'] as String,
      birthDate: DateTime.parse(json['birthDate'] as String),
      assignedClubId: json['assignedClubId'] as int?,
    );
  }

  final int id;
  final String firstName;
  final String lastName;
  final String dni;
  final DateTime birthDate;
  final int? assignedClubId;
}

enum PlayerAssignmentStatus { idle, saving, saved, error }

class PlayerAssignmentRow {
  PlayerAssignmentRow({
    required this.playerId,
    required this.firstName,
    required this.lastName,
    required this.dni,
    required this.birthDate,
    required this.assignedClubId,
  }) : selectedClubId = assignedClubId;

  factory PlayerAssignmentRow.fromPlayer(PlayerSearchResult player) {
    return PlayerAssignmentRow(
      playerId: player.id,
      firstName: player.firstName,
      lastName: player.lastName,
      dni: player.dni,
      birthDate: player.birthDate,
      assignedClubId: player.assignedClubId,
    );
  }

  final int playerId;
  final String firstName;
  final String lastName;
  final String dni;
  final DateTime birthDate;

  int? assignedClubId;
  int? selectedClubId;
  int? pendingClubId;
  bool hasPendingClubChange = false;
  PlayerAssignmentStatus status = PlayerAssignmentStatus.idle;
  String? errorMessage;
}
