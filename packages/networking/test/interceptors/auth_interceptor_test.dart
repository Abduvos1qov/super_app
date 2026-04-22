import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:networking/networking.dart';

class _MockTokenProvider extends Mock implements TokenProvider {}

void main() {
  group('AuthInterceptor', () {
    late TokenProvider tokenProvider;
    late AuthInterceptor sut;

    setUp(() {
      tokenProvider = _MockTokenProvider();
      sut = AuthInterceptor(tokenProvider);
    });

    test('attaches Bearer header when a token is present', () async {
      when(() => tokenProvider.currentToken())
          .thenAnswer((_) async => 'abc-123');

      final options = RequestOptions(path: '/x');
      RequestOptions? resolved;
      final handler = _CapturingRequestHandler((opts) => resolved = opts);

      await sut.onRequest(options, handler);

      expect(resolved?.headers['Authorization'], equals('Bearer abc-123'));
    });

    test('does not set Authorization when token is null', () async {
      when(() => tokenProvider.currentToken()).thenAnswer((_) async => null);

      final options = RequestOptions(path: '/x');
      RequestOptions? resolved;
      final handler = _CapturingRequestHandler((opts) => resolved = opts);

      await sut.onRequest(options, handler);

      expect(resolved?.headers.containsKey('Authorization'), isFalse);
    });

    test('does not set Authorization when token is empty', () async {
      when(() => tokenProvider.currentToken()).thenAnswer((_) async => '');

      final options = RequestOptions(path: '/x');
      RequestOptions? resolved;
      final handler = _CapturingRequestHandler((opts) => resolved = opts);

      await sut.onRequest(options, handler);

      expect(resolved?.headers.containsKey('Authorization'), isFalse);
    });

    test('invalidates the token on 401 response', () async {
      when(() => tokenProvider.invalidate()).thenAnswer((_) async {});

      final options = RequestOptions(path: '/x');
      final err = DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<Object?>(
          requestOptions: options,
          statusCode: 401,
        ),
      );
      final handler = _CapturingErrorHandler();

      await sut.onError(err, handler);

      verify(() => tokenProvider.invalidate()).called(1);
    });

    test('does not invalidate on non-401 responses', () async {
      when(() => tokenProvider.invalidate()).thenAnswer((_) async {});

      final options = RequestOptions(path: '/x');
      final err = DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<Object?>(
          requestOptions: options,
          statusCode: 500,
        ),
      );
      final handler = _CapturingErrorHandler();

      await sut.onError(err, handler);

      verifyNever(() => tokenProvider.invalidate());
    });
  });
}

/// Minimal [RequestInterceptorHandler] stand-in that captures the options
/// passed to `next(...)` so we can assert on mutated headers.
class _CapturingRequestHandler extends RequestInterceptorHandler {
  _CapturingRequestHandler(this._onNext);

  final void Function(RequestOptions options) _onNext;

  @override
  void next(RequestOptions options) => _onNext(options);
}

class _CapturingErrorHandler extends ErrorInterceptorHandler {
  @override
  void next(DioException err) {}
}
