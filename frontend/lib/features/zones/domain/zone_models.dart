import 'package:flutter/material.dart';

enum ZoneStatus { open, inProgress, playing, finished }

extension ZoneStatusX on ZoneStatus {
  static ZoneStatus fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'IN_PROGRESS':
        return ZoneStatus.inProgress;
      case 'PLAYING':
        return ZoneStatus.playing;
      case 'FINISHED':
        return ZoneStatus.finished;
      default:
        return ZoneStatus.open;
    }
  }

  String get label {
    switch (this) {
      case ZoneStatus.open:
        return 'Abierta';
      case ZoneStatus.inProgress:
        return 'En curso';
      case ZoneStatus.playing:
        return 'Jugando';
      case ZoneStatus.finished:
        return 'Finalizada';
    }
  }

  Color get color {
    switch (this) {
      case ZoneStatus.open:
        return Colors.blue;
      case ZoneStatus.inProgress:
        return Colors.orange;
      case ZoneStatus.playing:
        return Colors.teal;
      case ZoneStatus.finished:
        return Colors.green;
    }
  }
}

class ZoneSummary {
  ZoneSummary({
    required this.id,
    required this.name,
    required this.tournamentId,
    required this.status,
    required this.lockedAt,
    required this.tournamentName,
    required this.tournamentYear,
    required this.tournamentLocked,
    required this.leagueName,
    required this.clubCount,
    required this.matchCount,
  });

  factory ZoneSummary.fromJson(Map<String, dynamic> json) {
    final tournament = json['tournament'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final league = tournament['league'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final statusValue = json['status'] as String? ?? 'OPEN';
    final lockedAtValue = json['lockedAt'] as String?;
    final count = json['_count'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return ZoneSummary(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Sin nombre',
      tournamentId: tournament['id'] as int? ?? 0,
      status: ZoneStatusX.fromApi(statusValue),
      lockedAt: lockedAtValue != null ? DateTime.tryParse(lockedAtValue) : null,
      tournamentName: tournament['name'] as String? ?? 'Torneo',
      tournamentYear: tournament['year'] as int? ?? 0,
      tournamentLocked: (tournament['fixtureLockedAt'] as String?) != null,
      leagueName: league['name'] as String? ?? 'Liga',
      clubCount: count['clubZones'] as int? ?? 0,
      matchCount: count['matches'] as int? ?? 0,
    );
  }

  final int id;
  final String name;
  final int tournamentId;
  final ZoneStatus status;
  final DateTime? lockedAt;
  final String tournamentName;
  final int tournamentYear;
  final bool tournamentLocked;
  final String leagueName;
  final int clubCount;
  final int matchCount;

  bool get hasFixture => matchCount > 0;
  bool get isEditable => !tournamentLocked && status == ZoneStatus.open;
}

class ZoneDetail {
  ZoneDetail({
    required this.id,
    required this.name,
    required this.status,
    required this.lockedAt,
    required this.tournament,
    required this.clubs,
    this.fixtureSeed,
  });

  factory ZoneDetail.fromJson(Map<String, dynamic> json) {
    final tournament = ZoneTournament.fromJson(
      json['tournament'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
    final clubZones = json['clubZones'] as List<dynamic>? ?? [];
    return ZoneDetail(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Sin nombre',
      status: ZoneStatusX.fromApi(json['status'] as String? ?? 'OPEN'),
      lockedAt: (json['lockedAt'] as String?) != null
          ? DateTime.tryParse(json['lockedAt'] as String)
          : null,
      tournament: tournament,
      clubs: clubZones
          .map((entry) => ZoneClub.fromJson(entry as Map<String, dynamic>))
          .toList(),
      fixtureSeed: json['fixtureSeed'] as int?,
    );
  }

  final int id;
  final String name;
  final ZoneStatus status;
  final DateTime? lockedAt;
  final ZoneTournament tournament;
  final List<ZoneClub> clubs;
  final int? fixtureSeed;

  bool get isLocked => status != ZoneStatus.open || lockedAt != null;
}

class ZoneTournament {
  ZoneTournament({
    required this.id,
    required this.name,
    required this.year,
    required this.leagueId,
    required this.leagueName,
    required this.fixtureLocked,
  });

  factory ZoneTournament.fromJson(Map<String, dynamic> json) {
    final league = json['league'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return ZoneTournament(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Torneo',
      year: json['year'] as int? ?? 0,
      leagueId: league['id'] as int? ?? 0,
      leagueName: league['name'] as String? ?? 'Liga',
      fixtureLocked: (json['fixtureLockedAt'] as String?) != null,
    );
  }

  final int id;
  final String name;
  final int year;
  final int leagueId;
  final String leagueName;
  final bool fixtureLocked;
}

class ZoneClub {
  ZoneClub({required this.id, required this.name, this.shortName});

  factory ZoneClub.fromJson(Map<String, dynamic> json) {
    final club = json['club'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return ZoneClub(
      id: club['id'] as int? ?? json['clubId'] as int? ?? 0,
      name: club['name'] as String? ?? 'Club',
      shortName: club['shortName'] as String?,
    );
  }

  final int id;
  final String name;
  final String? shortName;
}
