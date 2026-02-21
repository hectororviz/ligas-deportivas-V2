class ZoneStandingsData {
  ZoneStandingsData({
    required this.zone,
    required this.general,
    required this.categories,
  });

  factory ZoneStandingsData.fromJson(Map<String, dynamic> json) {
    final generalRows = _parseStandingsList(json['general']);
    final categoryRows = <ZoneCategoryStandings>[];
    for (final category in _asList(json['categories'])) {
      final parsed = _tryParseCategoryStandings(_asMap(category));
      if (parsed != null) {
        categoryRows.add(parsed);
      }
    }

    return ZoneStandingsData(
      zone: ZoneStandingsInfo.fromJson(_asMap(json['zone'])),
      general: generalRows,
      categories: categoryRows,
    );
  }

  final ZoneStandingsInfo zone;
  final List<StandingsRow> general;
  final List<ZoneCategoryStandings> categories;
}

class ZoneStandingsInfo {
  ZoneStandingsInfo({
    required this.id,
    required this.name,
    required this.tournamentId,
    required this.tournamentName,
    required this.tournamentYear,
    required this.leagueId,
    required this.leagueName,
  });

  factory ZoneStandingsInfo.fromJson(Map<String, dynamic> json) {
    return ZoneStandingsInfo(
      id: _parseInt(json['id']),
      name: _parseString(json['name'], fallback: 'Zona'),
      tournamentId: _parseInt(json['tournamentId']),
      tournamentName: _parseString(json['tournamentName'], fallback: 'Torneo'),
      tournamentYear: _parseInt(json['tournamentYear']),
      leagueId: _parseInt(json['leagueId']),
      leagueName: _parseString(json['leagueName'], fallback: 'Liga'),
    );
  }

  final int id;
  final String name;
  final int tournamentId;
  final String tournamentName;
  final int tournamentYear;
  final int leagueId;
  final String leagueName;
}

class ZoneCategoryStandings {
  ZoneCategoryStandings({
    required this.tournamentCategoryId,
    required this.categoryId,
    required this.categoryName,
    required this.countsForGeneral,
    required this.standings,
  });

  factory ZoneCategoryStandings.fromJson(Map<String, dynamic> json) {
    return ZoneCategoryStandings(
      tournamentCategoryId: _parseInt(json['tournamentCategoryId']),
      categoryId: _parseInt(json['categoryId']),
      categoryName: _parseString(json['categoryName'], fallback: 'Categoría'),
      countsForGeneral: _parseBool(json['countsForGeneral'], fallback: true),
      standings: _parseStandingsList(json['standings']),
    );
  }

  final int tournamentCategoryId;
  final int categoryId;
  final String categoryName;
  final bool countsForGeneral;
  final List<StandingsRow> standings;
}

class StandingsRow {
  StandingsRow({
    required this.clubId,
    required this.clubName,
    required this.clubShortName,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
  });

  factory StandingsRow.fromJson(Map<String, dynamic> json) {
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
      goalDifference: _parseGoalDifference(json['goalDifference'], goalsFor: goalsFor, goalsAgainst: goalsAgainst),
      points: _parseInt(json['points']),
    );
  }

  final int clubId;
  final String clubName;
  final String? clubShortName;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;

  String get displayClubName {
    final shortName = clubShortName?.trim();
    if (shortName != null && shortName.isNotEmpty) {
      return shortName;
    }
    return clubName;
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

int _parseGoalDifference(dynamic value, {required int goalsFor, required int goalsAgainst}) {
  final parsed = _tryParseInt(value);
  if (parsed != null) {
    return parsed;
  }
  return goalsFor - goalsAgainst;
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
      final goalsFor = _parseInt(json['goalsFor']);
      final goalsAgainst = _parseInt(json['goalsAgainst']);
      return StandingsRow(
        clubId: _parseInt(json['clubId']),
        clubName: _parseString(json['clubName'], fallback: 'Club'),
        clubShortName: _parseString(json['clubShortName']),
        played: _parseInt(json['played']),
        wins: _parseInt(json['wins']),
        draws: _parseInt(json['draws']),
        losses: _parseInt(json['losses']),
        goalsFor: goalsFor,
        goalsAgainst: goalsAgainst,
        goalDifference: _parseGoalDifference(
          json['goalDifference'],
          goalsFor: goalsFor,
          goalsAgainst: goalsAgainst,
        ),
        points: _parseInt(json['points']),
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
