import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/sanctions_models.dart';

class CreateSuspensionDialog extends ConsumerStatefulWidget {
  final int playerId;
  final String playerName;
  final List<int> cardIds;
  final VoidCallback onCreated;

  const CreateSuspensionDialog({
    super.key,
    required this.playerId,
    required this.playerName,
    required this.cardIds,
    required this.onCreated,
  });

  @override
  ConsumerState<CreateSuspensionDialog> createState() => _CreateSuspensionDialogState();
}

class _CreateSuspensionDialogState extends ConsumerState<CreateSuspensionDialog> {
  int _originalMatches = 1;
  String _reason = '';
  bool _creating = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear Suspensión'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jugador: ${widget.playerName}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (widget.cardIds.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Tarjetas vinculadas: ${widget.cardIds.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 24),
              TextFormField(
                initialValue: _originalMatches.toString(),
                decoration: const InputDecoration(
                  labelText: 'Fechas de suspensión',
                  helperText: 'Cantidad de partidos que debe cumplir',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final parsed = int.tryParse(v) ?? 1;
                  setState(() => _originalMatches = parsed.clamp(1, 99));
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Motivo (opcional)',
                  helperText: 'Razón de la suspensión',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (v) => setState(() => _reason = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _creating ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _creating ? null : _create,
          child: _creating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Crear Suspensión'),
        ),
      ],
    );
  }

  void _create() {
    setState(() => _creating = true);
    widget.onCreated();
    Navigator.of(context).pop();
  }
}
