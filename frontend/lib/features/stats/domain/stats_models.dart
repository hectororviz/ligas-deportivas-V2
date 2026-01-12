class StatsTournamentSummary {
  StatsTournamentSummary({
    required this.id,
    required this.name,
    required this.year,
    required this.leagueName,
  });

  factory StatsTournamentSummary.fromJson(Map<String, dynamic> json) {
    final league = json['league'] as Map<String, dynamic>? ?? const {};
    return StatsTournamentSummary(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Torneo',
      year: json['year'] as int? ?? 0,
      leagueName: league['name'] as String? ?? 'Liga',
    );
  }

  final int id;
  final String name;
  final int year;
  final String leagueName;

  String get displayName => '$name $year';
}

class StatsTournamentDetail {
  StatsTournamentDetail({
    required this.id,
    required this.categories,
  });

  factory StatsTournamentDetail.fromJson(Map<String, dynamic> json) {
    return StatsTournamentDetail(
      id: json['id'] as int,
      categories: (json['categories'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(StatsCategory.fromJson)
          .toList(),
    );
  }

  final int id;
  final List<StatsCategory> categories;
}

class StatsCategory {
  StatsCategory({
    required this.id,
    required this.name,
    required this.promotional,
  });

  factory StatsCategory.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>? ?? const {};
    return StatsCategory(
      id: json['categoryId'] as int? ?? 0,
      name: category['name'] as String? ?? 'Categoría',
      promotional: category['promotional'] as bool? ?? false,
    );
  }

  final int id;
  final String name;
  final bool promotional;
}

class StatsLeaderboardsResponse {
  StatsLeaderboardsResponse({
    required this.filtersApplied,
    required this.leaderboards,
  });

  factory StatsLeaderboardsResponse.fromJson(Map<String, dynamic> json) {
    return StatsLeaderboardsResponse(
      filtersApplied: StatsFiltersApplied.fromJson(
        json['filtersApplied'] as Map<String, dynamic>? ?? const {},
      ),
      leaderboards: StatsLeaderboards.fromJson(
        json['leaderboards'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  final StatsFiltersApplied filtersApplied;
  final StatsLeaderboards leaderboards;
}

class StatsFiltersApplied {
  StatsFiltersApplied({
    required this.tournamentId,
    required this.zoneId,
    required this.categoryId,
  });

  factory StatsFiltersApplied.fromJson(Map<String, dynamic> json) {
    return StatsFiltersApplied(
      tournamentId: json['tournamentId'] as int? ?? 0,
      zoneId: json['zoneId'] as int?,
      categoryId: json['categoryId'] as int?,
    );
  }

  final int tournamentId;
  final int? zoneId;
  final int? categoryId;
}

class StatsLeaderboards {
  StatsLeaderboards({
    required this.topScorersPlayers,
    required this.mostMatchesScoringPlayers,
    required this.mostBracesPlayers,
    required this.mostHatTricksPlayers,
    required this.topScoringTeams,
    required this.bestDefenseTeams,
    required this.mostCleanSheetsTeams,
    required this.mostWinsTeams,
    required this.mostGoalsMatches,
    required this.biggestWinsMatches,
  });

  factory StatsLeaderboards.fromJson(Map<String, dynamic> json) {
    return StatsLeaderboards(
      topScorersPlayers: (json['topScorersPlayers'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(StatsPlayerGoalsEntry.fromJson)
          .toList(),
      mostMatchesScoringPlayers:
          (json['mostMatchesScoringPlayers'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>()
              .map(StatsPlayerMatchesEntry.fromJson)
              .toList(),
      mostBracesPlayers: (json['mostBracesPlayers'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(StatsPlayerBracesEntry.fromJson)
          .toList(),
      mostHatTricksPlayers:
          (json['mostHatTricksPlayers'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>()
              .map(StatsPlayerHatTricksEntry.fromJson)
              .toList(),
      topScoringTeams: (json['topScoringTeams'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(StatsTeamGoalsForEntry.fromJson)
          .toList(),
      bestDefenseTeams: (json['bestDefenseTeams'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(StatsTeamGoalsAgainstEntry.fromJson)
          .toList(),
      mostCleanSheetsTeams:
          (json['mostCleanSheetsTeams'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>()
              .map(StatsTeamCleanSheetsEntry.fromJson)
              .toList(),
      mostWinsTeams: (json['mostWinsTeams'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(StatsTeamWinsEntry.fromJson)
          .toList(),
      mostGoalsMatches: (json['mostGoalsMatches'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(StatsMatchGoalsEntry.fromJson)
          .toList(),
      biggestWinsMatches: (json['biggestWinsMatches'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(StatsMatchBiggestWinEntry.fromJson)
          .toList(),
    );
  }

  final List<StatsPlayerGoalsEntry> topScorersPlayers;
  final List<StatsPlayerMatchesEntry> mostMatchesScoringPlayers;
  final List<StatsPlayerBracesEntry> mostBracesPlayers;
  final List<StatsPlayerHatTricksEntry> mostHatTricksPlayers;
  final List<StatsTeamGoalsForEntry> topScoringTeams;
  final List<StatsTeamGoalsAgainstEntry> bestDefenseTeams;
  final List<StatsTeamCleanSheetsEntry> mostCleanSheetsTeams;
  final List<StatsTeamWinsEntry> mostWinsTeams;
  final List<StatsMatchGoalsEntry> mostGoalsMatches;
  final List<StatsMatchBiggestWinEntry> biggestWinsMatches;
}

class StatsPlayerGoalsEntry {
  StatsPlayerGoalsEntry({
    required this.playerId,
    required this.playerName,
    required this.clubId,
    required this.clubName,
    required this.goals,
  });

  factory StatsPlayerGoalsEntry.fromJson(Map<String, dynamic> json) {
    return StatsPlayerGoalsEntry(
      playerId: json['playerId'] as int? ?? 0,
      playerName: json['playerName'] as String? ?? 'Jugador',
      clubId: json['clubId'] as int? ?? 0,
      clubName: json['clubName'] as String? ?? 'Club',
      goals: json['goals'] as int? ?? 0,
    );
  }

  final int playerId;
  final String playerName;
  final int clubId;
  final String clubName;
  final int goals;
}

class StatsPlayerMatchesEntry {
  StatsPlayerMatchesEntry({
    required this.playerId,
    required this.playerName,
    required this.clubId,
    required this.clubName,
    required this.matchesWithGoal,
  });

  factory StatsPlayerMatchesEntry.fromJson(Map<String, dynamic> json) {
    return StatsPlayerMatchesEntry(
      playerId: json['playerId'] as int? ?? 0,
      playerName: json['playerName'] as String? ?? 'Jugador',
      clubId: json['clubId'] as int? ?? 0,
      clubName: json['clubName'] as String? ?? 'Club',
      matchesWithGoal: json['matchesWithGoal'] as int? ?? 0,
    );
  }

  final int playerId;
  final String playerName;
  final int clubId;
  final String clubName;
  final int matchesWithGoal;
}

class StatsPlayerBracesEntry {
  StatsPlayerBracesEntry({
    required this.playerId,
    required this.playerName,
    required this.clubId,
    required this.clubName,
    required this.bracesCount,
  });

  factory StatsPlayerBracesEntry.fromJson(Map<String, dynamic> json) {
    return StatsPlayerBracesEntry(
      playerId: json['playerId'] as int? ?? 0,
      playerName: json['playerName'] as String? ?? 'Jugador',
      clubId: json['clubId'] as int? ?? 0,
      clubName: json['clubName'] as String? ?? 'Club',
      bracesCount: json['bracesCount'] as int? ?? 0,
    );
  }

  final int playerId;
  final String playerName;
  final int clubId;
  final String clubName;
  final int bracesCount;
}

class StatsPlayerHatTricksEntry {
  StatsPlayerHatTricksEntry({
    required this.playerId,
    required this.playerName,
    required this.clubId,
    required this.clubName,
    required this.hatTricksCount,
  });

  factory StatsPlayerHatTricksEntry.fromJson(Map<String, dynamic> json) {
    return StatsPlayerHatTricksEntry(
      playerId: json['playerId'] as int? ?? 0,
      playerName: json['playerName'] as String? ?? 'Jugador',
      clubId: json['clubId'] as int? ?? 0,
      clubName: json['clubName'] as String? ?? 'Club',
      hatTricksCount: json['hatTricksCount'] as int? ?? 0,
    );
  }

  final int playerId;
  final String playerName;
  final int clubId;
  final String clubName;
  final int hatTricksCount;
}

class StatsTeamGoalsForEntry {
  StatsTeamGoalsForEntry({
    required this.clubId,
    required this.clubName,
    required this.goalsFor,
  });

  factory StatsTeamGoalsForEntry.fromJson(Map<String, dynamic> json) {
    return StatsTeamGoalsForEntry(
      clubId: json['clubId'] as int? ?? 0,
      clubName: json['clubName'] as String? ?? 'Club',
      goalsFor: json['goalsFor'] as int? ?? 0,
    );
  }

  final int clubId;
  final String clubName;
  final int goalsFor;
}

class StatsTeamGoalsAgainstEntry {
  StatsTeamGoalsAgainstEntry({
    required this.clubId,
    required this.clubName,
    required this.goalsAgainst,
  });

  factory StatsTeamGoalsAgainstEntry.fromJson(Map<String, dynamic> json) {
    return StatsTeamGoalsAgainstEntry(
      clubId: json['clubId'] as int? ?? 0,
      clubName: json['clubName'] as String? ?? 'Club',
      goalsAgainst: json['goalsAgainst'] as int? ?? 0,
    );
  }

  final int clubId;
  final String clubName;
  final int goalsAgainst;
}

class StatsTeamCleanSheetsEntry {
  StatsTeamCleanSheetsEntry({
    required this.clubId,
    required this.clubName,
    required this.cleanSheets,
  });

  factory StatsTeamCleanSheetsEntry.fromJson(Map<String, dynamic> json) {
    return StatsTeamCleanSheetsEntry(
      clubId: json['clubId'] as int? ?? 0,
      clubName: json['clubName'] as String? ?? 'Club',
      cleanSheets: json['cleanSheets'] as int? ?? 0,
    );
  }

  final int clubId;
  final String clubName;
  final int cleanSheets;
}

class StatsTeamWinsEntry {
  StatsTeamWinsEntry({
    required this.clubId,
    required this.clubName,
    required this.wins,
  });

  factory StatsTeamWinsEntry.fromJson(Map<String, dynamic> json) {
    return StatsTeamWinsEntry(
      clubId: json['clubId'] as int? ?? 0,
      clubName: json['clubName'] as String? ?? 'Club',
      wins: json['wins'] as int? ?? 0,
    );
  }

  final int clubId;
  final String clubName;
  final int wins;
}

class StatsMatchGoalsEntry {
  StatsMatchGoalsEntry({
    required this.matchCategoryId,
    required this.matchId,
    required this.zoneName,
    required this.categoryName,
    required this.homeClubName,
    required this.awayClubName,
    required this.homeScore,
    required this.awayScore,
    required this.totalGoals,
  });

  factory StatsMatchGoalsEntry.fromJson(Map<String, dynamic> json) {
    return StatsMatchGoalsEntry(
      matchCategoryId: json['matchCategoryId'] as int? ?? 0,
      matchId: json['matchId'] as int? ?? 0,
      zoneName: json['zoneName'] as String?,
      categoryName: json['categoryName'] as String? ?? 'Categoría',
      homeClubName: json['homeClubName'] as String? ?? 'Local',
      awayClubName: json['awayClubName'] as String? ?? 'Visitante',
      homeScore: json['homeScore'] as int? ?? 0,
      awayScore: json['awayScore'] as int? ?? 0,
      totalGoals: json['totalGoals'] as int? ?? 0,
    );
  }

  final int matchCategoryId;
  final int matchId;
  final String? zoneName;
  final String categoryName;
  final String homeClubName;
  final String awayClubName;
  final int homeScore;
  final int awayScore;
  final int totalGoals;
}

class StatsMatchBiggestWinEntry {
  StatsMatchBiggestWinEntry({
    required this.matchCategoryId,
    required this.matchId,
    required this.zoneName,
    required this.categoryName,
    required this.homeClubName,
    required this.awayClubName,
    required this.homeScore,
    required this.awayScore,
    required this.goalDiff,
  });

  factory StatsMatchBiggestWinEntry.fromJson(Map<String, dynamic> json) {
    return StatsMatchBiggestWinEntry(
      matchCategoryId: json['matchCategoryId'] as int? ?? 0,
      matchId: json['matchId'] as int? ?? 0,
      zoneName: json['zoneName'] as String?,
      categoryName: json['categoryName'] as String? ?? 'Categoría',
      homeClubName: json['homeClubName'] as String? ?? 'Local',
      awayClubName: json['awayClubName'] as String? ?? 'Visitante',
      homeScore: json['homeScore'] as int? ?? 0,
      awayScore: json['awayScore'] as int? ?? 0,
      goalDiff: json['goalDiff'] as int? ?? 0,
    );
  }

  final int matchCategoryId;
  final int matchId;
  final String? zoneName;
  final String categoryName;
  final String homeClubName;
  final String awayClubName;
  final int homeScore;
  final int awayScore;
  final int goalDiff;
}
