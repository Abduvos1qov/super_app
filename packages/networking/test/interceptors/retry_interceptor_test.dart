import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:networking/networking.dart';

/// Simulates a server that returns a canned sequence of [DioException] /
/// [Response] outcomes, one per attempt. Lets us exercise the retry
/// interceptor's replay logic without real network I/O.
class _ScriptedTransport extends Interceptor {
  _ScriptedTransport(this._script);

  final List<Object> _script;
  int attempts = 0;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final step = _script[attempts];
    attempts += 1;
    switch (step) {
      case final Response<Object?> response:
        handler.resolve(response.copyWith(requestOptions: options));
      case final DioException exception:
        handler.reject(
          DioException(
            requestOptions: options,
            type: exception.type,
            response: exception.response == null
                ? null
                : Response<Object?>(
                    requestOptions: options,
                    statusCode: exception.response?.statusCode,
                  ),
            message: exception.message,
          ),
          true,
        );
      default:
        throw StateError('Unsupported script step: $step');
    }
  }
}

extension _ResponseCopy on Response<Object?> {
  Response<Object?> copyWith({RequestOptions? requestOptions}) =>
      Response<Object?>(
        requestOptions: requestOptions ?? this.requestOptions,
        statusCode: statusCode,
        data: data,
      );
}

Dio _dioWith(_ScriptedTransport transport, RetryInterceptor retry) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
  retry.attach(dio);
  dio.interceptors.addAll([retry, transport]);
  return dio;
}

RetryInterceptor _retry({int maxRetries = 3}) => RetryInterceptor(
      maxRetries: maxRetries,
      baseDelay: const Duration(milliseconds: 1),
      delay: (_) async {},
    );

void main() {
  group('RetryInterceptor', () {
    test('retries a GET 500 response and resolves on eventual 200', () async {
      final transport = _ScriptedTransport([
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.badResponse,
          response: Response<Object?>(
            requestOptions: RequestOptions(path: '/x'),
            statusCode: 500,
          ),
        ),
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.badResponse,
          response: Response<Object?>(
            requestOptions: RequestOptions(path: '/x'),
            statusCode: 500,
          ),
        ),
        Response<Object?>(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 200,
          data: const {'ok': true},
        ),
      ]);
      final dio = _dioWith(transport, _retry());

      final response = await dio.get<Object?>('/x');

      expect(response.statusCode, equals(200));
      expect(transport.attempts, equals(3));
    });

    test('does not retry POST on 500', () async {
      final transport = _ScriptedTransport([
        DioException(
          requestOptions: RequestOptions(path: '/x', method: 'POST'),
          type: DioExceptionType.badResponse,
          response: Response<Object?>(
            requestOptions: RequestOptions(path: '/x'),
            statusCode: 500,
          ),
        ),
      ]);
      final dio = _dioWith(transport, _retry());

      await expectLater(dio.post<Object?>('/x'), throwsA(isA<DioException>()));
      expect(transport.attempts, equals(1));
    });

    test('retries on connection timeout', () async {
      final transport = _ScriptedTransport([
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionTimeout,
        ),
        Response<Object?>(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 200,
        ),
      ]);
      final dio = _dioWith(transport, _retry());

      final response = await dio.get<Object?>('/x');

      expect(response.statusCode, equals(200));
      expect(transport.attempts, equals(2));
    });

    test('gives up after maxRetries and rethrows the last error', () async {
      final transport = _ScriptedTransport(
        List<Object>.generate(
          10,
          (_) => DioException(
            requestOptions: RequestOptions(path: '/x'),
            type: DioExceptionType.badResponse,
            response: Response<Object?>(
              requestOptions: RequestOptions(path: '/x'),
              statusCode: 500,
            ),
          ),
        ),
      );
      final dio = _dioWith(transport, _retry());

      await expectLater(
        dio.get<Object?>('/x'),
        throwsA(isA<DioException>()),
      );
      // 1 original + 3 retries = 4 attempts total.
      expect(transport.attempts, equals(4));
    });

    test('does not retry on 4xx responses', () async {
      final transport = _ScriptedTransport([
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.badResponse,
          response: Response<Object?>(
            requestOptions: RequestOptions(path: '/x'),
            statusCode: 404,
          ),
        ),
      ]);
      final dio = _dioWith(transport, _retry());

      await expectLater(
        dio.get<Object?>('/x'),
        throwsA(isA<DioException>()),
      );
      expect(transport.attempts, equals(1));
    });

    test('retries DELETE (idempotent) on 5xx', () async {
      final transport = _ScriptedTransport([
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.badResponse,
          response: Response<Object?>(
            requestOptions: RequestOptions(path: '/x'),
            statusCode: 502,
          ),
        ),
        Response<Object?>(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 204,
        ),
      ]);
      final dio = _dioWith(transport, _retry());

      final response = await dio.delete<Object?>('/x');

      expect(response.statusCode, equals(204));
      expect(transport.attempts, equals(2));
    });
  });
}
