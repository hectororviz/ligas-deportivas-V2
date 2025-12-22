import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../services/auth_controller.dart';

enum _UserMenuAction { settings, logout, login }

class UserMenuButton extends ConsumerWidget {
  const UserMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    if (user == null) {
      return PopupMenuButton<_UserMenuAction>(
        onSelected: (action) => _onSelected(context, ref, action),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (context) => const [
          PopupMenuItem(value: _UserMenuAction.login, child: Text('Iniciar sesión')),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(radius: 20, child: Icon(Icons.person_outline)),
            const SizedBox(height: 6),
            SizedBox(
              width: 120,
              child: Text(
                'Invitado',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          ],
        ),
      );
    }

    final avatarUrl = user.avatarUrls?['96'];
    final initials = user.initials.isEmpty
        ? (user.fullName.isNotEmpty ? user.fullName[0] : '?')
        : user.initials;

    return PopupMenuButton<_UserMenuAction>(
      onSelected: (action) => _onSelected(context, ref, action),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => const [
        PopupMenuItem(value: _UserMenuAction.settings, child: Text('Configurar')),
        PopupMenuDivider(),
        PopupMenuItem(value: _UserMenuAction.logout, child: Text('Cerrar sesión')),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null ? Text(initials) : null,
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 120,
            child: Text(
              user.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        ],
      ),
    );
  }

  Future<void> _onSelected(BuildContext context, WidgetRef ref, _UserMenuAction action) async {
    switch (action) {
      case _UserMenuAction.settings:
        if (context.mounted) {
          context.go('/settings/account');
        }
        break;
      case _UserMenuAction.logout:
        await ref.read(authControllerProvider.notifier).logout();
        if (context.mounted) {
          context.go('/home');
        }
        break;
      case _UserMenuAction.login:
        if (context.mounted) {
          context.go('/login');
        }
        break;
    }
  }
}
