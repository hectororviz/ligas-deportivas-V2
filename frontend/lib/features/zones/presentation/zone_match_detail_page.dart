import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/zone_match_models.dart';
import 'zone_fixture_page.dart' show zoneMatchesProvider;
import '../../../services/api_client.dart';
import '../../../services/auth_controller.dart';

const _moduleMatches = 'PARTIDOS';
const _actionUpdate = 'UPDATE';

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
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final canEditScores =
        (user?.roles.contains('ADMIN') ?? false) || (user?.hasPermission(module: _moduleMatches, action: _actionUpdate) ?? false);

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

          return _ZoneMatchDetailContent(
            match: match,
            zoneId: zoneId,
            canEditScores: canEditScores,
          );
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

class _ZoneMatchDetailContent extends ConsumerWidget {
  const _ZoneMatchDetailContent({
    required this.match,
    required this.zoneId,
    required this.canEditScores,
  });

  final ZoneMatch match;
  final int zoneId;
  final bool canEditScores;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    _CategoriesTable(
                      match: match,
                      zoneId: zoneId,
                      canEditScores: canEditScores,
                    ),
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

    final logoUrl = club?.logoUrl;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          logoUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _FallbackAvatar(name: club?.displayName ?? '—', club: club);
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

class _CategoriesTable extends ConsumerStatefulWidget {
  const _CategoriesTable({
    required this.match,
    required this.zoneId,
    required this.canEditScores,
  });

  final ZoneMatch match;
  final int zoneId;
  final bool canEditScores;

  @override
  ConsumerState<_CategoriesTable> createState() => _CategoriesTableState();
}

class _CategoriesTableState extends ConsumerState<_CategoriesTable> {
  final Map<int, TextEditingController> _homeControllers = {};
  final Map<int, TextEditingController> _awayControllers = {};
  final Map<int, int> _initialHomeScores = {};
  final Map<int, int> _initialAwayScores = {};
  final Set<int> _savingCategoryIds = <int>{};

  @override
  void initState() {
    super.initState();
    if (widget.canEditScores) {
      _initializeControllers();
    }
  }

  @override
  void didUpdateWidget(covariant _CategoriesTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.canEditScores && widget.canEditScores) {
      _initializeControllers();
      return;
    }
    if (oldWidget.canEditScores && !widget.canEditScores) {
      _disposeControllers();
      return;
    }
    if (widget.canEditScores) {
      _synchronizeControllers();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _initializeControllers() {
    _disposeControllers();
    for (final category in widget.match.categories) {
      final homeController = TextEditingController(text: '${category.homeScore}');
      final awayController = TextEditingController(text: '${category.awayScore}');
      homeController.addListener(_onScoreChanged);
      awayController.addListener(_onScoreChanged);
      _homeControllers[category.id] = homeController;
      _awayControllers[category.id] = awayController;
      _initialHomeScores[category.id] = category.homeScore;
      _initialAwayScores[category.id] = category.awayScore;
    }
  }

  void _synchronizeControllers() {
    final currentIds = widget.match.categories.map((category) => category.id).toSet();
    final existingIds = _homeControllers.keys.toSet();
    if (currentIds.length != existingIds.length || !currentIds.containsAll(existingIds)) {
      _initializeControllers();
      return;
    }

    for (final category in widget.match.categories) {
      final homeController = _homeControllers[category.id]!;
      final awayController = _awayControllers[category.id]!;

      final homeText = '${category.homeScore}';
      final awayText = '${category.awayScore}';

      if (!_savingCategoryIds.contains(category.id) && homeController.text != homeText) {
        homeController.value = TextEditingValue(
          text: homeText,
          selection: TextSelection.collapsed(offset: homeText.length),
        );
      }

      if (!_savingCategoryIds.contains(category.id) && awayController.text != awayText) {
        awayController.value = TextEditingValue(
          text: awayText,
          selection: TextSelection.collapsed(offset: awayText.length),
        );
      }

      _initialHomeScores[category.id] = category.homeScore;
      _initialAwayScores[category.id] = category.awayScore;
    }
  }

  void _disposeControllers() {
    for (final controller in _homeControllers.values) {
      controller.removeListener(_onScoreChanged);
      controller.dispose();
    }
    for (final controller in _awayControllers.values) {
      controller.removeListener(_onScoreChanged);
      controller.dispose();
    }
    _homeControllers.clear();
    _awayControllers.clear();
    _initialHomeScores.clear();
    _initialAwayScores.clear();
  }

  void _onScoreChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  bool _hasChanges(ZoneMatchCategory category) {
    final homeValue = int.tryParse(_homeControllers[category.id]?.text ?? '') ?? 0;
    final awayValue = int.tryParse(_awayControllers[category.id]?.text ?? '') ?? 0;
    final initialHome = _initialHomeScores[category.id] ?? category.homeScore;
    final initialAway = _initialAwayScores[category.id] ?? category.awayScore;
    return homeValue != initialHome || awayValue != initialAway;
  }

  _ScoreOutcome _homeOutcomeFor(ZoneMatchCategory category) {
    final homeValue = int.tryParse(_homeControllers[category.id]?.text ?? '') ?? 0;
    final awayValue = int.tryParse(_awayControllers[category.id]?.text ?? '') ?? 0;
    return _scoreOutcome(homeValue, awayValue);
  }

  _ScoreOutcome _awayOutcomeFor(ZoneMatchCategory category) {
    final homeValue = int.tryParse(_homeControllers[category.id]?.text ?? '') ?? 0;
    final awayValue = int.tryParse(_awayControllers[category.id]?.text ?? '') ?? 0;
    return _scoreOutcome(awayValue, homeValue);
  }

  Future<void> _saveCategory(ZoneMatchCategory category) async {
    if (!widget.canEditScores) {
      return;
    }

    final homeValue = int.tryParse(_homeControllers[category.id]?.text ?? '') ?? 0;
    final awayValue = int.tryParse(_awayControllers[category.id]?.text ?? '') ?? 0;

    if (homeValue < 0 || awayValue < 0) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Los marcadores deben ser mayores o iguales a cero.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _savingCategoryIds.add(category.id);
    });

    try {
      final api = ref.read(apiClientProvider);
      await api.post(
        '/matches/${widget.match.id}/categories/${category.id}/result',
        data: {
          'homeScore': homeValue,
          'awayScore': awayValue,
          'confirm': true,
          'playerGoals': const [],
          'otherGoals': const [],
        },
      );

      if (!mounted) {
        return;
      }

      _initialHomeScores[category.id] = homeValue;
      _initialAwayScores[category.id] = awayValue;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marcador de "${category.categoryName}" actualizado.')),
      );

      ref.invalidate(zoneMatchesProvider(widget.zoneId));
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      final message = _mapError(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el marcador: $message')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el marcador: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingCategoryIds.remove(category.id);
        });
      }
    }
  }

  String _mapError(DioException error) {
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
      if (message is List) {
        final first = message.cast<Object?>().firstWhere(
              (item) => item is String && item.isNotEmpty,
              orElse: () => null,
            );
        if (first is String && first.isNotEmpty) {
          return first;
        }
      }
    }
    if (error.message != null && error.message!.isNotEmpty) {
      return error.message!;
    }
    return 'Ocurrió un error inesperado. Intenta nuevamente.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = widget.match.categories;

    final borderColor = theme.colorScheme.outlineVariant.withOpacity(0.6);

    final columnWidths = <int, TableColumnWidth>{
      0: const FlexColumnWidth(2),
      1: const FlexColumnWidth(),
      2: const FlexColumnWidth(),
    };
    if (widget.canEditScores) {
      columnWidths[3] = const IntrinsicColumnWidth();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Table(
        columnWidths: columnWidths,
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
            children: [
              const _TableHeaderCell(label: 'Categoría', textAlign: TextAlign.left),
              const _TableHeaderCell(label: 'Goles Local'),
              const _TableHeaderCell(label: 'Goles Visitante'),
              if (widget.canEditScores)
                const _TableHeaderCell(label: 'Acciones'),
            ],
          ),
          for (final category in categories)
            TableRow(
              children: [
                _TableTextCell(label: category.categoryName),
                if (widget.canEditScores)
                  _ScoreInputCell(
                    controller: _homeControllers[category.id]!,
                    outcome: _homeOutcomeFor(category),
                    enabled: !_savingCategoryIds.contains(category.id),
                  )
                else
                  _ScoreCell(
                    score: category.homeScore,
                    outcome: _scoreOutcome(category.homeScore, category.awayScore),
                  ),
                if (widget.canEditScores)
                  _ScoreInputCell(
                    controller: _awayControllers[category.id]!,
                    outcome: _awayOutcomeFor(category),
                    enabled: !_savingCategoryIds.contains(category.id),
                  )
                else
                  _ScoreCell(
                    score: category.awayScore,
                    outcome: _scoreOutcome(category.awayScore, category.homeScore),
                  ),
                if (widget.canEditScores)
                  _ActionCell(
                    onSave: _hasChanges(category) && !_savingCategoryIds.contains(category.id)
                        ? () => _saveCategory(category)
                        : null,
                    saving: _savingCategoryIds.contains(category.id),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ScoreInputCell extends StatelessWidget {
  const _ScoreInputCell({
    required this.controller,
    required this.outcome,
    required this.enabled,
  });

  final TextEditingController controller;
  final _ScoreOutcome outcome;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = _backgroundColor(outcome);
    final foreground = _foregroundColor(outcome, theme);

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: background,
      child: SizedBox(
        width: 72,
        child: TextFormField(
          controller: controller,
          enabled: enabled,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: const [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(),
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

class _ActionCell extends StatelessWidget {
  const _ActionCell({
    required this.onSave,
    required this.saving,
  });

  final VoidCallback? onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (saving) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: IconButton(
        onPressed: onSave,
        icon: const Icon(Icons.save_outlined),
        color: onSave != null ? theme.colorScheme.primary : theme.disabledColor,
        tooltip: 'Guardar marcador',
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
