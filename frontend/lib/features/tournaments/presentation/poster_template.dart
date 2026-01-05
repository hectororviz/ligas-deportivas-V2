import 'dart:convert';

class PosterTemplateConfig {
  const PosterTemplateConfig({
    this.layers = const [],
    this.version = 0,
    this.updatedAt,
    this.backgroundUrl,
    this.hasCustomTemplate = false,
  });

  final List<PosterLayer> layers;
  final int version;
  final DateTime? updatedAt;
  final String? backgroundUrl;
  final bool hasCustomTemplate;

  factory PosterTemplateConfig.fromJson(Map<String, dynamic> json) {
    final template = json['template'];
    final layersJson = template is Map<String, dynamic> ? template['layers'] : null;
    final layersList = (layersJson is List ? layersJson : const [])
        .whereType<Map<String, dynamic>>()
        .map(PosterLayer.fromJson)
        .toList();
    return PosterTemplateConfig(
      layers: layersList,
      version: json['version'] as int? ?? 0,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
      backgroundUrl: json['backgroundUrl'] as String?,
      hasCustomTemplate: json['hasCustomTemplate'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toTemplateJson() {
    return {
      'layers': layers.map((layer) => layer.toJson()).toList(),
    };
  }

  String toTemplateJsonString() => jsonEncode(toTemplateJson());

  PosterTemplateConfig copyWith({
    List<PosterLayer>? layers,
    int? version,
    DateTime? updatedAt,
    String? backgroundUrl,
    bool? hasCustomTemplate,
  }) {
    return PosterTemplateConfig(
      layers: layers ?? this.layers,
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
      backgroundUrl: backgroundUrl ?? this.backgroundUrl,
      hasCustomTemplate: hasCustomTemplate ?? this.hasCustomTemplate,
    );
  }
}

class PosterLayer {
  PosterLayer({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0,
    this.opacity = 1,
    this.zIndex = 0,
    this.locked = false,
    this.text,
    this.fontSize,
    this.fontFamily,
    this.fontWeight,
    this.fontStyle,
    this.color,
    this.align,
    this.strokeColor,
    this.strokeWidth,
    this.src,
    this.fit,
    this.isBackground,
    this.shape,
    this.fill,
    this.radius,
  });

  final String id;
  final String type;
  double x;
  double y;
  double width;
  double height;
  double rotation;
  double opacity;
  int zIndex;
  bool locked;

  String? text;
  double? fontSize;
  String? fontFamily;
  String? fontWeight;
  String? fontStyle;
  String? color;
  String? align;
  String? strokeColor;
  double? strokeWidth;

  String? src;
  String? fit;
  bool? isBackground;

  String? shape;
  String? fill;
  double? radius;

  factory PosterLayer.fromJson(Map<String, dynamic> json) {
    return PosterLayer(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      width: (json['width'] as num?)?.toDouble() ?? 0,
      height: (json['height'] as num?)?.toDouble() ?? 0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1,
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
      locked: json['locked'] as bool? ?? false,
      text: json['text'] as String?,
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      fontFamily: json['fontFamily'] as String?,
      fontWeight: json['fontWeight']?.toString(),
      fontStyle: json['fontStyle'] as String?,
      color: json['color'] as String?,
      align: json['align'] as String?,
      strokeColor: json['strokeColor'] as String?,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble(),
      src: json['src'] as String?,
      fit: json['fit'] as String?,
      isBackground: json['isBackground'] as bool?,
      shape: json['shape'] as String?,
      fill: json['fill'] as String?,
      radius: (json['radius'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'rotation': rotation,
      'opacity': opacity,
      'zIndex': zIndex,
      'locked': locked,
      if (text != null) 'text': text,
      if (fontSize != null) 'fontSize': fontSize,
      if (fontFamily != null) 'fontFamily': fontFamily,
      if (fontWeight != null) 'fontWeight': fontWeight,
      if (fontStyle != null) 'fontStyle': fontStyle,
      if (color != null) 'color': color,
      if (align != null) 'align': align,
      if (strokeColor != null) 'strokeColor': strokeColor,
      if (strokeWidth != null) 'strokeWidth': strokeWidth,
      if (src != null) 'src': src,
      if (fit != null) 'fit': fit,
      if (isBackground != null) 'isBackground': isBackground,
      if (shape != null) 'shape': shape,
      if (fill != null) 'fill': fill,
      if (radius != null) 'radius': radius,
    };
  }
}

class PosterTemplateToken {
  const PosterTemplateToken({
    required this.token,
    required this.description,
    this.example,
  });

  final String token;
  final String description;
  final String? example;

  factory PosterTemplateToken.fromJson(Map<String, dynamic> json) {
    return PosterTemplateToken(
      token: json['token'] as String? ?? '',
      description: json['description'] as String? ?? '',
      example: json['example'] as String?,
    );
  }
}
