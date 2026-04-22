import 'package:core/core.dart';
import 'package:dio/dio.dart';

/// Structured request/response/error logger that emits through [AppLogger].
///
/// Logs are tagged `networking` and include the HTTP method, path, status
/// code, and request duration. Request and response bodies are NOT logged —
/// they frequently contain PII or tokens and should be inspected via a
/// man-in-the-middle proxy when needed.
class LoggingInterceptor extends Interceptor {
  /// Builds an interceptor backed by [logger]. Tests pass a custom
  /// [AppLogger] with a capturing sink; production omits the argument and
  /// gets a default `networking`-tagged logger.
  LoggingInterceptor({AppLogger? logger})
      : _logger = logger ?? AppLogger(tag: 'networking');

  static const _startStampKey = '__networking_request_start__';

  final AppLogger _logger;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    options.extra[_startStampKey] = DateTime.now();
    _logger.info('--> ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final options = response.requestOptions;
    final duration = _elapsed(options);
    _logger.info(
      '<-- ${response.statusCode} ${options.method} ${options.uri}'
      ' (${duration.inMilliseconds}ms)',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    final duration = _elapsed(options);
    final status = err.response?.statusCode;
    _logger.warning(
      'xxx ${status ?? err.type.name} ${options.method} ${options.uri}'
      ' (${duration.inMilliseconds}ms): ${err.message ?? ''}',
      error: err,
    );
    handler.next(err);
  }

  Duration _elapsed(RequestOptions options) {
    if (options.extra[_startStampKey] case final DateTime start) {
      return DateTime.now().difference(start);
    }
    return Duration.zero;
  }
}
