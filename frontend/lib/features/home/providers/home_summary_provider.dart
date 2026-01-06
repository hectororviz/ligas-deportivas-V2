import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';
import '../domain/home_summary.dart';

final homeSummaryProvider = FutureProvider<HomeSummary>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<Map<String, dynamic>>('/home/summary');
  return HomeSummary.fromJson(response.data ?? <String, dynamic>{});
});
