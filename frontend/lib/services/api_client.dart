import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref));

class ApiClient {
  ApiClient(this.ref)
      : _dio = Dio(
          BaseOptions(
            baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000/api/v1'),
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

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return _dio.post<T>(path, data: data);
  }

  Future<Response<T>> patch<T>(String path, {dynamic data}) {
    return _dio.patch<T>(path, data: data);
  }
}
