import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/responsive.dart';
import '../../../services/api_client.dart';
import '../domain/zone_models.dart';
import 'manual_fixture_models.dart';
import 'zone_providers.dart';

class ManualFixtureBuilderPage extends ConsumerStatefulWidget {
  const ManualFixtureBuilderPage({super.key, required this.zoneId});

  final int zoneId;

  @override
  ConsumerState<ManualFixtureBuilderPage> createState() => _ManualFixtureBuilderPageState();
}

class _ManualFixtureBuilderPageState extends ConsumerState<ManualFixtureBuilderPage> {
  FixtureMeta? _meta;
  List<ManualFixtureDate> _round1Dates = [];
  int _selectedDateIndex = 0;
  String _searchText = '';
  bool _saving = false;
  String? _errorMessage;

  void _initializeFixture(ZoneDetail zone) {
    if (_meta != null && _round1Dates.isNotEmpty) {
      return;
    }
    final meta = computeFixtureMeta(zone.clubs.length);
    _meta = meta;
    _round1Dates = List.generate(
      meta.totalDates,
      (index) => ManualFixtureDate(
        dateNumber: index + 1,
        matches: List.generate(
          meta.matchesPerDate,
          (matchIndex) => ManualFixtureMatchSlot(index: matchIndex),
        ),
      ),
    );
  }

  Future<void> _saveFixture(ZoneDetail zone) async {
    final meta = _meta;
    if (meta == null || _saving) {
      return;
    }
    final clubIds = zone.clubs.map((club) => club.id).toList();
    final globalValidation = validateAll(_round1Dates, clubIds, meta);
    final dateValidations = _round1Dates
        .map((date) => validateDate(date, clubIds, meta, _round1Dates))
        .toList();
    final hasIncomplete = dateValidations.any((result) => !result.isComplete);
    final hasInvalid = dateValidations.any((result) => !result.isValid);
    if (hasIncomplete || hasInvalid || !globalValidation.isValid) {
      setState(() {
        _errorMessage = 'Corregí los errores antes de guardar el fixture.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final round2 = buildRound2FromRound1(_round1Dates);
      final offset = meta.totalDates;
      final matchdays = <Map<String, dynamic>>[];

      for (final date in _round1Dates) {
        matchdays.add(_serializeMatchday(date, 'FIRST', date.dateNumber));
      }
      for (final date in round2) {
        matchdays.add(_serializeMatchday(date, 'SECOND', date.dateNumber + offset));
      }

      await api.post(
        '/zones/${widget.zoneId}/fixture/manual',
        data: {
          'doubleRound': true,
          'matchdays': matchdays,
        },
      );

      if (!mounted) {
        return;
      }
      ref.invalidate(zoneMatchesProvider(widget.zoneId));
      ref.invalidate(zoneDetailProvider(widget.zoneId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fixture manual guardado correctamente.')),
      );
      GoRouter.of(context).pop();
    } on DioException catch (error) {
      setState(() {
        _errorMessage = 'Error al guardar el fixture: ${_mapError(error)}';
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Error al guardar el fixture: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Map<String, dynamic> _serializeMatchday(
    ManualFixtureDate date,
    String round,
    int matchdayNumber,
  ) {
    return {
      'round': round,
      'matchday': matchdayNumber,
      'matches': date.matches
          .where((match) => match.homeClubId != null && match.awayClubId != null)
          .map(
            (match) => {
              'homeClubId': match.homeClubId,
              'awayClubId': match.awayClubId,
            },
          )
          .toList(),
      if (date.byeClubId != null) 'byeClubId': date.byeClubId,
    };
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
        if (first is String) {
          return first;
        }
      }
    }
    return error.message ?? 'Ocurrió un error inesperado.';
  }

  void _handleDrop(int clubId, ManualFixtureDropTarget target) {
    final meta = _meta;
    if (meta == null) {
      return;
    }
    final validation = validateDrop(
      clubId: clubId,
      target: target,
      dates: _round1Dates,
      meta: meta,
    );
    if (!validation.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation.reason ?? 'No se pudo asignar el club.')),
      );
      return;
    }
    setState(() {
      final date = _round1Dates[target.dateIndex];
      if (target.type == ManualFixtureDropType.bye) {
        _round1Dates[target.dateIndex] = date.copyWith(byeClubId: clubId);
        return;
      }
      if (target.matchIndex == null) {
        return;
      }
      final updatedMatches = [...date.matches];
      final match = updatedMatches[target.matchIndex!];
      if (target.type == ManualFixtureDropType.home) {
        updatedMatches[target.matchIndex!] = match.copyWith(homeClubId: clubId);
      } else {
        updatedMatches[target.matchIndex!] = match.copyWith(awayClubId: clubId);
      }
      _round1Dates[target.dateIndex] = date.copyWith(matches: updatedMatches);
    });
  }

  void _clearMatch(int dateIndex, int matchIndex) {
    setState(() {
      final date = _round1Dates[dateIndex];
      final updatedMatches = [...date.matches];
      updatedMatches[matchIndex] = ManualFixtureMatchSlot(index: matchIndex);
      _round1Dates[dateIndex] = date.copyWith(matches: updatedMatches);
    });
  }

  void _clearSlot(int dateIndex, int matchIndex, ManualFixtureDropType type) {
    setState(() {
      final date = _round1Dates[dateIndex];
      final updatedMatches = [...date.matches];
      final match = updatedMatches[matchIndex];
      if (type == ManualFixtureDropType.home) {
        updatedMatches[matchIndex] = match.copyWith(homeClubId: null);
      } else if (type == ManualFixtureDropType.away) {
        updatedMatches[matchIndex] = match.copyWith(awayClubId: null);
      }
      _round1Dates[dateIndex] = date.copyWith(matches: updatedMatches);
    });
  }

  void _clearBye(int dateIndex) {
    setState(() {
      final date = _round1Dates[dateIndex];
      _round1Dates[dateIndex] = date.copyWith(byeClubId: null);
    });
  }

  void _swapMatch(int dateIndex, int matchIndex) {
    setState(() {
      final date = _round1Dates[dateIndex];
      final updatedMatches = [...date.matches];
      final match = updatedMatches[matchIndex];
      updatedMatches[matchIndex] = match.copyWith(
        homeClubId: match.awayClubId,
        awayClubId: match.homeClubId,
      );
      _round1Dates[dateIndex] = date.copyWith(matches: updatedMatches);
    });
  }

  List<ZoneClub> _filteredClubs(List<ZoneClub> clubs) {
    if (_searchText.isEmpty) {
      return clubs;
    }
    final query = _searchText.toLowerCase();
    return clubs
        .where((club) => club.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final zoneAsync = ref.watch(zoneDetailProvider(widget.zoneId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generación Manual de Fixture – Ronda 1'),
      ),
      body: zoneAsync.when(
        data: (zone) {
          _initializeFixture(zone);
          final meta = _meta!;
          final clubs = zone.clubs;
          final clubIds = clubs.map((club) => club.id).toList();
          final filteredClubs = _filteredClubs(clubs);
          final round2Dates = buildRound2FromRound1(_round1Dates);
          final currentDate = _round1Dates[_selectedDateIndex];
          final dateValidation = validateDate(currentDate, clubIds, meta, _round1Dates);
          final globalValidation = validateAll(_round1Dates, clubIds, meta);
          final dateValidations = _round1Dates
              .map((date) => validateDate(date, clubIds, meta, _round1Dates))
              .toList();
          final allComplete = dateValidations.every((result) => result.isComplete);
          final allValid = dateValidations.every((result) => result.isValid) && globalValidation.isValid;
          final canSave = allComplete && allValid;
          final isWide = Responsive.isDesktop(context);
          final content = isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildClubPanel(zone, filteredClubs, meta)),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _buildDatePanel(zone, currentDate, dateValidation, meta)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildRoundPanel(globalValidation, round2Dates, meta, zone)),
                  ],
                )
              : Column(
                  children: [
                    _buildClubPanel(zone, filteredClubs, meta),
                    const SizedBox(height: 16),
                    _buildDatePanel(zone, currentDate, dateValidation, meta),
                    const SizedBox(height: 16),
                    _buildRoundPanel(globalValidation, round2Dates, meta, zone),
                  ],
                );

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeader(canSave, zone),
                  const SizedBox(height: 12),
                  _buildTabs(dateValidations),
                  const SizedBox(height: 16),
                  if (_errorMessage != null) ...[
                    _buildErrorBanner(_errorMessage!),
                    const SizedBox(height: 12),
                  ],
                  Expanded(child: content),
                ],
              ),
            ),
          );
        },
        error: (error, _) => Center(child: Text('Error al cargar la zona: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildHeader(bool canSave, ZoneDetail zone) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Editás solo la Ronda 1. La Ronda 2 se genera invirtiendo localías.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            FilledButton.icon(
              onPressed: canSave && !_saving ? () => _saveFixture(zone) : null,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Guardando...' : 'Guardar Fixture'),
            ),
            OutlinedButton.icon(
              onPressed: () => GoRouter.of(context).pop(),
              icon: const Icon(Icons.arrow_back_outlined),
              label: const Text('Cancelar / Volver'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabs(List<DateValidationResult> dateValidations) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dateValidations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final validation = dateValidations[index];
          final selected = index == _selectedDateIndex;
          final icon = validation.isValid
              ? (validation.isComplete ? Icons.check_circle : Icons.warning_amber)
              : Icons.error;
          final iconColor = validation.isValid
              ? (validation.isComplete ? Colors.green : Colors.orange)
              : Theme.of(context).colorScheme.error;
          return ChoiceChip(
            selected: selected,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 6),
                Text('Fecha ${index + 1}'),
              ],
            ),
            onSelected: (_) => setState(() => _selectedDateIndex = index),
          );
        },
      ),
    );
  }

  Widget _buildClubPanel(ZoneDetail zone, List<ZoneClub> clubs, FixtureMeta meta) {
    final currentDate = _round1Dates[_selectedDateIndex];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Clubes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar club...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _searchText = value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: clubs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final club = clubs[index];
                  final isAssigned = clubRoleForDate(currentDate, club.id) != null;
                  final previousRole = _selectedDateIndex > 0
                      ? clubRoleForDate(_round1Dates[_selectedDateIndex - 1], club.id)
                      : null;
                  return Opacity(
                    opacity: isAssigned ? 0.4 : 1,
                    child: Draggable<int>(
                      data: club.id,
                      feedback: _buildClubChip(club, dragging: true),
                      childWhenDragging: _buildClubChip(club, assigned: isAssigned, previousRole: previousRole),
                      maxSimultaneousDrags: isAssigned ? 0 : 1,
                      child: _buildClubChip(club, assigned: isAssigned, previousRole: previousRole),
                    ),
                  );
                },
              ),
            ),
            if (!meta.hasBye) ...[
              const SizedBox(height: 8),
              Text(
                'Sin libre porque la cantidad de clubes es par.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClubChip(
    ZoneClub club, {
    bool assigned = false,
    ManualFixtureClubRole? previousRole,
    bool dragging = false,
  }) {
    final roleLabel = switch (previousRole) {
      ManualFixtureClubRole.home => 'L',
      ManualFixtureClubRole.away => 'V',
      ManualFixtureClubRole.bye => 'Libre',
      null => null,
    };
    return Material(
      color: dragging ? Colors.white : Colors.transparent,
      child: ListTile(
        dense: true,
        leading: roleLabel == null
            ? const Icon(Icons.shield_outlined)
            : CircleAvatar(
                radius: 14,
                backgroundColor: Colors.blueGrey.shade100,
                child: Text(roleLabel, style: const TextStyle(fontSize: 10)),
              ),
        title: Text(club.shortName ?? club.name),
        subtitle: assigned ? const Text('Asignado') : null,
        trailing: assigned ? const Icon(Icons.check_circle, size: 18) : null,
      ),
    );
  }

  Widget _buildDatePanel(
    ZoneDetail zone,
    ManualFixtureDate date,
    DateValidationResult validation,
    FixtureMeta meta,
  ) {
    final clubIds = zone.clubs.map((club) => club.id).toList();
    final assignedIds = <int>{};
    for (final match in date.matches) {
      if (match.homeClubId != null) {
        assignedIds.add(match.homeClubId!);
      }
      if (match.awayClubId != null) {
        assignedIds.add(match.awayClubId!);
      }
    }
    if (date.byeClubId != null) {
      assignedIds.add(date.byeClubId!);
    }
    final missingClubs = clubIds.where((id) => !assignedIds.contains(id)).toList();
    final clubLookup = {for (final club in zone.clubs) club.id: club};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fecha ${date.dateNumber}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Asignados: ${assignedIds.length}/${clubIds.length}'),
            if (missingClubs.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Faltan: ${missingClubs.map((id) => clubLookup[id]?.shortName ?? clubLookup[id]?.name ?? id).join(', ')}',
              ),
            ],
            if (!validation.isValid) ...[
              const SizedBox(height: 8),
              Text(
                validation.errors.join(' '),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: date.matches.length + (meta.hasBye ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (meta.hasBye && index == date.matches.length) {
                    return _buildByeSlot(date, clubLookup);
                  }
                  final match = date.matches[index];
                  return _buildMatchSlot(match, index, clubLookup);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchSlot(
    ManualFixtureMatchSlot match,
    int matchIndex,
    Map<int, ZoneClub> clubLookup,
  ) {
    final dateIndex = _selectedDateIndex;
    return Row(
      children: [
        Expanded(
          child: _DropSlot(
            label: 'Local',
            clubId: match.homeClubId,
            clubName: _clubNameFor(match.homeClubId, clubLookup),
            target: ManualFixtureDropTarget(
              type: ManualFixtureDropType.home,
              dateIndex: dateIndex,
              matchIndex: matchIndex,
            ),
            onDrop: _handleDrop,
            onClear: match.homeClubId != null
                ? () => _clearSlot(dateIndex, matchIndex, ManualFixtureDropType.home)
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DropSlot(
            label: 'Visitante',
            clubId: match.awayClubId,
            clubName: _clubNameFor(match.awayClubId, clubLookup),
            target: ManualFixtureDropTarget(
              type: ManualFixtureDropType.away,
              dateIndex: dateIndex,
              matchIndex: matchIndex,
            ),
            onDrop: _handleDrop,
            onClear: match.awayClubId != null
                ? () => _clearSlot(dateIndex, matchIndex, ManualFixtureDropType.away)
                : null,
          ),
        ),
        IconButton(
          tooltip: 'Swap',
          onPressed: match.homeClubId != null && match.awayClubId != null ? () => _swapMatch(dateIndex, matchIndex) : null,
          icon: const Icon(Icons.swap_horiz_outlined),
        ),
        IconButton(
          tooltip: 'Limpiar partido',
          onPressed: match.homeClubId != null || match.awayClubId != null ? () => _clearMatch(dateIndex, matchIndex) : null,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }

  Widget _buildByeSlot(ManualFixtureDate date, Map<int, ZoneClub> clubLookup) {
    return Row(
      children: [
        Expanded(
          child: _DropSlot(
            label: 'Libre',
            clubId: date.byeClubId,
            clubName: _clubNameFor(date.byeClubId, clubLookup),
            target: ManualFixtureDropTarget(
              type: ManualFixtureDropType.bye,
              dateIndex: _selectedDateIndex,
            ),
            onDrop: _handleDrop,
            onClear: date.byeClubId != null ? () => _clearBye(_selectedDateIndex) : null,
          ),
        ),
      ],
    );
  }

  String? _clubNameFor(int? clubId, Map<int, ZoneClub> clubLookup) {
    if (clubId == null) {
      return null;
    }
    return clubLookup[clubId]?.shortName ?? clubLookup[clubId]?.name ?? 'Club $clubId';
  }

  Widget _buildRoundPanel(
    GlobalValidationResult validation,
    List<ManualFixtureDate> round2Dates,
    FixtureMeta meta,
    ZoneDetail zone,
  ) {
    final totalPairs = zone.clubs.length * (zone.clubs.length - 1) ~/ 2;
    final completedPairs = totalPairs - validation.missingPairs.length;
    final clubLookup = {for (final club in zone.clubs) club.id: club};
    final duplicateLabels = validation.duplicatePairs.keys
        .map((key) => _pairLabel(key, clubLookup))
        .where((label) => label.isNotEmpty)
        .toList();
    final missingLabels = validation.missingPairs
        .map((key) => _pairLabel(key, clubLookup))
        .where((label) => label.isNotEmpty)
        .toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estado de la ronda', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Cruces completos: $completedPairs / $totalPairs'),
            if (validation.duplicatePairs.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Cruces duplicados: ${duplicateLabels.join(', ')}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (validation.missingPairs.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Faltan cruces: ${missingLabels.join(', ')}'),
            ],
            if (meta.hasBye) ...[
              const SizedBox(height: 12),
              Text('Libres por equipo:'),
              ...validation.byeCounts.entries.map((entry) {
                final clubName = clubLookup[entry.key]?.shortName ?? clubLookup[entry.key]?.name ?? entry.key;
                final value = entry.value;
                final color = value == 1 ? Colors.green : Theme.of(context).colorScheme.error;
                return Text('$clubName: $value/1', style: TextStyle(color: color));
              }),
            ],
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text('Ver Ronda 2 (generada)'),
              children: round2Dates
                  .map(
                    (date) => ListTile(
                      title: Text('Fecha ${date.dateNumber}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...date.matches.map((match) {
                            final homeName = clubLookup[match.homeClubId]?.shortName ??
                                clubLookup[match.homeClubId]?.name ??
                                'Club ${match.homeClubId ?? '-'}';
                            final awayName = clubLookup[match.awayClubId]?.shortName ??
                                clubLookup[match.awayClubId]?.name ??
                                'Club ${match.awayClubId ?? '-'}';
                            return Text('$homeName vs $awayName');
                          }),
                          if (meta.hasBye && date.byeClubId != null)
                            Text('Libre: ${clubLookup[date.byeClubId]?.shortName ?? clubLookup[date.byeClubId]?.name}'),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _pairLabel(String key, Map<int, ZoneClub> clubLookup) {
    final parts = key.split('-');
    if (parts.length != 2) {
      return key;
    }
    final first = int.tryParse(parts[0]);
    final second = int.tryParse(parts[1]);
    if (first == null || second == null) {
      return key;
    }
    final firstName = clubLookup[first]?.shortName ?? clubLookup[first]?.name ?? 'Club $first';
    final secondName = clubLookup[second]?.shortName ?? clubLookup[second]?.name ?? 'Club $second';
    return '$firstName - $secondName';
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _DropSlot extends StatelessWidget {
  const _DropSlot({
    required this.label,
    required this.target,
    required this.onDrop,
    this.clubId,
    this.clubName,
    this.onClear,
  });

  final String label;
  final ManualFixtureDropTarget target;
  final void Function(int clubId, ManualFixtureDropTarget target) onDrop;
  final int? clubId;
  final String? clubName;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_ManualFixtureBuilderPageState>();
    return DragTarget<int>(
      onWillAccept: (clubId) {
        if (clubId == null || state == null) {
          return false;
        }
        final meta = state._meta;
        if (meta == null) {
          return false;
        }
        final result = validateDrop(
          clubId: clubId,
          target: target,
          dates: state._round1Dates,
          meta: meta,
        );
        return result.ok;
      },
      onAccept: (clubId) => onDrop(clubId, target),
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;
        final theme = Theme.of(context);
        final borderColor = isHighlighted ? theme.colorScheme.primary : theme.dividerColor;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  clubId != null ? clubName ?? 'Club $clubId' : 'Arrastrá un club ($label)',
                ),
              ),
              if (clubId != null && onClear != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClear,
                  tooltip: 'Quitar',
                ),
            ],
          ),
        );
      },
    );
  }
}
