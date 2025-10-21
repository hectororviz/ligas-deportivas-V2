import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/fixtures/presentation/fixtures_page.dart';
import '../../features/home/home_page.dart';
import '../../features/leagues/presentation/leagues_page.dart';
import '../../features/results/presentation/results_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/shared/widgets/app_shell.dart';
import '../../features/standings/presentation/standings_page.dart';
import '../../features/tournaments/presentation/tournaments_page.dart';
import '../../services/auth_controller.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListener = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> notifyListener;

  @override
  void dispose() {
    notifyListener.cancel();
    super.dispose();
  }
}

GoRouter createRouter(Ref ref) {
  final authNotifier = ref.read(authControllerProvider.notifier);
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: GoRouterRefreshStream(authNotifier.stream),
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      if (!authState.isAuthenticated && !loggingIn) {
        return '/login';
      }
      if (authState.isAuthenticated && loggingIn) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomePage()),
          GoRoute(path: '/leagues', builder: (context, state) => const LeaguesPage()),
          GoRoute(path: '/tournaments', builder: (context, state) => const TournamentsPage()),
          GoRoute(path: '/fixtures', builder: (context, state) => const FixturesPage()),
          GoRoute(path: '/results', builder: (context, state) => const ResultsPage()),
          GoRoute(path: '/standings', builder: (context, state) => const StandingsPage()),
          GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
        ],
      )
    ],
  );
}
