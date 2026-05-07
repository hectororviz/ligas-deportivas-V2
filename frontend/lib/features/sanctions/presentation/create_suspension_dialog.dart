import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateSuspensionResult {
  final int originalMatches;
  final String? reason;

  CreateSuspensionResult({
    required this.originalMatches,
    this.reason,
  });
}

class CreateSuspensionDialog extends ConsumerStatefulWidget {
  final String playerName;
  final int yellowCardCount;

  const CreateSuspensionDialog({
    super.key,
    required this.playerName,
    this.yellowCardCount = 0,
  });

  @override
  ConsumerState<CreateSuspensionDialog> createState() => _CreateSuspensionDialogState();
}

class _CreateSuspensionDialogState extends ConsumerState<CreateSuspensionDialog> {
  late int _originalMatches;
  String _reason = '';
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    // Default: 1 match for yellow limit accumulation, more could be configured
    _originalMatches = widget.yellowCardCount > 0 ? 1 : 1;
  }

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
              if (widget.yellowCardCount > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Acumulación de ${widget.yellowCardCount} amarillas',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 12,
                    ),
                  ),
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
                onChanged: (v) => setState(() => _reason = v.isEmpty ? '' : v),
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
    
    // Return the result to the caller
    Navigator.of(context).pop(CreateSuspensionResult(
      originalMatches: _originalMatches,
      reason: _reason.isEmpty ? null : _reason,
    ));
  }
}
