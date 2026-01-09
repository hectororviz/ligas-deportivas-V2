import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../services/auth_controller.dart';

enum VerifyEmailStatus {
  loading,
  success,
  error,
  missingToken,
}

class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key, required this.token});

  final String? token;

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  VerifyEmailStatus _status = VerifyEmailStatus.loading;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final token = widget.token?.trim();
    if (token == null || token.isEmpty) {
      _status = VerifyEmailStatus.missingToken;
    } else {
      _verifyEmail(token);
    }
  }

  Future<void> _verifyEmail(String token) async {
    try {
      await ref.read(authControllerProvider.notifier).verifyEmail(token);
      if (!mounted) return;
      setState(() {
        _status = VerifyEmailStatus.success;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = VerifyEmailStatus.error;
        _errorMessage = 'No pudimos validar el correo. El enlace puede haber expirado.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String title;
    String message;
    IconData icon;
    Color iconColor;

    switch (_status) {
      case VerifyEmailStatus.loading:
        title = 'Validando correo';
        message = 'Estamos confirmando tu correo electrónico.';
        icon = Icons.mark_email_unread_outlined;
        iconColor = Theme.of(context).colorScheme.primary;
        break;
      case VerifyEmailStatus.success:
        title = 'Correo validado';
        message = 'Tu correo fue confirmado correctamente. Ya puedes iniciar sesión.';
        icon = Icons.check_circle_outline;
        iconColor = Colors.green;
        break;
      case VerifyEmailStatus.error:
        title = 'No se pudo validar';
        message = _errorMessage ?? 'Ocurrió un error al validar el correo.';
        icon = Icons.error_outline;
        iconColor = Theme.of(context).colorScheme.error;
        break;
      case VerifyEmailStatus.missingToken:
        title = 'Enlace incompleto';
        message = 'No encontramos el token de validación. Revisa el enlace recibido.';
        icon = Icons.link_off;
        iconColor = Theme.of(context).colorScheme.error;
        break;
    }

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(icon, size: 64, color: iconColor),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (_status == VerifyEmailStatus.loading)
                    const Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    FilledButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Ir a iniciar sesión'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
