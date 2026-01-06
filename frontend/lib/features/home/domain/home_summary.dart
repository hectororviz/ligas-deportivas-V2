class HomeSummary {
  HomeSummary({required this.tournaments, this.generatedAt});

  factory HomeSummary.fromJson(Map<String, dynamic> json) {
    final tournamentsJson = json['tournaments'] as List<dynamic>? ?? [];
    return HomeSummary(
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'] as String)
          : null,
      tournaments: tournamentsJson
          .whereType<Map<String, dynamic>>()
          .map(HomeTournamentSummary.fromJson)
          .toList(),
    );
  }

  final List<HomeTournamentSummary> tournaments;
  final DateTime? generatedAt;
}

class HomeTournamentSummary {
  HomeTournamentSummary({
    required this.id,
    required this.leagueName,
    required this.name,
    required this.year,
    required this.zones,
  });

  factory HomeTournamentSummary.fromJson(Map<String, dynamic> json) {
    final zonesJson = json['zones'] as List<dynamic>? ?? [];
    return HomeTournamentSummary(
      id: json['id'] as int? ?? 0,
      leagueName: json['leagueName'] as String? ?? 'Liga',
      name: json['name'] as String? ?? 'Torneo',
      year: json['year'] as int? ?? 0,
      zones: zonesJson
          .whereType<Map<String, dynamic>>()
          .map(HomeZoneSummary.fromJson)
          .toList(),
    );
  }

  final int id;
  final String leagueName;
  final String name;
  final int year;
  final List<HomeZoneSummary> zones;

  String get displayName => year > 0 ? '$name $year' : name;
}

class HomeZoneSummary {
  HomeZoneSummary({
    required this.id,
    required this.name,
    required this.top,
    required this.nextMatchday,
  });

  factory HomeZoneSummary.fromJson(Map<String, dynamic> json) {
    final topJson = json['top'] as List<dynamic>? ?? [];
    return HomeZoneSummary(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Zona',
      top: topJson
          .whereType<Map<String, dynamic>>()
          .map(HomeStandingRow.fromJson)
          .toList(),
      nextMatchday: json['nextMatchday'] == null
          ? null
          : HomeNextMatchday.fromJson(
              json['nextMatchday'] as Map<String, dynamic>,
            ),
    );
  }

  final int id;
  final String name;
  final List<HomeStandingRow> top;
  final HomeNextMatchday? nextMatchday;
}

class HomeStandingRow {
  HomeStandingRow({
    required this.clubId,
    required this.clubName,
    required this.points,
    required this.goalDifference,
  });

  factory HomeStandingRow.fromJson(Map<String, dynamic> json) {
    return HomeStandingRow(
      clubId: json['clubId'] as int? ?? 0,
      clubName: json['clubName'] as String? ?? 'Club',
      points: json['points'] as int? ?? 0,
      goalDifference: json['goalDifference'] as int? ?? 0,
    );
  }

  final int clubId;
  final String clubName;
  final int points;
  final int goalDifference;
}

class HomeNextMatchday {
  HomeNextMatchday({
    required this.matchday,
    required this.date,
    required this.status,
    required this.kickoffTime,
  });

  factory HomeNextMatchday.fromJson(Map<String, dynamic> json) {
    final dateValue = json['date'] as String?;
    return HomeNextMatchday(
      matchday: json['matchday'] as int? ?? 0,
      date: dateValue != null ? DateTime.tryParse(dateValue) : null,
      status: json['status'] as String? ?? '',
      kickoffTime: json['kickoffTime'] as String?,
    );
  }

  final int matchday;
  final DateTime? date;
  final String status;
  final String? kickoffTime;
}
