import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';
import '../shared/models/club_summary.dart';
import '../shared/providers/clubs_catalog_provider.dart';
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
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            const _UsersTableHeader(),
                            const Divider(height: 1),
                            for (var i = 0; i < paginated.users.length; i++) ...[
                              _UserRow(user: paginated.users[i]),
                              if (i != paginated.users.length - 1)
                                const Divider(height: 1),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
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

class _UsersTableHeader extends StatelessWidget {
  const _UsersTableHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Container(
      color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Nombre', style: style)),
          Expanded(flex: 3, child: Text('Email', style: style)),
          Expanded(flex: 2, child: Text('Perfil', style: style)),
          Expanded(flex: 2, child: Text('Club', style: style)),
          SizedBox(
            width: 160,
            child: Text(
              'Restablecer clave',
              style: style,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              'Eliminar',
              style: style,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserRow extends ConsumerStatefulWidget {
  const _UserRow({required this.user});

  final ManagedUser user;

  @override
  ConsumerState<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends ConsumerState<_UserRow> {
  bool _isSendingReset = false;
  bool _isUpdatingRole = false;
  bool _isUpdatingClub = false;
  bool _isDeleting = false;
  int? _selectedClubId;
  String? _selectedRoleKey;
  int? _currentRoleAssignmentId;

  @override
  void initState() {
    super.initState();
    _selectedClubId = widget.user.club?.id;
    _selectedRoleKey = widget.user.primaryRole?.roleKey;
    _currentRoleAssignmentId = widget.user.primaryRole?.assignmentId;
  }

  @override
  void didUpdateWidget(covariant _UserRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id ||
        oldWidget.user.club?.id != widget.user.club?.id) {
      _selectedClubId = widget.user.club?.id;
    }
    final oldRoleKey = oldWidget.user.primaryRole?.roleKey;
    final newRoleKey = widget.user.primaryRole?.roleKey;
    if (oldWidget.user.id != widget.user.id || oldRoleKey != newRoleKey) {
      _selectedRoleKey = newRoleKey;
      _currentRoleAssignmentId = widget.user.primaryRole?.assignmentId;
    }
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    return result == true;
  }

  Future<void> _handlePasswordReset() async {
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

  Future<void> _handleDeleteUser() async {
    if (_isDeleting) {
      return;
    }

    final confirmed = await _showConfirmationDialog(
      title: 'Eliminar usuario',
      message:
          '¿Deseas eliminar la cuenta de ${widget.user.fullName}? Esta acción no se puede deshacer.',
    );

    if (!confirmed) {
      return;
    }

    setState(() => _isDeleting = true);
    try {
      await ref.read(apiClientProvider).delete('/users/${widget.user.id}');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Se eliminó la cuenta de ${widget.user.email}.')),
      );
      ref.invalidate(usersProvider);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar la cuenta: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _handleClubChange(int? clubId) async {
    if (_isUpdatingClub || clubId == _selectedClubId) {
      return;
    }

    final confirmed = await _showConfirmationDialog(
      title: 'Actualizar club',
      message: clubId == null
          ? '¿Deseas quitar el club asociado de este usuario?'
          : '¿Deseas asociar este usuario al club seleccionado?',
    );

    if (!confirmed) {
      setState(() {});
      return;
    }

    final previousClubId = _selectedClubId;
    setState(() {
      _selectedClubId = clubId;
      _isUpdatingClub = true;
    });

    try {
      await ref.read(apiClientProvider).patch(
            '/users/${widget.user.id}',
            data: {'clubId': clubId},
          );
      if (!mounted) {
        return;
      }
      final message = clubId == null
          ? 'Se quitó el club asociado.'
          : 'Se actualizó el club asociado.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      ref.invalidate(usersProvider);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el club asociado: $error')),
      );
      setState(() {
        _selectedClubId = previousClubId;
      });
    } finally {
      if (mounted) {
        setState(() => _isUpdatingClub = false);
      }
    }
  }

  Future<void> _handleRoleChange(String? roleKey) async {
    if (_isUpdatingRole || roleKey == _selectedRoleKey) {
      return;
    }

    final confirmed = await _showConfirmationDialog(
      title: 'Actualizar perfil',
      message: roleKey == null
          ? '¿Deseas quitar el perfil asignado a este usuario?'
          : '¿Deseas asignar el perfil seleccionado a este usuario?',
    );

    if (!confirmed) {
      setState(() {});
      return;
    }

    final previousRoleKey = _selectedRoleKey;
    final previousAssignmentId = _currentRoleAssignmentId;

    final isDifferent = previousRoleKey != roleKey;

    setState(() {
      _selectedRoleKey = roleKey;
      _isUpdatingRole = true;
      if (isDifferent) {
        _currentRoleAssignmentId = null;
      }
    });

    try {
      final client = ref.read(apiClientProvider);

      if (previousAssignmentId != null && previousRoleKey != roleKey) {
        await client.delete('/users/roles/$previousAssignmentId');
      }

      if (roleKey != null) {
        await client.post(
          '/users/${widget.user.id}/roles',
          data: {'roleKey': roleKey},
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            roleKey == null ? 'Se quitó el perfil asignado.' : 'Se actualizó el perfil asignado.',
          ),
        ),
      );
      ref.invalidate(usersProvider);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el perfil: $error')),
      );
      setState(() {
        _selectedRoleKey = previousRoleKey;
        _currentRoleAssignmentId = previousAssignmentId;
      });
    } finally {
      if (mounted) {
        setState(() => _isUpdatingRole = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rolesAsync = ref.watch(rolesCatalogProvider);
    final clubsAsync = ref.watch(clubsCatalogProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              widget.user.fullName,
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: SelectableText(
              widget.user.email,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: rolesAsync.when(
              data: (roles) {
                final items = <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Sin perfil'),
                  ),
                  ...roles.map(
                    (role) => DropdownMenuItem<String?>(
                      value: role.key,
                      child: Text(role.name),
                    ),
                  ),
                ];
                return Row(
                  children: [
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          value: _selectedRoleKey,
                          items: items,
                          onChanged: _isUpdatingRole
                              ? null
                              : (value) {
                                  unawaited(_handleRoleChange(value));
                                },
                        ),
                      ),
                    ),
                    if (_isUpdatingRole)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (error, stackTrace) => Text(
                'Error al cargar perfiles',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: clubsAsync.when(
              data: (clubs) {
                final items = <DropdownMenuItem<int?>>[
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Sin club'),
                  ),
                  ...clubs.map(
                    (club) => DropdownMenuItem<int?>(
                      value: club.id,
                      child: Text(club.name),
                    ),
                  ),
                ];
                return Row(
                  children: [
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          isExpanded: true,
                          value: _selectedClubId,
                          items: items,
                          onChanged: _isUpdatingClub
                              ? null
                              : (value) {
                                  unawaited(_handleClubChange(value));
                                },
                        ),
                      ),
                    ),
                    if (_isUpdatingClub)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (error, stackTrace) => Text(
                'Error al cargar clubes',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 160,
            child: Align(
              alignment: Alignment.center,
              child: TextButton.icon(
                onPressed: _isSendingReset
                    ? null
                    : () {
                        unawaited(_handlePasswordReset());
                      },
                icon: _isSendingReset
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_reset),
                label: Text(_isSendingReset ? 'Enviando...' : 'Restablecer'),
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: Center(
              child: IconButton(
                tooltip: 'Eliminar cuenta',
                onPressed: _isDeleting ? null : _handleDeleteUser,
                icon: _isDeleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline),
              ),
            ),
          ),
        ],
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
    required this.club,
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
      club: json['club'] == null
          ? null
          : ClubSummary.fromJson(json['club'] as Map<String, dynamic>),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      roles: roles,
    );
  }

  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String? language;
  final ClubSummary? club;
  final DateTime createdAt;
  final List<ManagedUserRole> roles;

  String get fullName {
    final pieces = [firstName, lastName].where((part) => part.trim().isNotEmpty).toList();
    if (pieces.isEmpty) {
      return email;
    }
    return pieces.join(' ');
  }

  ManagedUserRole? get primaryRole {
    if (roles.isEmpty) {
      return null;
    }
    return roles.first;
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
