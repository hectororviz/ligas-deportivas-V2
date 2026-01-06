import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_client.dart';
import 'site_identity.dart';
import 'site_identity_provider.dart';

class SiteIdentityPage extends ConsumerStatefulWidget {
  const SiteIdentityPage({super.key});

  @override
  ConsumerState<SiteIdentityPage> createState() => _SiteIdentityPageState();
}

class _SiteIdentityPageState extends ConsumerState<SiteIdentityPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final ProviderSubscription<AsyncValue<SiteIdentity>>
      _identitySubscription;

  bool _saving = false;
  Uint8List? _iconBytes;
  String? _iconFileName;
  bool _removeIcon = false;
  Uint8List? _faviconBytes;
  String? _faviconFileName;
  bool _removeFavicon = false;
  Uint8List? _loginImageBytes;
  String? _loginImageFileName;
  bool _removeLoginImage = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _identitySubscription =
        ref.listenManual(siteIdentityProvider, (previous, next) {
      next.whenData((identity) {
        if (!mounted) {
          return;
        }
        if (_titleController.text != identity.title) {
          _titleController
            ..text = identity.title
            ..selection =
                TextSelection.collapsed(offset: identity.title.length);
        }
      });
    });

    ref.read(siteIdentityProvider).whenData((identity) {
      if (!mounted) {
        return;
      }
      if (_titleController.text != identity.title) {
        _titleController
          ..text = identity.title
          ..selection = TextSelection.collapsed(offset: identity.title.length);
      }
    });
  }

  @override
  void dispose() {
    _identitySubscription.close();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final identityAsync = ref.watch(siteIdentityProvider);
    final identity = identityAsync.valueOrNull;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: identityAsync.when(
        data: (_) => _buildContent(context, identity),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('No se pudo cargar la identidad del sitio: $error'),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SiteIdentity? identity) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        Text(
          'Identidad del sitio',
          style: theme.textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Actualiza el nombre y el ícono que se muestran en la pantalla de inicio de sesión y en la navegación.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Marca e imagen', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIconPreview(identity),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ícono', style: theme.textTheme.titleSmall),
                            const SizedBox(height: 8),
                            Text(
                              'Se recomienda utilizar una imagen cuadrada de 200x200 px en formato PNG o JPG.',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _saving ? null : _pickIcon,
                                  icon: const Icon(Icons.upload_file_outlined),
                                  label: const Text('Seleccionar archivo'),
                                ),
                                if ((identity?.iconUrl != null ||
                                        _iconBytes != null) &&
                                    !_removeIcon)
                                  TextButton(
                                    onPressed: _saving
                                        ? null
                                        : () {
                                            setState(() {
                                              _iconBytes = null;
                                              _iconFileName = null;
                                              _removeIcon = true;
                                            });
                                          },
                                    child: const Text('Quitar ícono'),
                                  ),
                                if (_removeIcon)
                                  TextButton(
                                    onPressed: _saving
                                        ? null
                                        : () {
                                            setState(() {
                                              _removeIcon = false;
                                            });
                                          },
                                    child: const Text('Cancelar'),
                                  )
                              ],
                            ),
                            if (_iconFileName != null && !_removeIcon)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Seleccionado: $_iconFileName',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            if (_removeIcon)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'El ícono actual se eliminará.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.error),
                                ),
                              ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFaviconPreview(identity),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Favicon', style: theme.textTheme.titleSmall),
                            const SizedBox(height: 8),
                            Text(
                              'Se recomienda un favicon en formato SVG o PNG grande.',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _saving ? null : _pickFavicon,
                                  icon: const Icon(Icons.upload_file_outlined),
                                  label: const Text('Seleccionar archivo'),
                                ),
                                if ((identity?.faviconBasePath != null ||
                                        _faviconBytes != null) &&
                                    !_removeFavicon)
                                  TextButton(
                                    onPressed: _saving
                                        ? null
                                        : () {
                                            setState(() {
                                              _faviconBytes = null;
                                              _faviconFileName = null;
                                              _removeFavicon = true;
                                            });
                                          },
                                    child: const Text('Quitar favicon'),
                                  ),
                                if (_removeFavicon)
                                  TextButton(
                                    onPressed: _saving
                                        ? null
                                        : () {
                                            setState(() {
                                              _removeFavicon = false;
                                            });
                                          },
                                    child: const Text('Cancelar'),
                                  )
                              ],
                            ),
                            if (_faviconFileName != null && !_removeFavicon)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Seleccionado: $_faviconFileName',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            if (_removeFavicon)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'El favicon actual se eliminará.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.error),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLoginImagePreview(identity),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Inicio', style: theme.textTheme.titleSmall),
                            const SizedBox(height: 8),
                            Text(
                              'Imagen del login con tamaño recomendado de 320x250 px.',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _saving ? null : _pickLoginImage,
                                  icon: const Icon(Icons.upload_file_outlined),
                                  label: const Text('Seleccionar archivo'),
                                ),
                                if ((identity?.flyerUrl != null ||
                                        _loginImageBytes != null) &&
                                    !_removeLoginImage)
                                  TextButton(
                                    onPressed: _saving
                                        ? null
                                        : () {
                                            setState(() {
                                              _loginImageBytes = null;
                                              _loginImageFileName = null;
                                              _removeLoginImage = true;
                                            });
                                          },
                                    child: const Text('Quitar imagen'),
                                  ),
                                if (_removeLoginImage)
                                  TextButton(
                                    onPressed: _saving
                                        ? null
                                        : () {
                                            setState(() {
                                              _removeLoginImage = false;
                                            });
                                          },
                                    child: const Text('Cancelar'),
                                  )
                              ],
                            ),
                            if (_loginImageFileName != null && !_removeLoginImage)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Seleccionado: $_loginImageFileName',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            if (_removeLoginImage)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'La imagen de inicio se eliminará.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.error),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Título'),
                    validator: (value) {
                      if (value == null || value.trim().length < 3) {
                        return 'Ingresa un título válido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Guardar cambios'),
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

  Widget _buildIconPreview(SiteIdentity? identity) {
    Widget child;
    if (_removeIcon) {
      child = const Icon(Icons.hide_image_outlined, size: 32);
    } else if (_iconBytes != null) {
      child = Image.memory(_iconBytes!, fit: BoxFit.cover);
    } else if (identity?.iconUrl != null) {
      child = Image.network(identity!.iconUrl!, fit: BoxFit.cover);
    } else {
      child = const FlutterLogo(size: 32);
    }

    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _buildFaviconPreview(SiteIdentity? identity) {
    Widget child;
    if (_removeFavicon) {
      child = const Icon(Icons.hide_image_outlined, size: 20);
    } else if (_faviconBytes != null) {
      child = Image.memory(_faviconBytes!, fit: BoxFit.cover);
    } else if (identity?.faviconBasePath != null) {
      child = Image.network(
        '${identity!.faviconBasePath}/favicon-32x32.png',
        fit: BoxFit.cover,
      );
    } else {
      child = const Icon(Icons.public_outlined, size: 20);
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _buildLoginImagePreview(SiteIdentity? identity) {
    Widget child;
    if (_removeLoginImage) {
      child = const Icon(Icons.hide_image_outlined, size: 32);
    } else if (_loginImageBytes != null) {
      child = Image.memory(_loginImageBytes!, fit: BoxFit.cover);
    } else if (identity?.flyerUrl != null) {
      child = Image.network(identity!.flyerUrl!, fit: BoxFit.cover);
    } else {
      child = const Icon(Icons.image_outlined, size: 32);
    }

    return Container(
      width: 160,
      height: 125,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: child,
    );
  }

  Future<void> _pickIcon() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    if (file.bytes == null) {
      return;
    }

    setState(() {
      _iconBytes = file.bytes;
      _iconFileName = file.name;
      _removeIcon = false;
    });
  }

  Future<void> _pickFavicon() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'svg', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    if (file.bytes == null) {
      return;
    }

    setState(() {
      _faviconBytes = file.bytes;
      _faviconFileName = file.name;
      _removeFavicon = false;
    });
  }

  Future<void> _pickLoginImage() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    if (file.bytes == null) {
      return;
    }

    setState(() {
      _loginImageBytes = file.bytes;
      _loginImageFileName = file.name;
      _removeLoginImage = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final formData = FormData.fromMap({
        'title': _titleController.text.trim(),
      });

      if (_iconBytes != null) {
        formData.files.add(
          MapEntry(
            'icon',
            MultipartFile.fromBytes(
              _iconBytes!,
              filename: _iconFileName ?? 'site-icon.png',
            ),
          ),
        );
      } else if (_removeIcon) {
        formData.fields.add(const MapEntry('removeIcon', 'true'));
      }

      if (_loginImageBytes != null) {
        formData.files.add(
          MapEntry(
            'flyer',
            MultipartFile.fromBytes(
              _loginImageBytes!,
              filename: _loginImageFileName ?? 'login-image.png',
            ),
          ),
        );
      } else if (_removeLoginImage) {
        formData.fields.add(const MapEntry('removeFlyer', 'true'));
      }

      final apiClient = ref.read(apiClientProvider);
      await apiClient.put('/site-identity', data: formData);
      if (_faviconBytes != null || _removeFavicon) {
        final faviconData = FormData();
        if (_faviconBytes != null) {
          faviconData.files.add(
            MapEntry(
              'file',
              MultipartFile.fromBytes(
                _faviconBytes!,
                filename: _faviconFileName ?? 'favicon.png',
              ),
            ),
          );
        } else if (_removeFavicon) {
          faviconData.fields.add(const MapEntry('remove', 'true'));
        }
        await apiClient.post('/site-identity/favicon', data: faviconData);
      }
      ref.invalidate(siteIdentityProvider);
      await ref.read(siteIdentityProvider.future);

      if (!mounted) {
        return;
      }

      setState(() {
        _iconBytes = null;
        _iconFileName = null;
        _removeIcon = false;
        _faviconBytes = null;
        _faviconFileName = null;
        _removeFavicon = false;
        _loginImageBytes = null;
        _loginImageFileName = null;
        _removeLoginImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identidad del sitio actualizada.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la identidad: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }
}
