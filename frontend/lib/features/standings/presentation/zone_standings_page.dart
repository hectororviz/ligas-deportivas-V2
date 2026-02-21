import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/binary_download.dart';
import '../../../core/utils/responsive.dart';
import '../../../services/api_client.dart';
import '../../settings/site_identity_provider.dart';
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
      final leagueColor =
          ref.read(leagueColorsProvider)[widget.data.zone.leagueId] ?? Theme.of(context).colorScheme.primary;
      String? siteLogoUrl;
      try {
        final identity = await ref.read(siteIdentityProvider.future);
        if (identity.iconUrl != null && identity.iconUrl!.isNotEmpty) {
          siteLogoUrl = identity.iconUrl;
        } else {
          final basePath = identity.faviconBasePath;
          if (basePath != null && basePath.isNotEmpty) {
            siteLogoUrl = '$basePath/android-chrome-192x192.png';
          }
        }
      } catch (_) {
        siteLogoUrl = null;
      }

      final bytes = await _StandingsImageExporter.create(
        widget.data,
        leagueColor: leagueColor,
        siteLogoUrl: siteLogoUrl,
      );
      final fileName = _StandingsImageExporter.fileName(widget.data);
      if (kIsWeb) {
        await downloadBinary(
          bytes: bytes,
          filename: fileName,
          mimeType: 'image/png',
        );
      } else {
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
      }

      if (!mounted) {
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
                  'Tabla de posiciones',
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
  static const double _imageWidth = 2400;
  static const double _horizontalPadding = 96;
  static const double _verticalPadding = 72;
  static const double _sectionGap = 44;
  static const double _gridGap = 30;
  static const double _titleSize = 68;
  static const double _subtitleSize = 34;
  static const double _sectionTitleSize = 38;
  static const double _categoryTitleSize = 32;
  static const double _promoSize = 25;
  static const double _footerSize = 28;
  static const double _headerRowHeight = 82;
  static const double _dataRowHeight = 74;
  static const double _headerFontSize = 28;
  static const double _cellFontSize = 28;
  static const double _cellHorizontalPadding = 16;
  static const double _logoSize = 183;

  static const List<String> _columns = [
    'Posición',
    'Club',
    'PJ',
    'PG',
    'PE',
    'PP',
    'GF',
    'GC',
    'DG',
    'Pts',
  ];

  static const List<double> _columnFlex = [1.2, 6.7, 0.72, 0.72, 0.72, 0.72, 0.72, 0.72, 0.72, 0.72];

  static Future<Uint8List> create(
    ZoneStandingsData data, {
    required Color leagueColor,
    String? siteLogoUrl,
  }) async {
    final contentWidth = _imageWidth - (_horizontalPadding * 2);
    final generalTableWidth = contentWidth * 0.9;
    final categoriesTableWidth = (contentWidth - _gridGap) / 2;
    final imageHeight = _calculateHeight(data);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, _imageWidth, imageHeight),
      Paint()..color = const Color(0xFFFFFFFF),
    );

    final logoImage = await _loadLogo(siteLogoUrl);

    var y = _verticalPadding;
    _drawLogo(canvas, y, logoImage: logoImage);
    y = _drawCenteredText(
      canvas,
      'TABLA DE POSICIONES',
      y,
      size: _titleSize,
      weight: FontWeight.w700,
      maxWidth: _imageWidth,
    );

    y = _drawCenteredText(
      canvas,
      '${data.zone.leagueName} · ${data.zone.tournamentName} ${data.zone.tournamentYear} · ${data.zone.name}',
      y + 8,
      size: _subtitleSize,
      weight: FontWeight.w500,
      maxWidth: _imageWidth,
    );

    y = _drawCenteredText(
      canvas,
      'Tabla de posiciones',
      y + 24,
      size: _sectionTitleSize,
      weight: FontWeight.w700,
      maxWidth: _imageWidth,
    );

    y += 16;
    _drawTable(
      canvas,
      x: (_imageWidth - generalTableWidth) / 2,
      y: y,
      width: generalTableWidth,
      rows: data.general,
      leagueColor: leagueColor,
    );
    y += _tableHeight(data.general.length) + _sectionGap;

    if (data.categories.isEmpty) {
      _drawCenteredText(
        canvas,
        'Sin categorías con datos disponibles.',
        y,
        size: _subtitleSize,
        weight: FontWeight.w500,
        maxWidth: _imageWidth,
      );
    } else {
      y = _drawCenteredText(
        canvas,
        'Tablas por categoría',
        y,
        size: _sectionTitleSize,
        weight: FontWeight.w700,
        maxWidth: _imageWidth,
      );
      y += 12;

      for (var i = 0; i < data.categories.length; i += 2) {
        final left = data.categories[i];
        final right = i + 1 < data.categories.length ? data.categories[i + 1] : null;

        final leftHeight = _categoryBlockHeight(left.standings.length, left.countsForGeneral);
        final rightHeight = right == null
            ? 0.0
            : _categoryBlockHeight(right.standings.length, right.countsForGeneral);
        final rowHeight = leftHeight > rightHeight ? leftHeight : rightHeight;

        _drawCategoryBlock(
          canvas,
          x: _horizontalPadding,
          y: y,
          width: categoriesTableWidth,
          category: left,
          leagueColor: leagueColor,
        );

        if (right != null) {
          _drawCategoryBlock(
            canvas,
            x: _horizontalPadding + categoriesTableWidth + _gridGap,
            y: y,
            width: categoriesTableWidth,
            category: right,
            leagueColor: leagueColor,
          );
        }

        y += rowHeight + _sectionGap;
      }
    }

    _drawCenteredText(
      canvas,
      'ligas.csdsoler.com.ar',
      imageHeight - _verticalPadding + 6,
      size: _footerSize,
      weight: FontWeight.w600,
      maxWidth: _imageWidth,
    );

    final image = await recorder.endRecording().toImage(_imageWidth.toInt(), imageHeight.toInt());
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

  static double _calculateHeight(ZoneStandingsData data) {
    var height = _verticalPadding;
    height += (_titleSize * 1.3) + (_subtitleSize * 1.5) + 24;
    height += (_sectionTitleSize * 1.4) + 16;
    height += _tableHeight(data.general.length) + _sectionGap;

    if (data.categories.isEmpty) {
      height += _subtitleSize * 1.6;
    } else {
      height += (_sectionTitleSize * 1.4) + 12;
      for (var i = 0; i < data.categories.length; i += 2) {
        final left = data.categories[i];
        final right = i + 1 < data.categories.length ? data.categories[i + 1] : null;
        final leftHeight = _categoryBlockHeight(left.standings.length, left.countsForGeneral);
        final rightHeight = right == null
            ? 0.0
            : _categoryBlockHeight(right.standings.length, right.countsForGeneral);
        height += (leftHeight > rightHeight ? leftHeight : rightHeight) + _sectionGap;
      }
    }

    return height + _verticalPadding + _footerSize + 20;
  }

  static double _categoryBlockHeight(int rows, bool countsForGeneral) {
    final promoHeight = countsForGeneral ? 0.0 : (_promoSize * 1.4) + 6;
    return (_categoryTitleSize * 1.4) + promoHeight + 10 + _tableHeight(rows);
  }

  static double _tableHeight(int rows) {
    final count = rows == 0 ? 1 : rows;
    return _headerRowHeight + (_dataRowHeight * count);
  }

  static void _drawCategoryBlock(
    Canvas canvas, {
    required double x,
    required double y,
    required double width,
    required ZoneCategoryStandings category,
    required Color leagueColor,
  }) {
    var currentY = y;
    currentY = _drawCenteredText(
      canvas,
      category.categoryName,
      currentY,
      size: _categoryTitleSize,
      weight: FontWeight.w700,
      maxWidth: width,
      originX: x,
    );

    if (!category.countsForGeneral) {
      currentY = _drawCenteredText(
        canvas,
        'Promocional (no suma a la tabla general)',
        currentY + 4,
        size: _promoSize,
        weight: FontWeight.w500,
        maxWidth: width,
        originX: x,
      );
    }

    _drawTable(
      canvas,
      x: x,
      y: currentY + 10,
      width: width,
      rows: category.standings,
      leagueColor: leagueColor,
    );
  }

  static void _drawTable(
    Canvas canvas, {
    required double x,
    required double y,
    required double width,
    required List<StandingsRow> rows,
    required Color leagueColor,
  }) {
    final headerPaint = Paint()..color = leagueColor;
    final oddRowPaint = Paint()..color = _lighten(leagueColor, 0.72);
    final evenRowPaint = Paint()..color = _lighten(leagueColor, 0.82);
    final borderPaint = Paint()
      ..color = const Color(0xFFA9ADB6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final rowCount = rows.isEmpty ? 1 : rows.length;
    final tableHeight = _headerRowHeight + (_dataRowHeight * rowCount);

    final tableRect = Rect.fromLTWH(x, y, width, tableHeight);
    canvas.drawRect(tableRect, borderPaint);
    canvas.drawRect(Rect.fromLTWH(x, y, width, _headerRowHeight), headerPaint);

    final columns = _normalizedColumnWidths(width);
    var cursorX = x;
    for (var i = 0; i < _columns.length; i++) {
      final columnWidth = columns[i];
      _drawCellText(
        canvas,
        text: _columns[i],
        x: cursorX,
        y: y,
        width: columnWidth,
        height: _headerRowHeight,
        align: i == 1 ? TextAlign.left : TextAlign.center,
        size: _headerFontSize,
        weight: FontWeight.w700,
        color: Colors.white,
      );
      cursorX += columnWidth;
    }

    for (var index = 0; index < rowCount; index++) {
      final rowY = y + _headerRowHeight + (index * _dataRowHeight);
      canvas.drawRect(
        Rect.fromLTWH(x, rowY, width, _dataRowHeight),
        index.isEven ? evenRowPaint : oddRowPaint,
      );

      final row = index < rows.length ? rows[index] : null;
      final values = row == null
          ? const ['-', 'Sin datos', '-', '-', '-', '-', '-', '-', '-', '-']
          : [
              '${index + 1}',
              row.displayClubName,
              '${row.played}',
              '${row.wins}',
              '${row.draws}',
              '${row.losses}',
              '${row.goalsFor}',
              '${row.goalsAgainst}',
              '${row.goalDifference}',
              '${row.points}',
            ];

      var cellX = x;
      for (var i = 0; i < values.length; i++) {
        final columnWidth = columns[i];
        _drawCellText(
          canvas,
          text: values[i],
          x: cellX,
          y: rowY,
          width: columnWidth,
          height: _dataRowHeight,
          align: i == 1 ? TextAlign.left : TextAlign.center,
          size: _cellFontSize,
          weight: FontWeight.w500,
          color: const Color(0xFF20232B),
        );
        cellX += columnWidth;
      }
    }

    var lineX = x;
    for (var i = 0; i < columns.length - 1; i++) {
      lineX += columns[i];
      canvas.drawLine(Offset(lineX, y), Offset(lineX, y + tableHeight), borderPaint);
    }

    for (var i = 0; i <= rowCount; i++) {
      final lineY = y + _headerRowHeight + (i * _dataRowHeight);
      canvas.drawLine(Offset(x, lineY), Offset(x + width, lineY), borderPaint);
    }
  }

  static List<double> _normalizedColumnWidths(double tableWidth) {
    final totalFlex = _columnFlex.fold<double>(0, (acc, value) => acc + value);
    return _columnFlex.map((value) => tableWidth * (value / totalFlex)).toList(growable: false);
  }

  static double _drawCenteredText(
    Canvas canvas,
    String text,
    double y, {
    required double size,
    required FontWeight weight,
    required double maxWidth,
    double originX = 0,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: const Color(0xFF111827),
          fontSize: size,
          height: 1.25,
          fontWeight: weight,
        ),
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    final textX = originX + ((maxWidth - painter.width) / 2);
    painter.paint(canvas, Offset(textX, y));
    return y + painter.height;
  }



  static Future<ui.Image?> _loadLogo(String? siteLogoUrl) async {
    if (siteLogoUrl == null || siteLogoUrl.isEmpty) {
      return null;
    }
    try {
      final uri = Uri.tryParse(siteLogoUrl);
      if (uri != null) {
        final resolvedUri = uri.hasScheme ? uri : Uri.base.resolveUri(uri);
        final data = await NetworkAssetBundle(resolvedUri).load(resolvedUri.toString());
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: _logoSize.toInt());
        final frame = await codec.getNextFrame();
        return frame.image;
      }
    } catch (_) {
      // Intentamos fallback local.
    }

    try {
      final fallbackUri = Uri.base.resolve('favicon.png');
      final data = await NetworkAssetBundle(fallbackUri).load(fallbackUri.toString());
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: _logoSize.toInt());
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  static void _drawLogo(Canvas canvas, double y, {ui.Image? logoImage}) {
    final x = _horizontalPadding;
    final rect = Rect.fromLTWH(x, y, _logoSize, _logoSize);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(20));

    if (logoImage != null) {
      canvas.save();
      canvas.clipRRect(rrect);
      paintImage(canvas: canvas, rect: rect, image: logoImage, fit: BoxFit.cover);
      canvas.restore();
      return;
    }

    canvas.drawRRect(rrect, Paint()..color = const Color(0xFFE5E7EB));
    _drawCenteredText(
      canvas,
      'LP',
      y + (_logoSize * 0.25),
      size: _logoSize * 0.36,
      weight: FontWeight.w700,
      maxWidth: _logoSize,
      originX: x,
    );
  }

  static Color _lighten(Color color, double amount) {
    return Color.lerp(color, Colors.white, amount) ?? color;
  }

  static void _drawCellText(
    Canvas canvas, {
    required String text,
    required double x,
    required double y,
    required double width,
    required double height,
    required TextAlign align,
    required double size,
    required FontWeight weight,
    Color color = const Color(0xFF20232B),
  }) {
    final inset = align == TextAlign.left ? _cellHorizontalPadding : 8.0;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width - (inset * 2));

    final textX = switch (align) {
      TextAlign.left => x + inset,
      TextAlign.right => x + width - painter.width - inset,
      _ => x + ((width - painter.width) / 2),
    };
    final textY = y + ((height - painter.height) / 2);
    painter.paint(canvas, Offset(textX, textY));
  }
}
