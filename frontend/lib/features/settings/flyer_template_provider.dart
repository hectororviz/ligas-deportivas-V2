import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_client.dart';
import 'flyer_template.dart';

final flyerTemplateProvider = FutureProvider<FlyerTemplateConfig>((ref) async {
  final response = await ref.read(apiClientProvider).get<Map<String, dynamic>>('/site-identity/flyer-template');
  final data = response.data;
  if (data is Map<String, dynamic>) {
    return FlyerTemplateConfig.fromJson(data);
  }
  return const FlyerTemplateConfig();
});

final flyerTokenDefinitionsProvider = FutureProvider<List<FlyerTemplateToken>>((ref) async {
  final response = await ref.read(apiClientProvider).get<List<dynamic>>('/matches/flyer/tokens');
  final data = response.data;
  if (data is List) {
    return data
        .whereType<Map<String, dynamic>>()
        .map(FlyerTemplateToken.fromJson)
        .where((token) => token.token.isNotEmpty)
        .toList();
  }
  return const [];
});
