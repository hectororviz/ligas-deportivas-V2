class SiteIdentity {
  const SiteIdentity({
    required this.title,
    this.iconUrl,
    this.flyerUrl,
  });

  final String title;
  final String? iconUrl;
  final String? flyerUrl;

  factory SiteIdentity.fromJson(Map<String, dynamic> json) {
    return SiteIdentity(
      title: (json['title'] as String?) ?? 'Ligas Deportivas',
      iconUrl: json['iconUrl'] as String?,
      flyerUrl: json['flyerUrl'] as String?,
    );
  }
}
