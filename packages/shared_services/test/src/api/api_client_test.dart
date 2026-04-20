import 'package:flutter_test/flutter_test.dart';
import 'package:shared_services/shared_services.dart';

void main() {
  group('ApiClient', () {
    test('attaches AuthInterceptor and propagates base URL', () {
      final client = ApiClient(
        baseUrl: 'https://api.example.test',
        tokenStorage: InMemoryTokenStorage(),
      );

      expect(client.dio.options.baseUrl, equals('https://api.example.test'));
      expect(
        client.dio.interceptors.whereType<AuthInterceptor>(),
        isNotEmpty,
      );
    });
  });
}
