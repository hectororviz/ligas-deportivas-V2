import 'package:flutter/material.dart';

import '../../../core/utils/responsive.dart';
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
    final isMobile = Responsive.isMobile(context);
    final colors = AppDataTableColors.score(theme, leagueColor);
    final headerStyle =
        theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: colors.headerText);

    return SingleChildScrollView(
      key: PageStorageKey<String>(storageKey),
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: isMobile ? 12 : 28,
        horizontalMargin: isMobile ? 8 : 24,
        headingRowHeight: isMobile ? 46 : 56,
        dataRowMinHeight: isMobile ? 44 : 48,
        dataRowMaxHeight: isMobile ? 50 : 56,
        headingRowColor: buildHeaderColor(colors.headerBackground),
        headingTextStyle: headerStyle,
        columns: [
          DataColumn(label: Text(isMobile ? '' : 'Posición')),
          const DataColumn(label: Text('Club')),
          const DataColumn(label: Text('PJ'), numeric: true),
          const DataColumn(label: Text('PG'), numeric: true),
          const DataColumn(label: Text('PE'), numeric: true),
          const DataColumn(label: Text('PP'), numeric: true),
          const DataColumn(label: Text('GF'), numeric: true),
          const DataColumn(label: Text('GC'), numeric: true),
          const DataColumn(label: Text('DG'), numeric: true),
          const DataColumn(label: Text('Pts'), numeric: true),
        ],
        rows: [
          for (var index = 0; index < rows.length; index++)
            DataRow(
              color: buildStripedRowColor(index: index, colors: colors),
              cells: [
                DataCell(Text('${index + 1}')),
                DataCell(SizedBox(width: isMobile ? 170 : 260, child: Text(rows[index].displayClubName))),
                DataCell(Text(rows[index].played.toString())),
                DataCell(Text(rows[index].wins.toString())),
                DataCell(Text(rows[index].draws.toString())),
                DataCell(Text(rows[index].losses.toString())),
                DataCell(Text(rows[index].goalsFor.toString())),
                DataCell(Text(rows[index].goalsAgainst.toString())),
                DataCell(Text(rows[index].goalDifference.toString())),
                DataCell(Text(
                  rows[index].points.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )),
              ],
            ),
        ],
      ),
    );
  }
}
