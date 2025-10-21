import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

final appThemeProvider = Provider<AppTheme>((ref) => AppTheme(ref));
final appRouterProvider = Provider<GoRouter>((ref) => createRouter(ref));
