import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';
import '../domain/zone_models.dart';
import '../domain/zone_match_models.dart';

final zoneDetailProvider = FutureProvider.autoDispose.family<ZoneDetail, int>((ref, zoneId) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<Map<String, dynamic>>('/zones/$zoneId');
  final data = response.data ?? <String, dynamic>{};
  return ZoneDetail.fromJson(data);
});

final zoneMatchesProvider = FutureProvider.autoDispose.family<ZoneMatchesData, int>((ref, zoneId) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<Map<String, dynamic>>('/zones/$zoneId/matches');
  final data = response.data ?? <String, dynamic>{};
  return ZoneMatchesData.fromJson(data);
});
