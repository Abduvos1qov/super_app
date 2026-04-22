import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:networking/networking.dart';

class _MockTokenProvider extends Mock implements TokenProvider {}

TokenProvider _stubTokenProvider() {
  final provider = _MockTokenProvider();
  when(provider.currentToken).thenAnswer((_) async => null);
  when(provider.invalidate).thenAnswer((_) async {});
  return provider;
}

/// Dio interceptor that short-circuits every request with a canned outcome.
/// Lets us assert the gateway's error-mapping logic without real I/O.
class _StubResponder extends Interceptor {
  _StubResponder(this._handle);

  final void Function(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) _handle;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) =>
      _handle(options, handler);
}

ApiClient _clientWith(Interceptor responder) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.com'))
    ..interceptors.add(responder);
  return ApiClient(
    baseUrl: 'https://example.com',
    tokenProvider: _stubTokenProvider(),
    dio: dio,
  );
}

Map<String, Object?> _echo(Object? json) =>
    (json as Map?)?.cast<String, Object?>() ?? const <String, Object?>{};

void main() {
  group('NetworkGatewayImpl', () {
    test('maps a 200 response to Ok with decoded payload', () async {
      final responder = _StubResponder((options, handler) {
        handler.resolve(
          Response<Object?>(
            requestOptions: options,
            statusCode: 200,
            data: const {'id': 42},
          ),
        );
      });
      final sut = NetworkGatewayImpl(_clientWith(responder));

      final result = await sut.get<Map<String, Object?>>(
        '/ping',
        decode: _echo,
      );

      expect(result, isA<Ok<Map<String, Object?>, AppError>>());
      expect(result.valueOrThrow, equals({'id': 42}));
    });

    test('maps 401 to AuthError with expiredToken kind', () async {
      final responder = _StubResponder((options, handler) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response<Object?>(
              requestOptions: options,
              statusCode: 401,
            ),
          ),
          true,
        );
      });
      final sut = NetworkGatewayImpl(_clientWith(responder));

      final result = await sut.get<Map<String, Object?>>(
        '/me',
        decode: _echo,
      );

      expect(result, isA<Err<Map<String, Object?>, AppError>>());
      final error = (result as Err<Map<String, Object?>, AppError>).error;
      expect(error, isA<AuthError>());
      expect((error as AuthError).kind, equals(AuthErrorKind.expiredToken));
    });

    test('maps 403 to AuthError with forbidden kind', () async {
      final responder = _StubResponder((options, handler) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response<Object?>(
              requestOptions: options,
              statusCode: 403,
            ),
          ),
          true,
        );
      });
      final sut = NetworkGatewayImpl(_clientWith(responder));

      final result = await sut.get<Map<String, Object?>>(
        '/me',
        decode: _echo,
      );

      final error = (result as Err<Map<String, Object?>, AppError>).error;
      expect(error, isA<AuthError>());
      expect((error as AuthError).kind, equals(AuthErrorKind.forbidden));
    });

    test('maps 5xx to ServerError carrying the status code', () async {
      final responder = _StubResponder((options, handler) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response<Object?>(
              requestOptions: options,
              statusCode: 503,
            ),
          ),
          true,
        );
      });
      final sut = NetworkGatewayImpl(_clientWith(responder));

      final result = await sut.get<Map<String, Object?>>(
        '/health',
        decode: _echo,
      );

      final error = (result as Err<Map<String, Object?>, AppError>).error;
      expect(error, isA<ServerError>());
      expect((error as ServerError).statusCode, equals(503));
    });

    test('maps non-401/403 4xx to ValidationError', () async {
      final responder = _StubResponder((options, handler) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response<Object?>(
              requestOptions: options,
              statusCode: 422,
            ),
          ),
          true,
        );
      });
      final sut = NetworkGatewayImpl(_clientWith(responder));

      final result = await sut.post<Map<String, Object?>>(
        '/submit',
        decode: _echo,
      );

      final error = (result as Err<Map<String, Object?>, AppError>).error;
      expect(error, isA<ValidationError>());
    });

    test('maps connection timeout to NetworkError', () async {
      final responder = _StubResponder((options, handler) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionTimeout,
          ),
          true,
        );
      });
      final sut = NetworkGatewayImpl(_clientWith(responder));

      final result = await sut.get<Map<String, Object?>>(
        '/slow',
        decode: _echo,
      );

      final error = (result as Err<Map<String, Object?>, AppError>).error;
      expect(error, isA<NetworkError>());
    });

    test('maps cancelled requests to UnknownError', () async {
      final responder = _StubResponder((options, handler) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
          ),
          true,
        );
      });
      final sut = NetworkGatewayImpl(_clientWith(responder));

      final result = await sut.get<Map<String, Object?>>(
        '/cancelled',
        decode: _echo,
      );

      final error = (result as Err<Map<String, Object?>, AppError>).error;
      expect(error, isA<UnknownError>());
    });

    test('put forwards body, query, and headers to Dio', () async {
      RequestOptions? captured;
      final responder = _StubResponder((options, handler) {
        captured = options;
        handler.resolve(
          Response<Object?>(
            requestOptions: options,
            statusCode: 200,
            data: const {'ok': true},
          ),
        );
      });
      final sut = NetworkGatewayImpl(_clientWith(responder));

      await sut.put<Map<String, Object?>>(
        '/resource/1',
        decode: _echo,
        body: const {'name': 'Aziz'},
        query: const {'expand': 'profile'},
        headers: const {'X-Trace': 'abc'},
      );

      expect(captured?.method, equals('PUT'));
      expect(captured?.data, equals({'name': 'Aziz'}));
      expect(captured?.queryParameters, equals({'expand': 'profile'}));
      expect(captured?.headers['X-Trace'], equals('abc'));
    });
  });
}
