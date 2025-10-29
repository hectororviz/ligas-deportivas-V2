import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';
import '../../../services/auth_controller.dart';
import '../../shared/widgets/table_filters_bar.dart';

const _moduleCategories = 'CATEGORIAS';
const _actionCreate = 'CREATE';
const _actionUpdate = 'UPDATE';

class _CategoryFilters {
  const _CategoryFilters({this.query = ''});

  final String query;

  bool get isEmpty => query.trim().isEmpty;

  _CategoryFilters copyWith({String? query}) {
    return _CategoryFilters(query: query ?? this.query);
  }
}

class _CategoryFiltersController extends StateNotifier<_CategoryFilters> {
  _CategoryFiltersController() : super(const _CategoryFilters());

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void clear() {
    state = const _CategoryFilters();
  }
}

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

final categoryFiltersProvider =
    StateNotifierProvider<_CategoryFiltersController, _CategoryFilters>(
  (ref) => _CategoryFiltersController(),
);

final filteredCategoriesProvider =
    Provider<AsyncValue<List<CategorySummary>>>((ref) {
  final filters = ref.watch(categoryFiltersProvider);
  final categories = ref.watch(categoriesProvider);
  return categories.whenData((items) {
    final query = filters.query.trim().toLowerCase();
    if (query.isEmpty) {
      return items;
    }
    return items
        .where((category) {
          final normalizedName = category.name.toLowerCase();
          final range = category.birthYearRangeLabel.toLowerCase();
          final gender = category.genderLabel.toLowerCase();
          return normalizedName.contains(query) ||
              range.contains(query) ||
              gender.contains(query);
        })
        .toList();
  });
});

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(categoryFiltersProvider);
    _searchController = TextEditingController(text: filters.query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreateCategory() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => const _CategoryFormDialog(),
    );
    if (created == true) {
      ref.invalidate(categoriesProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categoría creada correctamente.')),
      );
    }
  }

  Future<void> _openEditCategory(CategorySummary category) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => _CategoryFormDialog(category: category),
    );
    if (updated == true) {
      ref.invalidate(categoriesProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Categoría "${category.name}" actualizada.')),
      );
    }
  }

  Future<void> _showCategoryDetails(CategorySummary category) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(category.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'Años de nacimiento', value: category.birthYearRangeLabel),
              _DetailRow(label: 'Género', value: category.genderLabel),
              _DetailRow(label: 'Estado', value: category.active ? 'Activa' : 'Inactiva'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Cerrar'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final canCreate =
        user?.hasPermission(module: _moduleCategories, action: _actionCreate) ?? false;
    final canEdit =
        user?.hasPermission(module: _moduleCategories, action: _actionUpdate) ?? false;
    final filters = ref.watch(categoryFiltersProvider);
    final categoriesAsync = ref.watch(filteredCategoriesProvider);
    final allCategoriesAsync = ref.watch(categoriesProvider);
    final totalCategories = allCategoriesAsync.maybeWhen(
      data: (value) => value.length,
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _openCreateCategory,
              icon: const Icon(Icons.add),
              label: const Text('Agregar categoría'),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categorias',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Administracion y creacion de categorias',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: TableFiltersBar(
                  children: [
                    TableFilterField(
                      label: 'Buscar',
                      width: 320,
                      child: TableFilterSearchField(
                        controller: _searchController,
                        placeholder: 'Buscar por nombre o género',
                        showClearButton: filters.query.isNotEmpty,
                        onChanged: (value) =>
                            ref.read(categoryFiltersProvider.notifier).setQuery(value),
                        onClear: () {
                          _searchController.clear();
                          ref.read(categoryFiltersProvider.notifier).clear();
                        },
                      ),
                    ),
                  ],
                  trailing: filters.isEmpty
                      ? null
                      : TextButton.icon(
                          onPressed: () {
                            _searchController.clear();
                            ref.read(categoryFiltersProvider.notifier).clear();
                          },
                          icon: const Icon(Icons.filter_alt_off_outlined),
                          label: const Text('Limpiar filtros'),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: categoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) {
                    if (!filters.isEmpty) {
                      return _CategoriesEmptyFiltersState(
                        onClear: () {
                          _searchController.clear();
                          ref.read(categoryFiltersProvider.notifier).clear();
                        },
                      );
                    }
                    return const _EmptyState();
                  }
                  return Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.category_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Categorías registradas',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              Text(
                                '${totalCategories ?? categories.length} en total',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: _CategoriesDataTable(
                            categories: categories,
                            canEdit: canEdit,
                            onDetails: _showCategoryDetails,
                            onEdit: _openEditCategory,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriesDataTable extends StatelessWidget {
  const _CategoriesDataTable({
    required this.categories,
    required this.canEdit,
    required this.onDetails,
    required this.onEdit,
  });

  final List<CategorySummary> categories;
  final bool canEdit;
  final ValueChanged<CategorySummary> onDetails;
  final ValueChanged<CategorySummary> onEdit;

  @override
  Widget build(BuildContext context) {
    final table = DataTable(
      headingRowHeight: 52,
      dataRowMinHeight: 64,
      dataRowMaxHeight: 80,
      columns: const [
        DataColumn(label: Text('Nombre')),
        DataColumn(label: Text('Años de nacimiento')),
        DataColumn(label: Text('Género')),
        DataColumn(label: Text('Activo')),
        DataColumn(label: Text('Acciones')),
      ],
      rows: categories
          .map(
            (category) => DataRow(
              cells: [
                DataCell(Text(category.name)),
                DataCell(Text(category.birthYearRangeLabel)),
                DataCell(Text(category.genderLabel)),
                DataCell(Text(category.active ? 'Activo' : 'Inactivo')),
                DataCell(
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => onDetails(category),
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Detalles'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: canEdit ? () => onEdit(category) : null,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          thumbVisibility: true,
          controller: PrimaryScrollController.maybeOf(context),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 12),
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: table,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoriesEmptyFiltersState extends StatelessWidget {
  const _CategoriesEmptyFiltersState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_alt_off_outlined, size: 48),
          const SizedBox(height: 12),
          const Text('No se encontraron categorías con los filtros actuales.'),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: onClear,
            child: const Text('Limpiar filtros'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
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
  const _CategoryFormDialog({this.category});

  final CategorySummary? category;

  @override
  ConsumerState<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _minYearController;
  late final TextEditingController _maxYearController;
  String _gender = 'MASCULINO';
  bool _active = true;
  bool _isSaving = false;
  Object? _errorMessage;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _nameController = TextEditingController(text: category?.name ?? '');
    _minYearController =
        TextEditingController(text: category?.birthYearMin.toString() ?? '');
    _maxYearController =
        TextEditingController(text: category?.birthYearMax.toString() ?? '');
    if (category != null) {
      _gender = category.gender;
      _active = category.active;
    }
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
      final payload = {
        'name': _nameController.text.trim(),
        'birthYearMin': minYear,
        'birthYearMax': maxYear,
        'gender': _gender,
        'active': _active,
      };
      if (widget.category == null) {
        await api.post('/categories', data: payload);
      } else {
        await api.patch('/categories/${widget.category!.id}', data: payload);
      }
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
                  widget.category == null ? 'Agregar categoría' : 'Editar categoría',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.category == null
                      ? 'Definí el rango de años, género y estado inicial de la categoría.'
                      : 'Actualizá el rango de años, género y estado de la categoría.',
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
                          : Text(
                              widget.category == null ? 'Guardar' : 'Guardar cambios'),
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
    required this.active,
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) => CategorySummary(
        id: json['id'] as int,
        name: json['name'] as String,
        birthYearMin: json['birthYearMin'] as int,
        birthYearMax: json['birthYearMax'] as int,
        gender: json['gender'] as String? ?? 'MIXTO',
        active: json['active'] as bool? ?? true,
      );

  final int id;
  final String name;
  final int birthYearMin;
  final int birthYearMax;
  final String gender;
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
