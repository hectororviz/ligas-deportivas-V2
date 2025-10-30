import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/zone_match_models.dart';
import 'zone_fixture_page.dart' show zoneMatchesProvider;

class ZoneMatchDetailPage extends ConsumerWidget {
  const ZoneMatchDetailPage({
    super.key,
    required this.zoneId,
    required this.matchId,
    this.initialMatch,
  });

  final int zoneId;
  final int matchId;
  final ZoneMatch? initialMatch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(zoneMatchesProvider(zoneId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del partido')),
      body: matchesAsync.when(
        data: (matches) {
          ZoneMatch? match = initialMatch;
          for (final item in matches) {
            if (item.id == matchId) {
              match = item;
              break;
            }
          }

          if (match == null) {
            return const Center(child: Text('Partido no encontrado.'));
          }

          return _ZoneMatchDetailContent(match: match);
        },
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
                    'Ocurrió un error al cargar el partido.',
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ZoneMatchDetailContent extends StatelessWidget {
  const _ZoneMatchDetailContent({required this.match});

  final ZoneMatch match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _ClubSummary(
                          club: match.homeClub,
                          pointsLabel: _formatPoints(match, isHome: true),
                          alignEnd: true,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Text(
                              'VS',
                              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Fecha ${match.matchday} · ${match.round.label}',
                              style: theme.textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _ClubSummary(
                          club: match.awayClub,
                          pointsLabel: _formatPoints(match, isHome: false),
                          alignEnd: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (match.categories.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'No hay categorías registradas para este partido.',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    _CategoriesTable(match: match),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatPoints(ZoneMatch match, {required bool isHome}) {
    final status = match.status?.toUpperCase();
    final finished = status == 'FINISHED';
    if (!finished) {
      return '—';
    }
    final points = isHome ? match.homePoints : match.awayPoints;
    return points == 1 ? '1 pt' : '$points pts';
  }
}

class _ClubSummary extends StatelessWidget {
  const _ClubSummary({
    required this.club,
    required this.pointsLabel,
    required this.alignEnd,
  });

  final FixtureClub? club;
  final String pointsLabel;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = alignEnd ? TextAlign.right : TextAlign.left;
    final name = club?.displayName ?? 'Por definir';
    return Column(
      crossAxisAlignment: alignment,
      children: [
        _ClubCrest(club: club),
        const SizedBox(height: 12),
        Text(
          name,
          textAlign: textAlign,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          pointsLabel,
          textAlign: textAlign,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ClubCrest extends StatelessWidget {
  const _ClubCrest({this.club});

  final FixtureClub? club;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const size = 72.0;

    if (club?.logoUrl != null && club!.logoUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          club.logoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _FallbackAvatar(name: club.displayName, club: club);
          },
        ),
      );
    }

    return _FallbackAvatar(name: club?.displayName ?? '—', club: club);
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({required this.name, required this.club});

  final String name;
  final FixtureClub? club;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const size = 72.0;
    final primary = club?.primaryColor ?? theme.colorScheme.primary;
    final secondary = club?.secondaryColor ?? theme.colorScheme.primaryContainer;
    final initials = _initialsFromName(name);
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: secondary.withOpacity(0.35),
      child: Text(
        initials,
        style: theme.textTheme.titleLarge?.copyWith(color: primary, fontWeight: FontWeight.bold),
      ),
    );
  }
}

String _initialsFromName(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
  if (words.isEmpty) {
    return '—';
  }
  if (words.length == 1) {
    final word = words.first;
    if (word.length >= 2) {
      return word.substring(0, 2).toUpperCase();
    }
    return word.substring(0, 1).toUpperCase();
  }
  final buffer = StringBuffer();
  for (final word in words.take(2)) {
    buffer.write(word[0]);
  }
  return buffer.toString().toUpperCase();
}

class _CategoriesTable extends StatelessWidget {
  const _CategoriesTable({required this.match});

  final ZoneMatch match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = match.categories;

    final borderColor = theme.colorScheme.outlineVariant.withOpacity(0.6);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(),
          2: FlexColumnWidth(),
        },
        border: TableBorder(
          top: BorderSide(color: borderColor),
          bottom: BorderSide(color: borderColor),
          left: BorderSide(color: borderColor),
          right: BorderSide(color: borderColor),
          horizontalInside: BorderSide(color: borderColor.withOpacity(0.7)),
          verticalInside: BorderSide(color: borderColor.withOpacity(0.7)),
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(color: theme.colorScheme.surfaceVariant.withOpacity(0.45)),
            children: const [
              _TableHeaderCell(label: 'Categoría', textAlign: TextAlign.left),
              _TableHeaderCell(label: 'Goles Local'),
              _TableHeaderCell(label: 'Goles Visitante'),
            ],
          ),
          for (final category in categories)
            TableRow(
              children: [
                _TableTextCell(label: category.categoryName),
                _ScoreCell(
                  score: category.homeScore,
                  outcome: _scoreOutcome(category.homeScore, category.awayScore),
                ),
                _ScoreCell(
                  score: category.awayScore,
                  outcome: _scoreOutcome(category.awayScore, category.homeScore),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  const _TableHeaderCell({required this.label, this.textAlign = TextAlign.center});

  final String label;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Text(
        label,
        textAlign: textAlign,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _TableTextCell extends StatelessWidget {
  const _TableTextCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Text(
        label,
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}

enum _ScoreOutcome { win, draw, loss }

_ScoreOutcome _scoreOutcome(int score, int opponentScore) {
  if (score > opponentScore) {
    return _ScoreOutcome.win;
  }
  if (score == opponentScore) {
    return _ScoreOutcome.draw;
  }
  return _ScoreOutcome.loss;
}

class _ScoreCell extends StatelessWidget {
  const _ScoreCell({required this.score, required this.outcome});

  final int score;
  final _ScoreOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = _backgroundColor(outcome);
    final foreground = _foregroundColor(outcome, theme);
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: background,
      child: Text(
        '$score',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }

  Color _backgroundColor(_ScoreOutcome outcome) {
    switch (outcome) {
      case _ScoreOutcome.win:
        return const Color(0xFFE8F5E9);
      case _ScoreOutcome.draw:
        return const Color(0xFFFFF8E1);
      case _ScoreOutcome.loss:
        return const Color(0xFFFFEBEE);
    }
  }

  Color _foregroundColor(_ScoreOutcome outcome, ThemeData theme) {
    switch (outcome) {
      case _ScoreOutcome.win:
        return const Color(0xFF2E7D32);
      case _ScoreOutcome.draw:
        return const Color(0xFFF9A825);
      case _ScoreOutcome.loss:
        return const Color(0xFFC62828);
    }
  }
}
