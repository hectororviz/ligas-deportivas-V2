import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/sanctions_models.dart';

class EditRulesDialog extends ConsumerStatefulWidget {
  final DisciplinaryRules rules;
  final Function(DisciplinaryRules) onSave;

  const EditRulesDialog({
    super.key,
    required this.rules,
    required this.onSave,
  });

  @override
  ConsumerState<EditRulesDialog> createState() => _EditRulesDialogState();
}

class _EditRulesDialogState extends ConsumerState<EditRulesDialog> {
  late int _yellowCardLimit;
  late int _yellowLimitSuspensionMatches;
  late int _directRedSuspensionMatches;
  late int _doubleYellowSuspensionMatches;
  late bool _resetYellowsOnPhaseChange;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _yellowCardLimit = widget.rules.yellowCardLimit;
    _yellowLimitSuspensionMatches = widget.rules.yellowLimitSuspensionMatches;
    _directRedSuspensionMatches = widget.rules.directRedSuspensionMatches;
    _doubleYellowSuspensionMatches = widget.rules.doubleYellowSuspensionMatches;
    _resetYellowsOnPhaseChange = widget.rules.resetYellowsOnPhaseChange;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Reglas Disciplinarias'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNumberField(
                label: 'Límite de amarillas',
                value: _yellowCardLimit,
                onChanged: (v) => setState(() => _yellowCardLimit = v),
                helperText: 'Cantidad de amarillas para suspensión',
              ),
              const SizedBox(height: 16),
              _buildNumberField(
                label: 'Suspensión por límite',
                value: _yellowLimitSuspensionMatches,
                onChanged: (v) => setState(() => _yellowLimitSuspensionMatches = v),
                helperText: 'Fechas de suspensión por acumulación',
              ),
              const SizedBox(height: 16),
              _buildNumberField(
                label: 'Suspensión por roja directa',
                value: _directRedSuspensionMatches,
                onChanged: (v) => setState(() => _directRedSuspensionMatches = v),
                helperText: 'Fechas de suspensión',
              ),
              const SizedBox(height: 16),
              _buildNumberField(
                label: 'Suspensión por doble amarilla',
                value: _doubleYellowSuspensionMatches,
                onChanged: (v) => setState(() => _doubleYellowSuspensionMatches = v),
                helperText: 'Fechas de suspensión',
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Resetear amarillas por fase'),
                subtitle: const Text('Las amarillas se resetean al cambiar de fase'),
                value: _resetYellowsOnPhaseChange,
                onChanged: (v) => setState(() => _resetYellowsOnPhaseChange = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    String? helperText,
  }) {
    return TextFormField(
      initialValue: value.toString(),
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      onChanged: (v) {
        final parsed = int.tryParse(v) ?? 1;
        onChanged(parsed.clamp(1, 99));
      },
    );
  }

  void _save() async {
    setState(() => _saving = true);
    
    final updated = DisciplinaryRules(
      id: widget.rules.id,
      tournamentId: widget.rules.tournamentId,
      yellowCardLimit: _yellowCardLimit,
      yellowLimitSuspensionMatches: _yellowLimitSuspensionMatches,
      directRedSuspensionMatches: _directRedSuspensionMatches,
      doubleYellowSuspensionMatches: _doubleYellowSuspensionMatches,
      resetYellowsOnPhaseChange: _resetYellowsOnPhaseChange,
      createdAt: widget.rules.createdAt,
      updatedAt: DateTime.now(),
    );
    
    await widget.onSave(updated);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
