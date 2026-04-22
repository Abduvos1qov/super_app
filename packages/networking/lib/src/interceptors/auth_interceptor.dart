import 'package:dio/dio.dart';

import 'package:networking/src/token_provider.dart';

/// Attaches the bearer token supplied by [TokenProvider] to every outgoing
/// request. On a `401 Unauthorized` response the token is invalidated so the
/// next request starts from a signed-out state.
///
/// Refresh-token flow is intentionally out of scope here; the auth package
/// observes invalidation through its own [TokenProvider] implementation and
/// decides whether to attempt a refresh or route the user to sign-in.
class AuthInterceptor extends Interceptor {
  /// Creates an interceptor that reads and invalidates tokens through the
  /// provided [TokenProvider].
  AuthInterceptor(this._tokenProvider);

  final TokenProvider _tokenProvider;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenProvider.currentToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await _tokenProvider.invalidate();
    }
    handler.next(err);
  }
}
