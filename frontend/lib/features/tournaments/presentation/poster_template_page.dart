import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http_parser/http_parser.dart';

import '../../../services/api_client.dart';
import 'poster_template.dart';
import 'poster_template_provider.dart';

const _canvasWidth = 1080.0;
const _canvasHeight = 1920.0;
const _defaultFontLabel = 'Default';
const _googleFonts = [
  _defaultFontLabel,
  'Roboto',
  'Montserrat',
  'Poppins',
  'Oswald',
  'Lato',
  'Open Sans',
  'Playfair Display',
  'Merriweather',
];
const _fontWeights = ['normal', '500', '600', '700', '800', 'bold'];
const _fontStyles = ['normal', 'italic'];

class PosterTemplatePage extends ConsumerStatefulWidget {
  const PosterTemplatePage({super.key, required this.competitionId, this.tournamentName});

  final int competitionId;
  final String? tournamentName;

  @override
  ConsumerState<PosterTemplatePage> createState() => _PosterTemplatePageState();
}

class _PosterTemplatePageState extends ConsumerState<PosterTemplatePage> {
  final TransformationController _transformationController = TransformationController();
  final TextEditingController _matchIdController = TextEditingController();

  PosterTemplateConfig? _config;
  List<PosterLayer> _layers = [];
  String? _backgroundUrl;
  int? _selectedIndex;
  bool _saving = false;
  bool _previewing = false;
  Uint8List? _backgroundBytes;
  String? _backgroundName;

  @override
  void dispose() {
    _transformationController.dispose();
    _matchIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templateAsync = ref.watch(posterTemplateProvider(widget.competitionId));
    final tokensAsync = ref.watch(posterTokenDefinitionsProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: templateAsync.when(
        data: (template) {
          _ensureInitialized(template);
          return _buildContent(context, tokensAsync);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('No se pudo cargar la plantilla: $error')),
      ),
    );
  }

  void _ensureInitialized(PosterTemplateConfig template) {
    if (_config != null) {
      return;
    }
    _config = template;
    _layers = template.layers.isEmpty ? _defaultLayers() : [...template.layers];
    _sortLayersStable();
    _reindexLayers();
    _backgroundUrl = template.backgroundUrl;
  }

  Widget _buildContent(BuildContext context, AsyncValue<List<PosterTemplateToken>> tokensAsync) {
    final theme = Theme.of(context);
    final title = 'Plantilla de posters · ${widget.tournamentName ?? 'Torneo ${widget.competitionId}'}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Configura el diseño de la placa promocional (1080x1920).'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: _saving ? null : _saveTemplate,
              icon: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: const Text('Guardar'),
            ),
            OutlinedButton.icon(
              onPressed: _previewing ? null : _previewTemplate,
              icon: _previewing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.visibility_outlined),
              label: const Text('Previsualizar'),
            ),
            SizedBox(
              width: 160,
              child: TextField(
                controller: _matchIdController,
                decoration: const InputDecoration(labelText: 'MatchId para preview'),
                keyboardType: TextInputType.number,
              ),
            ),
            OutlinedButton.icon(
              onPressed: _pickBackground,
              icon: const Icon(Icons.image_outlined),
              label: const Text('Cambiar fondo'),
            ),
            OutlinedButton.icon(
              onPressed: () => _addLayer(_createTextLayer()),
              icon: const Icon(Icons.text_fields),
              label: const Text('Agregar texto'),
            ),
            OutlinedButton.icon(
              onPressed: () => _addLayer(_createShapeLayer()),
              icon: const Icon(Icons.crop_square),
              label: const Text('Agregar banda'),
            ),
            OutlinedButton.icon(
              onPressed: () => _addLayer(_createLogoLayer(isHome: true)),
              icon: const Icon(Icons.sports_soccer),
              label: const Text('Logo local'),
            ),
            OutlinedButton.icon(
              onPressed: () => _addLayer(_createLogoLayer(isHome: false)),
              icon: const Icon(Icons.sports_soccer),
              label: const Text('Logo visita'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Center(child: _buildCanvas()),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: _buildInspector(tokensAsync),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCanvas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fitScale = math.min(
          constraints.maxWidth / _canvasWidth,
          constraints.maxHeight / _canvasHeight,
        );
        if (fitScale.isFinite && fitScale > 0) {
          final current = _transformationController.value;
          if (current.isIdentity()) {
            _transformationController.value = Matrix4.identity()..scale(fitScale);
          }
        }
        final scale = _transformationController.value.getMaxScaleOnAxis();
        final minScale = fitScale.isFinite
            ? math.min(1.0, math.max(fitScale, 0.1))
            : 0.1;
        return InteractiveViewer(
          transformationController: _transformationController,
          minScale: minScale,
          maxScale: 2.0,
          constrained: false,
          child: SizedBox(
            width: _canvasWidth,
            height: _canvasHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black12,
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Stack(
                children: [
                  for (var index = 0; index < _layers.length; index++)
                    _buildLayer(_layers[index], index, scale),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLayer(PosterLayer layer, int index, double scale) {
    final isSelected = _selectedIndex == index;
    final isBackgroundLayer = layer.type == 'image' && (layer.isBackground ?? false);
    final displaySrc = isBackgroundLayer ? _backgroundUrl : layer.src;

    Widget child;
    switch (layer.type) {
      case 'shape':
        child = Container(
          width: layer.width,
          height: layer.height,
          decoration: BoxDecoration(
            color: _parseColor(layer.fill) ?? Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(layer.radius ?? 0),
          ),
        );
      case 'image':
        if (isBackgroundLayer && _backgroundBytes != null) {
          child = Image.memory(
            _backgroundBytes!,
            width: layer.width,
            height: layer.height,
            fit: BoxFit.cover,
          );
        } else if (displaySrc == null || displaySrc.isEmpty || displaySrc.contains('{{')) {
          child = Container(
            width: layer.width,
            height: layer.height,
            color: Colors.black12,
            alignment: Alignment.center,
            child: Text(layer.isBackground == true ? 'Fondo' : 'Logo'),
          );
        } else {
          child = Image.network(
            displaySrc,
            width: layer.width,
            height: layer.height,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: layer.width,
              height: layer.height,
              color: Colors.black12,
              alignment: Alignment.center,
              child: const Text('Imagen'),
            ),
          );
        }
      case 'text':
      default:
        final align = _mapAlignment(layer.align ?? 'left');
        final baseStyle = TextStyle(
          fontSize: layer.fontSize ?? 42,
          color: _parseColor(layer.color) ?? Colors.white,
          fontWeight: _parseFontWeight(layer.fontWeight),
          fontStyle: _parseFontStyle(layer.fontStyle),
        );
        final fontFamily = layer.fontFamily;
        final textStyle = fontFamily == null || fontFamily.isEmpty
            ? baseStyle
            : GoogleFonts.getFont(fontFamily, textStyle: baseStyle);
        child = Container(
          width: layer.width,
          height: layer.height,
          alignment: align,
          child: Text(
            layer.text ?? '',
            textAlign: _mapTextAlign(layer.align ?? 'left'),
            style: textStyle,
          ),
        );
    }

    return Positioned(
      left: layer.x,
      top: layer.y,
      width: layer.width,
      height: layer.height,
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        onPanUpdate: layer.locked
            ? null
            : (details) {
                setState(() {
                  layer.x += details.delta.dx / scale;
                  layer.y += details.delta.dy / scale;
                });
              },
        child: Stack(
          children: [
            Opacity(opacity: layer.opacity, child: child),
            if (isSelected)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blueAccent, width: 2),
                    ),
                  ),
                ),
              ),
            if (isSelected && !layer.locked)
              Positioned(
                right: -8,
                bottom: -8,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      layer.width = math.max(20, layer.width + details.delta.dx / scale);
                      layer.height = math.max(20, layer.height + details.delta.dy / scale);
                    });
                  },
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInspector(AsyncValue<List<PosterTemplateToken>> tokensAsync) {
    final selectedLayer = _selectedIndex != null ? _layers[_selectedIndex!] : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Capas', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            children: [
              for (var index = 0; index < _layers.length; index++)
                ListTile(
                  title: Text('${_layers[index].type} · ${_layers[index].id}'),
                  selected: _selectedIndex == index,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(_layers[index].locked ? Icons.lock : Icons.lock_open),
                        onPressed: () => _toggleLock(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_upward),
                        onPressed: index == 0 ? null : () => _moveLayer(index, -1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_downward),
                        onPressed: index == _layers.length - 1 ? null : () => _moveLayer(index, 1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _removeLayer(index),
                      ),
                    ],
                  ),
                  onTap: () => setState(() => _selectedIndex = index),
                ),
              const Divider(height: 32),
              Text('Propiedades', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (selectedLayer == null)
                const Text('Selecciona una capa para editar sus propiedades.')
              else
                _buildLayerEditor(selectedLayer),
              const Divider(height: 32),
              Text('Placeholders', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              tokensAsync.when(
                data: (tokens) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: tokens
                      .map(
                        (token) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('{{${token.token}}} · ${token.description}'),
                        ),
                      )
                      .toList(),
                ),
                loading: () => const Text('Cargando tokens...'),
                error: (error, _) => Text('Error: $error'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLayerEditor(PosterLayer layer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNumberField(
          'X',
          layer.x,
          (value) => _updateLayer(layer, (l) => l.x = value),
          fieldKey: '${layer.id}-x',
        ),
        _buildNumberField(
          'Y',
          layer.y,
          (value) => _updateLayer(layer, (l) => l.y = value),
          fieldKey: '${layer.id}-y',
        ),
        _buildNumberField(
          'Ancho',
          layer.width,
          (value) => _updateLayer(layer, (l) => l.width = value),
          fieldKey: '${layer.id}-width',
        ),
        _buildNumberField(
          'Alto',
          layer.height,
          (value) => _updateLayer(layer, (l) => l.height = value),
          fieldKey: '${layer.id}-height',
        ),
        _buildNumberField(
          'Opacidad',
          layer.opacity,
          (value) => _updateLayer(layer, (l) => l.opacity = value.clamp(0, 1).toDouble()),
          precision: 2,
          fieldKey: '${layer.id}-opacity',
        ),
        if (layer.type == 'text') ...[
          _buildTextField(
            'Texto',
            layer.text ?? '',
            (value) => _updateLayer(layer, (l) => l.text = value),
            fieldKey: '${layer.id}-text',
          ),
          _buildNumberField(
            'Tamaño',
            layer.fontSize ?? 42,
            (value) => _updateLayer(layer, (l) => l.fontSize = value),
            fieldKey: '${layer.id}-fontSize',
          ),
          _buildTextField(
            'Color (#hex)',
            layer.color ?? '#FFFFFF',
            (value) => _updateLayer(layer, (l) => l.color = value),
            fieldKey: '${layer.id}-color',
          ),
          _buildDropdown(
            'Alineación',
            layer.align ?? 'left',
            const ['left', 'center', 'right'],
            (value) => _updateLayer(layer, (l) => l.align = value),
          ),
          _buildDropdown(
            'Tipografía',
            layer.fontFamily ?? _defaultFontLabel,
            _googleFonts,
            (value) => _updateLayer(
              layer,
              (l) => l.fontFamily = value == _defaultFontLabel ? null : value,
            ),
          ),
          _buildDropdown(
            'Peso',
            layer.fontWeight ?? 'normal',
            _fontWeights,
            (value) => _updateLayer(layer, (l) => l.fontWeight = value),
          ),
          _buildDropdown(
            'Estilo',
            layer.fontStyle ?? 'normal',
            _fontStyles,
            (value) => _updateLayer(layer, (l) => l.fontStyle = value),
          ),
        ],
        if (layer.type == 'image') ...[
          _buildTextField(
            'Src',
            layer.src ?? '',
            (value) => _updateLayer(layer, (l) => l.src = value),
            fieldKey: '${layer.id}-src',
          ),
          _buildDropdown(
            'Fit',
            layer.fit ?? 'cover',
            const ['cover', 'contain'],
            (value) => _updateLayer(layer, (l) => l.fit = value),
          ),
        ],
        if (layer.type == 'shape')
          _buildTextField(
            'Relleno (#hex)',
            layer.fill ?? '#000000',
            (value) => _updateLayer(layer, (l) => l.fill = value),
            fieldKey: '${layer.id}-fill',
          ),
      ],
    );
  }

  Widget _buildNumberField(
    String label,
    double value,
    ValueChanged<double> onChanged, {
    int precision = 0,
    String? fieldKey,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        key: fieldKey != null ? ValueKey(fieldKey) : null,
        initialValue: value.toStringAsFixed(precision),
        decoration: InputDecoration(labelText: label),
        keyboardType: TextInputType.number,
        onChanged: (value) {
          final parsed = double.tryParse(value);
          if (parsed != null) {
            onChanged(parsed);
          }
        },
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String value,
    ValueChanged<String> onChanged, {
    String? fieldKey,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        key: fieldKey != null ? ValueKey(fieldKey) : null,
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> options, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: options.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
        onChanged: (selected) {
          if (selected != null) {
            onChanged(selected);
          }
        },
      ),
    );
  }

  void _updateLayer(PosterLayer layer, void Function(PosterLayer) update) {
    setState(() {
      update(layer);
    });
  }

  void _toggleLock(int index) {
    setState(() {
      _layers[index].locked = !_layers[index].locked;
    });
  }

  void _removeLayer(int index) {
    setState(() {
      if (_selectedIndex == index) {
        _selectedIndex = null;
      }
      _layers.removeAt(index);
      _reindexLayers();
    });
  }

  void _addLayer(PosterLayer layer) {
    setState(() {
      _layers.add(layer);
      _selectedIndex = _layers.length - 1;
      _reindexLayers();
    });
  }

  void _moveLayer(int index, int direction) {
    setState(() {
      final newIndex = index + direction;
      final layer = _layers.removeAt(index);
      _layers.insert(newIndex, layer);
      _selectedIndex = newIndex;
      _reindexLayers();
    });
  }

  void _reindexLayers() {
    for (var i = 0; i < _layers.length; i++) {
      _layers[i].zIndex = i;
    }
  }

  void _sortLayersStable() {
    final indexed = _layers.asMap().entries.toList()
      ..sort((a, b) {
        final zComparison = a.value.zIndex.compareTo(b.value.zIndex);
        if (zComparison != 0) {
          return zComparison;
        }
        return a.key.compareTo(b.key);
      });
    _layers = [for (final entry in indexed) entry.value];
  }

  Future<void> _pickBackground() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) {
      return;
    }
    setState(() {
      _backgroundBytes = result.files.single.bytes;
      _backgroundName = result.files.single.name;
      _backgroundUrl = null;
    });
    _ensureBackgroundLayer();
  }

  void _ensureBackgroundLayer() {
    final existing = _layers.indexWhere((layer) => layer.type == 'image' && (layer.isBackground ?? false));
    if (existing == -1) {
      _layers.insert(
        0,
        PosterLayer(
          id: _generateId('background'),
          type: 'image',
          x: 0,
          y: 0,
          width: _canvasWidth,
          height: _canvasHeight,
          src: '',
          isBackground: true,
          fit: 'cover',
        ),
      );
      _reindexLayers();
    }
  }

  PosterLayer _createTextLayer() {
    return PosterLayer(
      id: _generateId('text'),
      type: 'text',
      x: 120,
      y: 200,
      width: 840,
      height: 140,
      text: 'Título',
      fontSize: 72,
      color: '#FFFFFF',
      align: 'center',
    );
  }

  PosterLayer _createShapeLayer() {
    return PosterLayer(
      id: _generateId('shape'),
      type: 'shape',
      x: 0,
      y: 1400,
      width: _canvasWidth,
      height: 240,
      fill: '#000000',
      opacity: 0.6,
      shape: 'rect',
    );
  }

  PosterLayer _createLogoLayer({required bool isHome}) {
    return PosterLayer(
      id: _generateId(isHome ? 'home-logo' : 'away-logo'),
      type: 'image',
      x: isHome ? 140 : 640,
      y: 820,
      width: 300,
      height: 300,
      src: isHome ? '{{homeClub.logoUrl}}' : '{{awayClub.logoUrl}}',
      fit: 'contain',
    );
  }

  List<PosterLayer> _defaultLayers() {
    return [
      PosterLayer(
        id: _generateId('background'),
        type: 'image',
        x: 0,
        y: 0,
        width: _canvasWidth,
        height: _canvasHeight,
        src: '',
        isBackground: true,
        fit: 'cover',
      ),
      _createLogoLayer(isHome: true),
      _createLogoLayer(isHome: false),
      PosterLayer(
        id: _generateId('tournament'),
        type: 'text',
        x: 80,
        y: 120,
        width: 920,
        height: 120,
        text: '{{tournament.name}}',
        fontSize: 64,
        color: '#FFFFFF',
        align: 'center',
      ),
      PosterLayer(
        id: _generateId('matchday'),
        type: 'text',
        x: 80,
        y: 280,
        width: 920,
        height: 120,
        text: 'Fecha {{match.matchday}} · {{match.dayName}}',
        fontSize: 48,
        color: '#FFFFFF',
        align: 'center',
      ),
    ];
  }

  Future<void> _saveTemplate() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      final formData = FormData.fromMap({
        'template': PosterTemplateConfig(layers: _layers).toTemplateJsonString(),
        if (_backgroundBytes != null)
          'background': MultipartFile.fromBytes(
            _backgroundBytes!,
            filename: _backgroundName ?? 'background.png',
            contentType: MediaType('image', 'png'),
          ),
      });
      await api.put('/competitions/${widget.competitionId}/poster-template', data: formData);
      ref.invalidate(posterTemplateProvider(widget.competitionId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plantilla guardada correctamente.')),
        );
      }
      setState(() {
        _backgroundBytes = null;
        _config = null;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar la plantilla: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _previewTemplate() async {
    if (_previewing) return;
    final matchId = int.tryParse(_matchIdController.text.trim());
    if (matchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un matchId para la vista previa.')),
      );
      return;
    }
    setState(() => _previewing = true);
    try {
      final api = ref.read(apiClientProvider);
      final data = await api.getBytes(
        '/competitions/${widget.competitionId}/poster-template/preview',
        queryParameters: {'matchId': matchId},
      );
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Vista previa'),
          content: SizedBox(
            width: 360,
            child: Image.memory(data),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo generar la vista previa: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _previewing = false);
    }
  }

  String _generateId(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$prefix-$timestamp-${math.Random().nextInt(9999)}';
  }

  Alignment _mapAlignment(String align) {
    switch (align) {
      case 'center':
        return Alignment.center;
      case 'right':
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }

  TextAlign _mapTextAlign(String align) {
    switch (align) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.left;
    }
  }

  Color? _parseColor(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final cleaned = value.replaceAll('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    if (cleaned.length == 8) {
      return Color(int.parse(cleaned, radix: 16));
    }
    return null;
  }

  FontWeight _parseFontWeight(String? value) {
    switch (value) {
      case '100':
        return FontWeight.w100;
      case '200':
        return FontWeight.w200;
      case '300':
        return FontWeight.w300;
      case '400':
      case 'normal':
        return FontWeight.w400;
      case '500':
        return FontWeight.w500;
      case '600':
        return FontWeight.w600;
      case '700':
      case 'bold':
        return FontWeight.w700;
      case '800':
        return FontWeight.w800;
      case '900':
        return FontWeight.w900;
      default:
        return FontWeight.normal;
    }
  }

  FontStyle _parseFontStyle(String? value) {
    switch (value) {
      case 'italic':
        return FontStyle.italic;
      default:
        return FontStyle.normal;
    }
  }
}
