import 'package:dio/dio.dart';

import '../../storage/token_storage.dart';

/// Attaches the bearer token to outgoing requests and evicts it on 401.
/// Refresh-token flow is intentionally deferred — add it when the auth
/// service lands.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.tokenStorage});

  final TokenStorage tokenStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenStorage.read();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await tokenStorage.clear();
    }
    handler.next(err);
  }
}
