import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/fixtures/presentation/fixtures_page.dart';
import '../../features/home/home_page.dart';
import '../../features/leagues/presentation/leagues_page.dart';
import '../../features/clubs/presentation/clubs_page.dart';
import '../../features/clubs/presentation/club_admin_page.dart';
import '../../features/categories/presentation/categories_page.dart';
import '../../features/players/presentation/players_page.dart';
import '../../features/settings/league_colors_page.dart';
import '../../features/settings/role_permissions_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/settings/account_settings_page.dart';
import '../../features/settings/site_identity_page.dart';
import '../../features/shared/widgets/app_shell.dart';
import '../../features/standings/presentation/standings_page.dart';
import '../../features/standings/presentation/zone_standings_page.dart';
import '../../features/tournaments/presentation/tournaments_page.dart';
import '../../features/zones/presentation/zones_page.dart';
import '../../features/zones/domain/zone_match_models.dart';
import '../../features/zones/presentation/zone_fixture_page.dart';
import '../../features/zones/presentation/zone_match_detail_page.dart';
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
          GoRoute(path: '/clubs', builder: (context, state) => const ClubsPage()),
          GoRoute(
            path: '/club/:slug',
            builder: (context, state) {
              final slug = state.pathParameters['slug']!;
              return ClubAdminPage(slug: slug);
            },
          ),
          GoRoute(path: '/categories', builder: (context, state) => const CategoriesPage()),
          GoRoute(path: '/players', builder: (context, state) => const PlayersPage()),
          GoRoute(path: '/tournaments', builder: (context, state) => const TournamentsPage()),
          GoRoute(path: '/zones', builder: (context, state) => const ZonesPage()),
          GoRoute(
            path: '/zones/:zoneId/standings',
            builder: (context, state) {
              final rawId = state.pathParameters['zoneId'];
              final zoneId = rawId != null ? int.tryParse(rawId) : null;
              if (zoneId == null) {
                return const Center(child: Text('Zona no válida'));
              }
              return ZoneStandingsPage(zoneId: zoneId);
            },
          ),
          GoRoute(
            path: '/zones/:zoneId/fixture',
            builder: (context, state) {
              final rawId = state.pathParameters['zoneId'];
              final zoneId = rawId != null ? int.tryParse(rawId) : null;
              if (zoneId == null) {
                return const Center(child: Text('Zona no válida'));
              }
              final extra = state.extra;
              final viewOnly = extra is ZoneFixturePageArgs ? extra.viewOnly : false;
              return ZoneFixturePage(zoneId: zoneId, viewOnly: viewOnly);
            },
            routes: [
              GoRoute(
                path: 'matches/:matchId',
                builder: (context, state) {
                  final zoneParam = state.pathParameters['zoneId'];
                  final matchParam = state.pathParameters['matchId'];
                  final zoneId = zoneParam != null ? int.tryParse(zoneParam) : null;
                  final matchId = matchParam != null ? int.tryParse(matchParam) : null;
                  if (zoneId == null || matchId == null) {
                    return const Center(child: Text('Partido no válido'));
                  }
                  final extra = state.extra;
                  ZoneMatch? initialMatch;
                  if (extra is ZoneMatch) {
                    initialMatch = extra;
                  }
                  return ZoneMatchDetailPage(
                    zoneId: zoneId,
                    matchId: matchId,
                    initialMatch: initialMatch,
                  );
                },
              ),
            ],
          ),
          GoRoute(path: '/fixtures', builder: (context, state) => const FixturesPage()),
          GoRoute(path: '/standings', builder: (context, state) => const StandingsPage()),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
            routes: [
              GoRoute(
                path: 'identity',
                builder: (context, state) => const SiteIdentityPage(),
              ),
              GoRoute(
                path: 'account',
                builder: (context, state) => const AccountSettingsPage(),
              ),
              GoRoute(
                path: 'colors',
                builder: (context, state) => const LeagueColorsPage(),
              ),
              GoRoute(
                path: 'permissions',
                builder: (context, state) => const RolePermissionsPage(),
              )
            ],
          ),
        ],
      )
    ],
  );
}
