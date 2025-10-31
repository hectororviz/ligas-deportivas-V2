import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/api_client.dart';

class AuthenticatedImage extends ConsumerStatefulWidget {
  const AuthenticatedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.error,
    this.headers,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? error;
  final Map<String, String>? headers;

  @override
  ConsumerState<AuthenticatedImage> createState() => _AuthenticatedImageState();
}

class _AuthenticatedImageState extends ConsumerState<AuthenticatedImage> {
  Uint8List? _bytes;
  Object? _error;
  bool _loading = false;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant AuthenticatedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    _cancelToken?.cancel();
    final url = widget.imageUrl.trim();
    if (url.isEmpty) {
      setState(() {
        _bytes = null;
        _error = null;
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _bytes = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final cancelToken = CancelToken();
      _cancelToken = cancelToken;
      final bytes = await api.getBytes(
        url,
        cancelToken: cancelToken,
        headers: widget.headers,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _bytes = bytes;
        _loading = false;
      });
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        gaplessPlayback: true,
      );
    }
    if (_loading) {
      return widget.placeholder ??
          const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null) {
      return widget.error ?? widget.placeholder ?? const SizedBox.shrink();
    }
    return widget.placeholder ?? const SizedBox.shrink();
  }
}
