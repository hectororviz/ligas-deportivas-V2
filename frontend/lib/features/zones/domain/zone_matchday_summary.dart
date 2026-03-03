import '../../standings/domain/standings_models.dart';
import 'zone_match_models.dart';

class ZoneMatchdaySummary {
  ZoneMatchdaySummary({
    required this.zone,
    required this.matchday,
    required this.matches,
    required this.scoreboard,
    required this.generalStandings,
    required this.categoryStandings,
  });

  factory ZoneMatchdaySummary.fromJson(Map<String, dynamic> json) {
    final matches = (json['matches'] as List<dynamic>? ?? <dynamic>[]) // ignore: implicit_dynamic_parameter
        .map((entry) => MatchdaySummaryMatch.fromJson(entry as Map<String, dynamic>))
        .toList();

    final scoreboard = json['scoreboard'] is Map<String, dynamic>
        ? MatchdayScoreboard.fromJson(json['scoreboard'] as Map<String, dynamic>)
        : MatchdayScoreboard.empty();

    final standingsJson = json['standings'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return ZoneMatchdaySummary(
      zone: ZoneStandingsInfo.fromJson(_asMap(json['zone'])),
      matchday: MatchdaySummaryInfo.fromJson(_asMap(json['matchday'])),
      matches: matches,
      scoreboard: scoreboard,
      generalStandings: _parseStandingsList(standingsJson['general']),
      categoryStandings: _parseCategoryStandingsList(standingsJson['categories']),
    );
  }

  final ZoneStandingsInfo zone;
  final MatchdaySummaryInfo matchday;
  final List<MatchdaySummaryMatch> matches;
  final MatchdayScoreboard scoreboard;
  final List<StandingsRow> generalStandings;
  final List<ZoneCategoryStandings> categoryStandings;
}

class MatchdaySummaryInfo {
  MatchdaySummaryInfo({
    required this.matchday,
    required this.status,
    this.date,
  });

  factory MatchdaySummaryInfo.fromJson(Map<String, dynamic> json) {
    return MatchdaySummaryInfo(
      matchday: _parseInt(json['matchday']),
      status: ZoneMatchdayStatusX.fromApi(json['status'] as String? ?? 'PENDING'),
      date: json['date'] != null ? DateTime.tryParse(json['date'] as String) : null,
    );
  }

  final int matchday;
  final ZoneMatchdayStatus status;
  final DateTime? date;
}

class MatchdaySummaryMatch {
  MatchdaySummaryMatch({
    required this.id,
    required this.round,
    required this.homeClub,
    required this.awayClub,
    required this.categories,
  });

  factory MatchdaySummaryMatch.fromJson(Map<String, dynamic> json) {
    return MatchdaySummaryMatch(
      id: _parseInt(json['id']),
      round: FixtureRoundX.fromApi(json['round'] as String? ?? 'FIRST'),
      homeClub: SummaryClub.fromJson(_asMap(json['homeClub'])),
      awayClub: SummaryClub.fromJson(_asMap(json['awayClub'])),
      categories: (json['categories'] as List<dynamic>? ?? <dynamic>[]) // ignore: implicit_dynamic_parameter
          .map((entry) => MatchdaySummaryCategory.fromJson(entry as Map<String, dynamic>))
          .toList(),
    );
  }

  final int id;
  final FixtureRound round;
  final SummaryClub? homeClub;
  final SummaryClub? awayClub;
  final List<MatchdaySummaryCategory> categories;
}

class SummaryClub {
  SummaryClub({
    required this.id,
    required this.name,
    this.shortName,
  });

  factory SummaryClub.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      return SummaryClub(id: 0, name: 'Por definir');
    }
    return SummaryClub(
      id: _parseInt(json['id']),
      name: _parseString(json['name'], fallback: 'Por definir'),
      shortName: _parseString(json['shortName']),
    );
  }

  final int id;
  final String name;
  final String? shortName;

  String get displayName => (shortName != null && shortName!.isNotEmpty) ? shortName! : name;
}

class MatchdaySummaryCategory {
  MatchdaySummaryCategory({
    required this.tournamentCategoryId,
    required this.categoryId,
    required this.categoryName,
    required this.countsForGeneral,
    required this.homeScore,
    required this.awayScore,
  });

  factory MatchdaySummaryCategory.fromJson(Map<String, dynamic> json) {
    return MatchdaySummaryCategory(
      tournamentCategoryId: _parseInt(json['tournamentCategoryId']),
      categoryId: _parseInt(json['categoryId']),
      categoryName: _parseString(json['categoryName'], fallback: 'Categoría'),
      countsForGeneral: _parseBool(json['countsForGeneral'], fallback: true),
      homeScore: _tryParseInt(json['homeScore']),
      awayScore: _tryParseInt(json['awayScore']),
    );
  }

  final int tournamentCategoryId;
  final int categoryId;
  final String categoryName;
  final bool countsForGeneral;
  final int? homeScore;
  final int? awayScore;
}

class MatchdayScoreboardCategory {
  MatchdayScoreboardCategory({
    required this.tournamentCategoryId,
    required this.categoryId,
    required this.categoryName,
    required this.countsForGeneral,
  });

  factory MatchdayScoreboardCategory.fromJson(Map<String, dynamic> json) {
    return MatchdayScoreboardCategory(
      tournamentCategoryId: _parseInt(json['tournamentCategoryId']),
      categoryId: _parseInt(json['categoryId']),
      categoryName: _parseString(json['categoryName'], fallback: 'Categoría'),
      countsForGeneral: _parseBool(json['countsForGeneral'], fallback: true),
    );
  }

  final int tournamentCategoryId;
  final int categoryId;
  final String categoryName;
  final bool countsForGeneral;
}

class MatchdayScoreboardRow {
  MatchdayScoreboardRow({
    required this.clubId,
    required this.clubName,
    required this.pointsTotal,
    required this.goalsByCategory,
  });

  factory MatchdayScoreboardRow.fromJson(Map<String, dynamic> json) {
    return MatchdayScoreboardRow(
      clubId: _parseInt(json['clubId']),
      clubName: _parseString(json['clubName'], fallback: 'Club'),
      pointsTotal: _parseInt(json['pointsTotal']),
      goalsByCategory: _parseGoalsByCategory(json['goalsByCategory']),
    );
  }

  final int clubId;
  final String clubName;
  final int pointsTotal;
  final Map<int, int?> goalsByCategory;
}

class MatchdayScoreboard {
  MatchdayScoreboard({
    required this.categories,
    required this.rows,
  });

  factory MatchdayScoreboard.fromJson(Map<String, dynamic> json) {
    return MatchdayScoreboard(
      categories: (json['categories'] as List<dynamic>? ?? <dynamic>[]) // ignore: implicit_dynamic_parameter
          .map((entry) => MatchdayScoreboardCategory.fromJson(entry as Map<String, dynamic>))
          .toList(),
      rows: (json['rows'] as List<dynamic>? ?? <dynamic>[]) // ignore: implicit_dynamic_parameter
          .map((entry) => MatchdayScoreboardRow.fromJson(entry as Map<String, dynamic>))
          .toList(),
    );
  }

  factory MatchdayScoreboard.empty() {
    return MatchdayScoreboard(categories: const [], rows: const []);
  }

  final List<MatchdayScoreboardCategory> categories;
  final List<MatchdayScoreboardRow> rows;
}

List<StandingsRow> _parseStandingsList(dynamic value) {
  final rows = <StandingsRow>[];
  for (final entry in _asList(value)) {
    final parsed = _tryParseStandingsRow(_asMap(entry));
    if (parsed != null) {
      rows.add(parsed);
    }
  }
  return rows;
}

List<ZoneCategoryStandings> _parseCategoryStandingsList(dynamic value) {
  final rows = <ZoneCategoryStandings>[];
  for (final entry in _asList(value)) {
    final parsed = _tryParseCategoryStandings(_asMap(entry));
    if (parsed != null) {
      rows.add(parsed);
    }
  }
  return rows;
}

Map<int, int?> _parseGoalsByCategory(dynamic value) {
  final map = <int, int?>{};
  if (value is Map) {
    value.forEach((key, dynamic rawValue) {
      final parsedKey = _tryParseInt(key);
      if (parsedKey == null) {
        return;
      }
      map[parsedKey] = _tryParseInt(rawValue);
    });
  }
  return map;
}

int _parseInt(dynamic value, {int fallback = 0}) {
  return _tryParseInt(value) ?? fallback;
}

int? _tryParseInt(dynamic value) {
  if (value is bool) {
    return value ? 1 : 0;
  }
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.round();
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    final parsedInt = int.tryParse(value);
    if (parsedInt != null) {
      return parsedInt;
    }
    final parsedDouble = double.tryParse(value);
    if (parsedDouble != null) {
      return parsedDouble.round();
    }
  }
  return null;
}

StandingsRow? _tryParseStandingsRow(Map<String, dynamic> json) {
  if (json.isEmpty) {
    return null;
  }
  try {
    return StandingsRow.fromJson(json);
  } catch (_) {
    try {
      final club = _asMap(json['club']);
      final goalsFor = _parseInt(json['goalsFor']);
      final goalsAgainst = _parseInt(json['goalsAgainst']);
      return StandingsRow(
        clubId: _parseInt(json['clubId'], fallback: _parseInt(club['id'])),
        clubName: _parseString(json['clubName'], fallback: _parseString(club['name'], fallback: 'Club')),
        clubShortName: _parseString(json['clubShortName'], fallback: _parseString(club['shortName'])),
        played: _parseInt(json['played']),
        wins: _parseInt(json['wins']),
        draws: _parseInt(json['draws']),
        losses: _parseInt(json['losses']),
        goalsFor: goalsFor,
        goalsAgainst: goalsAgainst,
        goalDifference: _parseInt(json['goalDifference'], fallback: goalsFor - goalsAgainst),
        points: _parseInt(json['points']),
      );
    } catch (_) {
      return null;
    }
  }
}

ZoneCategoryStandings? _tryParseCategoryStandings(Map<String, dynamic> json) {
  if (json.isEmpty) {
    return null;
  }
  try {
    return ZoneCategoryStandings.fromJson(json);
  } catch (_) {
    try {
      return ZoneCategoryStandings(
        tournamentCategoryId: _parseInt(json['tournamentCategoryId']),
        categoryId: _parseInt(json['categoryId']),
        categoryName: _parseString(json['categoryName'], fallback: 'Categoría'),
        countsForGeneral: _parseBool(json['countsForGeneral'], fallback: true),
        standings: _parseStandingsList(json['standings']),
      );
    } catch (_) {
      return null;
    }
  }
}

String _parseString(dynamic value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  if (value is String) {
    if (value.trim().isEmpty) {
      return fallback;
    }
    return value;
  }
  if (value is num || value is bool) {
    return value.toString();
  }
  return fallback;
}

bool _parseBool(dynamic value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    if (value == 1) {
      return true;
    }
    if (value == 0) {
      return false;
    }
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'si' || normalized == 'sí') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
  }
  return fallback;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, dynamic v) => MapEntry('$key', v));
  }
  return <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) {
    return value;
  }
  return const <dynamic>[];
}
