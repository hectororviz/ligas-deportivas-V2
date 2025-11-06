class ClubSummary {
  const ClubSummary({required this.id, required this.name});

  factory ClubSummary.fromJson(Map<String, dynamic> json) {
    return ClubSummary(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  final int id;
  final String name;
}

class PaginatedClubs {
  const PaginatedClubs({
    required this.clubs,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory PaginatedClubs.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as List<dynamic>? ?? [])
        .map((item) => ClubSummary.fromJson(item as Map<String, dynamic>))
        .toList();
    return PaginatedClubs(
      clubs: data,
      total: json['total'] as int? ?? data.length,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? (data.isEmpty ? 1 : data.length),
    );
  }

  final List<ClubSummary> clubs;
  final int total;
  final int page;
  final int pageSize;
}
