import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:shared_models/shared_models.dart';
import 'package:storage/storage.dart';

import 'package:auth/auth.dart';

class _StubAuthService implements AuthService {
  @override
  Future<Result<User, AppError>> currentUser(AuthToken token) async =>
      Ok<User, AppError>(const User(id: 'u', phone: '+1', displayName: 'u'));

  @override
  Future<Result<AuthToken, AppError>> refresh(AuthToken current) async =>
      Ok<AuthToken, AppError>(current);

  @override
  Future<Result<void, AppError>> requestOtp(String phone) async =>
      const Ok<void, AppError>(null);

  @override
  Future<Result<AuthToken, AppError>> signInWithOtp({
    required String phone,
    required String otp,
  }) async {
    return Ok<AuthToken, AppError>(
      AuthToken(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAt: DateTime.utc(2030, 1, 1),
      ),
    );
  }
}

void main() {
  group('AuthTokenProviderAdapter', () {
    late InMemorySecureStorage secure;
    late SecureTokenStorage tokenStorage;
    late DefaultSessionController session;
    late AuthTokenProviderAdapter adapter;

    setUp(() {
      secure = InMemorySecureStorage();
      tokenStorage = SecureTokenStorage(secure);
      session = DefaultSessionController(
        authService: _StubAuthService(),
        tokenStorage: tokenStorage,
      );
      adapter = AuthTokenProviderAdapter(
        sessionController: session,
        tokenStorage: tokenStorage,
      );
    });

    tearDown(() async {
      await session.dispose();
    });

    test('currentToken returns the stored accessToken', () async {
      await tokenStorage.write(
        AuthToken(
          accessToken: 'hello-token',
          refreshToken: 'r',
          expiresAt: DateTime.utc(2030, 1, 1),
        ),
      );

      expect(await adapter.currentToken(), 'hello-token');
    });

    test('currentToken returns null when nothing is persisted', () async {
      expect(await adapter.currentToken(), isNull);
    });

    test('currentToken returns null on decode error', () async {
      await secure.write(SecureTokenStorage.storageKey, 'broken-json');

      expect(await adapter.currentToken(), isNull);
    });

    test('invalidate signs out and clears storage', () async {
      await tokenStorage.write(
        AuthToken(
          accessToken: 'a',
          refreshToken: 'r',
          expiresAt: DateTime.utc(2030, 1, 1),
        ),
      );

      await adapter.invalidate();

      expect(session.current, const SessionAnonymous());
      final stored = await tokenStorage.read();
      expect(stored.valueOrThrow, isNull);
    });
  });
}
