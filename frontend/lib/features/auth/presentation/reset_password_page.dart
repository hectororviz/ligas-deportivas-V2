import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../services/auth_controller.dart';

enum ResetPasswordStatus {
  form,
  success,
  missingToken,
  error,
}

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key, required this.token});

  final String? token;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  ResetPasswordStatus _status = ResetPasswordStatus.form;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final token = widget.token?.trim();
    if (token == null || token.isEmpty) {
      _status = ResetPasswordStatus.missingToken;
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    final password = value?.trim() ?? '';
    if (password.isEmpty) {
      return 'Ingresa una nueva contraseña.';
    }
    if (password.length < 8) {
      return 'Debe tener al menos 8 caracteres.';
    }
    final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$');
    if (!regex.hasMatch(password)) {
      return 'Debe incluir mayúsculas, minúsculas y un número.';
    }
    return null;
  }

  String? _validateConfirmation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma la contraseña.';
    }
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden.';
    }
    return null;
  }

  Future<void> _submit() async {
    final token = widget.token?.trim();
    if (token == null || token.isEmpty) {
      setState(() => _status = ResetPasswordStatus.missingToken);
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .resetPassword(token: token, password: _passwordController.text.trim());
      if (!mounted) return;
      setState(() => _status = ResetPasswordStatus.success);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = ResetPasswordStatus.error;
        _errorMessage = 'No pudimos restablecer la contraseña. El enlace puede haber expirado.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _buildContent(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    switch (_status) {
      case ResetPasswordStatus.missingToken:
        return _buildMessage(
          icon: Icons.link_off,
          iconColor: theme.colorScheme.error,
          title: 'Enlace incompleto',
          message: 'No encontramos el token para restablecer la contraseña.',
          actionLabel: 'Volver a iniciar sesión',
        );
      case ResetPasswordStatus.success:
        return _buildMessage(
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
          title: 'Contraseña actualizada',
          message: 'Ya puedes iniciar sesión con tu nueva contraseña.',
          actionLabel: 'Ir a iniciar sesión',
        );
      case ResetPasswordStatus.error:
        return _buildMessage(
          icon: Icons.error_outline,
          iconColor: theme.colorScheme.error,
          title: 'No se pudo restablecer',
          message: _errorMessage ?? 'Ocurrió un error al restablecer la contraseña.',
          actionLabel: 'Volver a iniciar sesión',
        );
      case ResetPasswordStatus.form:
        return _buildForm(theme);
    }
  }

  Widget _buildForm(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.lock_reset, size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          'Restablecer contraseña',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Ingresa una nueva contraseña segura para tu cuenta.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nueva contraseña',
                  border: OutlineInputBorder(),
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar contraseña',
                  border: OutlineInputBorder(),
                ),
                validator: _validateConfirmation,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Debe tener al menos 8 caracteres y contener mayúsculas, minúsculas y números.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Actualizar contraseña'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.go('/login'),
          child: const Text('Volver a iniciar sesión'),
        ),
      ],
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String actionLabel,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(icon, size: 64, color: iconColor),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => context.go('/login'),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}
