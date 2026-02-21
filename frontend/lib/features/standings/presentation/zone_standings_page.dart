import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../services/api_client.dart';
import '../domain/standings_models.dart';
import 'standings_table.dart';

final zoneStandingsProvider = FutureProvider.autoDispose.family<ZoneStandingsData, int>((ref, zoneId) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<Map<String, dynamic>>('/zones/$zoneId/standings');
  final data = response.data ?? <String, dynamic>{};
  return ZoneStandingsData.fromJson(data);
});

class ZoneStandingsPage extends ConsumerWidget {
  const ZoneStandingsPage({super.key, required this.zoneId});

  final int zoneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standingsAsync = ref.watch(zoneStandingsProvider(zoneId));

    return standingsAsync.when(
      data: (data) => _ZoneStandingsView(data: data),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(
                  'No pudimos cargar las tablas de la zona.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(zoneStandingsProvider(zoneId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ZoneStandingsView extends ConsumerStatefulWidget {
  const _ZoneStandingsView({required this.data});

  final ZoneStandingsData data;

  @override
  ConsumerState<_ZoneStandingsView> createState() => _ZoneStandingsViewState();
}

class _ZoneStandingsViewState extends ConsumerState<_ZoneStandingsView> {
  bool _isExporting = false;

  Future<void> _downloadStandingsImage() async {
    setState(() => _isExporting = true);
    try {
      final bytes = await _StandingsImageExporter.create(widget.data);
      final fileName = _StandingsImageExporter.fileName(widget.data);
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar tabla de resultados',
        fileName: fileName,
        bytes: bytes,
      );

      if (!mounted) {
        return;
      }

      if (savedPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Descarga cancelada.')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagen descargada correctamente.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos generar la imagen de la tabla.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final theme = Theme.of(context);
    final leagueColors = ref.watch(leagueColorsProvider);
    final leagueColor = leagueColors[data.zone.leagueId] ?? theme.colorScheme.primary;
    final subtitle = '${data.zone.tournamentName} ${data.zone.tournamentYear} · ${data.zone.leagueName}';
    final isMobile = Responsive.isMobile(context);
    final cardPadding = isMobile ? const EdgeInsets.all(12) : const EdgeInsets.all(20);
    final tilePadding = isMobile
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    final tileChildrenPadding =
        isMobile ? const EdgeInsets.fromLTRB(12, 0, 12, 12) : const EdgeInsets.fromLTRB(20, 0, 20, 16);

    final listPadding = isMobile
        ? const EdgeInsets.fromLTRB(8, 16, 8, 16)
        : const EdgeInsets.all(24);

    return ListView(
      padding: listPadding,
      children: [
        Text(
          data.zone.name,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _isExporting ? null : _downloadStandingsImage,
          icon: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_outlined),
          label: Text(_isExporting ? 'Generando imagen...' : 'Descargar imagen de tablas'),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tabla general',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  'La tabla general suma los resultados de todas las categorías que participan en la zona (excepto las promocionales).',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                StandingsTable(
                  storageKey: 'zone-${data.zone.id}-general-table',
                  rows: data.general,
                  emptyMessage: 'Todavía no hay datos para la tabla general.',
                  leagueColor: leagueColor,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Tablas por categoría',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (data.categories.isEmpty)
          Card(
            child: Padding(
              padding: cardPadding,
              child: Text(
                'No hay categorías con estadísticas disponibles en esta zona.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          )
        else
          ...data.categories.map(
            (category) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                key: PageStorageKey('zone-${data.zone.id}-category-${category.tournamentCategoryId}'),
                tilePadding: tilePadding,
                childrenPadding: tileChildrenPadding,
                title: Text(
                  category.categoryName,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: category.countsForGeneral
                    ? null
                    : Text(
                        'Categoría promocional (no suma a la tabla general).',
                        style: theme.textTheme.bodySmall,
                      ),
                children: [
                  StandingsTable(
                    storageKey:
                        'zone-${data.zone.id}-category-${category.tournamentCategoryId}-table',
                    rows: category.standings,
                    emptyMessage: 'No hay datos para esta categoría.',
                    leagueColor: leagueColor,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StandingsImageExporter {
  static const double _horizontalPadding = 48;
  static const double _verticalPadding = 40;
  static const double _titleSize = 34;
  static const double _subtitleSize = 24;
  static const double _headerSize = 21;
  static const double _lineSize = 18;
  static const double _lineHeight = 1.35;

  static Future<Uint8List> create(ZoneStandingsData data) async {
    const width = 1600.0;
    final lines = _buildLines(data);
    final imageHeight = _calculateHeight(lines.length);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final backgroundPaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRect(Rect.fromLTWH(0, 0, width, imageHeight), backgroundPaint);

    final linePainter = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(_horizontalPadding, 170),
      Offset(width - _horizontalPadding, 170),
      linePainter,
    );

    var y = _verticalPadding;
    y = _drawText(canvas, 'Liga: ${data.zone.leagueName}', _horizontalPadding, y,
        size: _titleSize, weight: FontWeight.w700);
    y = _drawText(
      canvas,
      'Torneo: ${data.zone.tournamentName} ${data.zone.tournamentYear}',
      _horizontalPadding,
      y,
      size: _subtitleSize,
      weight: FontWeight.w600,
    );
    y = _drawText(
      canvas,
      'Zona: ${data.zone.name}',
      _horizontalPadding,
      y,
      size: _subtitleSize,
      weight: FontWeight.w600,
    );
    y += 30;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final isHeader = line.startsWith('TABLA') || line.startsWith('Categoría:');
      final isTableHeader = line.startsWith('#  Club');
      final isSeparator = line == _separator;
      if (isSeparator) {
        canvas.drawLine(
          Offset(_horizontalPadding, y + 8),
          Offset(width - _horizontalPadding, y + 8),
          linePainter,
        );
        y += 18;
        continue;
      }
      y = _drawText(
        canvas,
        line,
        _horizontalPadding,
        y,
        size: isHeader ? _headerSize : _lineSize,
        weight: isHeader || isTableHeader ? FontWeight.w700 : FontWeight.w400,
        mono: !isHeader,
      );
      if (isHeader && i > 0) {
        y += 4;
      }
    }

    final image = await recorder.endRecording().toImage(width.toInt(), imageHeight.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      throw StateError('No se pudo generar la imagen de tablas.');
    }
    return bytes.buffer.asUint8List();
  }

  static String fileName(ZoneStandingsData data) {
    final base = '${data.zone.leagueName}-${data.zone.tournamentName}-${data.zone.name}'
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return 'tablas-$base.png';
  }

  static List<String> _buildLines(ZoneStandingsData data) {
    final lines = <String>[
      'TABLA GENERAL',
      _tableHeader,
      ..._rows(data.general),
      _separator,
      'TABLAS DE TODAS LAS CATEGORÍAS',
    ];

    if (data.categories.isEmpty) {
      lines.add('Sin categorías con datos disponibles.');
      return lines;
    }

    for (final category in data.categories) {
      lines.add('Categoría: ${category.categoryName}');
      if (!category.countsForGeneral) {
        lines.add('  * Promocional (no suma a la tabla general).');
      }
      lines.add(_tableHeader);
      lines.addAll(_rows(category.standings));
      lines.add(_separator);
    }
    return lines;
  }

  static List<String> _rows(List<StandingsRow> rows) {
    if (rows.isEmpty) {
      return const ['(Sin datos)'];
    }
    return rows.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final row = entry.value;
      return '${index.toString().padLeft(2)}  '
          '${_trim(row.clubName, 28).padRight(28)}  '
          '${row.played.toString().padLeft(2)}  '
          '${row.wins.toString().padLeft(2)}  '
          '${row.draws.toString().padLeft(2)}  '
          '${row.losses.toString().padLeft(2)}  '
          '${row.goalsFor.toString().padLeft(2)}  '
          '${row.goalsAgainst.toString().padLeft(2)}  '
          '${row.goalDifference >= 0 ? '+' : ''}${row.goalDifference.toString().padLeft(2)}  '
          '${row.points.toString().padLeft(3)}';
    }).toList();
  }

  static double _calculateHeight(int linesCount) {
    final estimated = (_verticalPadding * 2) + 220 + (linesCount * _lineSize * _lineHeight);
    return estimated < 900 ? 900 : estimated;
  }

  static double _drawText(
    Canvas canvas,
    String text,
    double x,
    double y, {
    required double size,
    required FontWeight weight,
    bool mono = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: const Color(0xFF111827),
          fontSize: size,
          height: _lineHeight,
          fontWeight: weight,
          fontFamily: mono ? 'monospace' : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 1500);

    painter.paint(canvas, Offset(x, y));
    return y + painter.height;
  }

  static String _trim(String value, int maxLength) {
    if (value.length <= maxLength) {
      return value;
    }
    if (maxLength <= 1) {
      return value.substring(0, maxLength);
    }
    return '${value.substring(0, maxLength - 1)}…';
  }

  static const _tableHeader = '#  Club                          PJ  G  E  P  GF  GC  DG  PTS';
  static const _separator = '----';
}
