class SiteIdentity {
  const SiteIdentity({
    required this.title,
    this.iconUrl,
    this.faviconUrl,
    this.flyerUrl,
  });

  final String title;
  final String? iconUrl;
  final String? faviconUrl;
  final String? flyerUrl;

  factory SiteIdentity.fromJson(Map<String, dynamic> json) {
    return SiteIdentity(
      title: (json['title'] as String?) ?? 'Ligas Deportivas',
      iconUrl: json['iconUrl'] as String?,
      faviconUrl: json['faviconUrl'] as String?,
      flyerUrl: json['flyerUrl'] as String?,
    );
  }
}
