import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: const [
        ListTile(
          leading: Icon(Icons.palette_outlined),
          title: Text('Colores por liga'),
          subtitle: Text('Configura los colores identificatorios de cada liga.'),
        ),
        ListTile(
          leading: Icon(Icons.security_outlined),
          title: Text('Permisos y roles'),
          subtitle: Text('Administra el acceso a módulos según rol y alcance.'),
        ),
      ],
    );
  }
}
