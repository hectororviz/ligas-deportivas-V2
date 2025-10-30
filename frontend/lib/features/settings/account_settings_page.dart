import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/auth_controller.dart';

class AccountSettingsPage extends ConsumerStatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  ConsumerState<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends ConsumerState<AccountSettingsPage> {
  final _profileFormKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();
  final _securityFormKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final TextEditingController _languageController = TextEditingController();
  final TextEditingController _emailChangeController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _savingProfile = false;
  bool _requestingEmailChange = false;
  bool _savingPassword = false;
  bool _uploadingAvatar = false;
  String? _avatarPreviewUrl;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _languageController.text = user?.language ?? 'es-AR';
    _avatarPreviewUrl = user?.avatarUrls?['256'];

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      final nextUser = next.user;
      if (nextUser != null && mounted) {
        setState(() {
          _nameController.text = nextUser.fullName;
          _emailController.text = nextUser.email;
          _languageController.text = nextUser.language ?? _languageController.text;
          _avatarPreviewUrl = nextUser.avatarUrls?['256'] ?? _avatarPreviewUrl;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _languageController.dispose();
    _emailChangeController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: DefaultTabController(
        length: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Configuración de la cuenta', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Administra tus datos personales, seguridad y avatar desde un único lugar.',
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            TabBar(
              labelColor: theme.colorScheme.primary,
              indicatorColor: theme.colorScheme.primary,
              isScrollable: true,
              tabs: const [
                Tab(icon: Icon(Icons.person_outline), text: 'Perfil'),
                Tab(icon: Icon(Icons.lock_outline), text: 'Seguridad'),
                Tab(icon: Icon(Icons.image_outlined), text: 'Avatar'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  _buildProfileTab(context),
                  _buildSecurityTab(context),
                  _buildAvatarTab(context),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.only(right: 8.0),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _profileFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Datos personales', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nombre completo'),
                    validator: (value) => (value == null || value.trim().length < 3)
                        ? 'Ingresa un nombre válido'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _languageController.text.isEmpty ? 'es-AR' : _languageController.text,
                    decoration: const InputDecoration(labelText: 'Idioma'),
                    items: const [
                      DropdownMenuItem(value: 'es-AR', child: Text('Español (Argentina)')),
                      DropdownMenuItem(value: 'es-ES', child: Text('Español (España)')),
                      DropdownMenuItem(value: 'en-US', child: Text('Inglés (EE.UU.)')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _languageController.text = value;
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Correo electrónico'),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: _savingProfile ? null : () => _submitProfile(context),
                      child: _savingProfile
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Guardar cambios'),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _emailFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cambiar correo electrónico', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Text(
                    'Recibirás un enlace de confirmación en tu correo actual para validar el cambio.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailChangeController,
                    decoration: const InputDecoration(labelText: 'Nuevo correo'),
                    validator: (value) =>
                        (value == null || value.isEmpty || !value.contains('@')) ? 'Ingresa un correo válido' : null,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed:
                          _requestingEmailChange ? null : () => _submitEmailChange(context),
                      child: _requestingEmailChange
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Enviar confirmación'),
                    ),
                  )
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildSecurityTab(BuildContext context) {
    final theme = Theme.of(context);
    final strength = _passwordStrength(_newPasswordController.text);
    return ListView(
      padding: const EdgeInsets.only(right: 8.0),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _securityFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Actualizar contraseña', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _currentPasswordController,
                    decoration: const InputDecoration(labelText: 'Contraseña actual'),
                    obscureText: true,
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Ingresa tu contraseña actual' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _newPasswordController,
                    decoration: const InputDecoration(labelText: 'Nueva contraseña'),
                    obscureText: true,
                    onChanged: (_) => setState(() {}),
                    validator: (value) =>
                        (value == null || value.length < 12) ? 'Debe tener al menos 12 caracteres' : null,
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: strength / 4,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    color: strength >= 3
                        ? theme.colorScheme.primary
                        : strength >= 2
                            ? Colors.orange
                            : Colors.redAccent,
                  ),
                  const SizedBox(height: 8),
                  Text('Debe incluir mayúsculas, minúsculas y números.', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: const InputDecoration(labelText: 'Confirmar nueva contraseña'),
                    obscureText: true,
                    validator: (value) => value != _newPasswordController.text ? 'Las contraseñas no coinciden' : null,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: _savingPassword ? null : () => _submitPassword(context),
                      child: _savingPassword
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Actualizar contraseña'),
                    ),
                  )
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildAvatarTab(BuildContext context) {
    final theme = Theme.of(context);
    final avatarUrl = _avatarPreviewUrl ?? ref.watch(authControllerProvider).user?.avatarUrls?['256'];
    return ListView(
      padding: const EdgeInsets.only(right: 8.0),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Foto de perfil', style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null
                          ? Text(ref.watch(authControllerProvider).user?.initials ?? '')
                          : null,
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Formatos permitidos: JPEG, PNG o WebP. Tamaño máximo 2 MB.'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              FilledButton.icon(
                                onPressed: _uploadingAvatar ? null : () => _pickAvatar(context),
                                icon: const Icon(Icons.upload_outlined),
                                label: const Text('Subir imagen'),
                              ),
                              if (_uploadingAvatar) ...[
                                const SizedBox(width: 16),
                                const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              ]
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  Future<void> _submitProfile(BuildContext context) async {
    if (!_profileFormKey.currentState!.validate()) {
      return;
    }
    setState(() => _savingProfile = true);
    try {
      await ref.read(authControllerProvider.notifier).updateProfileSettings(
            name: _nameController.text.trim(),
            language: _languageController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar el perfil: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingProfile = false);
      }
    }
  }

  Future<void> _submitEmailChange(BuildContext context) async {
    if (!_emailFormKey.currentState!.validate()) {
      return;
    }
    setState(() => _requestingEmailChange = true);
    try {
      await ref.read(authControllerProvider.notifier).requestEmailChange(
            _emailChangeController.text.trim(),
          );
      _emailChangeController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enviamos un correo para confirmar el cambio.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo solicitar el cambio: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _requestingEmailChange = false);
      }
    }
  }

  Future<void> _submitPassword(BuildContext context) async {
    if (!_securityFormKey.currentState!.validate()) {
      return;
    }
    setState(() => _savingPassword = true);
    try {
      await ref.read(authControllerProvider.notifier).changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La contraseña se actualizó correctamente.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cambiar la contraseña: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingPassword = false);
      }
    }
  }

  Future<void> _pickAvatar(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return;
      }
      final file = result.files.single;
      final Uint8List? bytes = file.bytes;
      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo leer el archivo seleccionado.')),
        );
        return;
      }
      setState(() => _uploadingAvatar = true);
      final urls = await ref.read(authControllerProvider.notifier).uploadAvatar(
            bytes: bytes.toList(),
            filename: file.name,
          );
      if (urls != null && mounted) {
        setState(() => _avatarPreviewUrl = urls['256'] ?? _avatarPreviewUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Actualizamos tu foto de perfil.')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el avatar: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingAvatar = false);
      }
    }
  }

  int _passwordStrength(String value) {
    var score = 0;
    if (value.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(value)) score++;
    if (RegExp(r'[a-z]').hasMatch(value)) score++;
    if (RegExp(r'\d').hasMatch(value)) score++;
    return score.clamp(0, 4);
  }
}
