import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';
import '../../shared/widgets/page_scaffold.dart';

const _defaultPageSize = 100;

final adminUsersProvider = FutureProvider<PaginatedAdminUsers>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<Map<String, dynamic>>(
    '/users',
    queryParameters: {
      'page': 1,
      'pageSize': _defaultPageSize,
    },
  );
  final data = response.data ?? <String, dynamic>{};
  return PaginatedAdminUsers.fromJson(data);
});

final clubsOptionsProvider = FutureProvider<List<ClubOption>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<Map<String, dynamic>>(
    '/clubs',
    queryParameters: {
      'page': 1,
      'pageSize': 200,
      'status': 'active',
    },
  );
  final data = response.data ?? <String, dynamic>{};
  return ClubCatalog.fromJson(data).clubs
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
});

class UsersAdminPage extends ConsumerStatefulWidget {
  const UsersAdminPage({super.key});

  @override
  ConsumerState<UsersAdminPage> createState() => _UsersAdminPageState();
}

class _UsersAdminPageState extends ConsumerState<UsersAdminPage> {
  final Set<int> _updatingUsers = {};

  Future<void> _updateUserClub(AdminUser user, int? clubId) async {
    final currentClubId = user.club?.id;
    if (currentClubId == clubId || (_isNullish(currentClubId) && _isNullish(clubId))) {
      return;
    }

    setState(() => _updatingUsers.add(user.id));

    try {
      await ref.read(apiClientProvider).patch(
            '/users/${user.id}',
            data: {'clubId': clubId},
          );
      ref.invalidate(adminUsersProvider);
      if (!mounted) {
        return;
      }
      final message = clubId == null
          ? 'El usuario fue desvinculado del club correctamente.'
          : 'Club actualizado correctamente.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el club: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingUsers.remove(user.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final clubsAsync = ref.watch(clubsOptionsProvider);

    return PageScaffold(
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24.0),
          children: [
            Text(
              'Administración de usuarios',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Asocia cada usuario a un club para facilitar la gestión de permisos y responsabilidades.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: usersAsync.when(
                  data: (page) {
                    if (page.users.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('No hay usuarios registrados en el sistema.'),
                        ),
                      );
                    }

                    final clubOptions = clubsAsync.valueOrNull ?? <ClubOption>[];
                    final isLoadingClubs = clubsAsync.isLoading;
                    final clubsError = clubsAsync.hasError ? clubsAsync.error : null;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mostrando ${page.users.length} de ${page.total} usuarios registrados.',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (clubsError != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No se pudieron cargar los clubes disponibles: $clubsError',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.redAccent),
                                ),
                              )
                            ],
                          ),
                        ] else if (isLoadingClubs) ...[
                          const SizedBox(height: 12),
                          const LinearProgressIndicator(),
                        ],
                        const SizedBox(height: 16),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final user = page.users[index];
                            final isUpdating = _updatingUsers.contains(user.id);
                            final dropdownItems = _buildClubOptions(
                              clubOptions: clubOptions,
                              currentClub: user.club,
                            );
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withOpacity(0.6),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.displayName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          user.email,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 320),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Expanded(
                                          child: DropdownButtonFormField<int?>(
                                            value: user.club?.id,
                                            items: dropdownItems,
                                            decoration: const InputDecoration(
                                              labelText: 'Club asociado',
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (isUpdating || isLoadingClubs)
                                                ? null
                                                : (value) => _updateUserClub(user, value),
                                          ),
                                        ),
                                        if (isUpdating) ...[
                                          const SizedBox(width: 12),
                                          const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ],
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            );
                          },
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemCount: page.users.length,
                        ),
                        if (page.total > page.users.length) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Se muestran los primeros ${page.users.length} usuarios. Ajusta el tamaño de página si necesitas ver más.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ]
                      ],
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stack) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
                        const SizedBox(height: 12),
                        Text(
                          'No se pudieron cargar los usuarios: $error',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<DropdownMenuItem<int?>> _buildClubOptions({
    required List<ClubOption> clubOptions,
    ClubOption? currentClub,
  }) {
    final items = <DropdownMenuItem<int?>>[
      const DropdownMenuItem<int?>(
        value: null,
        child: Text('Sin club asignado'),
      ),
      ...clubOptions.map(
        (club) => DropdownMenuItem<int?>(
          value: club.id,
          child: Text(club.name),
        ),
      ),
    ];

    if (currentClub != null && !items.any((item) => item.value == currentClub.id)) {
      items.add(
        DropdownMenuItem<int?>(
          value: currentClub.id,
          enabled: false,
          child: Text('${currentClub.name} (inactivo)'),
        ),
      );
    }

    return items;
  }
}

bool _isNullish(int? value) => value == null;

class PaginatedAdminUsers {
  PaginatedAdminUsers({
    required this.users,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory PaginatedAdminUsers.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as List<dynamic>? ?? [])
        .map((item) => AdminUser.fromJson(item as Map<String, dynamic>))
        .toList();
    final meta = json['meta'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return PaginatedAdminUsers(
      users: data,
      total: meta['total'] as int? ?? data.length,
      page: meta['page'] as int? ?? 1,
      pageSize: meta['pageSize'] as int? ?? data.length,
    );
  }

  final List<AdminUser> users;
  final int total;
  final int page;
  final int pageSize;
}

class AdminUser {
  AdminUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.club,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    final clubJson = json['club'] as Map<String, dynamic>?;
    return AdminUser(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      club: clubJson == null ? null : ClubOption.fromJson(clubJson),
    );
  }

  final int id;
  final String email;
  final String? firstName;
  final String? lastName;
  final ClubOption? club;

  String get displayName {
    final parts = <String>[
      if ((firstName ?? '').trim().isNotEmpty) firstName!.trim(),
      if ((lastName ?? '').trim().isNotEmpty) lastName!.trim(),
    ];
    return parts.isEmpty ? email : parts.join(' ');
  }
}

class ClubOption {
  const ClubOption({required this.id, required this.name});

  factory ClubOption.fromJson(Map<String, dynamic> json) {
    return ClubOption(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  final int id;
  final String name;
}

class ClubCatalog {
  ClubCatalog({required this.clubs, required this.total});

  factory ClubCatalog.fromJson(Map<String, dynamic> json) {
    final clubs = (json['data'] as List<dynamic>? ?? [])
        .map((item) => ClubOption.fromJson(item as Map<String, dynamic>))
        .toList();
    final meta = json['meta'] as Map<String, dynamic>?;
    final total = meta != null
        ? meta['total'] as int? ?? clubs.length
        : json['total'] as int? ?? clubs.length;
    return ClubCatalog(clubs: clubs, total: total);
  }

  final List<ClubOption> clubs;
  final int total;
}
