import 'package:flutter/material.dart';

Color? _parseHexColor(String? hex) {
  if (hex == null || hex.isEmpty) {
    return null;
  }

  final buffer = StringBuffer();
  if (!hex.startsWith('#')) {
    buffer.write('#');
  }
  buffer.write(hex);
  final value = int.tryParse(buffer.toString().substring(1), radix: 16);
  if (value == null) {
    return null;
  }
  if (buffer.length == 7) {
    return Color(value + 0xFF000000);
  }
  if (buffer.length == 9) {
    return Color(value);
  }
  return null;
}

enum FixtureRound { first, second }

extension FixtureRoundX on FixtureRound {
  static FixtureRound fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'SECOND':
        return FixtureRound.second;
      default:
        return FixtureRound.first;
    }
  }

  String get label {
    switch (this) {
      case FixtureRound.first:
        return 'Rueda 1';
      case FixtureRound.second:
        return 'Rueda 2';
    }
  }
}

class FixtureClub {
  FixtureClub({
    required this.id,
    required this.name,
    this.shortName,
    this.logoUrl,
    this.primaryHex,
    this.secondaryHex,
  });

  factory FixtureClub.fromJson(Map<String, dynamic> json) {
    return FixtureClub(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Club',
      shortName: json['shortName'] as String?,
      logoUrl: json['logoUrl'] as String?,
      primaryHex: json['primaryColor'] as String?,
      secondaryHex: json['secondaryColor'] as String?,
    );
  }

  final int id;
  final String name;
  final String? shortName;
  final String? logoUrl;
  final String? primaryHex;
  final String? secondaryHex;

  String get displayName => (shortName != null && shortName!.isNotEmpty) ? shortName! : name;

  Color? get primaryColor => _parseHexColor(primaryHex);
  Color? get secondaryColor => _parseHexColor(secondaryHex);
}

class ZoneMatchCategory {
  ZoneMatchCategory({
    required this.id,
    required this.tournamentCategoryId,
    required this.categoryName,
    required this.homeScore,
    required this.awayScore,
    required this.isPromocional,
    this.kickoffTime,
    this.birthYearMin,
    this.birthYearMax,
  });

  factory ZoneMatchCategory.fromJson(Map<String, dynamic> json) {
    final tournamentCategory = json['tournamentCategory'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final category = tournamentCategory['category'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final name = category['name'] as String? ?? tournamentCategory['name'] as String? ?? 'Categoría';
    final birthYearMin = category['birthYearMin'] as int?;
    final birthYearMax = category['birthYearMax'] as int?;
    final homeScoreValue = json['homeScore'];
    final awayScoreValue = json['awayScore'];
    return ZoneMatchCategory(
      id: json['id'] as int? ?? 0,
      tournamentCategoryId: json['tournamentCategoryId'] as int? ?? json['id'] as int? ?? 0,
      categoryName: name,
      homeScore: homeScoreValue is num ? homeScoreValue.toInt() : null,
      awayScore: awayScoreValue is num ? awayScoreValue.toInt() : null,
      isPromocional: json['isPromocional'] as bool? ?? false,
      kickoffTime: json['kickoffTime'] as String?,
      birthYearMin: birthYearMin,
      birthYearMax: birthYearMax,
    );
  }

  final int id;
  final int tournamentCategoryId;
  final String categoryName;
  final int? homeScore;
  final int? awayScore;
  final bool isPromocional;
  final String? kickoffTime;
  final int? birthYearMin;
  final int? birthYearMax;

  int? get sortYear {
    if (birthYearMin != null && birthYearMax != null) {
      return birthYearMin! <= birthYearMax! ? birthYearMin : birthYearMax;
    }
    return birthYearMin ?? birthYearMax;
  }
}

class ZoneMatch {
  ZoneMatch({
    required this.id,
    required this.matchday,
    required this.round,
    required this.homeClub,
    required this.awayClub,
    required this.categories,
    this.date,
    this.status,
  });

  factory ZoneMatch.fromJson(Map<String, dynamic> json) {
    final categories = (json['categories'] as List<dynamic>? ?? <dynamic>[])
        .map((entry) => ZoneMatchCategory.fromJson(entry as Map<String, dynamic>))
        .toList();
    categories.sort((a, b) {
      final aYear = a.sortYear;
      final bYear = b.sortYear;
      if (aYear != null && bYear != null && aYear != bYear) {
        return aYear.compareTo(bYear);
      }
      if (aYear != null && bYear == null) {
        return -1;
      }
      if (aYear == null && bYear != null) {
        return 1;
      }
      return a.categoryName.compareTo(b.categoryName);
    });
    return ZoneMatch(
      id: json['id'] as int? ?? 0,
      matchday: json['matchday'] as int? ?? 0,
      round: FixtureRoundX.fromApi(json['round'] as String? ?? 'FIRST'),
      homeClub: json['homeClub'] != null ? FixtureClub.fromJson(json['homeClub'] as Map<String, dynamic>) : null,
      awayClub: json['awayClub'] != null ? FixtureClub.fromJson(json['awayClub'] as Map<String, dynamic>) : null,
      categories: categories,
      date: json['date'] != null ? DateTime.tryParse(json['date'] as String) : null,
      status: json['status'] as String?,
    );
  }

  final int id;
  final int matchday;
  final FixtureRound round;
  final FixtureClub? homeClub;
  final FixtureClub? awayClub;
  final List<ZoneMatchCategory> categories;
  final DateTime? date;
  final String? status;

  String get homeDisplayName => homeClub?.displayName ?? 'Por definir';
  String get awayDisplayName => awayClub?.displayName ?? 'Por definir';

  int get totalHomeGoals =>
      categories.fold(0, (total, category) => total + (category.homeScore ?? 0));
  int get totalAwayGoals =>
      categories.fold(0, (total, category) => total + (category.awayScore ?? 0));

  bool get _hasRecordedScores {
    if (categories.isEmpty) {
      return false;
    }
    for (final category in categories) {
      if (category.homeScore != null && category.awayScore != null) {
        return true;
      }
    }
    return false;
  }

  bool get hasRecordedScores => _hasRecordedScores;

  int get homePoints => _calculatePoints(isHome: true);

  int get awayPoints => _calculatePoints(isHome: false);

  int _calculatePoints({required bool isHome}) {
    var total = 0;
    for (final category in categories) {
      final homeScore = category.homeScore;
      final awayScore = category.awayScore;
      if (homeScore == null || awayScore == null) {
        continue;
      }
      if (homeScore == awayScore) {
        total += 1;
      } else if (isHome && homeScore > awayScore) {
        total += 3;
      } else if (!isHome && awayScore > homeScore) {
        total += 3;
      }
    }
    return total;
  }
}

enum ZoneMatchdayStatus { pending, inProgress, incomplete, played }

extension ZoneMatchdayStatusX on ZoneMatchdayStatus {
  static ZoneMatchdayStatus fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'IN_PROGRESS':
        return ZoneMatchdayStatus.inProgress;
      case 'INCOMPLETE':
        return ZoneMatchdayStatus.incomplete;
      case 'PLAYED':
        return ZoneMatchdayStatus.played;
      default:
        return ZoneMatchdayStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case ZoneMatchdayStatus.pending:
        return 'PENDIENTE';
      case ZoneMatchdayStatus.inProgress:
        return 'EN_PROGRESO';
      case ZoneMatchdayStatus.incomplete:
        return 'INCOMPLETA';
      case ZoneMatchdayStatus.played:
        return 'JUGADA';
    }
  }
}

class ZoneMatchdayState {
  ZoneMatchdayState({required this.matchday, required this.status, this.date});

  factory ZoneMatchdayState.fromJson(Map<String, dynamic> json) {
    final statusValue = json['status'] as String? ?? 'PENDING';
    return ZoneMatchdayState(
      matchday: json['matchday'] as int? ?? 0,
      status: ZoneMatchdayStatusX.fromApi(statusValue),
      date: json['date'] != null ? DateTime.tryParse(json['date'] as String) : null,
    );
  }

  final int matchday;
  final ZoneMatchdayStatus status;
  final DateTime? date;
}

class ZoneMatchesData {
  ZoneMatchesData({required this.matches, required this.matchdays});

  factory ZoneMatchesData.fromJson(Map<String, dynamic> json) {
    final matches = (json['matches'] as List<dynamic>? ?? <dynamic>[]) // ignore: implicit_dynamic_parameter
        .map((entry) => ZoneMatch.fromJson(entry as Map<String, dynamic>))
        .toList();
    final matchdays = (json['matchdays'] as List<dynamic>? ?? <dynamic>[]) // ignore: implicit_dynamic_parameter
        .map((entry) => ZoneMatchdayState.fromJson(entry as Map<String, dynamic>))
        .toList();
    return ZoneMatchesData(matches: matches, matchdays: matchdays);
  }

  final List<ZoneMatch> matches;
  final List<ZoneMatchdayState> matchdays;
}
