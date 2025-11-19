import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.web_asset_outlined),
            title: const Text('Identidad del sitio'),
            subtitle: const Text('Personaliza el ícono y el título visibles en la plataforma.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/identity'),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Perfil de usuario'),
            subtitle: const Text('Actualiza tus datos personales, idioma y avatar.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/account'),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.group_outlined),
            title: const Text('Administración de usuarios'),
            subtitle: const Text('Consulta y gestiona los usuarios registrados en la plataforma.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/users'),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Colores por liga'),
            subtitle:
                const Text('Configura los colores identificatorios de cada liga.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/colors'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text('Permisos y roles'),
            subtitle:
                const Text('Administra el acceso a módulos según rol y alcance.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/permissions'),
          ),
        ),
      ],
    );
  }
}
