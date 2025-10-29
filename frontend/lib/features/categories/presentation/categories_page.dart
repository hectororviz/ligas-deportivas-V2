import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';
import '../../../services/auth_controller.dart';

const _moduleCategories = 'CATEGORIAS';
const _actionCreate = 'CREATE';

final categoriesProvider = FutureProvider<List<CategorySummary>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<List<dynamic>>('/categories');
  final data = response.data ?? [];
  final categories = data
      .map((item) => CategorySummary.fromJson(item as Map<String, dynamic>))
      .toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return categories;
});

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final canCreate =
        user?.hasPermission(module: _moduleCategories, action: _actionCreate) ?? false;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await showDialog<bool>(
                  context: context,
                  builder: (context) => const _CategoryFormDialog(),
                );
                if (created == true) {
                  ref.invalidate(categoriesProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Categoría creada correctamente.')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Agregar categoría'),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: categoriesAsync.when(
          data: (categories) {
            if (categories.isEmpty) {
              return const _EmptyState();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Categorías',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Consulta el detalle de edades, género y estado de cada categoría habilitada.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowHeight: 52,
                        dataRowMinHeight: 56,
                        dataRowMaxHeight: 72,
                        columns: const [
                          DataColumn(label: Text('Nombre')),
                          DataColumn(label: Text('Años de nacimiento')),
                          DataColumn(label: Text('Género')),
                          DataColumn(label: Text('Promocional')),
                          DataColumn(label: Text('Activo')),
                        ],
                        rows: categories
                            .map(
                              (category) => DataRow(
                                cells: [
                                  DataCell(Text(category.name)),
                                  DataCell(Text(category.birthYearRangeLabel)),
                                  DataCell(Text(category.genderLabel)),
                                  DataCell(Text(category.promotional ? 'Sí' : 'No')),
                                  DataCell(Text(category.active ? 'Sí' : 'No')),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          error: (error, stackTrace) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'No se pudieron cargar las categorías.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$error',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () => ref.invalidate(categoriesProvider),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.category_outlined,
                  size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Aún no se cargaron categorías',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Creá las categorías para organizar a tus equipos por edades y género.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryFormDialog extends ConsumerStatefulWidget {
  const _CategoryFormDialog();

  @override
  ConsumerState<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _minYearController;
  late final TextEditingController _maxYearController;
  String _gender = 'MASCULINO';
  bool _promotional = false;
  bool _active = true;
  bool _isSaving = false;
  Object? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _minYearController = TextEditingController();
    _maxYearController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minYearController.dispose();
    _maxYearController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final minYear = int.tryParse(_minYearController.text.trim());
    final maxYear = int.tryParse(_maxYearController.text.trim());
    if (minYear == null || maxYear == null) {
      setState(() {
        _errorMessage = 'Ingresá un rango de años válido.';
      });
      return;
    }
    if (minYear > maxYear) {
      setState(() {
        _errorMessage = 'El año mínimo no puede ser mayor al máximo.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      await api.post('/categories', data: {
        'name': _nameController.text.trim(),
        'birthYearMin': minYear,
        'birthYearMax': maxYear,
        'gender': _gender,
        'promotional': _promotional,
        'active': _active,
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.response?.data is Map<String, dynamic>
            ? (error.response?.data['message'] ?? error.message)
            : error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Agregar categoría',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Definí el rango de años, género y estado inicial de la categoría.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ej. Sub-11',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es obligatorio.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minYearController,
                        decoration: const InputDecoration(
                          labelText: 'Año de nacimiento (mínimo)',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Obligatorio';
                          }
                          final parsed = int.tryParse(value.trim());
                          if (parsed == null) {
                            return 'Ingresá un número válido.';
                          }
                          if (parsed < 1900 || parsed > 2100) {
                            return 'Ingresá un año válido.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _maxYearController,
                        decoration: const InputDecoration(
                          labelText: 'Año de nacimiento (máximo)',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Obligatorio';
                          }
                          final parsed = int.tryParse(value.trim());
                          if (parsed == null) {
                            return 'Ingresá un número válido.';
                          }
                          if (parsed < 1900 || parsed > 2100) {
                            return 'Ingresá un año válido.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _gender,
                  items: const [
                    DropdownMenuItem(value: 'MASCULINO', child: Text('Masculino')),
                    DropdownMenuItem(value: 'FEMENINO', child: Text('Femenino')),
                    DropdownMenuItem(value: 'MIXTO', child: Text('Mixto')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _gender = value);
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Género'),
                ),
                const SizedBox(height: 16),
                SwitchListTile.adaptive(
                  value: _promotional,
                  onChanged: (value) => setState(() => _promotional = value),
                  title: const Text('Categoría promocional'),
                  contentPadding: EdgeInsets.zero,
                  subtitle: const Text('Las categorías promocionales no suman a la tabla general.'),
                ),
                SwitchListTile.adaptive(
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                  title: const Text('Categoría activa'),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    '$_errorMessage',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CategorySummary {
  CategorySummary({
    required this.id,
    required this.name,
    required this.birthYearMin,
    required this.birthYearMax,
    required this.gender,
    required this.promotional,
    required this.active,
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) => CategorySummary(
        id: json['id'] as int,
        name: json['name'] as String,
        birthYearMin: json['birthYearMin'] as int,
        birthYearMax: json['birthYearMax'] as int,
        gender: json['gender'] as String? ?? 'MIXTO',
        promotional: json['promotional'] as bool? ?? false,
        active: json['active'] as bool? ?? true,
      );

  final int id;
  final String name;
  final int birthYearMin;
  final int birthYearMax;
  final String gender;
  final bool promotional;
  final bool active;

  String get birthYearRangeLabel {
    if (birthYearMin == birthYearMax) {
      return '$birthYearMin';
    }
    return '$birthYearMin - $birthYearMax';
  }

  String get genderLabel {
    switch (gender) {
      case 'MASCULINO':
        return 'Masculino';
      case 'FEMENINO':
        return 'Femenino';
      default:
        return 'Mixto';
    }
  }
}
