import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';

class FixturesPage extends ConsumerStatefulWidget {
  const FixturesPage({super.key});

  @override
  ConsumerState<FixturesPage> createState() => _FixturesPageState();
}

class _FixturesPageState extends ConsumerState<FixturesPage> {
  final _tournamentController = TextEditingController();
  String? _message;
  bool _loading = false;

  @override
  void dispose() {
    _tournamentController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final id = int.tryParse(_tournamentController.text.trim());
    if (id == null) {
      setState(() => _message = 'Ingresa un ID de torneo válido.');
      return;
    }
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await ref.read(apiClientProvider).post('/tournaments/$id/fixture');
      setState(() => _message = 'Fixture generado correctamente.');
    } catch (error) {
      setState(() => _message = 'Error generando fixture: $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Generación de Fixture',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            'Utiliza esta sección para generar rondas ida y vuelta según el método del círculo.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tournamentController,
                  decoration: const InputDecoration(labelText: 'ID de torneo'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _loading ? null : _generate,
                child: _loading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Generar fixture'),
              )
            ],
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(
              _message!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: _message!.startsWith('Error') ? Colors.red : Colors.green),
            )
          ]
        ],
      ),
    );
  }
}
