import 'package:flutter/material.dart';

import '../../shared/widgets/app_data_table_style.dart';
import '../domain/standings_models.dart';

class StandingsTable extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          emptyMessage,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final theme = Theme.of(context);
    final colors = AppDataTableColors.score(theme, leagueColor);
    final headerStyle =
        theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: colors.headerText);

    return SingleChildScrollView(
      key: PageStorageKey<String>(storageKey),
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
          for (var index = 0; index < rows.length; index++)
            DataRow(
              color: buildStripedRowColor(index: index, colors: colors),
              cells: [
                DataCell(Text('${index + 1}')),
                DataCell(Text(rows[index].clubName)),
                DataCell(Text(rows[index].played.toString())),
                DataCell(Text(rows[index].wins.toString())),
                DataCell(Text(rows[index].draws.toString())),
                DataCell(Text(rows[index].losses.toString())),
                DataCell(Text(rows[index].goalsFor.toString())),
                DataCell(Text(rows[index].goalsAgainst.toString())),
                DataCell(Text(rows[index].goalDifference.toString())),
                DataCell(Text(rows[index].points.toString())),
              ],
            ),
        ],
      ),
    );
  }
}
