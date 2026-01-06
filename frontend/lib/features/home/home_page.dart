import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/utils/responsive.dart';
import 'domain/home_summary.dart';
import 'providers/home_summary_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.pagePadding(context);
    final titleStyle =
        isMobile ? theme.textTheme.headlineSmall : theme.textTheme.headlineMedium;
    final summaryAsync = ref.watch(homeSummaryProvider);

    return summaryAsync.when(
      data: (summary) {
        if (summary.tournaments.isEmpty) {
          return Center(
            child: Padding(
              padding: padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline,
                      size: 56, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'No hay torneos vigentes para mostrar.',
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cuando haya torneos activos podrás ver aquí el resumen por zonas.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = _gridColumns(constraints.maxWidth);
            return ListView(
              padding: padding,
              children: [
                Text(
                  'Torneos vigentes',
                  style: titleStyle?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Resumen rápido de las zonas activas y sus posiciones.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: summary.tournaments.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 360,
                  ),
                  itemBuilder: (context, index) {
                    final tournament = summary.tournaments[index];
                    return _TournamentSummaryCard(
                      tournament: tournament,
                      isMobile: isMobile,
                    );
                  },
                ),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        return Center(
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(
                  'No pudimos cargar el resumen de torneos.',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(homeSummaryProvider),
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

int _gridColumns(double width) {
  if (width >= 1200) {
    return 3;
  }
  if (width >= 600) {
    return 2;
  }
  return 1;
}

class _TournamentSummaryCard extends StatefulWidget {
  const _TournamentSummaryCard({
    required this.tournament,
    required this.isMobile,
  });

  final HomeTournamentSummary tournament;
  final bool isMobile;

  @override
  State<_TournamentSummaryCard> createState() => _TournamentSummaryCardState();
}

class _TournamentSummaryCardState extends State<_TournamentSummaryCard> {
  late final PageController _controller;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zones = widget.tournament.zones;
    if (zones.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            widget.tournament.displayName,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    final zoneCount = zones.length;
    final currentZone = zones[_page];
    final showArrows = !widget.isMobile && zoneCount > 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.tournament.leagueName,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.tournament.displayName,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Zona ${currentZone.name}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: _CarouselFrame(
                controller: _controller,
                zoneCount: zoneCount,
                onPageChanged: (index) => setState(() => _page = index),
                zones: zones,
                enableKeyboard: !widget.isMobile,
                showArrows: showArrows,
                onArrowLeft: _page > 0 ? () => _goTo(_page - 1) : null,
                onArrowRight:
                    _page < zoneCount - 1 ? () => _goTo(_page + 1) : null,
              ),
            ),
            const SizedBox(height: 12),
            _DotsIndicator(
              count: zoneCount,
              currentIndex: _page,
              onSelected: _goTo,
            ),
          ],
        ),
      ),
    );
  }
}

class _CarouselFrame extends StatelessWidget {
  const _CarouselFrame({
    required this.controller,
    required this.zoneCount,
    required this.onPageChanged,
    required this.zones,
    required this.enableKeyboard,
    required this.showArrows,
    this.onArrowLeft,
    this.onArrowRight,
  });

  final PageController controller;
  final int zoneCount;
  final ValueChanged<int> onPageChanged;
  final List<HomeZoneSummary> zones;
  final bool enableKeyboard;
  final bool showArrows;
  final VoidCallback? onArrowLeft;
  final VoidCallback? onArrowRight;

  @override
  Widget build(BuildContext context) {
    final pageView = PageView.builder(
      controller: controller,
      itemCount: zoneCount,
      onPageChanged: onPageChanged,
      itemBuilder: (context, index) {
        return _ZoneSlide(zone: zones[index]);
      },
    );

    final content = showArrows
        ? Row(
            children: [
              IconButton(
                tooltip: 'Zona anterior',
                icon: const Icon(Icons.chevron_left),
                onPressed: onArrowLeft,
              ),
              Expanded(child: pageView),
              IconButton(
                tooltip: 'Zona siguiente',
                icon: const Icon(Icons.chevron_right),
                onPressed: onArrowRight,
              ),
            ],
          )
        : pageView;

    if (!enableKeyboard) {
      return content;
    }

    return FocusableActionDetector(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.arrowLeft): const _CarouselPrevIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowRight): const _CarouselNextIntent(),
      },
      actions: {
        _CarouselPrevIntent: CallbackAction<_CarouselPrevIntent>(
          onInvoke: (intent) => onArrowLeft?.call(),
        ),
        _CarouselNextIntent: CallbackAction<_CarouselNextIntent>(
          onInvoke: (intent) => onArrowRight?.call(),
        ),
      },
      child: content,
    );
  }
}

class _CarouselPrevIntent extends Intent {
  const _CarouselPrevIntent();
}

class _CarouselNextIntent extends Intent {
  const _CarouselNextIntent();
}

class _ZoneSlide extends StatelessWidget {
  const _ZoneSlide({required this.zone});

  final HomeZoneSummary zone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final standings = zone.top;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: standings.isEmpty
                ? Text(
                    'Sin posiciones cargadas',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : _StandingsTable(standings: standings),
          ),
          const Divider(height: 12),
          Text(
            _nextMatchdayLabel(zone.nextMatchday),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StandingsTable extends StatelessWidget {
  const _StandingsTable({required this.standings});

  final List<HomeStandingRow> standings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurfaceVariant,
    );
    final zebraColor = theme.colorScheme.surfaceVariant.withOpacity(0.35);

    return Table(
      columnWidths: const {
        0: FixedColumnWidth(32),
        1: FlexColumnWidth(),
        2: FixedColumnWidth(48),
      },
      children: [
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('#', style: headerStyle),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('Club', style: headerStyle),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('Pts', style: headerStyle, textAlign: TextAlign.end),
            ),
          ],
        ),
        ...standings.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          return TableRow(
            decoration: BoxDecoration(
              color: index.isEven ? zebraColor : Colors.transparent,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  _positionLabel(index),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  row.clubName,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${row.points}',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({
    required this.count,
    required this.currentIndex,
    required this.onSelected,
  });

  final int count;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: InkWell(
            onTap: () => onSelected(index),
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 12 : 8,
              height: isActive ? 12 : 8,
              decoration: BoxDecoration(
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }
}

String _nextMatchdayLabel(HomeNextMatchday? matchday) {
  if (matchday == null) {
    return 'Próxima fecha: sin programar';
  }
  if (matchday.date == null) {
    return 'Próxima fecha: a confirmar';
  }
  final dateFormatter = DateFormat('EEEE dd/MM', 'es');
  final timeFormatter = DateFormat('HH:mm');
  final dateLabel = dateFormatter.format(matchday.date!.toLocal());
  final capitalizedDate = toBeginningOfSentenceCase(dateLabel) ?? dateLabel;
  final kickoffTime = (matchday.kickoffTime?.isNotEmpty ?? false)
      ? matchday.kickoffTime!
      : timeFormatter.format(matchday.date!.toLocal());
  return 'Próxima fecha: Fecha ${matchday.matchday} - $capitalizedDate - $kickoffTime';
}

String _positionLabel(int index) {
  final position = index + 1;
  switch (position) {
    case 1:
      return '🥇 $position';
    case 2:
      return '🥈 $position';
    case 3:
      return '🥉 $position';
    default:
      return '$position';
  }
}
