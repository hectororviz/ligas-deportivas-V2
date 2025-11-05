import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_client.dart';

final rolesProvider = FutureProvider<List<RoleModel>>((ref) async {
  final response =
      await ref.read(apiClientProvider).get<List<dynamic>>('/roles');
  final data = response.data ?? [];
  return data
      .map((json) => RoleModel.fromJson(json as Map<String, dynamic>))
      .toList();
});

final permissionsCatalogProvider =
    FutureProvider<List<PermissionModel>>((ref) async {
  final response = await ref
      .read(apiClientProvider)
      .get<List<dynamic>>('/roles/permissions');
  final data = response.data ?? [];
  return data
      .map((json) => PermissionModel.fromJson(json as Map<String, dynamic>))
      .toList();
});

class RolePermissionsPage extends ConsumerStatefulWidget {
  const RolePermissionsPage({super.key});

  @override
  ConsumerState<RolePermissionsPage> createState() =>
      _RolePermissionsPageState();
}

class _RolePermissionsPageState extends ConsumerState<RolePermissionsPage> {
  int? _selectedRoleId;
  Set<int> _selectedPermissions = {};
  bool _isSaving = false;

  void _synchronizeSelectedRole(List<RoleModel> roles) {
    if (!mounted) {
      return;
    }

    int? newSelectedRoleId;
    Set<int>? newSelectedPermissions;

    if (roles.isEmpty) {
      if (_selectedRoleId != null || _selectedPermissions.isNotEmpty) {
        newSelectedRoleId = null;
        newSelectedPermissions = {};
      }
    } else if (_selectedRoleId == null ||
        !roles.any((role) => role.id == _selectedRoleId)) {
      final first = roles.first;
      newSelectedRoleId = first.id;
      newSelectedPermissions = {...first.permissionIds};
    } else {
      final current = roles.firstWhere((role) => role.id == _selectedRoleId);
      final updatedPermissions = {...current.permissionIds};
      if (_selectedPermissions.length != updatedPermissions.length ||
          !_selectedPermissions.containsAll(updatedPermissions)) {
        newSelectedPermissions = updatedPermissions;
      }
    }

    if (newSelectedRoleId != null || newSelectedPermissions != null) {
      final roleIdToApply = newSelectedRoleId ?? _selectedRoleId;
      final permissionsToApply = newSelectedPermissions ?? _selectedPermissions;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _selectedRoleId = roleIdToApply;
          _selectedPermissions = permissionsToApply;
        });
      });
    }
  }

  void _onRoleChanged(int? roleId, List<RoleModel> roles) {
    if (roleId == null) {
      return;
    }
    final role = roles.firstWhere((element) => element.id == roleId);
    setState(() {
      _selectedRoleId = roleId;
      _selectedPermissions = {...role.permissionIds};
    });
  }

  void _togglePermission(int permissionId, bool selected) {
    setState(() {
      if (selected) {
        _selectedPermissions.add(permissionId);
      } else {
        _selectedPermissions.remove(permissionId);
      }
    });
  }

  Future<void> _saveChanges() async {
    final roleId = _selectedRoleId;
    if (roleId == null || _isSaving) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref.read(apiClientProvider).patch(
        '/roles/$roleId/permissions',
        data: {'permissionIds': _selectedPermissions.toList()},
      );
      ref.invalidate(rolesProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permisos actualizados correctamente.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar permisos: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(rolesProvider);
    final permissionsAsync = ref.watch(permissionsCatalogProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Permisos y roles',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Define qué acciones puede realizar cada rol dentro del sistema y a qué alcance.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          rolesAsync.when(
            data: (roles) {
              _synchronizeSelectedRole(roles);
              return Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedRoleId,
                      decoration: const InputDecoration(labelText: 'Rol'),
                      onChanged: (value) => _onRoleChanged(value, roles),
                      items: roles
                          .map(
                            (role) => DropdownMenuItem<int>(
                              value: role.id,
                              child: Text(role.displayName),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: (_selectedRoleId == null || _isSaving)
                        ? null
                        : _saveChanges,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Guardar cambios'),
                  )
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                Center(child: Text('No se pudieron cargar los roles: $error')),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: permissionsAsync.when(
              data: (permissions) {
                if (permissions.isEmpty) {
                  return const Center(
                      child: Text('No hay permisos configurados.'));
                }
                final grouped = _groupByModule(permissions);
                return ListView(
                  children: grouped.entries.map((entry) {
                    final module = entry.key;
                    final modulePermissions = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        title: Text(_formatKey(module)),
                        children: modulePermissions.map((permission) {
                          final isSelected =
                              _selectedPermissions.contains(permission.id);
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: _selectedRoleId == null
                                ? null
                                : (value) => _togglePermission(
                                    permission.id, value ?? false),
                            title: Text(permission.displayName),
                            subtitle: Text(
                                'Acción: ${_formatKey(permission.action)} • Alcance: ${_formatKey(permission.scope)}'),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('No se pudieron cargar los permisos: $error'),
              ),
            ),
          )
        ],
      ),
    );
  }

  Map<String, List<PermissionModel>> _groupByModule(
      List<PermissionModel> permissions) {
    final map = <String, List<PermissionModel>>{};
    for (final permission in permissions) {
      map.putIfAbsent(permission.module, () => []).add(permission);
    }
    return map;
  }

  String _formatKey(String key) {
    return key
        .toLowerCase()
        .split('_')
        .map((segment) => segment.isEmpty
            ? segment
            : segment[0].toUpperCase() + segment.substring(1))
        .join(' ');
  }
}

class RoleModel {
  RoleModel({
    required this.id,
    required this.name,
    required this.key,
    required this.permissionIds,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    final permissions = json['permissions'] as List<dynamic>? ?? [];
    final permissionIds = <int>{};
    for (final entry in permissions) {
      if (entry is Map<String, dynamic>) {
        if (entry['permissionId'] is int) {
          permissionIds.add(entry['permissionId'] as int);
        }
        final permission = entry['permission'];
        if (permission is Map<String, dynamic> && permission['id'] is int) {
          permissionIds.add(permission['id'] as int);
        }
      }
    }
    return RoleModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      key: json['key'] as String? ?? '',
      permissionIds: permissionIds,
    );
  }

  final int id;
  final String name;
  final String key;
  final Set<int> permissionIds;

  String get displayName {
    if (name.isNotEmpty) {
      return name;
    }
    if (key.isNotEmpty) {
      return key
          .toLowerCase()
          .split('_')
          .map((segment) => segment.isEmpty
              ? segment
              : segment[0].toUpperCase() + segment.substring(1))
          .join(' ');
    }
    return 'Rol #$id';
  }
}

class PermissionModel {
  PermissionModel({
    required this.id,
    required this.module,
    required this.action,
    required this.scope,
    this.description,
  });

  factory PermissionModel.fromJson(Map<String, dynamic> json) =>
      PermissionModel(
        id: json['id'] as int,
        module: json['module'] as String? ?? 'DESCONOCIDO',
        action: json['action'] as String? ?? 'DESCONOCIDO',
        scope: json['scope'] as String? ?? 'GLOBAL',
        description: json['description'] as String?,
      );

  final int id;
  final String module;
  final String action;
  final String scope;
  final String? description;

  String get displayName => description?.isNotEmpty == true
      ? description!
      : '${_titleCase(action)} (${_titleCase(scope)})';

  String _titleCase(String value) {
    return value
        .toLowerCase()
        .split('_')
        .map((segment) => segment.isEmpty
            ? segment
            : segment[0].toUpperCase() + segment.substring(1))
        .join(' ');
  }
}
