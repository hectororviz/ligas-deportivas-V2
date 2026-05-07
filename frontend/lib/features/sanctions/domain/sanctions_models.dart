// Enums
enum CardType { YELLOW, RED }

enum CardDisciplinaryStatus { PENDING, PROCESSED, IGNORED }

enum SuspensionStatus { ACTIVE, COMPLETED, CANCELLED }

// Models
class PlayerCard {
  final int id;
  final int matchCategoryId;
  final int playerId;
  final int clubId;
  final CardType cardType;
  final int? minute;
  final CardDisciplinaryStatus disciplinaryStatus;
  final DateTime createdAt;
  final PlayerSummary? player;
  final ClubSummary? club;

  PlayerCard({
    required this.id,
    required this.matchCategoryId,
    required this.playerId,
    required this.clubId,
    required this.cardType,
    this.minute,
    required this.disciplinaryStatus,
    required this.createdAt,
    this.player,
    this.club,
  });

  factory PlayerCard.fromJson(Map<String, dynamic> json) {
    return PlayerCard(
      id: json['id'] as int,
      matchCategoryId: json['matchCategoryId'] as int,
      playerId: json['playerId'] as int,
      clubId: json['clubId'] as int,
      cardType: CardType.values.firstWhere(
        (e) => e.name == json['cardType'],
        orElse: () => CardType.YELLOW,
      ),
      minute: json['minute'] as int?,
      disciplinaryStatus: CardDisciplinaryStatus.values.firstWhere(
        (e) => e.name == json['disciplinaryStatus'],
        orElse: () => CardDisciplinaryStatus.PENDING,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      player: json['player'] != null
          ? PlayerSummary.fromJson(json['player'] as Map<String, dynamic>)
          : null,
      club: json['club'] != null
          ? ClubSummary.fromJson(json['club'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PlayerSuspension {
  final int id;
  final int playerId;
  final int tournamentId;
  final int originalMatches;
  final int remainingMatches;
  final SuspensionStatus status;
  final String? reason;
  final int createdById;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PlayerSummary? player;
  final List<OriginCard>? originCards;
  final List<ServedMatch>? servedMatches;

  PlayerSuspension({
    required this.id,
    required this.playerId,
    required this.tournamentId,
    required this.originalMatches,
    required this.remainingMatches,
    required this.status,
    this.reason,
    required this.createdById,
    required this.createdAt,
    required this.updatedAt,
    this.player,
    this.originCards,
    this.servedMatches,
  });

  factory PlayerSuspension.fromJson(Map<String, dynamic> json) {
    return PlayerSuspension(
      id: json['id'] as int,
      playerId: json['playerId'] as int,
      tournamentId: json['tournamentId'] as int,
      originalMatches: json['originalMatches'] as int,
      remainingMatches: json['remainingMatches'] as int,
      status: SuspensionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SuspensionStatus.ACTIVE,
      ),
      reason: json['reason'] as String?,
      createdById: json['createdById'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      player: json['player'] != null
          ? PlayerSummary.fromJson(json['player'] as Map<String, dynamic>)
          : null,
      originCards: json['originCards'] != null
          ? (json['originCards'] as List)
              .map((e) => OriginCard.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      servedMatches: json['servedMatches'] != null
          ? (json['servedMatches'] as List)
              .map((e) => ServedMatch.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}

class PointDeduction {
  final int id;
  final int clubId;
  final int tournamentId;
  final int? tournamentCategoryId;
  final int points;
  final String reason;
  final int createdById;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ClubSummary? club;
  final TournamentCategorySummary? tournamentCategory;

  PointDeduction({
    required this.id,
    required this.clubId,
    required this.tournamentId,
    this.tournamentCategoryId,
    required this.points,
    required this.reason,
    required this.createdById,
    required this.createdAt,
    required this.updatedAt,
    this.club,
    this.tournamentCategory,
  });

  factory PointDeduction.fromJson(Map<String, dynamic> json) {
    return PointDeduction(
      id: json['id'] as int,
      clubId: json['clubId'] as int,
      tournamentId: json['tournamentId'] as int,
      tournamentCategoryId: json['tournamentCategoryId'] as int?,
      points: json['points'] as int,
      reason: json['reason'] as String,
      createdById: json['createdById'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      club: json['club'] != null
          ? ClubSummary.fromJson(json['club'] as Map<String, dynamic>)
          : null,
      tournamentCategory: json['tournamentCategory'] != null
          ? TournamentCategorySummary.fromJson(
              json['tournamentCategory'] as Map<String, dynamic>)
          : null,
    );
  }
}

class DisciplinaryRules {
  final int id;
  final int tournamentId;
  final int yellowCardLimit;
  final int yellowLimitSuspensionMatches;
  final int directRedSuspensionMatches;
  final int doubleYellowSuspensionMatches;
  final bool resetYellowsOnPhaseChange;
  final DateTime createdAt;
  final DateTime updatedAt;

  DisciplinaryRules({
    required this.id,
    required this.tournamentId,
    required this.yellowCardLimit,
    required this.yellowLimitSuspensionMatches,
    required this.directRedSuspensionMatches,
    required this.doubleYellowSuspensionMatches,
    required this.resetYellowsOnPhaseChange,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DisciplinaryRules.fromJson(Map<String, dynamic> json) {
    return DisciplinaryRules(
      id: json['id'] as int,
      tournamentId: json['tournamentId'] as int,
      yellowCardLimit: json['yellowCardLimit'] as int,
      yellowLimitSuspensionMatches: json['yellowLimitSuspensionMatches'] as int,
      directRedSuspensionMatches: json['directRedSuspensionMatches'] as int,
      doubleYellowSuspensionMatches: json['doubleYellowSuspensionMatches'] as int,
      resetYellowsOnPhaseChange: json['resetYellowsOnPhaseChange'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static DisciplinaryRules get defaults => DisciplinaryRules(
        id: 0,
        tournamentId: 0,
        yellowCardLimit: 3,
        yellowLimitSuspensionMatches: 1,
        directRedSuspensionMatches: 2,
        doubleYellowSuspensionMatches: 1,
        resetYellowsOnPhaseChange: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
}

// Helper classes
class PlayerSummary {
  final int id;
  final String firstName;
  final String lastName;
  final String dni;

  PlayerSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dni,
  });

  factory PlayerSummary.fromJson(Map<String, dynamic> json) {
    return PlayerSummary(
      id: json['id'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      dni: json['dni'] as String,
    );
  }

  String get fullName => '$lastName, $firstName';
}

class ClubSummary {
  final int id;
  final String name;

  ClubSummary({
    required this.id,
    required this.name,
  });

  factory ClubSummary.fromJson(Map<String, dynamic> json) {
    return ClubSummary(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class TournamentCategorySummary {
  final int id;
  final String categoryName;

  TournamentCategorySummary({
    required this.id,
    required this.categoryName,
  });

  factory TournamentCategorySummary.fromJson(Map<String, dynamic> json) {
    return TournamentCategorySummary(
      id: json['id'] as int,
      categoryName: (json['category'] as Map<String, dynamic>)['name'] as String,
    );
  }
}

class OriginCard {
  final int id;
  final String cardType;
  final int matchCategoryId;

  OriginCard({
    required this.id,
    required this.cardType,
    required this.matchCategoryId,
  });

  factory OriginCard.fromJson(Map<String, dynamic> json) {
    return OriginCard(
      id: json['id'] as int,
      cardType: json['cardType'] as String,
      matchCategoryId: json['matchCategoryId'] as int,
    );
  }
}

class ServedMatch {
  final int id;
  final int matchCategoryId;
  final DateTime servedAt;

  ServedMatch({
    required this.id,
    required this.matchCategoryId,
    required this.servedAt,
  });

  factory ServedMatch.fromJson(Map<String, dynamic> json) {
    return ServedMatch(
      id: json['id'] as int,
      matchCategoryId: json['matchCategoryId'] as int,
      servedAt: DateTime.parse(json['servedAt'] as String),
    );
  }
}

// DTOs
class CreateCardDto {
  final int playerId;
  final int clubId;
  final CardType cardType;
  final int? minute;

  CreateCardDto({
    required this.playerId,
    required this.clubId,
    required this.cardType,
    this.minute,
  });

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'clubId': clubId,
        'cardType': cardType.name,
        if (minute != null) 'minute': minute,
      };
}

class CreateCardResponse {
  final PlayerCard card;
  final CardAlert alert;

  CreateCardResponse({
    required this.card,
    required this.alert,
  });

  factory CreateCardResponse.fromJson(Map<String, dynamic> json) {
    return CreateCardResponse(
      card: PlayerCard.fromJson(json['card'] as Map<String, dynamic>),
      alert: CardAlert.fromJson(json['alert'] as Map<String, dynamic>),
    );
  }
}

class CardAlert {
  final String? type;
  final int yellowCount;

  CardAlert({
    this.type,
    required this.yellowCount,
  });

  factory CardAlert.fromJson(Map<String, dynamic> json) {
    return CardAlert(
      type: json['type'] as String?,
      yellowCount: json['yellowCount'] as int,
    );
  }

  bool get shouldShow => type != null;

  String get message {
    switch (type) {
      case 'YELLOW_LIMIT':
        return 'El jugador acumuló $yellowCount amarillas. Considerar suspensión.';
      case 'DIRECT_RED':
        return 'Tarjeta roja directa registrada.';
      case 'DOUBLE_YELLOW':
        return 'Doble amarilla - expulsión.';
      default:
        return '';
    }
  }
}

class CreateSuspensionDto {
  final int playerId;
  final int originalMatches;
  final String? reason;
  final List<int>? cardIds;

  CreateSuspensionDto({
    required this.playerId,
    required this.originalMatches,
    this.reason,
    this.cardIds,
  });

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'originalMatches': originalMatches,
        if (reason != null) 'reason': reason,
        if (cardIds != null) 'cardIds': cardIds,
      };
}

class UpdateSuspensionDto {
  final SuspensionStatus? status;
  final int? remainingMatches;
  final String? reason;

  UpdateSuspensionDto({
    this.status,
    this.remainingMatches,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (status != null) map['status'] = status!.name;
    if (remainingMatches != null) map['remainingMatches'] = remainingMatches;
    if (reason != null) map['reason'] = reason;
    return map;
  }
}

class CreateDeductionDto {
  final int clubId;
  final int? tournamentCategoryId;
  final int points;
  final String reason;

  CreateDeductionDto({
    required this.clubId,
    this.tournamentCategoryId,
    required this.points,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'clubId': clubId,
        'points': points,
        'reason': reason,
        if (tournamentCategoryId != null)
          'tournamentCategoryId': tournamentCategoryId,
      };
}

class UpdateDisciplinaryRulesDto {
  final int? yellowCardLimit;
  final int? yellowLimitSuspensionMatches;
  final int? directRedSuspensionMatches;
  final int? doubleYellowSuspensionMatches;
  final bool? resetYellowsOnPhaseChange;

  UpdateDisciplinaryRulesDto({
    this.yellowCardLimit,
    this.yellowLimitSuspensionMatches,
    this.directRedSuspensionMatches,
    this.doubleYellowSuspensionMatches,
    this.resetYellowsOnPhaseChange,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (yellowCardLimit != null) map['yellowCardLimit'] = yellowCardLimit;
    if (yellowLimitSuspensionMatches != null)
      map['yellowLimitSuspensionMatches'] = yellowLimitSuspensionMatches;
    if (directRedSuspensionMatches != null)
      map['directRedSuspensionMatches'] = directRedSuspensionMatches;
    if (doubleYellowSuspensionMatches != null)
      map['doubleYellowSuspensionMatches'] = doubleYellowSuspensionMatches;
    if (resetYellowsOnPhaseChange != null)
      map['resetYellowsOnPhaseChange'] = resetYellowsOnPhaseChange;
    return map;
  }
}

class TournamentSanctionsSummary {
  final List<PlayerCard> pending;
  final List<PlayerSuspension> active;
  final List<dynamic> history;

  TournamentSanctionsSummary({
    required this.pending,
    required this.active,
    required this.history,
  });

  factory TournamentSanctionsSummary.fromJson(Map<String, dynamic> json) {
    return TournamentSanctionsSummary(
      pending: (json['pending'] as List)
          .map((e) => PlayerCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      active: (json['active'] as List)
          .map((e) => PlayerSuspension.fromJson(e as Map<String, dynamic>))
          .toList(),
      history: (json['history'] as List).map((e) {
        final map = e as Map<String, dynamic>;
        // Determinar si es suspensión o deducción por los campos
        if (map.containsKey('originalMatches')) {
          return PlayerSuspension.fromJson(map);
        } else {
          return PointDeduction.fromJson(map);
        }
      }).toList(),
    );
  }
}
