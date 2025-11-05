import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../services/api_client.dart';
import '../shared/widgets/page_scaffold.dart';

final userListFiltersProvider =
    StateNotifierProvider<_UserListFiltersController, _UserListFilters>(
  (ref) => _UserListFiltersController(),
);

final usersProvider = FutureProvider<PaginatedUsers>((ref) async {
  final filters = ref.watch(userListFiltersProvider);
  final api = ref.read(apiClientProvider);
  final response = await api.get<Map<String, dynamic>>(
    '/users',
    queryParameters: {
      'page': filters.page,
      'pageSize': filters.pageSize,
      if (filters.search.trim().isNotEmpty) 'search': filters.search.trim(),
    },
  );
  final data = response.data ?? <String, dynamic>{};
  return PaginatedUsers.fromJson(data);
});

final rolesCatalogProvider = FutureProvider<List<RoleSummary>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<List<dynamic>>('/roles');
  final data = response.data ?? <dynamic>[];
  final roles = data
      .map((entry) => RoleSummary.fromJson(entry as Map<String, dynamic>))
      .toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return roles;
});

class UserManagementPage extends ConsumerStatefulWidget {
  const UserManagementPage({super.key});

  @override
  ConsumerState<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends ConsumerState<UserManagementPage> {
  late final TextEditingController _searchController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(userListFiltersProvider);
    _searchController = TextEditingController(text: filters.search);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(userListFiltersProvider.notifier).setSearch(_searchController.text);
    });
  }

  void _changePage(int page) {
    ref.read(userListFiltersProvider.notifier).setPage(page);
  }

  void _changePageSize(int pageSize) {
    ref.read(userListFiltersProvider.notifier).setPageSize(pageSize);
  }

  Future<void> _refresh() async {
    await ref.refresh(usersProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filters = ref.watch(userListFiltersProvider);
    final usersAsync = ref.watch(usersProvider);

    return PageScaffold(
      builder: (context, scrollController) {
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Administración de usuarios',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Visualiza la lista de cuentas registradas, envía enlaces de restablecimiento de contraseña y define los perfiles asignados.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              _FiltersBar(
                searchController: _searchController,
                filters: filters,
                onPageSizeChanged: _changePageSize,
              ),
              const SizedBox(height: 24),
              usersAsync.when(
                data: (paginated) {
                  if (paginated.users.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline, size: 48, color: theme.colorScheme.primary),
                            const SizedBox(height: 16),
                            Text(
                              filters.search.trim().isEmpty
                                  ? 'Aún no hay usuarios registrados.'
                                  : 'No se encontraron usuarios que coincidan con la búsqueda.',
                              style: theme.textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Verifica los filtros aplicados o intenta nuevamente más tarde.',
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            )
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      ...paginated.users
                          .map((user) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _UserCard(user: user),
                              ))
                          .toList(),
                      _PaginationControls(
                        pagination: paginated,
                        onPageChanged: _changePage,
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) {
                  return Card(
                    color: theme.colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ocurrió un error al cargar los usuarios.',
                              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onErrorContainer)),
                          const SizedBox(height: 8),
                          Text('$error',
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer)),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () => ref.invalidate(usersProvider),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.searchController,
    required this.filters,
    required this.onPageSizeChanged,
  });

  final TextEditingController searchController;
  final _UserListFilters filters;
  final ValueChanged<int> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 720;
        final dropdown = SizedBox(
          width: isWide ? 220 : double.infinity,
          child: DropdownButtonFormField<int>(
            value: filters.pageSize,
            decoration: const InputDecoration(
              labelText: 'Resultados por página',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 10, child: Text('10')), 
              DropdownMenuItem(value: 20, child: Text('20')), 
              DropdownMenuItem(value: 50, child: Text('50')),
            ],
            onChanged: (value) {
              if (value != null) {
                onPageSizeChanged(value);
              }
            },
          ),
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por nombre o correo',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              dropdown,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar por nombre o correo',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            dropdown,
          ],
        );
      },
    );
  }
}

class _PaginationControls extends StatelessWidget {
  const _PaginationControls({
    required this.pagination,
    required this.onPageChanged,
  });

  final PaginatedUsers pagination;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canGoBack = pagination.hasPrevious;
    final canGoForward = pagination.hasNext;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Mostrando ${(pagination.page - 1) * pagination.pageSize + 1}-${pagination.displayedItems} de ${pagination.total} usuarios',
            style: theme.textTheme.bodyMedium,
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: canGoBack ? () => onPageChanged(pagination.page - 1) : null,
                icon: const Icon(Icons.chevron_left),
                label: const Text('Anterior'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: canGoForward ? () => onPageChanged(pagination.page + 1) : null,
                icon: const Icon(Icons.chevron_right),
                label: const Text('Siguiente'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserCard extends ConsumerStatefulWidget {
  const _UserCard({required this.user});

  final ManagedUser user;

  @override
  ConsumerState<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends ConsumerState<_UserCard> {
  bool _isSendingReset = false;
  bool _isAssigning = false;
  final Set<int> _removingRoleIds = {};

  Future<void> _sendPasswordReset() async {
    if (_isSendingReset) {
      return;
    }
    setState(() => _isSendingReset = true);
    try {
      await ref.read(apiClientProvider).post('/users/${widget.user.id}/password-reset');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Se envió un enlace de restablecimiento a ${widget.user.email}.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo enviar el correo de restablecimiento: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSendingReset = false);
      }
    }
  }

  Future<void> _assignProfile() async {
    if (_isAssigning) {
      return;
    }
    setState(() => _isAssigning = true);
    try {
      final roles = await ref.read(rolesCatalogProvider.future);
      final assignedKeys = widget.user.roles.map((role) => role.roleKey).toSet();
      final available = roles.where((role) => !assignedKeys.contains(role.key)).toList();
      if (available.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Este usuario ya tiene asignados todos los perfiles disponibles.')),
          );
        }
        return;
      }

      final selected = await showDialog<RoleSummary?>(
        context: context,
        builder: (context) {
          RoleSummary? current = available.first;
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Asignar perfil'),
                content: DropdownButtonFormField<RoleSummary>(
                  value: current,
                  items: [
                    for (final role in available)
                      DropdownMenuItem<RoleSummary>(
                        value: role,
                        child: Text(role.name),
                      )
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Perfil',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => current = value),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: current == null
                        ? null
                        : () => Navigator.of(context).pop(current),
                    child: const Text('Asignar'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (!mounted || selected == null) {
        return;
      }

      await ref.read(apiClientProvider).post(
        '/users/${widget.user.id}/roles',
        data: {'roleKey': selected.key},
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Se asignó el perfil "${selected.name}".')),
      );
      ref.invalidate(usersProvider);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo asignar el perfil: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isAssigning = false);
      }
    }
  }

  Future<void> _removeRole(ManagedUserRole role) async {
    if (_removingRoleIds.contains(role.assignmentId)) {
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitar perfil'),
        content: Text('¿Deseas quitar el perfil "${role.roleName}" de este usuario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Quitar'),
          )
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    setState(() => _removingRoleIds.add(role.assignmentId));
    try {
      await ref.read(apiClientProvider).delete('/users/roles/${role.assignmentId}');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Se quitó el perfil "${role.roleName}".')),
      );
      ref.invalidate(usersProvider);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo quitar el perfil: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _removingRoleIds.remove(role.assignmentId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMMd('es');
    final user = widget.user;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        user.email,
                        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Registrado el ${dateFormat.format(user.createdAt)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (user.language != null && user.language!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Idioma preferido: ${user.language}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isSendingReset ? null : _sendPasswordReset,
                      icon: _isSendingReset
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.lock_reset),
                      label: Text(_isSendingReset ? 'Enviando...' : 'Enviar enlace de restablecimiento'),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Perfiles asignados',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (user.roles.isEmpty)
              Text(
                'Este usuario aún no tiene perfiles asignados.',
                style: theme.textTheme.bodyMedium,
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final role in user.roles)
                    InputChip(
                      label: Text(role.displayName),
                      avatar: const Icon(Icons.badge_outlined, size: 18),
                      onDeleted: _removingRoleIds.contains(role.assignmentId)
                          ? null
                          : () => _removeRole(role),
                    )
                ],
              ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _isAssigning ? null : _assignProfile,
              icon: _isAssigning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add_alt),
              label: Text(_isAssigning ? 'Asignando...' : 'Asignar perfil'),
            ),
          ],
        ),
      ),
    );
  }
}

class PaginatedUsers {
  PaginatedUsers({
    required this.users,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory PaginatedUsers.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? const [];
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    final pageSize = (meta['pageSize'] as int?) ?? (data.isEmpty ? 20 : data.length);
    final page = (meta['page'] as int?) ?? 1;
    final total = (meta['total'] as int?) ?? data.length;

    return PaginatedUsers(
      users: data
          .map((entry) => ManagedUser.fromJson(entry as Map<String, dynamic>))
          .toList(),
      total: total,
      page: page,
      pageSize: pageSize == 0 ? 1 : pageSize,
    );
  }

  final List<ManagedUser> users;
  final int total;
  final int page;
  final int pageSize;

  int get totalPages => (total / pageSize).ceil().clamp(1, double.infinity).toInt();

  bool get hasNext => page < totalPages;

  bool get hasPrevious => page > 1;

  int get displayedItems {
    final maxItems = page * pageSize;
    return maxItems > total ? total : maxItems;
  }
}

class ManagedUser {
  ManagedUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.language,
    required this.createdAt,
    required this.roles,
  });

  factory ManagedUser.fromJson(Map<String, dynamic> json) {
    final roles = (json['roles'] as List<dynamic>? ?? const [])
        .map((entry) => ManagedUserRole.fromJson(entry as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.roleName.toLowerCase().compareTo(b.roleName.toLowerCase()));

    return ManagedUser(
      id: json['id'] as int,
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      language: json['language'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      roles: roles,
    );
  }

  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String? language;
  final DateTime createdAt;
  final List<ManagedUserRole> roles;

  String get fullName {
    final pieces = [firstName, lastName].where((part) => part.trim().isNotEmpty).toList();
    if (pieces.isEmpty) {
      return email;
    }
    return pieces.join(' ');
  }
}

class ManagedUserRole {
  ManagedUserRole({
    required this.assignmentId,
    required this.roleKey,
    required this.roleName,
    this.leagueName,
    this.clubName,
    this.categoryName,
  });

  factory ManagedUserRole.fromJson(Map<String, dynamic> json) {
    final role = json['role'] as Map<String, dynamic>? ?? const {};
    final league = json['league'] as Map<String, dynamic>?;
    final club = json['club'] as Map<String, dynamic>?;
    final category = json['category'] as Map<String, dynamic>?;

    return ManagedUserRole(
      assignmentId: json['id'] as int,
      roleKey: role['key'] as String? ?? '',
      roleName: role['name'] as String? ?? (role['key'] as String? ?? 'Rol'),
      leagueName: league != null ? league['name'] as String? : null,
      clubName: club != null ? club['name'] as String? : null,
      categoryName: category != null ? category['name'] as String? : null,
    );
  }

  final int assignmentId;
  final String roleKey;
  final String roleName;
  final String? leagueName;
  final String? clubName;
  final String? categoryName;

  String get displayName {
    final scope = scopeLabel;
    if (scope == null) {
      return roleName;
    }
    return '$roleName · $scope';
  }

  String? get scopeLabel {
    final parts = <String>[];
    if (leagueName != null && leagueName!.isNotEmpty) {
      parts.add(leagueName!);
    }
    if (clubName != null && clubName!.isNotEmpty) {
      parts.add(clubName!);
    }
    if (categoryName != null && categoryName!.isNotEmpty) {
      parts.add(categoryName!);
    }
    if (parts.isEmpty) {
      return null;
    }
    return parts.join(' • ');
  }
}

class RoleSummary {
  const RoleSummary({
    required this.key,
    required this.name,
    this.description,
  });

  factory RoleSummary.fromJson(Map<String, dynamic> json) => RoleSummary(
        key: json['key'] as String,
        name: json['name'] as String? ?? json['key'] as String,
        description: json['description'] as String?,
      );

  final String key;
  final String name;
  final String? description;
}

class _UserListFilters {
  const _UserListFilters({
    this.search = '',
    this.page = 1,
    this.pageSize = 20,
  });

  final String search;
  final int page;
  final int pageSize;

  _UserListFilters copyWith({String? search, int? page, int? pageSize}) {
    return _UserListFilters(
      search: search ?? this.search,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class _UserListFiltersController extends StateNotifier<_UserListFilters> {
  _UserListFiltersController() : super(const _UserListFilters());

  void setSearch(String search) {
    state = state.copyWith(search: search, page: 1);
  }

  void setPage(int page) {
    final nextPage = page < 1 ? 1 : page;
    state = state.copyWith(page: nextPage);
  }

  void setPageSize(int pageSize) {
    final size = pageSize < 1 ? 1 : pageSize;
    state = state.copyWith(pageSize: size, page: 1);
  }
}
