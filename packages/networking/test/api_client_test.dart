import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:networking/networking.dart';

class _MockTokenProvider extends Mock implements TokenProvider {}

void main() {
  group('ApiClient', () {
    late TokenProvider tokenProvider;

    setUp(() {
      tokenProvider = _MockTokenProvider();
    });

    test('applies base URL and timeouts to Dio options', () {
      final sut = ApiClient(
        baseUrl: 'https://example.com/api/',
        tokenProvider: tokenProvider,
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 7),
      );

      expect(sut.dio.options.baseUrl, equals('https://example.com/api/'));
      expect(
        sut.dio.options.connectTimeout,
        equals(const Duration(seconds: 3)),
      );
      expect(
        sut.dio.options.receiveTimeout,
        equals(const Duration(seconds: 7)),
      );
      expect(sut.dio.options.contentType, equals('application/json'));
    });

    test('installs auth, logging, and retry interceptors in order', () {
      final sut = ApiClient(
        baseUrl: 'https://example.com',
        tokenProvider: tokenProvider,
      );

      // Dio auto-installs an internal ImplyContentTypeInterceptor ahead of
      // any user interceptors; our stack follows in the documented order.
      final ours = sut.dio.interceptors
          .where(
            (i) =>
                i is AuthInterceptor ||
                i is LoggingInterceptor ||
                i is RetryInterceptor,
          )
          .toList();
      expect(ours, hasLength(3));
      expect(ours[0], isA<AuthInterceptor>());
      expect(ours[1], isA<LoggingInterceptor>());
      expect(ours[2], isA<RetryInterceptor>());
    });
  });
}
