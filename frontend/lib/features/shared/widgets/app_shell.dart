import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/auth_controller.dart';
import '../../settings/site_identity_provider.dart';
import 'user_menu_button.dart';

class NavigationItem {
  const NavigationItem({
    required this.label,
    required this.icon,
    required this.route,
    this.requiredPermission,
  });

  final String label;
  final IconData icon;
  final String route;
  final _NavigationPermission? requiredPermission;
}

class _NavigationPermission {
  const _NavigationPermission({
    required this.module,
    this.action = 'VIEW',
  });

  final String module;
  final String action;
}

const _navigationItems = <NavigationItem>[
  NavigationItem(label: 'Inicio', icon: Icons.dashboard_outlined, route: '/home'),
  NavigationItem(
    label: 'Ligas',
    icon: Icons.emoji_events_outlined,
    route: '/leagues',
    requiredPermission: _NavigationPermission(module: 'LIGAS'),
  ),
  NavigationItem(
    label: 'Clubes',
    icon: Icons.groups_2_outlined,
    route: '/clubs',
    requiredPermission: _NavigationPermission(module: 'CLUBES'),
  ),
  NavigationItem(
    label: 'Categorías',
    icon: Icons.category_outlined,
    route: '/categories',
    requiredPermission: _NavigationPermission(module: 'CATEGORIAS'),
  ),
  NavigationItem(
    label: 'Jugadores',
    icon: Icons.person_outline,
    route: '/players',
    requiredPermission: _NavigationPermission(module: 'JUGADORES'),
  ),
  NavigationItem(
    label: 'Torneos',
    icon: Icons.calendar_today_outlined,
    route: '/tournaments',
    requiredPermission: _NavigationPermission(module: 'TORNEOS'),
  ),
  NavigationItem(
    label: 'Zonas',
    icon: Icons.grid_view_outlined,
    route: '/zones',
    requiredPermission: _NavigationPermission(module: 'ZONAS'),
  ),
  NavigationItem(
    label: 'Fixture',
    icon: Icons.sports_soccer_outlined,
    route: '/fixtures',
    requiredPermission: _NavigationPermission(module: 'FIXTURE'),
  ),
  NavigationItem(
    label: 'Tablas',
    icon: Icons.leaderboard_outlined,
    route: '/standings',
    requiredPermission: _NavigationPermission(module: 'TABLAS'),
  ),
  NavigationItem(
    label: 'Configuración',
    icon: Icons.settings_outlined,
    route: '/settings',
    requiredPermission: _NavigationPermission(module: 'CONFIGURACION'),
  ),
];

final sidebarControllerProvider =
    StateNotifierProvider<SidebarController, bool>((ref) => SidebarController());

class SidebarController extends StateNotifier<bool> {
  SidebarController() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('sidebar_collapsed') ?? false;
  }

  Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    state = !state;
    await prefs.setBool('sidebar_collapsed', state);
  }
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late final ScrollController _horizontalScrollController;

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCollapsed = ref.watch(sidebarControllerProvider);
    final location = GoRouterState.of(context).uri.toString();
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final navigationItems = _navigationItems
        .where((item) {
          final permission = item.requiredPermission;
          if (permission == null) {
            return true;
          }
          return user?.hasPermission(
                module: permission.module,
                action: permission.action,
              ) ??
              false;
        })
        .toList();
    if (navigationItems.isEmpty && _navigationItems.isNotEmpty) {
      navigationItems.add(_navigationItems.first);
    }
    final currentIndex = navigationItems
        .indexWhere((item) => location == item.route || location.startsWith('${item.route}/'));
    final siteIdentity = ref.watch(siteIdentityProvider).valueOrNull;
    final width = MediaQuery.sizeOf(context).width;
    final autoCollapsed = width < 1024;
    final showCollapsed = autoCollapsed ? true : isCollapsed;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              extended: !showCollapsed,
              minExtendedWidth: 220,
              selectedIndex: currentIndex < 0 ? 0 : currentIndex,
              onDestinationSelected: (index) => context.go(navigationItems[index].route),
              leading: Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: siteIdentity?.iconUrl != null
                          ? Image.network(siteIdentity!.iconUrl!, fit: BoxFit.cover)
                          : const FlutterLogo(size: 36),
                    ),
                    const SizedBox(height: 16),
                    IconButton(
                      onPressed: () => ref.read(sidebarControllerProvider.notifier).toggle(),
                      icon: Icon(showCollapsed ? Icons.chevron_right : Icons.chevron_left),
                    )
                  ],
                ),
              ),
              labelType: showCollapsed ? NavigationRailLabelType.selected : NavigationRailLabelType.none,
              destinations: navigationItems
                  .map((item) => NavigationRailDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.icon, color: Theme.of(context).colorScheme.primary),
                        label: Text(item.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Row(
                      children: [
                        Spacer(),
                        UserMenuButton(),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: LayoutBuilder(
                      key: ValueKey(location),
                      builder: (context, constraints) {
                        final maxViewportWidth = constraints.maxWidth.isFinite
                            ? constraints.maxWidth
                            : MediaQuery.sizeOf(context).width;
                        final viewportWidth = maxViewportWidth.isFinite
                            ? maxViewportWidth
                            : MediaQuery.sizeOf(context).width;
                        final overflowAllowance = viewportWidth >= 1280.0 ? 0.0 : 640.0;
                        final maxContentWidth = viewportWidth + overflowAllowance;

                        return Scrollbar(
                          controller: _horizontalScrollController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          interactive: true,
                          scrollbarOrientation: ScrollbarOrientation.bottom,
                          thickness: 12,
                          radius: const Radius.circular(999),
                          child: SingleChildScrollView(
                            controller: _horizontalScrollController,
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: maxViewportWidth,
                                maxWidth: maxContentWidth,
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: KeyedSubtree(
                                  key: ValueKey(location),
                                  child: widget.child,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
