class FlyerTemplateConfig {
  const FlyerTemplateConfig({
    this.backgroundUrl,
    this.layoutPreviewUrl,
    this.layoutFileName,
    this.updatedAt,
    this.hasCustomTemplate = false,
  });

  factory FlyerTemplateConfig.fromJson(Map<String, dynamic> json) {
    return FlyerTemplateConfig(
      backgroundUrl: json['backgroundUrl'] as String?,
      layoutPreviewUrl: json['layoutPreviewUrl'] as String?,
      layoutFileName: json['layoutFileName'] as String?,
      updatedAt: _parseDate(json['updatedAt']),
      hasCustomTemplate: json['hasCustomTemplate'] as bool? ?? false,
    );
  }

  final String? backgroundUrl;
  final String? layoutPreviewUrl;
  final String? layoutFileName;
  final DateTime? updatedAt;
  final bool hasCustomTemplate;

  static DateTime? _parseDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class FlyerTemplateToken {
  const FlyerTemplateToken({
    required this.token,
    required this.description,
    this.example,
    this.usage,
  });

  factory FlyerTemplateToken.fromJson(Map<String, dynamic> json) {
    return FlyerTemplateToken(
      token: json['token'] as String? ?? '',
      description: json['description'] as String? ?? '',
      example: json['example'] as String?,
      usage: json['usage'] as String?,
    );
  }

  final String token;
  final String description;
  final String? example;
  final String? usage;
}
