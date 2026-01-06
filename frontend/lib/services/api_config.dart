import 'package:flutter/foundation.dart';

class ApiConfig {
  static final String baseUrl = _resolveBaseUrl();

  static String _resolveBaseUrl() {
    const defined = String.fromEnvironment('API_BASE_URL');
    final trimmed = defined.trim();
    final resolved = trimmed.isNotEmpty ? trimmed : _defaultBaseUrl();
    _validateBaseUrl(resolved);
    return resolved;
  }

  static String _defaultBaseUrl() {
    if (kIsWeb) {
      return Uri.base.resolve('/api/v1').toString();
    }

    return '/api/v1';
  }

  static void _validateBaseUrl(String baseUrl) {
    if (!kReleaseMode) {
      return;
    }

    final lowered = baseUrl.toLowerCase();
    if (lowered.contains('.local') ||
        lowered.contains('localhost') ||
        lowered.contains('127.0.0.1')) {
      throw StateError(
        'API_BASE_URL apunta a un host local en modo producción: $baseUrl',
      );
    }
  }
}
