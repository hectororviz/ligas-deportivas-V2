class SiteIdentity {
  const SiteIdentity({
    required this.title,
    this.iconUrl,
  });

  final String title;
  final String? iconUrl;

  factory SiteIdentity.fromJson(Map<String, dynamic> json) {
    return SiteIdentity(
      title: (json['title'] as String?) ?? 'Ligas Deportivas',
      iconUrl: json['iconUrl'] as String?,
    );
  }
}
