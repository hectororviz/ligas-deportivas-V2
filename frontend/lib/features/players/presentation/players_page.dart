import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/dni_capture.dart';
import '../../../core/utils/responsive.dart';
import '../../../services/api_client.dart';
import '../../../services/auth_controller.dart';
import '../../categories/providers/categories_catalog_provider.dart';
import '../../shared/models/club_summary.dart';
import '../../shared/providers/clubs_catalog_provider.dart';
import '../../shared/widgets/app_data_table_style.dart';
import '../../shared/widgets/page_scaffold.dart';
import '../../shared/widgets/table_filters_bar.dart';

const _modulePlayers = 'JUGADORES';
const _actionCreate = 'CREATE';
const _actionUpdate = 'UPDATE';
const int _noClubFilterValue = -1;

final playersFiltersProvider =
    StateNotifierProvider<_PlayersFiltersController, _PlayersFilters>((ref) {
  return _PlayersFiltersController();
});

final playersProvider = FutureProvider<PaginatedPlayers>((ref) async {
  final filters = ref.watch(playersFiltersProvider);
  final api = ref.read(apiClientProvider);
  try {
    final response =
        await api.get<Map<String, dynamic>>('/players', queryParameters: {
      if (filters.query.trim().isNotEmpty) 'search': filters.query.trim(),
      if (filters.status != PlayerStatusFilter.all) 'status': filters.status.name,
      if (filters.clubId != null)
        'clubId':
            filters.clubId == _noClubFilterValue ? '' : filters.clubId,
      if (filters.gender.apiValue != null) 'gender': filters.gender.apiValue,
      if (filters.birthYear != null) 'birthYear': filters.birthYear,
      if (filters.birthYearMin != null) 'birthYearMin': filters.birthYearMin,
      if (filters.birthYearMax != null) 'birthYearMax': filters.birthYearMax,
      'page': filters.page,
      'pageSize': filters.pageSize,
    });
    final data = response.data ?? {};
    return PaginatedPlayers.fromJson(data);
  } on DioException catch (error) {
    if (error.response?.statusCode == 404) {
      return PaginatedPlayers(
        players: const [],
        total: 0,
        page: filters.page,
        pageSize: filters.pageSize,
      );
    }
    rethrow;
  }
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

  Future<void> _openMassivePlayers() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const _MassivePlayersPage()),
    );
    if (!mounted || created != true) {
      return;
    }
    ref.invalidate(playersProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Jugadores guardados correctamente.')),
    );
  }


  Future<void> _scanDniAndCreatePlayer() async {
    try {
      final image = await captureDniImage();
      if (!mounted || image == null) {
        return;
      }

      final dimensions = await _decodeImageDimensions(image.bytes);
      if (kDebugMode) {
        debugPrint(
          '[DNI_SCAN][frontend] selected file name=${image.filename} mime=${image.mimeType} bytes=${image.bytes.length} dimensions=${dimensions?.$1 ?? 'unknown'}x${dimensions?.$2 ?? 'unknown'} base64Length=not_used(raw_upload)',
        );
      }

      final scanned = await _scanDniOnServer(image);
      if (!mounted) {
        return;
      }

      final confirmed = await _confirmScannedPlayer(scanned);
      if (!mounted || confirmed != true) {
        return;
      }

      await _createPlayerFromScan(scanned);
      if (!mounted) {
        return;
      }
      ref.invalidate(playersProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jugador creado.')),
      );
    } on UnsupportedError catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      final statusCode = error.response?.statusCode;
      String message;
      if (statusCode == 422) {
        final backendMessage = _extractBackendErrorMessage(error.response?.data);
        if (backendMessage == 'decoded but unexpected format') {
          message = 'se leyó el código pero el formato no coincide';
          await _showScanDebug(error.response?.data);
        } else if (backendMessage == 'No se pudo decodificar el PDF417.') {
          message = 'no se pudo leer el código';
        } else {
          message = 'se leyó el código pero el formato no coincide';
        }
      } else if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        message = 'La lectura tardó demasiado. Probá nuevamente.';
      } else {
        message = 'No pudimos procesar el DNI. Verificá la conexión e intentá otra vez.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocurrió un error al procesar el DNI.')),
      );
    }
  }



  Future<void> _showScanDebug(dynamic data) async {
    if (data is! Map<String, dynamic>) {
      return;
    }
    final payloadRaw = data['payloadRaw'];
    final stdoutRaw = data['stdoutRaw'];
    if (payloadRaw is! String && stdoutRaw is! String) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Debug'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (payloadRaw is String) ...[
                    _DebugCopyField(label: 'payloadRaw', value: payloadRaw),
                    const SizedBox(height: 12),
                  ],
                  if (stdoutRaw is String)
                    _DebugCopyField(label: 'stdoutRaw', value: stdoutRaw),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  String? _extractBackendErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String) {
        return message;
      }
      if (message is List && message.isNotEmpty) {
        final first = message.first;
        if (first is String) {
          return first;
        }
      }
    }
    return null;
  }

  Future<_ScannedDniPlayer> _scanDniOnServer(CapturedDniImage image) async {
    final api = ref.read(apiClientProvider);
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        image.bytes,
        filename: image.filename,
        contentType: MediaType.parse(image.mimeType),
      ),
    });

    if (kDebugMode) {
      debugPrint(
        '[DNI_SCAN][frontend] uploading raw file filename=${image.filename} mime=${image.mimeType} bytes=${image.bytes.length}',
      );
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4)),
            SizedBox(width: 16),
            Expanded(child: Text('Leyendo DNI...')),
          ],
        ),
      ),
    );

    try {
      final response = await api.post<Map<String, dynamic>>(
        '/players/dni/scan',
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );
      return _ScannedDniPlayer.fromJson(response.data ?? const {});
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
      }
    }
  }

  Future<(int, int)?> _decodeImageDimensions(List<int> bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
      final frame = await codec.getNextFrame();
      codec.dispose();
      return (frame.image.width, frame.image.height);
    } catch (_) {
      return null;
    }
  }

  Future<bool?> _confirmScannedPlayer(_ScannedDniPlayer player) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar alta rápida'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(label: 'Apellido', value: player.lastName),
              _InfoRow(label: 'Nombre', value: player.firstName),
              _InfoRow(label: 'Sexo', value: player.sex),
              _InfoRow(label: 'DNI', value: player.dni),
              _InfoRow(label: 'Fecha nacimiento', value: DateFormat('dd/MM/yyyy').format(player.birthDate)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirmar')),
          ],
        );
      },
    );
  }

  Future<void> _createPlayerFromScan(_ScannedDniPlayer player) async {
    final api = ref.read(apiClientProvider);
    await api.post('/players', data: {
      'firstName': player.firstName,
      'lastName': player.lastName,
      'dni': player.dni,
      'birthDate': player.birthDate.toIso8601String(),
      'gender': player.gender,
      'active': true,
    });
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
    final assignedClubId = user?.clubId;
    final hasClubScopedRole = user?.hasAnyRole(const ['DELEGATE', 'COACH']) ?? false;
    var restrictedClubIds =
        user?.allowedClubsFor(module: _modulePlayers, action: 'VIEW');
    if (restrictedClubIds == null && hasClubScopedRole && assignedClubId != null) {
      restrictedClubIds = {assignedClubId};
    }
    final restrictToAssignedClubs = restrictedClubIds != null;
    final playersAsync = ref.watch(playersProvider);
    final filters = ref.watch(playersFiltersProvider);
    final clubsAsync = ref.watch(clubsCatalogProvider);
    final categoriesAsync = ref.watch(categoriesCatalogProvider);
    final currentYear = DateTime.now().year;
    final birthYearOptions = List<int>.generate(60, (index) => currentYear - index);

    Widget buildBirthYearDropdown(List<_BirthYearFilterOption> options) {
      if (options.isEmpty) {
        return const SizedBox.shrink();
      }
      final selectedOption = options.firstWhere(
        (option) => option.matches(filters),
        orElse: () => options.first,
      );

      return DropdownButtonHideUnderline(
        child: DropdownButton<_BirthYearFilterOption>(
          value: selectedOption,
          isExpanded: true,
          items: options
              .map(
                (option) => DropdownMenuItem<_BirthYearFilterOption>(
                  value: option,
                  child: Text(option.label),
                ),
              )
              .toList(),
          onChanged: (option) {
            if (option == null) {
              return;
            }
            final notifier = ref.read(playersFiltersProvider.notifier);
            if (option.isAll) {
              notifier.clearBirthYearFilters();
            } else if (option.isYear) {
              notifier.setBirthYear(option.year);
            } else if (option.isRange) {
              notifier.setBirthYearRange(option.min!, option.max!);
            }
          },
        ),
      );
    }

    return PageScaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: canCreate
          ? _PlayersFloatingActions(
              onCreate: _openCreatePlayer,
              onMassive: _openMassivePlayers,
              onScanDni: _scanDniAndCreatePlayer,
            )
          : null,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24.0),
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
              child: ExpansionTile(
                title: const Text('Búsqueda'),
                initiallyExpanded: false,
                childrenPadding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                children: [
                  TableFiltersBar(
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
                        label: 'Club',
                        width: 240,
                        child: clubsAsync.when(
                          data: (clubs) {
                            final notifier =
                                ref.read(playersFiltersProvider.notifier);
                            if (restrictToAssignedClubs) {
                              final allowedIds =
                                  restrictedClubIds!.toList(growable: false);
                              final allowedClubs = clubs
                                  .where(
                                    (club) => allowedIds.contains(club.id),
                                  )
                                  .toList();

                              if (allowedClubs.isEmpty) {
                                if (filters.clubId != null) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    notifier.setClubId(null);
                                  });
                                }
                                return const Text('Sin clubes asignados');
                              }

                              final hasMultipleAllowed = allowedClubs.length > 1;
                              final validValues = <int?>{
                                if (hasMultipleAllowed) null,
                                ...allowedClubs.map((club) => club.id),
                              };

                              final desiredValue = validValues.contains(filters.clubId)
                                  ? filters.clubId
                                  : (hasMultipleAllowed
                                      ? null
                                      : allowedClubs.first.id);

                              if (filters.clubId != desiredValue) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  notifier.setClubId(desiredValue);
                                });
                              }

                              final items = [
                                if (hasMultipleAllowed)
                                  const DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text('Todos mis clubes'),
                                  ),
                                ...allowedClubs.map(
                                  (club) => DropdownMenuItem<int?>(
                                    value: club.id,
                                    child: Text(club.name),
                                  ),
                                ),
                              ];

                              return DropdownButtonHideUnderline(
                                child: DropdownButton<int?>(
                                  value: desiredValue,
                                  isExpanded: true,
                                  items: items,
                                  onChanged: (value) {
                                    notifier.setClubId(value);
                                  },
                                ),
                              );
                            }

                            final items = [
                              const DropdownMenuItem<int?>(
                                value: _noClubFilterValue,
                                child: Text('Sin club asignado'),
                              ),
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Todos'),
                              ),
                              ...clubs.map(
                                (club) => DropdownMenuItem<int?>(
                                  value: club.id,
                                  child: Text(club.name),
                                ),
                              ),
                            ];
                            return DropdownButtonHideUnderline(
                              child: DropdownButton<int?>(
                                value: filters.clubId,
                                isExpanded: true,
                                items: items,
                                onChanged: (value) {
                                  notifier.setClubId(value);
                                },
                              ),
                            );
                          },
                          loading: () => const Center(
                            child: SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          error: (error, _) => Center(
                            child: Tooltip(
                              message: 'No se pudieron cargar los clubes: $error',
                              child: const Icon(Icons.error_outline, color: Colors.redAccent),
                            ),
                          ),
                        ),
                      ),
                      TableFilterField(
                        label: 'Género',
                        width: 200,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<PlayerGenderFilter>(
                            value: filters.gender,
                            isExpanded: true,
                            items: PlayerGenderFilter.values
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
                                    .setGender(value);
                              }
                            },
                          ),
                        ),
                      ),
                      TableFilterField(
                        label: 'Categoría (año)',
                        width: 200,
                        child: categoriesAsync.when(
                          data: (categories) {
                            final options = [
                              const _BirthYearFilterOption.all(),
                              ...categories
                                  .where((category) =>
                                      category.birthYearMin != category.birthYearMax)
                                  .map(
                                    (category) => _BirthYearFilterOption.range(
                                      label: category.name,
                                      min: category.birthYearMin,
                                      max: category.birthYearMax,
                                    ),
                                  ),
                              ...birthYearOptions.map(
                                (year) => _BirthYearFilterOption.year(year),
                              ),
                            ];
                            return buildBirthYearDropdown(options);
                          },
                          loading: () => buildBirthYearDropdown([
                            const _BirthYearFilterOption.all(),
                            ...birthYearOptions.map(
                              (year) => _BirthYearFilterOption.year(year),
                            ),
                          ]),
                          error: (_, __) => buildBirthYearDropdown([
                            const _BirthYearFilterOption.all(),
                            ...birthYearOptions.map(
                              (year) => _BirthYearFilterOption.year(year),
                            ),
                          ]),
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
                      onPressed: filters.hasActiveFilters
                          ? () {
                              _searchController.clear();
                              ref.read(playersFiltersProvider.notifier).reset();
                            }
                          : null,
                      icon: const Icon(Icons.filter_alt_off_outlined),
                      label: const Text('Limpiar filtros'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            playersAsync.when(
              data: (paginated) {
                  if (paginated.players.isEmpty) {
                    if (filters.hasActiveFilters) {
                      return _PlayersEmptyFilterState(onClear: () {
                        ref.read(playersFiltersProvider.notifier).reset();
                        _searchController.clear();
                      });
                    }
                    return _PlayersEmptyState(
                      canCreate: canCreate,
                      onCreate: _openCreatePlayer,
                      onMassive: _openMassivePlayers,
                      onScanDni: _scanDniAndCreatePlayer,
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
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: _PlayersDataTable(
                            data: paginated,
                            canEdit: canEdit,
                            onEdit: _openEditPlayer,
                            onView: _openPlayerDetails,
                          ),
                        ),
                        const Divider(height: 1),
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
          ],
        );
      },
    );
  }
}

class _BirthYearFilterOption {
  const _BirthYearFilterOption._({
    required this.label,
    this.year,
    this.min,
    this.max,
  });

  const _BirthYearFilterOption.all() : this._(label: 'Todas');

  _BirthYearFilterOption.year(int year) : this._(label: '$year', year: year);

  _BirthYearFilterOption.range({
    required String label,
    required int min,
    required int max,
  }) : this._(label: label, min: min, max: max);

  final String label;
  final int? year;
  final int? min;
  final int? max;

  bool get isAll => year == null && min == null && max == null;

  bool get isYear => year != null;

  bool get isRange => min != null && max != null;

  bool matches(_PlayersFilters filters) {
    if (isAll) {
      return filters.birthYear == null &&
          filters.birthYearMin == null &&
          filters.birthYearMax == null;
    }
    if (isYear) {
      return filters.birthYear == year &&
          filters.birthYearMin == null &&
          filters.birthYearMax == null;
    }
    if (isRange) {
      return filters.birthYear == null &&
          filters.birthYearMin == min &&
          filters.birthYearMax == max;
    }
    return false;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _BirthYearFilterOption &&
        other.label == label &&
        other.year == year &&
        other.min == min &&
        other.max == max;
  }

  @override
  int get hashCode => Object.hash(label, year, min, max);
}

const _playersFilterUnset = Object();

class _PlayersFilters {
  const _PlayersFilters({
    this.query = '',
    this.status = PlayerStatusFilter.all,
    this.clubId,
    this.gender = PlayerGenderFilter.all,
    this.birthYear,
    this.birthYearMin,
    this.birthYearMax,
    this.page = 1,
    this.pageSize = 25,
  });

  final String query;
  final PlayerStatusFilter status;
  final int? clubId;
  final PlayerGenderFilter gender;
  final int? birthYear;
  final int? birthYearMin;
  final int? birthYearMax;
  final int page;
  final int pageSize;

  bool get hasActiveFilters =>
      query.trim().isNotEmpty ||
      status != PlayerStatusFilter.all ||
      clubId != null ||
      gender != PlayerGenderFilter.all ||
      birthYear != null ||
      birthYearMin != null ||
      birthYearMax != null;

  _PlayersFilters copyWith({
    String? query,
    PlayerStatusFilter? status,
    int? page,
    int? pageSize,
    Object? clubId = _playersFilterUnset,
    PlayerGenderFilter? gender,
    Object? birthYear = _playersFilterUnset,
    Object? birthYearMin = _playersFilterUnset,
    Object? birthYearMax = _playersFilterUnset,
  }) {
    return _PlayersFilters(
      query: query ?? this.query,
      status: status ?? this.status,
      clubId: clubId == _playersFilterUnset ? this.clubId : clubId as int?,
      gender: gender ?? this.gender,
      birthYear:
          birthYear == _playersFilterUnset ? this.birthYear : birthYear as int?,
      birthYearMin: birthYearMin == _playersFilterUnset
          ? this.birthYearMin
          : birthYearMin as int?,
      birthYearMax: birthYearMax == _playersFilterUnset
          ? this.birthYearMax
          : birthYearMax as int?,
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

  void setClubId(int? clubId) {
    state = state.copyWith(clubId: clubId, page: 1);
  }

  void setGender(PlayerGenderFilter gender) {
    state = state.copyWith(gender: gender, page: 1);
  }

  void setBirthYear(int? birthYear) {
    state = state.copyWith(
      birthYear: birthYear,
      birthYearMin: null,
      birthYearMax: null,
      page: 1,
    );
  }

  void setBirthYearRange(int min, int max) {
    state = state.copyWith(
      birthYear: null,
      birthYearMin: min,
      birthYearMax: max,
      page: 1,
    );
  }

  void clearBirthYearFilters() {
    state = state.copyWith(
      birthYear: null,
      birthYearMin: null,
      birthYearMax: null,
      page: 1,
    );
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

enum PlayerGenderFilter { all, male, female, mixed }

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

extension on PlayerGenderFilter {
  String get label {
    switch (this) {
      case PlayerGenderFilter.all:
        return 'Todos';
      case PlayerGenderFilter.male:
        return 'Masculino';
      case PlayerGenderFilter.female:
        return 'Femenino';
      case PlayerGenderFilter.mixed:
        return 'Mixto';
    }
  }

  String? get apiValue {
    switch (this) {
      case PlayerGenderFilter.all:
        return null;
      case PlayerGenderFilter.male:
        return 'MASCULINO';
      case PlayerGenderFilter.female:
        return 'FEMENINO';
      case PlayerGenderFilter.mixed:
        return 'MIXTO';
    }
  }
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

    final theme = Theme.of(context);
    final colors = AppDataTableColors.standard(theme);
    final headerStyle =
        theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: colors.headerText);
    final isMobile = Responsive.isMobile(context);

    final table = DataTable(
      columns: [
        const DataColumn(label: Text('Apellido')),
        const DataColumn(label: Text('Nombre')),
        const DataColumn(label: Text('Género')),
        const DataColumn(label: Text('Nacimiento')),
        if (!isMobile) const DataColumn(label: Text('Estado')),
        const DataColumn(label: Text('Acciones')),
      ],
      dataRowMinHeight: 44,
      dataRowMaxHeight: 60,
      headingRowHeight: 48,
      headingRowColor: buildHeaderColor(colors.headerBackground),
      headingTextStyle: headerStyle,
      rows: [
        for (var index = 0; index < players.length; index++)
          DataRow(
            color: buildStripedRowColor(index: index, colors: colors),
            cells: [
              DataCell(Text(players[index].lastName)),
              DataCell(Text(players[index].firstName)),
              DataCell(Text(players[index].genderLabel)),
              DataCell(Text(players[index].formattedBirthDateWithAge)),
              if (!isMobile)
                DataCell(
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      avatar: Icon(
                        players[index].active ? Icons.check_circle : Icons.pause_circle,
                        size: 18,
                        color: players[index].active
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      backgroundColor: players[index].active
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceVariant,
                      label: Text(
                        players[index].active ? 'Activo' : 'Inactivo',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: players[index].active
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              DataCell(
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => onView(players[index]),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Detalle'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: canEdit ? () => onEdit(players[index]) : null,
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
        return Scrollbar(
          thumbVisibility: true,
          notificationPredicate: (notification) =>
              notification.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: table,
            ),
          ),
        );
      },
    );
  }
}


class _ScannedDniPlayer {
  _ScannedDniPlayer({
    required this.lastName,
    required this.firstName,
    required this.sex,
    required this.dni,
    required this.birthDate,
  });

  factory _ScannedDniPlayer.fromJson(Map<String, dynamic> json) {
    final birthDateRaw = (json['birthDate'] as String? ?? '').trim();
    final parsedBirthDate = DateTime.tryParse(birthDateRaw);
    final player = _ScannedDniPlayer(
      lastName: (json['lastName'] as String? ?? '').trim(),
      firstName: (json['firstName'] as String? ?? '').trim(),
      sex: (json['sex'] as String? ?? '').trim().toUpperCase(),
      dni: (json['dni'] as String? ?? '').trim(),
      birthDate: parsedBirthDate ?? DateTime(1900),
    );

    if (player.lastName.isEmpty ||
        player.firstName.isEmpty ||
        player.dni.isEmpty ||
        !RegExp(r'^\d{6,9}$').hasMatch(player.dni) ||
        parsedBirthDate == null) {
      throw const FormatException('Respuesta inválida de escaneo DNI.');
    }

    return player;
  }

  final String lastName;
  final String firstName;
  final String sex;
  final String dni;
  final DateTime birthDate;

  String get gender {
    switch (sex) {
      case 'F':
        return 'FEMENINO';
      case 'M':
        return 'MASCULINO';
      default:
        return 'MIXTO';
    }
  }
}


class _DebugCopyField extends StatelessWidget {
  const _DebugCopyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.titleSmall),
            ),
            IconButton(
              tooltip: 'Copiar',
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () => Clipboard.setData(ClipboardData(text: value)),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(value),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          children: [
            TextSpan(
              text: value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
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
    final theme = Theme.of(context);
    final totalPages = math.max(1, (total / pageSize).ceil());
    final start = total == 0 ? 0 : ((page - 1) * pageSize) + 1;
    final end = total == 0 ? 0 : math.min(page * pageSize, total);
    final availableSizes = {10, 25, 50, 100, pageSize}.toList()..sort();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              total == 0
                  ? 'Mostrando 0 de 0'
                  : 'Mostrando $start-$end de $total',
              style: theme.textTheme.bodySmall,
            ),
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

class _PlayersEmptyState extends StatelessWidget {
  const _PlayersEmptyState({
    required this.canCreate,
    required this.onCreate,
    required this.onMassive,
    required this.onScanDni,
  });

  final bool canCreate;
  final VoidCallback onCreate;
  final VoidCallback onMassive;
  final VoidCallback onScanDni;

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
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar jugador'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onMassive,
                    icon: const Icon(Icons.table_chart_outlined),
                    label: const Text('Masivo'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onScanDni,
                    icon: const Icon(Icons.qr_code_scanner_outlined),
                    label: const Text('Escanear DNI'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayersFloatingActions extends StatelessWidget {
  const _PlayersFloatingActions({
    required this.onCreate,
    required this.onMassive,
    required this.onScanDni,
  });

  final VoidCallback onCreate;
  final VoidCallback onMassive;
  final VoidCallback onScanDni;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          heroTag: 'players-scan-dni',
          onPressed: onScanDni,
          icon: const Icon(Icons.qr_code_scanner_outlined),
          label: const Text('Escanear DNI'),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: 'players-massive',
          onPressed: onMassive,
          icon: const Icon(Icons.table_chart_outlined),
          label: const Text('Masivo'),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: 'players-add',
          onPressed: onCreate,
          icon: const Icon(Icons.add),
          label: const Text('Agregar jugador'),
        ),
      ],
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

class _MassivePlayersPage extends ConsumerStatefulWidget {
  const _MassivePlayersPage();

  @override
  ConsumerState<_MassivePlayersPage> createState() =>
      _MassivePlayersPageState();
}

class _MassivePlayersPageState extends ConsumerState<_MassivePlayersPage> {
  final _formKey = GlobalKey<FormState>();
  final List<_MassivePlayerRow> _rows = [];
  final ScrollController _horizontalScrollController = ScrollController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 10; i++) {
      _rows.add(_MassivePlayerRow.empty());
    }
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _addRow() {
    setState(() {
      _rows.add(_MassivePlayerRow.empty());
    });
  }

  bool _rowIsBlank(_MassivePlayerRow row) {
    return row.isBlank;
  }

  String? _requiredValidator(
    String? value,
    _MassivePlayerRow row,
    String message,
  ) {
    if (_rowIsBlank(row)) {
      return null;
    }
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  String? _birthDateValidator(String? value, _MassivePlayerRow row) {
    if (_rowIsBlank(row)) {
      return null;
    }
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Obligatorio';
    }
    final parsed = _parseBirthDate(text);
    if (parsed == null) {
      return 'Fecha inválida';
    }
    return null;
  }

  Future<void> _saveRows() async {
    if (_isSaving) {
      return;
    }
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisá los datos obligatorios.')),
      );
      return;
    }

    final playersToSave = _rows.where((row) => !row.isBlank).toList();
    if (playersToSave.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cargá al menos un jugador.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final api = ref.read(apiClientProvider);

    try {
      for (final row in playersToSave) {
        final birthDate = _parseBirthDate(row.birthDateController.text.trim());
        final payload = {
          'firstName': row.firstNameController.text.trim(),
          'lastName': row.lastNameController.text.trim(),
          'dni': row.dniController.text.trim(),
          'birthDate': birthDate != null
              ? DateFormat('yyyy-MM-dd').format(birthDate)
              : null,
          'gender': row.gender,
          'active': row.active,
          'address': {
            'street': row.streetController.text.trim(),
            'number': row.streetNumberController.text.trim(),
            'city': row.cityController.text.trim(),
          },
          'emergencyContact': {
            'name': row.emergencyNameController.text.trim(),
            'relationship': row.emergencyRelationshipController.text.trim(),
            'phone': row.emergencyPhoneController.text.trim(),
          },
        };

        await api.post('/players', data: payload);
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.response?.data is Map<String, dynamic>
                ? (error.response?.data['message'] ?? error.message)
                : error.message ?? 'No se pudo guardar.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $error')),
      );
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
    final theme = Theme.of(context);
    final colors = AppDataTableColors.standard(theme);
    final headerStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: colors.headerText,
    );

    final table = DataTable(
      columns: const [
        DataColumn(label: Text('Apellido')),
        DataColumn(label: Text('Nombre')),
        DataColumn(label: Text('Fecha de nacimiento')),
        DataColumn(label: Text('Género')),
        DataColumn(label: Text('DNI')),
        DataColumn(label: Text('Calle')),
        DataColumn(label: Text('Número')),
        DataColumn(label: Text('Localidad')),
        DataColumn(label: Text('Activo')),
        DataColumn(label: Text('Nombre emergencia')),
        DataColumn(label: Text('Vínculo')),
        DataColumn(label: Text('Teléfono')),
      ],
      dataRowMinHeight: 60,
      dataRowMaxHeight: 88,
      headingRowColor: buildHeaderColor(colors.headerBackground),
      headingTextStyle: headerStyle,
      rows: [
        for (var index = 0; index < _rows.length; index++)
          DataRow(
            color: buildStripedRowColor(index: index, colors: colors),
            cells: [
              DataCell(
                SizedBox(
                  width: 160,
                  child: TextFormField(
                    controller: _rows[index].lastNameController,
                    decoration: const InputDecoration(
                      hintText: 'Apellido',
                    ),
                    validator: (value) => _requiredValidator(
                      value,
                      _rows[index],
                      'Obligatorio',
                    ),
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 160,
                  child: TextFormField(
                    controller: _rows[index].firstNameController,
                    decoration: const InputDecoration(
                      hintText: 'Nombre',
                    ),
                    validator: (value) => _requiredValidator(
                      value,
                      _rows[index],
                      'Obligatorio',
                    ),
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 150,
                  child: TextFormField(
                    controller: _rows[index].birthDateController,
                    decoration: const InputDecoration(
                      hintText: 'DD/MM/AAAA',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                    ],
                    validator: (value) =>
                        _birthDateValidator(value, _rows[index]),
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 140,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _rows[index].gender,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'MASCULINO',
                          child: Text('Masculino'),
                        ),
                        DropdownMenuItem(
                          value: 'FEMENINO',
                          child: Text('Femenino'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _rows[index].gender = value;
                        });
                      },
                    ),
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 130,
                  child: TextFormField(
                    controller: _rows[index].dniController,
                    decoration: const InputDecoration(
                      hintText: 'DNI',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => _requiredValidator(
                      value,
                      _rows[index],
                      'Obligatorio',
                    ),
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 180,
                  child: TextFormField(
                    controller: _rows[index].streetController,
                    decoration: const InputDecoration(
                      hintText: 'Calle',
                    ),
                    validator: (value) => _requiredValidator(
                      value,
                      _rows[index],
                      'Obligatorio',
                    ),
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 110,
                  child: TextFormField(
                    controller: _rows[index].streetNumberController,
                    decoration: const InputDecoration(
                      hintText: 'N°',
                    ),
                    validator: (value) => _requiredValidator(
                      value,
                      _rows[index],
                      'Obligatorio',
                    ),
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 160,
                  child: TextFormField(
                    controller: _rows[index].cityController,
                    decoration: const InputDecoration(
                      hintText: 'Localidad',
                    ),
                    validator: (value) => _requiredValidator(
                      value,
                      _rows[index],
                      'Obligatorio',
                    ),
                  ),
                ),
              ),
              DataCell(
                Switch.adaptive(
                  value: _rows[index].active,
                  onChanged: (value) {
                    setState(() {
                      _rows[index].active = value;
                    });
                  },
                ),
              ),
              DataCell(
                SizedBox(
                  width: 180,
                  child: TextFormField(
                    controller: _rows[index].emergencyNameController,
                    decoration: const InputDecoration(
                      hintText: 'Nombre completo',
                    ),
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 140,
                  child: TextFormField(
                    controller: _rows[index].emergencyRelationshipController,
                    decoration: const InputDecoration(
                      hintText: 'Vínculo',
                    ),
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 140,
                  child: TextFormField(
                    controller: _rows[index].emergencyPhoneController,
                    decoration: const InputDecoration(
                      hintText: 'Teléfono',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ),
            ],
          ),
      ],
    );

    return PageScaffold(
      backgroundColor: Colors.transparent,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24.0),
          children: [
            Text(
              'Carga masiva de jugadores',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completá la tabla con los datos requeridos para cada jugador.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Scrollbar(
                        controller: _horizontalScrollController,
                        thumbVisibility: true,
                        notificationPredicate: (notification) =>
                            notification.metrics.axis == Axis.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          controller: _horizontalScrollController,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 1200),
                            child: table,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _isSaving ? null : _addRow,
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar fila'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: _isSaving ? null : _saveRows,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Guardar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MassivePlayerRow {
  _MassivePlayerRow({
    required this.firstNameController,
    required this.lastNameController,
    required this.dniController,
    required this.birthDateController,
    required this.streetController,
    required this.streetNumberController,
    required this.cityController,
    required this.emergencyNameController,
    required this.emergencyRelationshipController,
    required this.emergencyPhoneController,
    this.gender = 'MASCULINO',
    this.active = true,
  });

  factory _MassivePlayerRow.empty() => _MassivePlayerRow(
        firstNameController: TextEditingController(),
        lastNameController: TextEditingController(),
        dniController: TextEditingController(),
        birthDateController: TextEditingController(),
        streetController: TextEditingController(),
        streetNumberController: TextEditingController(),
        cityController: TextEditingController(),
        emergencyNameController: TextEditingController(),
        emergencyRelationshipController: TextEditingController(),
        emergencyPhoneController: TextEditingController(),
      );

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController dniController;
  final TextEditingController birthDateController;
  final TextEditingController streetController;
  final TextEditingController streetNumberController;
  final TextEditingController cityController;
  final TextEditingController emergencyNameController;
  final TextEditingController emergencyRelationshipController;
  final TextEditingController emergencyPhoneController;
  String gender;
  bool active;

  bool get isBlank {
    return firstNameController.text.trim().isEmpty &&
        lastNameController.text.trim().isEmpty &&
        dniController.text.trim().isEmpty &&
        birthDateController.text.trim().isEmpty &&
        streetController.text.trim().isEmpty &&
        streetNumberController.text.trim().isEmpty &&
        cityController.text.trim().isEmpty &&
        emergencyNameController.text.trim().isEmpty &&
        emergencyRelationshipController.text.trim().isEmpty &&
        emergencyPhoneController.text.trim().isEmpty;
  }

  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    dniController.dispose();
    birthDateController.dispose();
    streetController.dispose();
    streetNumberController.dispose();
    cityController.dispose();
    emergencyNameController.dispose();
    emergencyRelationshipController.dispose();
    emergencyPhoneController.dispose();
  }
}

class _PlayersTableSkeleton extends StatelessWidget {
  const _PlayersTableSkeleton();

  @override
  Widget build(BuildContext context) {
    final shimmerColor = Theme.of(context).colorScheme.surfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(6, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: index == 5 ? 0 : 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16,
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
  String _gender = 'MASCULINO';
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
    _gender = player?.gender ?? 'MASCULINO';
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
      if (error.response?.statusCode == 404) {
        setState(() {
          _duplicatePlayer = null;
        });
        return;
      }
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

  void _handleBirthDateChanged(String value) {
    if (widget.readOnly) {
      return;
    }
    final text = value.trim();
    DateTime? parsed;
    if (text.isNotEmpty) {
      try {
        parsed = DateFormat('dd/MM/yyyy').parseStrict(text);
      } catch (_) {
        parsed = null;
      }
    }
    setState(() {
      _birthDate = parsed;
    });
  }

  void _ensureBirthDateFormatted() {
    if (widget.readOnly) {
      return;
    }
    final birthDate = _birthDate;
    if (birthDate == null) {
      return;
    }
    final formatted = DateFormat('dd/MM/yyyy').format(birthDate);
    if (_birthDateController.text != formatted) {
      _birthDateController
        ..text = formatted
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: formatted.length),
        );
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
      locale: const Locale('es', 'US'),
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
      'gender': _gender,
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
    final showClubField = widget.player != null;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(right: 12),
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
              enabled: !readOnly,
              readOnly: readOnly,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
              ],
              onChanged: _handleBirthDateChanged,
              onEditingComplete: () {
                _ensureBirthDateFormatted();
                FocusScope.of(context).nextFocus();
              },
              decoration: InputDecoration(
                labelText: 'Fecha de nacimiento',
                hintText: 'DD/MM/AAAA',
                suffixIcon: readOnly
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.calendar_today_outlined),
                        onPressed: _pickBirthDate,
                      ),
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
            Text(
              'Género',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ToggleButtons(
              borderRadius: BorderRadius.circular(12),
              isSelected: [
                _gender == 'MASCULINO',
                _gender == 'FEMENINO',
              ],
              onPressed: readOnly
                  ? null
                  : (index) {
                      setState(() {
                        _gender = index == 0 ? 'MASCULINO' : 'FEMENINO';
                      });
                    },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Masculino'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Femenino'),
                ),
              ],
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
            if (showClubField) ...[
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
            ],
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
            label: 'Género',
            value: player.genderLabel,
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
    required this.gender,
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
      gender: json['gender'] as String? ?? 'MASCULINO',
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
  final String gender;
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

  String get genderLabel {
    switch (gender) {
      case 'FEMENINO':
        return 'Femenino';
      case 'MASCULINO':
        return 'Masculino';
      default:
        return 'Otro';
    }
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

DateTime? _parseBirthDate(String value) {
  final text = value.trim();
  if (text.isEmpty) {
    return null;
  }
  try {
    return DateFormat('dd/MM/yyyy').parseStrict(text);
  } catch (_) {
    return null;
  }
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
