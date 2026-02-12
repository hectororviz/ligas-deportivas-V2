import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_config.dart';
import 'auth_controller.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref));

class ApiClient {
  ApiClient(this.ref)
      : _dio = Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15)
          ),
        ) {
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      final authState = ref.read(authControllerProvider);
      final token = authState.accessToken;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    }, onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        final refreshed = await ref.read(authControllerProvider.notifier).tryRefresh();
        if (refreshed) {
          final token = ref.read(authControllerProvider).accessToken;
          if (token != null) {
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
          }
          final cloned = await _dio.fetch(error.requestOptions);
          return handler.resolve(cloned);
        }
      }
      return handler.next(error);
    }));
  }

  final Ref ref;
  final Dio _dio;

  String get baseUrl => _dio.options.baseUrl;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Options? options,
  }) {
    return _dio.post<T>(path, data: data, options: options);
  }

  Future<Response<T>> patch<T>(String path, {dynamic data}) {
    return _dio.patch<T>(path, data: data);
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) {
    return _dio.put<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path, {dynamic data}) {
    return _dio.delete<T>(path, data: data);
  }

  Future<Uint8List> getBytes(
    String path, {
    CancelToken? cancelToken,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get<List<int>>(
      path,
      queryParameters: queryParameters,
      options: Options(
        responseType: ResponseType.bytes,
        headers: headers,
      ),
      cancelToken: cancelToken,
    );
    final data = response.data;
    if (data == null) {
      throw StateError('No se recibieron datos para la imagen solicitada.');
    }
    return Uint8List.fromList(data);
  }
}
