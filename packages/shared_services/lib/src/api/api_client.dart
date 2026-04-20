import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../storage/token_storage.dart';
import 'interceptors/auth_interceptor.dart';

part 'api_client.g.dart';

/// Single [Dio] instance shared across every service. Features call methods
/// on `ApiClient.dio`; they never instantiate their own `Dio()`.
class ApiClient {
  ApiClient({
    required String baseUrl,
    required TokenStorage tokenStorage,
    Dio? dio,
  }) : _dio = (dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
                contentType: 'application/json',
              ),
            ))
          ..interceptors.add(AuthInterceptor(tokenStorage: tokenStorage));

  final Dio _dio;

  Dio get dio => _dio;
}

@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) => ApiClient(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8080',
      ),
      tokenStorage: ref.watch(tokenStorageProvider),
    );
