import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';

import 'package:auth/auth.dart';

void main() {
  group('SecureTokenStorage', () {
    late InMemorySecureStorage backing;
    late SecureTokenStorage sut;

    setUp(() {
      backing = InMemorySecureStorage();
      sut = SecureTokenStorage(backing);
    });

    test('read returns Ok(null) when nothing is persisted', () async {
      final result = await sut.read();

      expect(result, isA<Ok<AuthToken?, AppError>>());
      expect(result.valueOrThrow, isNull);
    });

    test('write then read round-trips the token', () async {
      final token = AuthToken(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAt: DateTime.utc(2030, 1, 1),
      );

      final writeResult = await sut.write(token);
      expect(writeResult.isOk, isTrue);

      final readResult = await sut.read();
      expect(readResult.valueOrThrow, equals(token));
    });

    test('clear removes the persisted token', () async {
      final token = AuthToken(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAt: DateTime.utc(2030, 1, 1),
      );
      await sut.write(token);

      final clearResult = await sut.clear();
      expect(clearResult.isOk, isTrue);

      final readResult = await sut.read();
      expect(readResult.valueOrThrow, isNull);
    });

    test('malformed JSON surfaces as ValidationError', () async {
      await backing.write(SecureTokenStorage.storageKey, 'not-json');

      final result = await sut.read();

      expect(result, isA<Err<AuthToken?, AppError>>());
      final error = (result as Err<AuthToken?, AppError>).error;
      expect(error, isA<ValidationError>());
    });
  });
}
