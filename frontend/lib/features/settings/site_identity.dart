class SiteIdentity {
  const SiteIdentity({
    required this.title,
    this.iconUrl,
    this.faviconBasePath,
    this.faviconUpdatedAt,
    this.flyerUrl,
  });

  final String title;
  final String? iconUrl;
  final String? faviconBasePath;
  final int? faviconUpdatedAt;
  final String? flyerUrl;

  factory SiteIdentity.fromJson(Map<String, dynamic> json) {
    final favicon = json['favicon'] as Map<String, dynamic>?;
    return SiteIdentity(
      title: (json['title'] as String?) ?? 'Ligas Deportivas',
      iconUrl: json['iconUrl'] as String?,
      faviconBasePath: favicon?['basePath'] as String?,
      faviconUpdatedAt: (favicon?['updatedAt'] as num?)?.toInt(),
      flyerUrl: json['flyerUrl'] as String?,
    );
  }
}
