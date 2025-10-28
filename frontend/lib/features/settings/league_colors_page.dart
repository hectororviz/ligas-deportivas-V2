import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../leagues/presentation/leagues_page.dart';
import '../../services/api_client.dart';

class LeagueColorsPage extends ConsumerStatefulWidget {
  const LeagueColorsPage({super.key});

  @override
  ConsumerState<LeagueColorsPage> createState() => _LeagueColorsPageState();
}

class _LeagueColorsPageState extends ConsumerState<LeagueColorsPage> {
  int? _updatingLeagueId;

  Future<void> _updateLeagueColor(League league) async {
    final newColor = await _promptForColor(league);
    if (newColor == null || !mounted) {
      return;
    }

    setState(() => _updatingLeagueId = league.id);
    try {
      await ref
          .read(apiClientProvider)
          .patch('/leagues/${league.id}', data: {'colorHex': newColor});
      ref.invalidate(leaguesProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Color de "${league.name}" actualizado.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el color: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingLeagueId = null);
      }
    }
  }

  Future<String?> _promptForColor(League league) async {
    final controller = TextEditingController(text: league.colorHex.toUpperCase());
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Color para ${league.name}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Código hexadecimal',
                  hintText: '#0057B8',
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  final regex = RegExp(r'^#([0-9a-fA-F]{6})$');
                  if (!regex.hasMatch(text)) {
                    return 'Ingresa un color válido en formato #RRGGBB.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const Text('Vista previa:'),
                    const SizedBox(width: 12),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller,
                      builder: (context, value, child) {
                        final text = value.text.trim();
                        Color previewColor;
                        try {
                          previewColor = Color(int.parse(text.replaceFirst('#', '0xff')));
                        } catch (_) {
                          previewColor = league.color;
                        }
                        return Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: previewColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                        );
                      },
                    )
                  ],
                ),
              )
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(controller.text.trim().toUpperCase());
              }
            },
            child: const Text('Guardar'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leaguesAsync = ref.watch(leaguesProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Colores por liga',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Actualiza los colores distintivos para identificar rápidamente cada liga en la plataforma.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: leaguesAsync.when(
              data: (leagues) {
                if (leagues.isEmpty) {
                  return const Center(
                    child: Text('No hay ligas registradas para configurar.'),
                  );
                }
                return ListView.separated(
                  itemCount: leagues.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final league = leagues[index];
                    final isUpdating = _updatingLeagueId == league.id;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: league.color),
                        title: Text(league.name),
                        subtitle: Text('Color actual: ${league.colorHex}'),
                        trailing: isUpdating
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : FilledButton.tonal(
                                onPressed: () => _updateLeagueColor(league),
                                child: const Text('Editar color'),
                              ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('No se pudieron cargar las ligas: $error'),
              ),
            ),
          )
        ],
      ),
    );
  }
}
