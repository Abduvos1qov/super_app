import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:networking/networking.dart';

/// In-memory [LogOutput] that records every rendered line so tests can
/// assert the interceptor emitted the expected messages.
class _CapturingOutput extends LogOutput {
  final List<String> lines = [];

  @override
  void output(OutputEvent event) => lines.addAll(event.lines);
}

AppLogger _loggerWith(_CapturingOutput sink) => AppLogger(
      tag: 'test',
      logger: Logger(
        printer: SimplePrinter(colors: false),
        output: sink,
      ),
    );

void main() {
  group('LoggingInterceptor', () {
    test('logs outgoing request method and URI', () {
      final sink = _CapturingOutput();
      final sut = LoggingInterceptor(logger: _loggerWith(sink));
      final options = RequestOptions(path: '/ping', method: 'GET')
        ..baseUrl = 'https://example.com';

      sut.onRequest(options, _NoopRequestHandler());

      expect(
        sink.lines.any((l) => l.contains('--> GET') && l.contains('/ping')),
        isTrue,
      );
    });

    test('logs response status and elapsed duration', () {
      final sink = _CapturingOutput();
      final sut = LoggingInterceptor(logger: _loggerWith(sink));
      final options = RequestOptions(path: '/ping', method: 'GET');

      sut
        ..onRequest(options, _NoopRequestHandler())
        ..onResponse(
          Response<Object?>(
            requestOptions: options,
            statusCode: 200,
          ),
          _NoopResponseHandler(),
        );

      expect(
        sink.lines.any((l) => l.contains('<-- 200') && l.contains('ms')),
        isTrue,
      );
    });

    test('logs errors with the HTTP status code when available', () {
      final sink = _CapturingOutput();
      final sut = LoggingInterceptor(logger: _loggerWith(sink));
      final options = RequestOptions(path: '/ping', method: 'GET');

      sut
        ..onRequest(options, _NoopRequestHandler())
        ..onError(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response<Object?>(
              requestOptions: options,
              statusCode: 500,
            ),
            message: 'boom',
          ),
          _NoopErrorHandler(),
        );

      expect(
        sink.lines.any((l) => l.contains('xxx 500') && l.contains('boom')),
        isTrue,
      );
    });
  });
}

class _NoopRequestHandler extends RequestInterceptorHandler {
  @override
  void next(RequestOptions options) {}
}

class _NoopResponseHandler extends ResponseInterceptorHandler {
  @override
  void next(Response<dynamic> response) {}
}

class _NoopErrorHandler extends ErrorInterceptorHandler {
  @override
  void next(DioException err) {}
}
