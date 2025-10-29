import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';
import '../../../services/auth_controller.dart';

final leaguesProvider = FutureProvider<List<League>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<List<dynamic>>('/leagues');
  final data = response.data ?? [];
  return data.map((json) => League.fromJson(json as Map<String, dynamic>)).toList();
});

class LeaguesPage extends ConsumerStatefulWidget {
  const LeaguesPage({super.key});

  @override
  ConsumerState<LeaguesPage> createState() => _LeaguesPageState();
}

class _LeaguesPageState extends ConsumerState<LeaguesPage> {
  Future<void> _openCreateLeague() async {
    _LeagueFormResult? result;
    do {
      result = await _showLeagueForm(
        context,
        allowSaveAndAdd: true,
      );
      if (!mounted || result == null) {
        break;
      }
      if (result == _LeagueFormResult.saved || result == _LeagueFormResult.savedAndAddAnother) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Liga guardada correctamente.')),
        );
      }
    } while (result == _LeagueFormResult.savedAndAddAnother);
  }

  Future<_LeagueFormResult?> _showLeagueForm(
    BuildContext context, {
    League? league,
    required bool allowSaveAndAdd,
  }) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 640;
    if (isCompact) {
      return showModalBottomSheet<_LeagueFormResult>(
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
            child: _LeagueFormDialog(
              league: league,
              allowSaveAndAdd: allowSaveAndAdd,
              isDialog: false,
            ),
          );
        },
      );
    }
    return showDialog<_LeagueFormResult>(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _LeagueFormDialog(
              league: league,
              allowSaveAndAdd: allowSaveAndAdd,
              isDialog: true,
            ),
          ),
        );
      },
    );
  }

  Future<void> _openEditLeague(League league) async {
    final result = await _showLeagueForm(
      context,
      league: league,
      allowSaveAndAdd: false,
    );
    if (!mounted || result == null) {
      return;
    }
    if (result == _LeagueFormResult.saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Liga "${league.name}" actualizada.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaguesAsync = ref.watch(leaguesProvider);
    final authState = ref.watch(authControllerProvider);
    final isAdmin = authState.user?.roles.contains('ADMIN') ?? false;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateLeague,
        icon: const Icon(Icons.add),
        label: const Text('Agregar liga'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ligas',
              style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Crea nuevas ligas en segundos y mantenlas organizadas con la configuración básica.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: leaguesAsync.when(
                  data: (leagues) {
                    if (leagues.isEmpty) {
                      return _EmptyLeaguesState(onCreate: _openCreateLeague);
                    }
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.table_view_outlined,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Ligas registradas',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${leagues.length} registradas',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: _LeaguesDataTable(
                                leagues: leagues,
                                isAdmin: isAdmin,
                                onEdit: _openEditLeague,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => _LeaguesErrorState(
                    error: error,
                    onRetry: () => ref.invalidate(leaguesProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _LeaguesDataTable extends StatelessWidget {
  const _LeaguesDataTable({
    required this.leagues,
    required this.isAdmin,
    required this.onEdit,
  });

  final List<League> leagues;
  final bool isAdmin;
  final ValueChanged<League> onEdit;

  @override
  Widget build(BuildContext context) {
    final table = DataTable(
      headingRowHeight: 52,
      dataRowMinHeight: 64,
      dataRowMaxHeight: 80,
      columns: const [
        DataColumn(label: Text('Liga')),
        DataColumn(label: Text('Identificador')),
        DataColumn(label: Text('Día de juego')),
        DataColumn(label: Text('Color distintivo')),
        DataColumn(label: Text('Acciones')),
      ],
      rows: leagues
          .map(
            (league) => DataRow(
              cells: [
                DataCell(Row(
                  children: [
                    _LeagueAvatar(league: league),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            league.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text('ID ${league.id}', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                )),
                DataCell(Text(league.slug ?? '—')),
                DataCell(Text(league.gameDay.label)),
                DataCell(_ColorPreview(color: league.color, colorHex: league.colorHex)),
                DataCell(
                  FilledButton.tonalIcon(
                    onPressed: isAdmin ? () => onEdit(league) : null,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
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

class _ColorPreview extends StatelessWidget {
  const _ColorPreview({required this.color, required this.colorHex});

  final Color color;
  final String colorHex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
        ),
        const SizedBox(width: 8),
        Text(colorHex.toUpperCase()),
      ],
    );
  }
}

class _LeagueAvatar extends StatelessWidget {
  const _LeagueAvatar({required this.league});

  final League league;

  @override
  Widget build(BuildContext context) {
    final background = league.color.withOpacity(0.15);
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: league.color,
          fontWeight: FontWeight.w600,
        );
    return CircleAvatar(
      radius: 24,
      backgroundColor: background,
      child: Text(
        league.initials,
        style: textStyle,
      ),
    );
  }
}

class _EmptyLeaguesState extends StatelessWidget {
  const _EmptyLeaguesState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Aún no tienes ligas registradas',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primera liga para comenzar a organizar torneos y fixtures.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Crear liga'),
            )
          ],
        ),
      ),
    );
  }
}

class _LeaguesErrorState extends StatelessWidget {
  const _LeaguesErrorState({required this.error, required this.onRetry});

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
          Text('No se pudieron cargar las ligas: $error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

enum _LeagueFormResult { saved, savedAndAddAnother }

class _LeagueFormDialog extends ConsumerStatefulWidget {
  const _LeagueFormDialog({
    required this.allowSaveAndAdd,
    this.league,
    required this.isDialog,
  });

  final bool allowSaveAndAdd;
  final League? league;
  final bool isDialog;

  @override
  ConsumerState<_LeagueFormDialog> createState() => _LeagueFormDialogState();
}

class _LeagueFormDialogState extends ConsumerState<_LeagueFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _slugController;
  late final TextEditingController _colorController;
  late GameDay _gameDay;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final league = widget.league;
    _nameController = TextEditingController(text: league?.name ?? '');
    _slugController = TextEditingController(text: league?.slug ?? '');
    _colorController =
        TextEditingController(text: (league?.colorHex ?? '#0057B8').toUpperCase());
    _gameDay = league?.gameDay ?? GameDay.domingo;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  String? _validateSlug(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    final regex = RegExp(r'^[a-z0-9-]+$');
    if (!regex.hasMatch(text)) {
      return 'Solo se permiten minúsculas, números y guiones.';
    }
    return null;
  }

  Future<void> _submit({required bool addAnother}) async {
    if (_isSaving) {
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
    final colorHex = _colorController.text.trim().toUpperCase();
    final slug = _slugController.text.trim();
    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'colorHex': colorHex,
      'gameDay': _gameDay.apiValue,
    };

    if (slug.isNotEmpty) {
      payload['slug'] = slug;
    }

    try {
      if (widget.league == null) {
        await api.post('/leagues', data: payload);
      } else {
        await api.patch('/leagues/${widget.league!.id}', data: payload);
      }
      ref.invalidate(leaguesProvider);
      if (!mounted) {
        return;
      }
      Navigator.of(context)
          .pop(addAnother ? _LeagueFormResult.savedAndAddAnother : _LeagueFormResult.saved);
    } on DioException catch (error) {
      final message = error.response?.data is Map<String, dynamic>
          ? (error.response!.data['message'] as String?)
          : error.message;
      setState(() {
        _errorMessage = message ?? 'Ocurrió un error inesperado al guardar la liga.';
        _isSaving = false;
      });
      if (message != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'No se pudo guardar la liga: $error';
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar la liga: $error')),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final content = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.league == null ? 'Crear liga' : 'Editar liga',
            style:
                Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Completa los datos esenciales. Podrás ajustar configuraciones avanzadas más adelante.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la liga',
              hintText: 'Ej. Liga Metropolitana',
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) {
                return 'El nombre es obligatorio.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _slugController,
            decoration: const InputDecoration(
              labelText: 'Identificador (slug)',
              hintText: 'ej. liga-metropolitana',
              helperText: 'Opcional. Si lo dejas vacío se generará automáticamente.',
            ),
            textInputAction: TextInputAction.next,
            validator: _validateSlug,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<GameDay>(
            value: _gameDay,
            decoration: const InputDecoration(
              labelText: 'Día de juego',
            ),
            items: GameDay.values
                .map(
                  (day) => DropdownMenuItem(
                    value: day,
                    child: Text(day.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() => _gameDay = value);
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Este día será la base para programar los partidos regulares de la liga.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          _HexColorField(controller: _colorController),
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
              if (widget.allowSaveAndAdd && widget.league == null) ...[
                FilledButton.tonal(
                  onPressed: _isSaving ? null : () => _submit(addAnother: true),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar y agregar otra'),
                ),
                const SizedBox(width: 12),
              ],
              FilledButton(
                onPressed: _isSaving ? null : () => _submit(addAnother: false),
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.league == null ? 'Guardar' : 'Guardar cambios'),
              ),
            ],
          )
        ],
      ),
    );

    if (widget.isDialog) {
      return SizedBox(width: 520, child: content);
    }
    return SingleChildScrollView(child: content);
  }


}

class _HexColorField extends StatelessWidget {
  const _HexColorField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Color distintivo (#RRGGBB)',
            hintText: '#0057B8',
          ),
          textCapitalization: TextCapitalization.characters,
          validator: (value) {
            final text = value?.trim() ?? '';
            final regex = RegExp(r'^#([0-9a-fA-F]{6})$');
            if (!regex.hasMatch(text)) {
              return 'Ingresa un color válido en formato #RRGGBB.';
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
              preview = Theme.of(context).colorScheme.primary;
            }
            return Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: preview,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Vista previa del color', style: Theme.of(context).textTheme.bodySmall),
              ],
            );
          },
        )
      ],
    );
  }
}

class League {
  League({
    required this.id,
    required this.name,
    required this.slug,
    required this.colorHex,
    required this.gameDay,
  });

  factory League.fromJson(Map<String, dynamic> json) {
    return League(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String?,
      colorHex: (json['colorHex'] as String? ?? '#0057B8').toUpperCase(),
      gameDay: _parseGameDay(json['gameDay'] as String?),
    );
  }

  final int id;
  final String name;
  final String? slug;
  final String colorHex;
  final GameDay gameDay;

  Color get color {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xff')));
    } catch (_) {
      return const Color(0xFF0057B8);
    }
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return '?';
    }
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}

enum GameDay {
  domingo('DOMINGO', 'Domingo'),
  lunes('LUNES', 'Lunes'),
  martes('MARTES', 'Martes'),
  miercoles('MIERCOLES', 'Miércoles'),
  jueves('JUEVES', 'Jueves'),
  viernes('VIERNES', 'Viernes'),
  sabado('SABADO', 'Sábado');

  const GameDay(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

GameDay _parseGameDay(String? value) {
  final normalized = value?.toUpperCase();
  for (final day in GameDay.values) {
    if (day.apiValue == normalized) {
      return day;
    }
  }
  return GameDay.domingo;
}
