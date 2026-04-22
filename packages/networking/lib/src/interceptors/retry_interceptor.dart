import 'dart:async';

import 'package:dio/dio.dart';

/// Retries idempotent requests with exponential backoff.
///
/// Retries are attempted only when ALL of the following hold:
///
/// - The HTTP method is `GET`, `PUT`, or `DELETE` (POST is not safe to
///   replay without server-side idempotency keys, which are out of scope).
/// - The failure is either a connection/timeout error OR a 5xx response.
/// - The caller has not already exhausted [maxRetries] attempts.
///
/// Backoff is geometric with factor 2 starting at [baseDelay] — 100 ms,
/// 200 ms, 400 ms by default. A delay provider is exposed for tests so
/// retry timing can be faked without real wall-clock sleeps.
class RetryInterceptor extends Interceptor {
  /// Creates a retry interceptor with optional overrides for tests.
  ///
  /// [dio] is the instance that replays the request; consumers typically
  /// omit it at construction time and call [attach] once the shared client
  /// is available. [delay] is injectable so tests skip real wall-clock
  /// sleeps.
  RetryInterceptor({
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 100),
    Dio? dio,
    Future<void> Function(Duration duration)? delay,
  })  : _dio = dio,
        _delay = delay ?? _defaultDelay;

  static const _attemptKey = '__networking_retry_attempt__';

  static const _idempotentMethods = <String>{'GET', 'PUT', 'DELETE'};

  /// Maximum number of retry attempts after the original failure.
  final int maxRetries;

  /// Starting backoff duration; each subsequent attempt doubles this.
  final Duration baseDelay;

  Dio? _dio;
  final Future<void> Function(Duration duration) _delay;

  /// Wires the shared [Dio] instance into the interceptor so it can replay
  /// the failed request. Called by `ApiClient` during construction.
  // ignore: use_setters_to_change_properties
  void attach(Dio dio) => _dio = dio;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = (options.extra[_attemptKey] as int?) ?? 0;
    final dio = _dio;

    if (dio == null || !_shouldRetry(err, attempt)) {
      handler.next(err);
      return;
    }

    final nextAttempt = attempt + 1;
    final delay = baseDelay * (1 << attempt);
    await _delay(delay);

    options.extra[_attemptKey] = nextAttempt;

    try {
      final response = await dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  bool _shouldRetry(DioException err, int attempt) {
    if (attempt >= maxRetries) return false;
    final method = err.requestOptions.method.toUpperCase();
    if (!_idempotentMethods.contains(method)) return false;

    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        true,
      DioExceptionType.badResponse =>
        (err.response?.statusCode ?? 0) >= 500,
      DioExceptionType.badCertificate ||
      DioExceptionType.cancel ||
      DioExceptionType.unknown =>
        false,
    };
  }

  static Future<void> _defaultDelay(Duration duration) =>
      Future<void>.delayed(duration);
}
