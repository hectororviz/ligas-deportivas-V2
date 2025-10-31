import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_client.dart';
import 'site_identity.dart';

final siteIdentityProvider = FutureProvider<SiteIdentity>((ref) async {
  final response = await ref.read(apiClientProvider).get<Map<String, dynamic>>('/site-identity');
  final data = response.data;
  if (data is Map<String, dynamic>) {
    return SiteIdentity.fromJson(data);
  }
  return const SiteIdentity(title: 'Ligas Deportivas');
});
