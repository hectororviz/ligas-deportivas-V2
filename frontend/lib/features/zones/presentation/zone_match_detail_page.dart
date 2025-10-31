import 'dart:math' as math;

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
    final fixtureAsync = ref.watch(zoneMatchesProvider(zoneId));
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final canEditScores =
        (user?.roles.contains('ADMIN') ?? false) || (user?.hasPermission(module: _moduleMatches, action: _actionUpdate) ?? false);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del partido')),
      body: fixtureAsync.when(
        data: (fixtureData) {
          ZoneMatch? match = initialMatch;
          for (final item in fixtureData.matches) {
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
  Future<void> _openGoalsDialog(ZoneMatchCategory category) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _MatchCategoryGoalsDialog(
        match: widget.match,
        category: category,
        canEdit: widget.canEditScores,
      ),
    );

    if (widget.canEditScores && saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Goles de "${category.categoryName}" actualizados.')),
      );
      ref.invalidate(zoneMatchesProvider(widget.zoneId));
    }
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
      3: const IntrinsicColumnWidth(),
    };

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
              const _TableHeaderCell(label: 'Goles'),
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
                _ActionCell(
                  onTap: () => _openGoalsDialog(category),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ActionCell extends StatelessWidget {
  const _ActionCell({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: FilledButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.sports_soccer_outlined),
        label: const Text('Goles'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: theme.textTheme.labelLarge,
        ),
      ),
    );
  }
}

class _PlayerGoalInput {
  _PlayerGoalInput({
    required this.playerId,
    required this.clubId,
    required this.fullName,
    this.goals = 0,
  });

  final int playerId;
  final int clubId;
  final String fullName;
  int goals;
}

class _RecordedPlayerGoal {
  _RecordedPlayerGoal({
    required this.playerId,
    required this.clubId,
    required this.goals,
    required this.fullName,
  });

  factory _RecordedPlayerGoal.fromJson(Map<String, dynamic> json) {
    final player = json['player'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final firstName = (player['firstName'] as String? ?? '').trim();
    final lastName = (player['lastName'] as String? ?? '').trim();
    final buffer = <String>[];
    if (lastName.isNotEmpty) {
      buffer.add(lastName.toUpperCase());
    }
    if (firstName.isNotEmpty) {
      buffer.add(firstName);
    }
    final composed = buffer.join(', ');
    final fallbackId = json['playerId'];
    return _RecordedPlayerGoal(
      playerId: json['playerId'] as int? ?? 0,
      clubId: json['clubId'] as int? ?? 0,
      goals: json['goals'] as int? ?? 0,
      fullName: composed.isNotEmpty
          ? composed
          : fallbackId != null
              ? 'Jugador $fallbackId'
              : 'Jugador',
    );
  }

  final int playerId;
  final int clubId;
  final int goals;
  final String fullName;
}

class _RecordedOtherGoal {
  _RecordedOtherGoal({
    required this.clubId,
    required this.goals,
  });

  factory _RecordedOtherGoal.fromJson(Map<String, dynamic> json) {
    return _RecordedOtherGoal(
      clubId: json['clubId'] as int? ?? 0,
      goals: json['goals'] as int? ?? 0,
    );
  }

  final int clubId;
  final int goals;
}

class _MatchCategoryResult {
  _MatchCategoryResult({
    required this.homeClubId,
    required this.awayClubId,
    required this.playerGoals,
    required this.otherGoals,
  });

  factory _MatchCategoryResult.fromJson(Map<String, dynamic> json) {
    return _MatchCategoryResult(
      homeClubId: json['homeClubId'] as int?,
      awayClubId: json['awayClubId'] as int?,
      playerGoals: (json['playerGoals'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(_RecordedPlayerGoal.fromJson)
          .toList(),
      otherGoals: (json['otherGoals'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(_RecordedOtherGoal.fromJson)
          .toList(),
    );
  }

  final int? homeClubId;
  final int? awayClubId;
  final List<_RecordedPlayerGoal> playerGoals;
  final List<_RecordedOtherGoal> otherGoals;
}

class _MatchCategoryGoalsDialog extends ConsumerStatefulWidget {
  const _MatchCategoryGoalsDialog({
    required this.match,
    required this.category,
    required this.canEdit,
  });

  final ZoneMatch match;
  final ZoneMatchCategory category;
  final bool canEdit;

  @override
  ConsumerState<_MatchCategoryGoalsDialog> createState() => _MatchCategoryGoalsDialogState();
}

class _MatchCategoryGoalsDialogState extends ConsumerState<_MatchCategoryGoalsDialog> {
  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;
  List<_PlayerGoalInput> _homeEntries = const <_PlayerGoalInput>[];
  List<_PlayerGoalInput> _awayEntries = const <_PlayerGoalInput>[];
  int _homeOtherGoals = 0;
  int _awayOtherGoals = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  int get _homeTotal => _homeEntries.fold<int>(0, (sum, entry) => sum + entry.goals) + _homeOtherGoals;

  int get _awayTotal => _awayEntries.fold<int>(0, (sum, entry) => sum + entry.goals) + _awayOtherGoals;

  Future<void> _loadData() async {
    final homeClubId = widget.match.homeClub?.id;
    final awayClubId = widget.match.awayClub?.id;
    if (homeClubId == null || awayClubId == null) {
      setState(() {
        _errorMessage = 'El partido no tiene clubes definidos.';
        _loading = false;
      });
      return;
    }

    try {
      final api = ref.read(apiClientProvider);
      final resultFuture = api.get<Map<String, dynamic>>(
        '/matches/${widget.match.id}/categories/${widget.category.id}/result',
      );
      final homePlayersFuture = api.get<Map<String, dynamic>>(
        '/clubs/$homeClubId/tournament-categories/${widget.category.tournamentCategoryId}/eligible-players',
        queryParameters: {
          'page': 1,
          'pageSize': 200,
          'onlyEnabled': true,
        },
      );
      final awayPlayersFuture = api.get<Map<String, dynamic>>(
        '/clubs/$awayClubId/tournament-categories/${widget.category.tournamentCategoryId}/eligible-players',
        queryParameters: {
          'page': 1,
          'pageSize': 200,
          'onlyEnabled': true,
        },
      );

      final resultResponse = await resultFuture;
      final homePlayersResponse = await homePlayersFuture;
      final awayPlayersResponse = await awayPlayersFuture;

      final result = _MatchCategoryResult.fromJson(resultResponse.data ?? <String, dynamic>{});
      final homeEntries = _parseEligiblePlayers(homePlayersResponse.data, homeClubId);
      final awayEntries = _parseEligiblePlayers(awayPlayersResponse.data, awayClubId);

      _applyRecordedGoals(homeEntries, result.playerGoals, homeClubId);
      _applyRecordedGoals(awayEntries, result.playerGoals, awayClubId);

      final homeOther = _findOtherGoals(result.otherGoals, homeClubId);
      final awayOther = _findOtherGoals(result.otherGoals, awayClubId);

      setState(() {
        _homeEntries = homeEntries;
        _awayEntries = awayEntries;
        _homeOtherGoals = homeOther;
        _awayOtherGoals = awayOther;
        _loading = false;
      });
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = mapDioError(error);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = '$error';
        _loading = false;
      });
    }
  }

  List<_PlayerGoalInput> _parseEligiblePlayers(Map<String, dynamic>? data, int clubId) {
    final players = <_PlayerGoalInput>[];
    final rawPlayers = data != null ? data['players'] as List<dynamic>? : null;
    for (final item in rawPlayers ?? const []) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      players.add(_PlayerGoalInput(
        playerId: item['id'] as int? ?? 0,
        clubId: clubId,
        fullName: _formatPlayerName(item),
      ));
    }
    players.sort((a, b) => a.fullName.compareTo(b.fullName));
    return players;
  }

  void _applyRecordedGoals(List<_PlayerGoalInput> entries, List<_RecordedPlayerGoal> recorded, int clubId) {
    for (final goal in recorded.where((item) => item.clubId == clubId)) {
      final index = entries.indexWhere((entry) => entry.playerId == goal.playerId);
      if (index >= 0) {
        entries[index].goals = goal.goals;
      } else {
        entries.add(_PlayerGoalInput(
          playerId: goal.playerId,
          clubId: clubId,
          fullName: goal.fullName,
          goals: goal.goals,
        ));
      }
    }
    entries.sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  int _findOtherGoals(List<_RecordedOtherGoal> goals, int clubId) {
    for (final goal in goals) {
      if (goal.clubId == clubId) {
        return goal.goals;
      }
    }
    return 0;
  }

  String _formatPlayerName(Map<String, dynamic> json) {
    final lastName = (json['lastName'] as String? ?? '').trim();
    final firstName = (json['firstName'] as String? ?? '').trim();
    if (lastName.isEmpty && firstName.isEmpty) {
      final id = json['id'];
      return id != null ? 'Jugador $id' : 'Jugador';
    }
    if (lastName.isEmpty) {
      return firstName;
    }
    if (firstName.isEmpty) {
      return lastName.toUpperCase();
    }
    return '${lastName.toUpperCase()}, $firstName';
  }

  void _updateHomeOtherGoals(int value) {
    setState(() {
      _homeOtherGoals = value;
    });
  }

  void _updateAwayOtherGoals(int value) {
    setState(() {
      _awayOtherGoals = value;
    });
  }

  Future<void> _onSave() async {
    if (!widget.canEdit) {
      Navigator.of(context).pop(false);
      return;
    }
    final homeClubId = widget.match.homeClub?.id;
    final awayClubId = widget.match.awayClub?.id;
    if (homeClubId == null || awayClubId == null) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _saving = true;
    });

    try {
      final api = ref.read(apiClientProvider);
      final playerGoals = <Map<String, dynamic>>[
        for (final entry in _homeEntries)
          if (entry.goals > 0)
            {
              'playerId': entry.playerId,
              'clubId': homeClubId,
              'goals': entry.goals,
            },
        for (final entry in _awayEntries)
          if (entry.goals > 0)
            {
              'playerId': entry.playerId,
              'clubId': awayClubId,
              'goals': entry.goals,
            },
      ];

      final otherGoals = <Map<String, dynamic>>[];
      if (_homeOtherGoals > 0) {
        otherGoals.add({'clubId': homeClubId, 'goals': _homeOtherGoals});
      }
      if (_awayOtherGoals > 0) {
        otherGoals.add({'clubId': awayClubId, 'goals': _awayOtherGoals});
      }

      await api.post(
        '/matches/${widget.match.id}/categories/${widget.category.id}/result',
        data: {
          'homeScore': _homeTotal,
          'awayScore': _awayTotal,
          'confirm': true,
          'playerGoals': playerGoals,
          'otherGoals': otherGoals,
        },
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      final message = mapDioError(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron guardar los goles: $message')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron guardar los goles: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Widget _buildGoalsColumn({
    required String title,
    required List<_PlayerGoalInput> entries,
    required int otherGoals,
    required ValueChanged<int> onOtherGoalsChanged,
    required bool enableEditing,
  }) {
    final theme = Theme.of(context);
    final listHeight = math.min(280.0, entries.length * 48.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.45),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: const [
                    Expanded(child: Text('Jugador')),
                    SizedBox(width: 80, child: Text('Goles', textAlign: TextAlign.center)),
                  ],
                ),
              ),
              if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
                  child: Text(
                    'Sin jugadores disponibles.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                SizedBox(
                  height: listHeight,
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: entries.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 1,
                      color: theme.colorScheme.outlineVariant.withOpacity(0.6),
                    ),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.fullName,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                key: ValueKey('${entry.clubId}-${entry.playerId}'),
                                initialValue: entry.goals.toString(),
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                enabled: enableEditing,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: !enableEditing
                                    ? null
                                    : (value) {
                                        final parsed = int.tryParse(value) ?? 0;
                                        setState(() {
                                          entry.goals = parsed;
                                        });
                                      },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.7))),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Otros goles',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        key: ValueKey('${title}_other_goals'),
                        initialValue: otherGoals.toString(),
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        enabled: enableEditing,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: !enableEditing
                            ? null
                            : (value) {
                                final parsed = int.tryParse(value) ?? 0;
                                onOtherGoalsChanged(parsed);
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _loading
        ? const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          )
        : _errorMessage != null
            ? SizedBox(
                height: 160,
                child: Center(
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildGoalsColumn(
                            title: widget.match.homeDisplayName,
                            entries: _homeEntries,
                            otherGoals: _homeOtherGoals,
                            onOtherGoalsChanged: _updateHomeOtherGoals,
                            enableEditing: widget.canEdit,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildGoalsColumn(
                            title: widget.match.awayDisplayName,
                            entries: _awayEntries,
                            otherGoals: _awayOtherGoals,
                            onOtherGoalsChanged: _updateAwayOtherGoals,
                            enableEditing: widget.canEdit,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total local: $_homeTotal', style: Theme.of(context).textTheme.titleMedium),
                        Text('Total visitante: $_awayTotal', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  ],
                ),
              );

    return AlertDialog(
      title: Text('Goles · ${widget.category.categoryName}'),
      content: SizedBox(width: 720, child: content),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(widget.canEdit ? 'Cancelar' : 'Cerrar'),
        ),
        if (widget.canEdit)
          FilledButton(
            onPressed: _saving || _loading || _errorMessage != null ? null : _onSave,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar'),
          ),
      ],
    );
  }
}

String mapDioError(DioException error) {
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

Color _scoreBackgroundColor(_ScoreOutcome outcome) {
  if (outcome == _ScoreOutcome.win) {
    return const Color(0xFFE8F5E9);
  }
  if (outcome == _ScoreOutcome.draw) {
    return const Color(0xFFFFF8E1);
  }
  return const Color(0xFFFFEBEE);
}

Color _scoreForegroundColor(_ScoreOutcome outcome) {
  if (outcome == _ScoreOutcome.win) {
    return const Color(0xFF2E7D32);
  }
  if (outcome == _ScoreOutcome.draw) {
    return const Color(0xFFF9A825);
  }
  return const Color(0xFFC62828);
}

class _ScoreCell extends StatelessWidget {
  const _ScoreCell({required this.score, required this.outcome});

  final int score;
  final _ScoreOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = _scoreBackgroundColor(outcome);
    final foreground = _scoreForegroundColor(outcome);
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

}
