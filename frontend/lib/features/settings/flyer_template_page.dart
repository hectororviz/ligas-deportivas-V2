import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_client.dart';
import 'flyer_template.dart';
import 'flyer_template_provider.dart';

class FlyerTemplatePage extends ConsumerStatefulWidget {
  const FlyerTemplatePage({super.key, this.competitionId, this.tournamentName});

  final int? competitionId;
  final String? tournamentName;

  @override
  ConsumerState<FlyerTemplatePage> createState() => _FlyerTemplatePageState();
}

class _FlyerTemplatePageState extends ConsumerState<FlyerTemplatePage> {
  bool _saving = false;
  bool _previewing = false;
  bool _deleting = false;
  Uint8List? _backgroundBytes;
  String? _backgroundName;
  Uint8List? _layoutBytes;
  String? _layoutName;

  @override
  Widget build(BuildContext context) {
    final templateAsync = ref.watch(flyerTemplateProvider(widget.competitionId));
    final tokensAsync = ref.watch(flyerTokenDefinitionsProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: templateAsync.when(
        data: (template) => _buildContent(context, template, tokensAsync),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('No se pudo cargar la configuración de flyers: $error'),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    FlyerTemplateConfig template,
    AsyncValue<List<FlyerTemplateToken>> tokensAsync,
  ) {
    final theme = Theme.of(context);
    final title = widget.competitionId == null
        ? 'Plantilla de flyers'
        : 'Plantilla de flyers · ${widget.tournamentName ?? 'Torneo ${widget.competitionId}'}';
    final description = widget.competitionId == null
        ? 'Sube un fondo en 1080x1920 y un archivo SVG para definir el layout base de los flyers automáticos.'
        : 'Esta configuración aplica únicamente para el torneo seleccionado. Si no cargas archivos, se utilizará la plantilla global.';
    final showResetBanner = widget.competitionId != null && !template.hasCustomTemplate;
    final templateScopeLabel = widget.competitionId == null
        ? null
        : template.hasCustomTemplate
            ? 'Plantilla personalizada para este torneo'
            : 'Usando la plantilla global del sitio';
    final showDeleteButton = widget.competitionId != null && template.hasCustomTemplate;

    return ListView(
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: theme.textTheme.bodyMedium,
        ),
        if (templateScopeLabel != null) ...[
          const SizedBox(height: 12),
          Text(
            templateScopeLabel,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
          ),
        ],
        if (showResetBanner) ...[
          const SizedBox(height: 12),
          Card(
            color: theme.colorScheme.surfaceVariant,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Este torneo está heredando la plantilla global. Carga archivos nuevos para sobrescribirla.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Archivos de plantilla', style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                _buildBackgroundPicker(context, template),
                const SizedBox(height: 24),
                _buildLayoutPicker(context, template),
                const SizedBox(height: 24),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Guardar cambios'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _previewing ? null : _showPreview,
                      icon: _previewing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.visibility_outlined),
                      label: const Text('Vista previa'),
                    ),
                    if (showDeleteButton) ...[
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: _deleting ? null : _deleteTemplate,
                        icon: _deleting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.restart_alt),
                        label: const Text('Restablecer a plantilla global'),
                      ),
                    ],
                  ],
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tokens disponibles', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                tokensAsync.when(
                  data: (tokens) => _buildTokenTable(tokens),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Text('No se pudieron cargar los tokens: $error'),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundPicker(BuildContext context, FlyerTemplateConfig template) {
    final theme = Theme.of(context);
    final placeholder = Container(
      width: 140,
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      clipBehavior: Clip.antiAlias,
      child: template.backgroundUrl != null
          ? Image.network(template.backgroundUrl!, fit: BoxFit.cover)
          : const Center(child: Icon(Icons.image_outlined, size: 40)),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        placeholder,
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fondo 1080x1920 (PNG o JPG)', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(
                'Este archivo se usará como imagen base para cada flyer. Debe respetar el tamaño y una relación vertical.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _saving ? null : _pickBackground,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('Seleccionar fondo'),
                  ),
                  if (_backgroundName != null)
                    Chip(
                      label: Text(_backgroundName!),
                      onDeleted: _saving
                          ? null
                          : () {
                              setState(() {
                                _backgroundBytes = null;
                                _backgroundName = null;
                              });
                            },
                    ),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildLayoutPicker(BuildContext context, FlyerTemplateConfig template) {
    final theme = Theme.of(context);
    final layoutName = _layoutName ?? template.layoutFileName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Layout SVG', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Text(
          'La plantilla SVG define las posiciones de textos, logos y tokens dinámicos. Puedes usar Mustache para insertar tokens.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: _saving ? null : _pickLayout,
              icon: const Icon(Icons.file_present_outlined),
              label: const Text('Seleccionar SVG'),
            ),
            if (layoutName != null)
              Chip(
                label: Text(layoutName),
                onDeleted: _saving
                    ? null
                    : () {
                        setState(() {
                          _layoutBytes = null;
                          _layoutName = null;
                        });
                      },
              ),
          ],
        ),
        if (template.updatedAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Última actualización: ${template.updatedAt}',
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Widget _buildTokenTable(List<FlyerTemplateToken> tokens) {
    if (tokens.isEmpty) {
      return const Text('No hay tokens configurados por el momento.');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Token')),
                DataColumn(label: Text('Descripción')),
                DataColumn(label: Text('Ejemplo / Uso')),
              ],
              rows: tokens
                  .map(
                    (token) => DataRow(
                      cells: [
                        DataCell(SelectableText('{{${token.token}}}')),
                        DataCell(Text(token.description)),
                        DataCell(_buildTokenUsage(token)),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTokenUsage(FlyerTemplateToken token) {
    final items = <String>[];
    if (token.example != null && token.example!.isNotEmpty) {
      items.add('Ejemplo: ${token.example}');
    }
    if (token.usage != null && token.usage!.isNotEmpty) {
      items.add('Uso: ${token.usage}');
    }
    if (items.isEmpty) {
      return const Text('-');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((text) => Text(text)).toList(),
    );
  }

  Future<void> _pickBackground() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    if (file.bytes == null) {
      return;
    }

    setState(() {
      _backgroundBytes = file.bytes;
      _backgroundName = file.name;
    });
  }

  Future<void> _pickLayout() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['svg'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    if (file.bytes == null) {
      return;
    }

    setState(() {
      _layoutBytes = file.bytes;
      _layoutName = file.name;
    });
  }

  Future<void> _submit() async {
    if (_backgroundBytes == null && _layoutBytes == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un archivo para actualizar.')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final formData = FormData();
      if (_backgroundBytes != null) {
        formData.files.add(
          MapEntry(
            'background',
            MultipartFile.fromBytes(
              _backgroundBytes!,
              filename: _backgroundName ?? 'flyer-background.png',
            ),
          ),
        );
      }
      if (_layoutBytes != null) {
        formData.files.add(
          MapEntry(
            'layout',
            MultipartFile.fromBytes(
              _layoutBytes!,
              filename: _layoutName ?? 'flyer-layout.svg',
              contentType: 'image/svg+xml',
            ),
          ),
        );
      }

      await ref.read(apiClientProvider).put(_templatePath(), data: formData);
      ref.invalidate(flyerTemplateProvider(widget.competitionId));

      if (!mounted) {
        return;
      }

      setState(() {
        _backgroundBytes = null;
        _backgroundName = null;
        _layoutBytes = null;
        _layoutName = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plantilla actualizada correctamente.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron guardar los cambios: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _showPreview() async {
    setState(() {
      _previewing = true;
    });

    try {
      final bytes = await ref.read(apiClientProvider).getBytes('${_templatePath()}/preview');
      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: SizedBox(
              width: 320,
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: Image.memory(bytes, fit: BoxFit.cover),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              )
            ],
          );
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo generar la vista previa: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _previewing = false;
        });
      }
    }
  }

  String _templatePath() {
    if (widget.competitionId == null) {
      return '/site-identity/flyer-template';
    }
    return '/competitions/${widget.competitionId}/flyer-template';
  }

  Future<void> _deleteTemplate() async {
    setState(() {
      _deleting = true;
    });

    try {
      await ref.read(apiClientProvider).delete(_templatePath());
      ref.invalidate(flyerTemplateProvider(widget.competitionId));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La plantilla del torneo se restableció a la configuración global.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo restablecer la plantilla: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deleting = false;
        });
      }
    }
  }
}
