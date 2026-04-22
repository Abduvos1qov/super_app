import 'package:dio/dio.dart';

import 'package:networking/src/interceptors/auth_interceptor.dart';
import 'package:networking/src/interceptors/logging_interceptor.dart';
import 'package:networking/src/interceptors/retry_interceptor.dart';
import 'package:networking/src/token_provider.dart';

/// A single shared [Dio] instance wired with the stock interceptor stack.
///
/// The order matters:
///
/// 1. [AuthInterceptor] — attaches the bearer token before any other stage
///    sees the request, so logs and retries operate on a fully-formed call.
/// 2. [LoggingInterceptor] — observes the outgoing request, the final
///    response, and any terminal error.
/// 3. [RetryInterceptor] — last in the chain so it can transparently replay
///    transient failures without the previous stages re-running token
///    lookup or emitting duplicate logs for the original failure.
///
/// Consumers interact with Dio via [dio]; most call sites should prefer
/// `NetworkGatewayImpl` which exposes a `Result`-based API instead.
class ApiClient {
  /// Builds an [ApiClient]. Tests can inject a pre-configured [Dio] and/or
  /// custom interceptors; production code passes only [baseUrl] and
  /// [tokenProvider] and lets the constructor install the default stack.
  ApiClient({
    required String baseUrl,
    required TokenProvider tokenProvider,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 20),
    Dio? dio,
    AuthInterceptor? authInterceptor,
    LoggingInterceptor? loggingInterceptor,
    RetryInterceptor? retryInterceptor,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: connectTimeout,
                receiveTimeout: receiveTimeout,
                contentType: 'application/json',
              ),
            ),
        _retryInterceptor = retryInterceptor ?? RetryInterceptor() {
    _dio.interceptors.addAll([
      authInterceptor ?? AuthInterceptor(tokenProvider),
      loggingInterceptor ?? LoggingInterceptor(),
      _retryInterceptor,
    ]);
    _retryInterceptor.attach(_dio);
  }

  final Dio _dio;
  final RetryInterceptor _retryInterceptor;

  /// The underlying Dio instance. Exposed so higher layers (like
  /// `NetworkGatewayImpl`) can issue requests; business code should prefer
  /// the gateway.
  Dio get dio => _dio;
}
