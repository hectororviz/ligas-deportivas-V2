import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../settings/site_identity_provider.dart';
import 'user_menu_button.dart';

class NavigationItem {
  const NavigationItem({
    required this.label,
    required this.icon,
    required this.route
  });

  final String label;
  final IconData icon;
  final String route;
}

const _navigationItems = <NavigationItem>[
  NavigationItem(label: 'Inicio', icon: Icons.dashboard_outlined, route: '/home'),
  NavigationItem(label: 'Ligas', icon: Icons.emoji_events_outlined, route: '/leagues'),
  NavigationItem(label: 'Clubes', icon: Icons.groups_2_outlined, route: '/clubs'),
  NavigationItem(label: 'Categorías', icon: Icons.category_outlined, route: '/categories'),
  NavigationItem(label: 'Jugadores', icon: Icons.person_outline, route: '/players'),
  NavigationItem(label: 'Torneos', icon: Icons.calendar_today_outlined, route: '/tournaments'),
  NavigationItem(label: 'Zonas', icon: Icons.grid_view_outlined, route: '/zones'),
  NavigationItem(label: 'Fixture', icon: Icons.sports_soccer_outlined, route: '/fixtures'),
  NavigationItem(label: 'Tablas', icon: Icons.leaderboard_outlined, route: '/standings'),
  NavigationItem(label: 'Configuración', icon: Icons.settings_outlined, route: '/settings'),
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
    final currentIndex = _navigationItems
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
              onDestinationSelected: (index) => context.go(_navigationItems[index].route),
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
              destinations: _navigationItems
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
                        final minContentWidth = maxViewportWidth.isFinite
                            ? maxViewportWidth
                            : MediaQuery.sizeOf(context).width;

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
                                minWidth: minContentWidth,
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
