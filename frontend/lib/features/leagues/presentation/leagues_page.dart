import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
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
        label: const Text('Nueva liga'),
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
                                  Icon(Icons.table_view_outlined, color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Ligas registradas',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  Text('${leagues.length} registradas',
                                      style: Theme.of(context).textTheme.bodyMedium),
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
              )
            ],
          ),
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
      columns: const [
        DataColumn(label: Text('Liga')),
        DataColumn(label: Text('Deporte')),
        DataColumn(label: Text('Visibilidad')),
        DataColumn(label: Text('Color distintivo')),
        DataColumn(label: Text('Competencia')),
        DataColumn(label: Text('Puntuación')),
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
                DataCell(Text(league.sport)),
                DataCell(_VisibilityChip(visibility: league.visibility)),
                DataCell(_ColorPreview(color: league.color, colorHex: league.colorHex)),
                DataCell(Text(league.competition.isActive ? 'Activa' : 'Inactiva')),
                DataCell(Text('V ${league.competition.scoring.winPoints} · '
                    'E ${league.competition.scoring.drawPoints} · '
                    'D ${league.competition.scoring.lossPoints}')),
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

class _VisibilityChip extends StatelessWidget {
  const _VisibilityChip({required this.visibility});

  final LeagueVisibility visibility;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPublic = visibility == LeagueVisibility.public;
    final backgroundColor = isPublic ? colorScheme.secondaryContainer : colorScheme.surfaceVariant;
    final foregroundColor = isPublic ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant;
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(isPublic ? 'Público' : 'Privado', style: TextStyle(color: foregroundColor)),
    );
  }
}

class _LeagueAvatar extends StatelessWidget {
  const _LeagueAvatar({required this.league});

  final League league;

  @override
  Widget build(BuildContext context) {
    if (league.logoUrl == null || league.logoUrl!.isEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: league.color.withOpacity(0.15),
        child: Icon(Icons.emoji_events_outlined, color: league.color),
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.transparent,
      backgroundImage: NetworkImage(league.logoUrl!),
      onBackgroundImageError: (_, __) {},
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
  late final TextEditingController _colorController;
  late final TextEditingController _winPointsController;
  late final TextEditingController _drawPointsController;
  late final TextEditingController _lossPointsController;
  late bool _active;
  late String _sport;
  late LeagueVisibility _visibility;
  PlatformFile? _selectedLogo;
  Uint8List? _logoPreview;
  bool _isSaving = false;
  String? _errorMessage;

  static const _sportOptions = <String>[
    'Fútbol',
    'Básquet',
    'Vóley',
    'Handball',
    'Rugby',
  ];

  @override
  void initState() {
    super.initState();
    final league = widget.league;
    _nameController = TextEditingController(text: league?.name ?? '');
    _colorController = TextEditingController(text: (league?.colorHex ?? '#0057B8').toUpperCase());
    _winPointsController = TextEditingController(text: '${league?.competition.scoring.winPoints ?? 3}');
    _drawPointsController = TextEditingController(text: '${league?.competition.scoring.drawPoints ?? 1}');
    _lossPointsController = TextEditingController(text: '${league?.competition.scoring.lossPoints ?? 0}');
    _active = league?.competition.isActive ?? true;
    _sport = league?.sport ?? _sportOptions.first;
    _visibility = league?.visibility ?? LeagueVisibility.public;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    _winPointsController.dispose();
    _drawPointsController.dispose();
    _lossPointsController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final file = result.files.single;
    setState(() {
      _selectedLogo = file;
      _logoPreview = file.bytes;
    });
  }

  void _removeLogo() {
    setState(() {
      _selectedLogo = null;
      _logoPreview = null;
    });
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
    final payload = {
      'name': _nameController.text.trim(),
      'sport': _sport,
      'visibility': _visibility.apiValue,
      'colorHex': _colorController.text.trim().toUpperCase(),
      'competitionConfig': {
        'active': _active,
        'scoring': {
          'win': int.tryParse(_winPointsController.text.trim()) ?? 0,
          'draw': int.tryParse(_drawPointsController.text.trim()) ?? 0,
          'loss': int.tryParse(_lossPointsController.text.trim()) ?? 0,
        }
      },
    };

    dynamic dataToSend = payload;
    if (_selectedLogo != null) {
      final formData = FormData.fromMap(payload);
      final file = _selectedLogo!;
      try {
        final bytes = file.bytes;
        if (bytes != null) {
          formData.files.add(
            MapEntry(
              'logo',
              MultipartFile.fromBytes(bytes, filename: file.name),
            ),
          );
        } else if (file.path != null) {
          formData.files.add(
            MapEntry(
              'logo',
              MultipartFile.fromFileSync(file.path!, filename: file.name),
            ),
          );
        }
      } catch (error) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'No se pudo preparar el logo seleccionado: $error';
        });
        return;
      }
      dataToSend = formData;
    }

    try {
      if (widget.league == null) {
        await api.post('/leagues', data: dataToSend);
      } else {
        await api.patch('/leagues/${widget.league!.id}', data: dataToSend);
      }
      ref.invalidate(leaguesProvider);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(addAnother ? _LeagueFormResult.savedAndAddAnother : _LeagueFormResult.saved);
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
          DropdownButtonFormField<String>(
            value: _sport,
            decoration: const InputDecoration(
              labelText: 'Deporte',
            ),
            items: _sportOptions
                .map(
                  (sport) => DropdownMenuItem(
                    value: sport,
                    child: Text(sport),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() => _sport = value);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<LeagueVisibility>(
            value: _visibility,
            decoration: const InputDecoration(labelText: 'Visibilidad'),
            items: LeagueVisibility.values
                .map(
                  (visibility) => DropdownMenuItem(
                    value: visibility,
                    child: Text(visibility.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() => _visibility = value);
            },
          ),
          const SizedBox(height: 16),
          _HexColorField(controller: _colorController),
          const SizedBox(height: 16),
          _LogoSelector(
            file: _selectedLogo,
            previewBytes: _logoPreview,
            existingUrl: widget.league?.logoUrl,
            onPick: _pickLogo,
            onRemove: _removeLogo,
            isLoading: _isSaving,
          ),
          const SizedBox(height: 20),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Competencia activa'),
            subtitle: const Text('Controla si la liga participa actualmente en torneos.'),
            value: _active,
            onChanged: (value) => setState(() => _active = value),
          ),
          const SizedBox(height: 8),
          Text(
            'Puntuación',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 160,
                child: TextFormField(
                  controller: _winPointsController,
                  decoration: const InputDecoration(labelText: 'Puntos por victoria'),
                  keyboardType: TextInputType.number,
                  validator: _validatePoints,
                ),
              ),
              SizedBox(
                width: 160,
                child: TextFormField(
                  controller: _drawPointsController,
                  decoration: const InputDecoration(labelText: 'Puntos por empate'),
                  keyboardType: TextInputType.number,
                  validator: _validatePoints,
                ),
              ),
              SizedBox(
                width: 160,
                child: TextFormField(
                  controller: _lossPointsController,
                  decoration: const InputDecoration(labelText: 'Puntos por derrota'),
                  keyboardType: TextInputType.number,
                  validator: _validatePoints,
                ),
              ),
            ],
          ),
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

  String? _validatePoints(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa un valor numérico.';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return 'Ingresa un número entero válido.';
    }
    return null;
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

class _LogoSelector extends StatelessWidget {
  const _LogoSelector({
    required this.onPick,
    required this.onRemove,
    required this.isLoading,
    this.file,
    this.previewBytes,
    this.existingUrl,
  });

  final VoidCallback onPick;
  final VoidCallback onRemove;
  final bool isLoading;
  final PlatformFile? file;
  final Uint8List? previewBytes;
  final String? existingUrl;

  @override
  Widget build(BuildContext context) {
    final hasSelection = file != null || (existingUrl != null && existingUrl!.isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Logo o imagen (opcional)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: isLoading ? null : onPick,
          borderRadius: BorderRadius.circular(16),
          child: DottedBorder(
            color: Theme.of(context).colorScheme.outlineVariant,
            radius: const Radius.circular(16),
            dashPattern: const [8, 6],
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (previewBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(previewBytes!, width: 120, height: 120, fit: BoxFit.cover),
                    )
                  else if (existingUrl != null && existingUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        existingUrl!,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  else
                    Icon(Icons.image_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    hasSelection ? 'Cambiar imagen' : 'Arrastra y suelta o selecciona un archivo',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Formatos PNG o JPG hasta 2 MB.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasSelection) ...[
          const SizedBox(height: 12),
          if (file != null && (previewBytes == null || previewBytes!.isEmpty))
            Text(
              file!.name,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (previewBytes == null && existingUrl == null)
            Text(
              'Se adjuntará ${file?.name ?? 'tu imagen seleccionada'} al guardar.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: isLoading ? null : onRemove,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Quitar imagen'),
          )
        ]
      ],
    );
  }
}

class League {
  League({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.sport,
    required this.visibility,
    required this.competition,
    this.logoUrl,
  });

  factory League.fromJson(Map<String, dynamic> json) {
    final visibilityRaw = (json['visibility'] as String?)?.toUpperCase();
    return League(
      id: json['id'] as int,
      name: json['name'] as String,
      colorHex: (json['colorHex'] as String? ?? '#0057B8').toUpperCase(),
      sport: json['sport'] as String? ?? 'Fútbol',
      visibility: _parseLeagueVisibility(visibilityRaw),
      logoUrl: json['logoUrl'] as String?,
      competition:
          LeagueCompetition.fromJson(json['competitionConfig'] as Map<String, dynamic>?),
    );
  }

  final int id;
  final String name;
  final String colorHex;
  final String sport;
  final LeagueVisibility visibility;
  final String? logoUrl;
  final LeagueCompetition competition;

  Color get color {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xff')));
    } catch (_) {
      return const Color(0xFF0057B8);
    }
  }
}

class LeagueCompetition {
  const LeagueCompetition({required this.isActive, required this.scoring});

  factory LeagueCompetition.fromJson(Map<String, dynamic>? json) {
    final scoringJson = json != null ? json['scoring'] as Map<String, dynamic>? : null;
    return LeagueCompetition(
      isActive: json?['active'] as bool? ?? true,
      scoring: LeagueScoring.fromJson(scoringJson),
    );
  }

  final bool isActive;
  final LeagueScoring scoring;
}

class LeagueScoring {
  const LeagueScoring({required this.winPoints, required this.drawPoints, required this.lossPoints});

  factory LeagueScoring.fromJson(Map<String, dynamic>? json) {
    return LeagueScoring(
      winPoints: json?['win'] as int? ?? 3,
      drawPoints: json?['draw'] as int? ?? 1,
      lossPoints: json?['loss'] as int? ?? 0,
    );
  }

  final int winPoints;
  final int drawPoints;
  final int lossPoints;
}

enum LeagueVisibility { public, private }

extension LeagueVisibilityX on LeagueVisibility {
  String get label => this == LeagueVisibility.public ? 'Público' : 'Privado';

  String get apiValue => this == LeagueVisibility.public ? 'PUBLIC' : 'PRIVATE';
}

LeagueVisibility _parseLeagueVisibility(String? value) {
  switch (value) {
    case 'PRIVATE':
      return LeagueVisibility.private;
    case 'PUBLIC':
    default:
      return LeagueVisibility.public;
  }
}

class DottedBorder extends StatelessWidget {
  const DottedBorder({
    super.key,
    required this.child,
    required this.color,
    required this.radius,
    required this.dashPattern,
  });

  final Widget child;
  final Color color;
  final Radius radius;
  final List<double> dashPattern;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedBorderPainter(
        color: color,
        radius: radius,
        dashPattern: dashPattern,
      ),
      child: ClipRRect(borderRadius: BorderRadius.all(radius), child: child),
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  _DottedBorderPainter({required this.color, required this.radius, required this.dashPattern});

  final Color color;
  final Radius radius;
  final List<double> dashPattern;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, radius);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      int index = 0;
      while (distance < metric.length) {
        final length = dashPattern[index % dashPattern.length];
        final next = distance + length;
        final extract = metric.extractPath(distance, next);
        if (index.isEven) {
          canvas.drawPath(extract, paint);
        }
        distance = next;
        index++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedBorderPainter oldDelegate) {
    return color != oldDelegate.color || radius != oldDelegate.radius || dashPattern != oldDelegate.dashPattern;
  }
}
