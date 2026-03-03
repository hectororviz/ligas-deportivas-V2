import 'package:flutter/foundation.dart';

enum ManualFixtureClubRole { home, away, bye }

enum ManualFixtureDropType { home, away, bye }

class FixtureMeta {
  FixtureMeta({
    required this.totalDates,
    required this.matchesPerDate,
    required this.hasBye,
  });

  final int totalDates;
  final int matchesPerDate;
  final bool hasBye;
}

class ManualFixtureMatchSlot {
  ManualFixtureMatchSlot({
    required this.index,
    this.homeClubId,
    this.awayClubId,
  });

  final int index;
  final int? homeClubId;
  final int? awayClubId;

  ManualFixtureMatchSlot copyWith({
    int? homeClubId,
    int? awayClubId,
  }) {
    return ManualFixtureMatchSlot(
      index: index,
      homeClubId: homeClubId ?? this.homeClubId,
      awayClubId: awayClubId ?? this.awayClubId,
    );
  }
}

class ManualFixtureDate {
  ManualFixtureDate({
    required this.dateNumber,
    required this.matches,
    this.byeClubId,
  });

  final int dateNumber;
  final List<ManualFixtureMatchSlot> matches;
  final int? byeClubId;

  ManualFixtureDate copyWith({
    List<ManualFixtureMatchSlot>? matches,
    int? byeClubId,
  }) {
    return ManualFixtureDate(
      dateNumber: dateNumber,
      matches: matches ?? this.matches,
      byeClubId: byeClubId,
    );
  }
}

class DateValidationResult {
  DateValidationResult({
    required this.isComplete,
    required this.isValid,
    required this.errors,
  });

  final bool isComplete;
  final bool isValid;
  final List<String> errors;
}

class GlobalValidationResult {
  GlobalValidationResult({
    required this.isValid,
    required this.errors,
    required this.duplicatePairs,
    required this.missingPairs,
    required this.byeCounts,
  });

  final bool isValid;
  final List<String> errors;
  final Map<String, List<int>> duplicatePairs;
  final Set<String> missingPairs;
  final Map<int, int> byeCounts;
}

FixtureMeta computeFixtureMeta(int clubCount) {
  final hasBye = clubCount.isOdd;
  final totalDates = hasBye ? clubCount : clubCount - 1;
  final matchesPerDate = clubCount ~/ 2;
  return FixtureMeta(
    totalDates: totalDates,
    matchesPerDate: matchesPerDate,
    hasBye: hasBye,
  );
}

ManualFixtureClubRole? clubRoleForDate(ManualFixtureDate date, int clubId) {
  if (date.byeClubId == clubId) {
    return ManualFixtureClubRole.bye;
  }
  for (final match in date.matches) {
    if (match.homeClubId == clubId) {
      return ManualFixtureClubRole.home;
    }
    if (match.awayClubId == clubId) {
      return ManualFixtureClubRole.away;
    }
  }
  return null;
}

String normalizePairKey(int homeId, int awayId) {
  final minId = homeId < awayId ? homeId : awayId;
  final maxId = homeId < awayId ? awayId : homeId;
  return '$minId-$maxId';
}

DateValidationResult validateDate(
  ManualFixtureDate date,
  List<int> clubIds,
  FixtureMeta meta,
  List<ManualFixtureDate> allDates,
) {
  final errors = <String>[];
  final usageCounts = <int, int>{for (final clubId in clubIds) clubId: 0};
  var complete = true;

  for (final match in date.matches) {
    if (match.homeClubId != null && match.awayClubId != null) {
      if (match.homeClubId == match.awayClubId) {
        errors.add('Un partido no puede tener Local y Visitante iguales.');
      }
    } else {
      complete = false;
    }
    if (match.homeClubId != null) {
      usageCounts[match.homeClubId!] = (usageCounts[match.homeClubId!] ?? 0) + 1;
    }
    if (match.awayClubId != null) {
      usageCounts[match.awayClubId!] = (usageCounts[match.awayClubId!] ?? 0) + 1;
    }
  }

  if (meta.hasBye) {
    if (date.byeClubId == null) {
      complete = false;
    } else {
      usageCounts[date.byeClubId!] = (usageCounts[date.byeClubId!] ?? 0) + 1;
    }
  }

  final duplicates = usageCounts.entries.where((entry) => entry.value > 1).toList();
  if (duplicates.isNotEmpty) {
    errors.add('Hay clubes repetidos en esta fecha.');
  }

  final missing = usageCounts.entries.where((entry) => entry.value == 0).toList();
  if (missing.isNotEmpty) {
    complete = false;
  }

  final dateIndex = date.dateNumber - 1;
  if (dateIndex > 0) {
    final previous = allDates[dateIndex - 1];
    for (final clubId in clubIds) {
      final currentRole = clubRoleForDate(date, clubId);
      final previousRole = clubRoleForDate(previous, clubId);
      if (currentRole == null || previousRole == null) {
        continue;
      }
      if (currentRole == ManualFixtureClubRole.bye || previousRole == ManualFixtureClubRole.bye) {
        continue;
      }
      if (currentRole == previousRole) {
        errors.add('El club $clubId repite condición en fechas consecutivas.');
        break;
      }
    }
  }

  if (dateIndex < allDates.length - 1) {
    final next = allDates[dateIndex + 1];
    for (final clubId in clubIds) {
      final currentRole = clubRoleForDate(date, clubId);
      final nextRole = clubRoleForDate(next, clubId);
      if (currentRole == null || nextRole == null) {
        continue;
      }
      if (currentRole == ManualFixtureClubRole.bye || nextRole == ManualFixtureClubRole.bye) {
        continue;
      }
      if (currentRole == nextRole) {
        errors.add('El club $clubId repite condición en fechas consecutivas.');
        break;
      }
    }
  }

  return DateValidationResult(
    isComplete: complete,
    isValid: errors.isEmpty,
    errors: errors,
  );
}

GlobalValidationResult validateAll(
  List<ManualFixtureDate> dates,
  List<int> clubIds,
  FixtureMeta meta,
) {
  final errors = <String>[];
  final pairs = <String, List<int>>{};
  final byeCounts = <int, int>{for (final clubId in clubIds) clubId: 0};

  for (final date in dates) {
    if (meta.hasBye && date.byeClubId != null) {
      byeCounts[date.byeClubId!] = (byeCounts[date.byeClubId!] ?? 0) + 1;
    }
    for (final match in date.matches) {
      if (match.homeClubId == null || match.awayClubId == null) {
        continue;
      }
      final key = normalizePairKey(match.homeClubId!, match.awayClubId!);
      pairs.putIfAbsent(key, () => []).add(date.dateNumber);
    }
  }

  final duplicatePairs = Map<String, List<int>>.fromEntries(
    pairs.entries.where((entry) => entry.value.length > 1),
  );
  if (duplicatePairs.isNotEmpty) {
    errors.add('Hay cruces duplicados en la ronda.');
  }

  final expectedPairs = <String>{};
  for (var i = 0; i < clubIds.length; i += 1) {
    for (var j = i + 1; j < clubIds.length; j += 1) {
      expectedPairs.add(normalizePairKey(clubIds[i], clubIds[j]));
    }
  }
  final missingPairs = expectedPairs.difference(pairs.keys.toSet());
  if (missingPairs.isNotEmpty) {
    errors.add('Faltan cruces por asignar en la ronda.');
  }

  if (meta.hasBye) {
    final invalidByes = byeCounts.entries.where((entry) => entry.value != 1).toList();
    if (invalidByes.isNotEmpty) {
      errors.add('Cada club debe tener un solo libre en la ronda.');
    }
  }

  return GlobalValidationResult(
    isValid: errors.isEmpty,
    errors: errors,
    duplicatePairs: duplicatePairs,
    missingPairs: missingPairs,
    byeCounts: byeCounts,
  );
}

@immutable
class ManualFixtureDropTarget {
  const ManualFixtureDropTarget({
    required this.type,
    required this.dateIndex,
    this.matchIndex,
  });

  final ManualFixtureDropType type;
  final int dateIndex;
  final int? matchIndex;
}

class DropValidationResult {
  DropValidationResult({required this.ok, this.reason});

  final bool ok;
  final String? reason;
}

DropValidationResult validateDrop({
  required int clubId,
  required ManualFixtureDropTarget target,
  required List<ManualFixtureDate> dates,
  required FixtureMeta meta,
}) {
  final date = dates[target.dateIndex];

  final alreadyUsed = clubRoleForDate(date, clubId) != null;
  if (alreadyUsed) {
    return DropValidationResult(ok: false, reason: 'El club ya fue asignado en esta fecha.');
  }

  if (target.type == ManualFixtureDropType.bye) {
    if (!meta.hasBye) {
      return DropValidationResult(ok: false, reason: 'Esta fecha no admite libres.');
    }
    final hasByeAlready = dates.any((entry) => entry.byeClubId == clubId);
    if (hasByeAlready) {
      return DropValidationResult(ok: false, reason: 'El club ya tuvo libre en la ronda.');
    }
  }

  ManualFixtureClubRole? newRole;
  if (target.type == ManualFixtureDropType.home) {
    newRole = ManualFixtureClubRole.home;
  } else if (target.type == ManualFixtureDropType.away) {
    newRole = ManualFixtureClubRole.away;
  }

  if (newRole != null && target.matchIndex != null) {
    final match = date.matches[target.matchIndex!];
    final otherId = target.type == ManualFixtureDropType.home ? match.awayClubId : match.homeClubId;
    if (otherId != null && otherId == clubId) {
      return DropValidationResult(ok: false, reason: 'No puedes enfrentar el mismo club consigo mismo.');
    }
  }

  if (newRole != null) {
    if (target.dateIndex > 0) {
      final previousRole = clubRoleForDate(dates[target.dateIndex - 1], clubId);
      if (previousRole != null &&
          previousRole != ManualFixtureClubRole.bye &&
          previousRole == newRole) {
        return DropValidationResult(
          ok: false,
          reason: 'No se permite repetir Local/Visitante en fechas consecutivas.',
        );
      }
    }
    if (target.dateIndex < dates.length - 1) {
      final nextRole = clubRoleForDate(dates[target.dateIndex + 1], clubId);
      if (nextRole != null && nextRole != ManualFixtureClubRole.bye && nextRole == newRole) {
        return DropValidationResult(
          ok: false,
          reason: 'No se permite repetir Local/Visitante en fechas consecutivas.',
        );
      }
    }
  }

  if (target.matchIndex != null && newRole != null) {
    final match = date.matches[target.matchIndex!];
    final prospectiveHome = target.type == ManualFixtureDropType.home ? clubId : match.homeClubId;
    final prospectiveAway = target.type == ManualFixtureDropType.away ? clubId : match.awayClubId;
    if (prospectiveHome != null && prospectiveAway != null) {
      final pairKey = normalizePairKey(prospectiveHome, prospectiveAway);
      for (var index = 0; index < dates.length; index += 1) {
        final dateEntry = dates[index];
        for (final existing in dateEntry.matches) {
          if (existing.homeClubId == null || existing.awayClubId == null) {
            continue;
          }
          final existingKey = normalizePairKey(existing.homeClubId!, existing.awayClubId!);
          if (existingKey == pairKey) {
            return DropValidationResult(
              ok: false,
              reason: 'Ese cruce ya existe en otra fecha.',
            );
          }
        }
      }
    }
  }

  return DropValidationResult(ok: true);
}

List<ManualFixtureDate> buildRound2FromRound1(
  List<ManualFixtureDate> round1Dates,
) {
  return round1Dates
      .map(
        (date) => ManualFixtureDate(
          dateNumber: date.dateNumber,
          byeClubId: date.byeClubId,
          matches: date.matches
              .map(
                (match) => ManualFixtureMatchSlot(
                  index: match.index,
                  homeClubId: match.awayClubId,
                  awayClubId: match.homeClubId,
                ),
              )
              .toList(),
        ),
      )
      .toList();
}
