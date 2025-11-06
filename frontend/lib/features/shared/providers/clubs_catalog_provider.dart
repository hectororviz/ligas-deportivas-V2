import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';
import '../models/club_summary.dart';

final clubsCatalogProvider = FutureProvider<List<ClubSummary>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<Map<String, dynamic>>('/clubs', queryParameters: {
    'page': 1,
    'pageSize': 200,
    'status': 'active',
  });
  final json = response.data ?? {};
  final paginated = PaginatedClubs.fromJson(json);
  final clubs = [...paginated.clubs]
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return clubs;
});
