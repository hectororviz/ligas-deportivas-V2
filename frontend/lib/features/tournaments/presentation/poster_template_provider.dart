import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';
import 'poster_template.dart';

final posterTemplateProvider = FutureProvider.family<PosterTemplateConfig, int>((ref, competitionId) async {
  final response = await ref.read(apiClientProvider).get<Map<String, dynamic>>(
        '/competitions/$competitionId/poster-template',
      );
  final data = response.data;
  if (data is Map<String, dynamic>) {
    return PosterTemplateConfig.fromJson(data);
  }
  return const PosterTemplateConfig();
});

final posterTokenDefinitionsProvider = FutureProvider<List<PosterTemplateToken>>((ref) async {
  final response = await ref.read(apiClientProvider).get<List<dynamic>>('/matches/poster/tokens');
  final data = response.data;
  if (data is List) {
    return data
        .whereType<Map<String, dynamic>>()
        .map(PosterTemplateToken.fromJson)
        .where((token) => token.token.isNotEmpty)
        .toList();
  }
  return const [];
});
