import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../core/utils/image_download.dart';
import '../../shared/widgets/app_data_table_style.dart';
import '../domain/standings_models.dart';

class StandingsTable extends StatefulWidget {
  const StandingsTable({
    super.key,
    required this.storageKey,
    required this.rows,
    required this.emptyMessage,
    required this.leagueColor,
  });

  final String storageKey;
  final List<StandingsRow> rows;
  final String emptyMessage;
  final Color leagueColor;

  @override
  State<StandingsTable> createState() => _StandingsTableState();
}

class _StandingsTableState extends State<StandingsTable> {
  final _captureKey = GlobalKey();
  bool _isDownloading = false;

  Future<void> _downloadTableImage() async {
    if (_isDownloading) {
      return;
    }

    setState(() => _isDownloading = true);
    try {
      final boundary =
          _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError('La tabla todavía no está lista para exportarse.');
      }

      final image = await boundary.toImage(pixelRatio: 2);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('No se pudo convertir la tabla a PNG.');
      }

      await downloadImage(
        bytes: byteData.buffer.asUint8List(),
        filename: '${widget.storageKey}.png',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos generar la imagen de la tabla.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          widget.emptyMessage,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final theme = Theme.of(context);
    final colors = AppDataTableColors.score(theme, widget.leagueColor);
    final headerStyle =
        theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: colors.headerText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: _isDownloading ? null : _downloadTableImage,
            icon: _isDownloading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
            label: const Text('Descargar imagen'),
          ),
        ),
        const SizedBox(height: 8),
        RepaintBoundary(
          key: _captureKey,
          child: SingleChildScrollView(
            key: PageStorageKey<String>(widget.storageKey),
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: buildHeaderColor(colors.headerBackground),
              headingTextStyle: headerStyle,
              columns: const [
                DataColumn(label: Text('Posición')),
                DataColumn(label: Text('Club')),
                DataColumn(label: Text('PJ'), numeric: true),
                DataColumn(label: Text('PG'), numeric: true),
                DataColumn(label: Text('PE'), numeric: true),
                DataColumn(label: Text('PP'), numeric: true),
                DataColumn(label: Text('GF'), numeric: true),
                DataColumn(label: Text('GC'), numeric: true),
                DataColumn(label: Text('DG'), numeric: true),
                DataColumn(label: Text('Pts'), numeric: true),
              ],
              rows: [
                for (var index = 0; index < widget.rows.length; index++)
                  DataRow(
                    color: buildStripedRowColor(index: index, colors: colors),
                    cells: [
                      DataCell(Text('${index + 1}')),
                      DataCell(Text(widget.rows[index].clubName)),
                      DataCell(Text(widget.rows[index].played.toString())),
                      DataCell(Text(widget.rows[index].wins.toString())),
                      DataCell(Text(widget.rows[index].draws.toString())),
                      DataCell(Text(widget.rows[index].losses.toString())),
                      DataCell(Text(widget.rows[index].goalsFor.toString())),
                      DataCell(Text(widget.rows[index].goalsAgainst.toString())),
                      DataCell(Text(widget.rows[index].goalDifference.toString())),
                      DataCell(Text(widget.rows[index].points.toString())),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
